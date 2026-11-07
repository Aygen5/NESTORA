import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../devices/domain/repositories/devices_repository.dart';
import '../../domain/entities/room.dart';
import '../../domain/repositories/rooms_repository.dart';
import 'rooms_state.dart';

/// Cubit managing smart home rooms, real-time room streams, search filtering,
/// and safe cascading room deletions (preserving devices or deleting them).
class RoomsCubit extends Cubit<RoomsState> {
  final RoomsRepository roomsRepository;
  final DevicesRepository devicesRepository;

  StreamSubscription<List<Room>>? _roomsSubscription;
  String? _currentUserId;

  RoomsCubit({
    required this.roomsRepository,
    required this.devicesRepository,
  }) : super(const RoomsInitial());

  /// Loads and listens to real-time updates for all rooms belonging to [userId].
  void loadRooms(String userId) {
    final cleanUid = userId.trim();
    if (cleanUid.isEmpty) {
      emit(const RoomsError('Geçersiz kullanıcı kimliği.'));
      return;
    }
    _currentUserId = cleanUid;

    if (state is! RoomsLoaded) {
      emit(const RoomsLoading());
    }

    _roomsSubscription?.cancel();

    _roomsSubscription = roomsRepository.watchRooms(cleanUid).listen(
      (rooms) {
        if (state is RoomsLoaded) {
          final current = state as RoomsLoaded;
          emit(current.copyWith(rooms: rooms, isSaving: false));
        } else {
          emit(RoomsLoaded(rooms: rooms));
        }
      },
      onError: (error) {
        emit(RoomsError('Odalar yüklenirken bir hata oluştu: $error'));
      },
    );
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

    final cleanUid = userId.trim();
    if (cleanUid.isEmpty) {
      _emitErrorMessage('Geçersiz kullanıcı kimliği.');
      return;
    }

    _setSaving(true);

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

    final result = await roomsRepository.createRoom(cleanUid, room);

    if (result.isSuccess) {
      _emitSuccessMessage('Oda başarıyla eklendi.');
    } else {
      _emitErrorMessage(result.failure.message);
    }
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

    final cleanUid = userId.trim();
    if (cleanUid.isEmpty) {
      _emitErrorMessage('Geçersiz kullanıcı kimliği.');
      return;
    }

    _setSaving(true);

    final updatedRoom = room.copyWith(
      name: cleanName,
      updatedAt: DateTime.now(),
    );

    final result = await roomsRepository.updateRoom(cleanUid, updatedRoom);

    if (result.isSuccess) {
      _emitSuccessMessage('Oda başarıyla güncellendi.');
    } else {
      _emitErrorMessage(result.failure.message);
    }
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
    final cleanUid = userId.trim();
    final cleanRoomId = roomId.trim();

    if (cleanUid.isEmpty || cleanRoomId.isEmpty) {
      _emitErrorMessage('Geçersiz silme isteği.');
      return;
    }

    _setSaving(true);

    // 1. Handle associated devices safely
    if (moveToRoomId != null && moveToRoomId.trim().isNotEmpty) {
      final moveRes = await devicesRepository.moveDevicesToRoom(
        cleanUid,
        cleanRoomId,
        moveToRoomId.trim(),
      );
      if (moveRes.isFailure) {
        _emitErrorMessage(
          'Cihazlar taşınamadığı için oda silinemedi: ${moveRes.failure.message}',
        );
        return;
      }
    } else {
      final deleteDevicesRes = await devicesRepository.deleteDevicesByRoom(
        cleanUid,
        cleanRoomId,
      );
      if (deleteDevicesRes.isFailure) {
        _emitErrorMessage(
          'Oda cihazları silinemediği için işlem durduruldu: ${deleteDevicesRes.failure.message}',
        );
        return;
      }
    }

    // 2. Delete room document
    final deleteRoomRes = await roomsRepository.deleteRoom(cleanUid, cleanRoomId);

    if (deleteRoomRes.isSuccess) {
      final msg = moveToRoomId != null && moveToRoomId.trim().isNotEmpty
          ? 'Oda silindi ve cihazlar başarıyla aktarıldı.'
          : 'Oda ve ilişkili cihazlar başarıyla silindi.';
      _emitSuccessMessage(msg);
    } else {
      _emitErrorMessage(deleteRoomRes.failure.message);
    }
  }

  /// Updates search query for filtering room lists in the UI.
  void searchRooms(String query) {
    if (state is RoomsLoaded) {
      final current = state as RoomsLoaded;
      emit(current.copyWith(searchQuery: query));
    }
  }

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

  void _setSaving(bool isSaving) {
    if (state is RoomsLoaded) {
      final current = state as RoomsLoaded;
      emit(current.copyWith(
        isSaving: isSaving,
        clearFeedback: true,
        clearError: true,
      ));
    }
  }

  void _emitSuccessMessage(String message) {
    if (state is RoomsLoaded) {
      final current = state as RoomsLoaded;
      emit(current.copyWith(
        isSaving: false,
        feedbackMessage: message,
      ));
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
  Future<void> deleteRoomById(String roomId, {String? userId}) {
    return deleteRoom(
      userId: userId ?? _currentUserId ?? 'demo-user',
      roomId: roomId,
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
    );
  }

  @override
  Future<void> close() {
    _roomsSubscription?.cancel();
    return super.close();
  }
}
