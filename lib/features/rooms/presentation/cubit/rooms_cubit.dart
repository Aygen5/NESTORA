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
import '../../domain/usecases/rooms_usecases.dart';
import 'rooms_state.dart';

// Akıllı ev odalarını, gerçek zamanlı oda akışlarını ve silme/taşıma işlemlerini yönetir.
class RoomsCubit extends Cubit<RoomsState> {
  final RoomsRepository roomsRepository;
  final DevicesRepository devicesRepository;
  final AnalyticsService? analyticsService;
  final CrashlyticsService? crashlyticsService;
  final SparkQuotaService? quotaService;
  final LocalCacheService? localCacheService;

  // İş mantığı kullanım senaryoları (Use Cases)
  final GetRoomsUseCase getRoomsUseCase;
  final WatchRoomsUseCase watchRoomsUseCase;
  final CreateRoomUseCase createRoomUseCase;
  final UpdateRoomUseCase updateRoomUseCase;
  final DeleteRoomUseCase deleteRoomUseCase;

  StreamSubscription<List<Room>>? _roomsSubscription;
  String? _currentUserId;

  RoomsCubit({
    required this.roomsRepository,
    required this.devicesRepository,
    this.analyticsService,
    this.crashlyticsService,
    this.quotaService,
    this.localCacheService,
    GetRoomsUseCase? getRoomsUseCase,
    WatchRoomsUseCase? watchRoomsUseCase,
    CreateRoomUseCase? createRoomUseCase,
    UpdateRoomUseCase? updateRoomUseCase,
    DeleteRoomUseCase? deleteRoomUseCase,
  })  : getRoomsUseCase = getRoomsUseCase ?? GetRoomsUseCase(roomsRepository),
        watchRoomsUseCase = watchRoomsUseCase ?? WatchRoomsUseCase(roomsRepository),
        createRoomUseCase = createRoomUseCase ?? CreateRoomUseCase(roomsRepository),
        updateRoomUseCase = updateRoomUseCase ?? UpdateRoomUseCase(roomsRepository),
        deleteRoomUseCase = deleteRoomUseCase ?? DeleteRoomUseCase(roomsRepository),
        super(RoomsLoaded(
          rooms: localCacheService?.loadRooms() ?? SeedData.defaultRooms,
        ));

  RoomsLoaded _ensureLoaded() {
    if (state is RoomsLoaded) {
      return state as RoomsLoaded;
    }
    final defaultList = localCacheService?.loadRooms(userId: _currentUserId) ??
        (_currentUserId == SeedData.defaultProfile.uid ? SeedData.defaultRooms : <Room>[]);
    final loaded = RoomsLoaded(rooms: defaultList);
    emit(loaded);
    return loaded;
  }

  // Çıkış yapıldığında oda durumunu sıfırlar ve akış dinleyicisini iptal eder.
  void reset() {
    _roomsSubscription?.cancel();
    _currentUserId = null;
    emit(RoomsLoaded(
      rooms: localCacheService?.loadRooms(userId: 'usr-1') ?? SeedData.defaultRooms,
    ));
  }

  // Kullanıcıya ait tüm odaları gerçek zamanlı dinler ve yükler.
  void loadRooms(String userId) {
    final cleanUid = userId.trim();
    if (cleanUid.isEmpty) {
      return;
    }
    _currentUserId = cleanUid;

    final initialRooms = localCacheService?.loadRooms(userId: cleanUid);
    final effectiveInitial = (initialRooms != null && initialRooms.isNotEmpty)
        ? initialRooms
        : (cleanUid == SeedData.defaultProfile.uid ? SeedData.defaultRooms : <Room>[]);
    emit(RoomsLoaded(rooms: effectiveInitial));

    _roomsSubscription?.cancel();
    quotaService?.registerListener('RoomsCubit_$cleanUid');

    try {
      _roomsSubscription = watchRoomsUseCase(cleanUid).listen(
        (rooms) {
          final effectiveRooms = (rooms.isEmpty && cleanUid == SeedData.defaultProfile.uid)
              ? (localCacheService?.loadRooms(userId: cleanUid) ?? SeedData.defaultRooms)
              : rooms;

          localCacheService?.saveRooms(effectiveRooms, userId: cleanUid);
          if (state is RoomsLoaded) {
            final current = state as RoomsLoaded;
            emit(current.copyWith(rooms: effectiveRooms, isSaving: false));
          } else {
            emit(RoomsLoaded(rooms: effectiveRooms));
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

  // Eve yeni bir oda ekler.
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
    final res = await createRoomUseCase(CreateRoomParams(userId: cleanUid, room: room));
    if (res.isFailure) {
      _emitErrorMessage(res.failure.message);
      return;
    }

    final updated = [...current.rooms, room];
    emit(current.copyWith(rooms: updated, isSaving: false, feedbackMessage: 'Oda başarıyla eklendi.'));
    localCacheService?.saveRooms(updated, userId: cleanUid);
    analyticsService?.logRoomCreated(roomType: room.iconName);
  }

  // Mevcut bir odanın bilgilerini günceller.
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
    final res = await updateRoomUseCase(UpdateRoomParams(userId: cleanUid, room: updatedRoom));
    if (res.isFailure) {
      _emitErrorMessage(res.failure.message);
      return;
    }

    final current = _ensureLoaded();
    final updated = current.rooms.map((r) => r.id == room.id ? updatedRoom : r).toList();
    emit(current.copyWith(rooms: updated, isSaving: false, feedbackMessage: 'Oda başarıyla güncellendi.'));
    localCacheService?.saveRooms(updated, userId: cleanUid);
  }

  // Odayı ve isteğe bağlı olarak içindeki cihazları siler ya da başka odaya taşır.
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

    final deleteRoomRes = await deleteRoomUseCase(DeleteRoomParams(userId: cleanUid, roomId: cleanRoomId));
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
    localCacheService?.saveRooms(updated, userId: cleanUid);
    analyticsService?.logRoomDeleted(roomId: cleanRoomId);
  }

  // Arayüzde oda araması için filtre sorgusunu günceller.
  void searchRooms(String query) {
    if (state is RoomsLoaded) {
      final current = state as RoomsLoaded;
      emit(current.copyWith(searchQuery: query));
    }
  }

  // Arama metodu takma adı.
  void setSearchQuery(String query) => searchRooms(query);

  // Arama filtresini temizler.
  void clearSearch() {
    if (state is RoomsLoaded) {
      final current = state as RoomsLoaded;
      emit(current.copyWith(clearSearch: true));
    }
  }

  // Geçici bildirim ve hata mesajlarını temizler.
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

  // Oturumu açık olan kullanıcının ID'si.
  String? get currentUserId => _currentUserId;

  // ID ile oda silmek için yardımcı metot.
  Future<void> deleteRoomById(String roomId, {String? moveToRoomId, String? userId}) {
    return deleteRoom(
      userId: userId ?? _currentUserId ?? 'demo-user',
      roomId: roomId,
      moveToRoomId: moveToRoomId,
    );
  }

  // Oda nesnesi eklemek için yardımcı metot.
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

  // Oda nesnesi güncellemek için yardımcı metot.
  Future<void> updateRoomEntity(Room room, {String? userId}) {
    return updateRoom(
      userId: userId ?? _currentUserId ?? 'demo-user',
      room: room,
    );
  }

  // Odanın görsel veya kapak fotoğrafı yolunu günceller.
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
