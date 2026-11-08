import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/seed_data.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/crashlytics_service.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/spark_quota_service.dart';
import '../../../devices/domain/repositories/devices_repository.dart';
import '../../domain/entities/room.dart';
import '../../domain/repositories/rooms_repository.dart';
import 'rooms_state.dart';

/// Cubit managing smart home rooms, real-time room streams, search filtering,
/// and safe cascading room deletions (preserving devices or deleting them).
/// Dispatches privacy-safe analytics events, logs unexpected room operation errors,
/// and guards Firestore resource limits under Firebase Spark Plan.
class RoomsCubit extends Cubit<RoomsState> {
  final RoomsRepository roomsRepository;
  final DevicesRepository devicesRepository;
  final AnalyticsService? analyticsService;
  final CrashlyticsService? crashlyticsService;
  final SparkQuotaService? quotaService;
  final LocalCacheService? localCacheService;

  StreamSubscription<List<Room>>? _roomsSubscription;
  String? _currentUserId;

  RoomsCubit({
    required this.roomsRepository,
    required this.devicesRepository,
    this.analyticsService,
    this.crashlyticsService,
    this.quotaService,
    this.localCacheService,
  }) : super(RoomsLoaded(
          rooms: localCacheService?.loadRooms() ?? SeedData.defaultRooms,
        ));

  RoomsLoaded _ensureLoaded() {
    if (state is RoomsLoaded) {
      return state as RoomsLoaded;
    }
    final defaultList = localCacheService?.loadRooms() ?? SeedData.defaultRooms;
    final loaded = RoomsLoaded(rooms: defaultList);
    emit(loaded);
    return loaded;
  }

  /// Loads and listens to real-time updates for all rooms belonging to [userId].
  void loadRooms(String userId) {
    final cleanUid = userId.trim();
    if (cleanUid.isEmpty) {
      return;
    }
    _currentUserId = cleanUid;

    _ensureLoaded();

    _roomsSubscription?.cancel();
    quotaService?.registerListener('RoomsCubit_$cleanUid');

    try {
      _roomsSubscription = roomsRepository.watchRooms(cleanUid).listen(
        (rooms) {
          if (rooms.isEmpty) return;
          localCacheService?.saveRooms(rooms);
          if (state is RoomsLoaded) {
            final current = state as RoomsLoaded;
            emit(current.copyWith(rooms: rooms, isSaving: false));
          } else {
            emit(RoomsLoaded(rooms: rooms));
          }
        },
        onError: (error, stack) {
          crashlyticsService?.recordError(
            error,
            stack,
            reason: 'Rooms watchRooms stream notice for user: $cleanUid',
          );
          debugPrint('RoomsCubit: Stream notice ($error). Using local active rooms.');
        },
      );
    } catch (e) {
      debugPrint('RoomsCubit: watchRooms initialization notice: $e');
    }
  }

  /// Creates a new room in the user's home.
  Future<void> createRoom({
    required String userId,
    required String name,
    required String iconName,
    double? targetTemperature,
    int? humidity,
    String? imageAsset,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      _emitErrorMessage('Oda adı boş bırakılamaz.');
      return;
    }

    final current = _ensureLoaded();
    if (quotaService != null && !quotaService!.canCreateRoom(current.rooms.length)) {
      _emitErrorMessage(
        'Maksimum oda sınırına (${quotaService!.maxRoomsPerUser}) ulaşıldı. Spark planı kotası gereği daha fazla oda eklenemez.',
      );
      return;
    }

    final roomId = 'room-${DateTime.now().millisecondsSinceEpoch}';
    final room = Room(
      id: roomId,
      name: cleanName,
      iconName: iconName.isNotEmpty ? iconName : 'chair',
      targetTemperature: targetTemperature ?? AppConstants.defaultRoomTemp,
      humidity: humidity ?? 50,
      imageAsset: imageAsset,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final cleanUid = userId.trim().isEmpty ? 'demo-user' : userId.trim();
    final res = await roomsRepository.createRoom(cleanUid, room);
    if (res.isFailure) {
      _emitErrorMessage(res.failure.message);
      return;
    }

    final updated = [...current.rooms, room];
    emit(current.copyWith(rooms: updated, isSaving: false, feedbackMessage: 'Oda başarıyla eklendi.'));
    localCacheService?.saveRooms(updated);
    analyticsService?.logRoomCreated(roomType: room.iconName);
  }

  /// Updates an existing room's details.
  Future<void> updateRoom({
    required String userId,
    required Room room,
  }) async {
    final cleanName = room.name.trim();
    if (cleanName.isEmpty) {
      _emitErrorMessage('Oda adı boş bırakılamaz.');
      return;
    }

    final updatedRoom = room.copyWith(
      name: cleanName,
      updatedAt: DateTime.now(),
    );

    final cleanUid = userId.trim().isEmpty ? 'demo-user' : userId.trim();
    final res = await roomsRepository.updateRoom(cleanUid, updatedRoom);
    if (res.isFailure) {
      _emitErrorMessage(res.failure.message);
      return;
    }

    final current = _ensureLoaded();
    final updated = current.rooms.map((r) => r.id == room.id ? updatedRoom : r).toList();
    emit(current.copyWith(rooms: updated, isSaving: false, feedbackMessage: 'Oda başarıyla güncellendi.'));
    localCacheService?.saveRooms(updated);
  }

  /// Deletes a room.
  /// If [moveToRoomId] is provided and non-empty, all devices located in this room
  /// will be safely reassigned to the target room before deleting the room.
  /// If [moveToRoomId] is null or empty, all associated devices are deleted atomically.
  Future<void> deleteRoom({
    required String userId,
    required String roomId,
    String? moveToRoomId,
  }) async {
    final cleanRoomId = roomId.trim();
    if (cleanRoomId.isEmpty) {
      _emitErrorMessage('Geçersiz silme isteği.');
      return;
    }

    final cleanUid = userId.trim().isEmpty ? 'demo-user' : userId.trim();
    if (moveToRoomId != null && moveToRoomId.trim().isNotEmpty) {
      final moveRes = await devicesRepository.moveDevicesToRoom(
        cleanUid,
        cleanRoomId,
        moveToRoomId.trim(),
      );
      if (moveRes.isFailure) {
        _emitErrorMessage('Cihazlar taşınamadığı için oda silme işlemi iptal edildi.');
        return;
      }
    } else {
      final deleteDevsRes = await devicesRepository.deleteDevicesByRoom(
        cleanUid,
        cleanRoomId,
      );
      if (deleteDevsRes.isFailure) {
        _emitErrorMessage('Oda cihazları silinemediği için oda silme işlemi iptal edildi.');
        return;
      }
    }

    final deleteRoomRes = await roomsRepository.deleteRoom(cleanUid, cleanRoomId);
    if (deleteRoomRes.isFailure) {
      _emitErrorMessage(deleteRoomRes.failure.message);
      return;
    }

    final current = _ensureLoaded();
    final updated = current.rooms.where((r) => r.id != cleanRoomId).toList();
    emit(current.copyWith(
      rooms: updated,
      isSaving: false,
      feedbackMessage: moveToRoomId != null && moveToRoomId.trim().isNotEmpty
          ? 'Oda silindi ve cihazlar başarıyla aktarıldı.'
          : 'Oda ve ilişkili cihazlar başarıyla silindi.',
    ));
    localCacheService?.saveRooms(updated);
    analyticsService?.logRoomDeleted(roomId: cleanRoomId);
  }

  /// Updates search query for filtering room lists in the UI.
  void searchRooms(String query) {
    if (state is RoomsLoaded) {
      final current = state as RoomsLoaded;
      emit(current.copyWith(searchQuery: query));
    }
  }

  /// Alias for searchRooms.
  void setSearchQuery(String query) => searchRooms(query);

  /// Clears search filter.
  void clearSearch() {
    if (state is RoomsLoaded) {
      final current = state as RoomsLoaded;
      emit(current.copyWith(clearSearch: true));
    }
  }

  /// Clears transient feedback or error messages.
  void clearMessages() {
    if (state is RoomsLoaded) {
      final current = state as RoomsLoaded;
      emit(current.copyWith(clearFeedback: true, clearError: true));
    }
  }

  void _emitErrorMessage(String message) {
    if (state is RoomsLoaded) {
      final current = state as RoomsLoaded;
      emit(current.copyWith(
        isSaving: false,
        errorMessage: message,
      ));
    }
  }

  /// Currently active authenticated user ID.
  String? get currentUserId => _currentUserId;

  /// Convenience method for deleting a room by ID.
  Future<void> deleteRoomById(String roomId, {String? moveToRoomId, String? userId}) {
    return deleteRoom(
      userId: userId ?? _currentUserId ?? 'demo-user',
      roomId: roomId,
      moveToRoomId: moveToRoomId,
    );
  }

  /// Convenience method for adding a Room entity.
  Future<void> addRoomEntity(Room room, {String? userId}) {
    return createRoom(
      userId: userId ?? _currentUserId ?? 'demo-user',
      name: room.name,
      iconName: room.iconName,
      targetTemperature: room.targetTemperature,
      humidity: room.humidity,
      imageAsset: room.imageAsset,
    );
  }

  /// Convenience method for updating an existing Room entity.
  Future<void> updateRoomEntity(Room room, {String? userId}) {
    return updateRoom(
      userId: userId ?? _currentUserId ?? 'demo-user',
      room: room,
    );
  }

  /// Updates the image asset or local file path of a room and persists it.
  Future<void> updateRoomImage(String roomId, String? imagePath, {String? userId}) async {
    final current = _ensureLoaded();
    final target = current.rooms.where((r) => r.id == roomId).firstOrNull;
    if (target == null) return;
    final updatedRoom = target.copyWith(
      imageAsset: imagePath,
      clearImageAsset: imagePath == null,
    );
    await updateRoom(userId: userId ?? _currentUserId ?? 'demo-user', room: updatedRoom);
  }

  @override
  Future<void> close() {
    _roomsSubscription?.cancel();
    if (_currentUserId != null) {
      quotaService?.unregisterListener('RoomsCubit_$_currentUserId');
    }
    return super.close();
  }
}
