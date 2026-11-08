import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/app/di/injection.dart';
import 'package:nestora/core/errors/failures.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/devices/domain/repositories/devices_repository.dart';
import 'package:nestora/features/rooms/domain/entities/room.dart';
import 'package:nestora/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_cubit.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Fake RoomsRepository
class FakeRoomsRepository implements RoomsRepository {
  bool shouldThrow = false;
  String errorMessage = 'Oda sunucu hatası';
  final List<Room> rooms = [];

  final StreamController<List<Room>> _controller =
      StreamController<List<Room>>.broadcast();

  void emitRooms(List<Room> list) {
    rooms.clear();
    rooms.addAll(list);
    _controller.add(List.from(rooms));
  }

  void emitError(dynamic error) {
    _controller.addError(error);
  }

  @override
  Stream<List<Room>> watchRooms(String userId) => _controller.stream;

  @override
  Future<Result<List<Room>>> getRooms(String userId) async {
    if (shouldThrow) return Result.failure(ServerFailure(errorMessage));
    return Result.success(rooms);
  }

  @override
  Future<Result<Room>> getRoomById(String userId, String roomId) async {
    if (shouldThrow) return Result.failure(ServerFailure(errorMessage));
    final room = rooms.firstWhere(
      (r) => r.id == roomId,
      orElse: () => throw StateError('Not found'),
    );
    return Result.success(room);
  }

  @override
  Future<Result<void>> createRoom(String userId, Room room) async {
    if (shouldThrow) return Result.failure(ServerFailure(errorMessage));
    rooms.add(room);
    _controller.add(List.from(rooms));
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateRoom(String userId, Room room) async {
    if (shouldThrow) return Result.failure(ServerFailure(errorMessage));
    final idx = rooms.indexWhere((r) => r.id == room.id);
    if (idx != -1) {
      rooms[idx] = room;
      _controller.add(List.from(rooms));
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteRoom(String userId, String roomId) async {
    if (shouldThrow) return Result.failure(ServerFailure(errorMessage));
    rooms.removeWhere((r) => r.id == roomId);
    _controller.add(List.from(rooms));
    return Result.success(null);
  }
}

// Fake DevicesRepository
class FakeDevicesRepository implements DevicesRepository {
  bool shouldFailMove = false;
  bool shouldFailDelete = false;
  String? movedFromRoomId;
  String? movedToRoomId;
  String? deletedRoomId;

  @override
  Future<Result<void>> moveDevicesToRoom(
    String userId,
    String fromRoomId,
    String toRoomId,
  ) async {
    if (shouldFailMove) {
      return Result.failure(const ServerFailure('Cihaz taşıma hatası'));
    }
    movedFromRoomId = fromRoomId;
    movedToRoomId = toRoomId;
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteDevicesByRoom(String userId, String roomId) async {
    if (shouldFailDelete) {
      return Result.failure(const ServerFailure('Oda cihazları silinemedi'));
    }
    deletedRoomId = roomId;
    return Result.success(null);
  }

  // Stubs for other methods
  @override
  Stream<List<Device>> watchDevices(String userId) => const Stream.empty();
  @override
  Stream<List<Device>> watchDevicesByRoom(String userId, String roomId) =>
      const Stream.empty();
  @override
  Future<Result<List<Device>>> getDevices(String userId) async =>
      Result.success(const []);
  @override
  Future<Result<Device>> getDeviceById(String userId, String deviceId) async =>
      Result.failure(const ServerFailure('Not implemented'));
  @override
  Future<Result<void>> createDevice(String userId, Device device) async =>
      Result.success(null);
  @override
  Future<Result<void>> updateDevice(String userId, Device device) async =>
      Result.success(null);
  @override
  Future<Result<void>> updateDeviceState(
    String userId,
    String deviceId,
    Map<String, dynamic> stateUpdates,
  ) async =>
      Result.success(null);
  @override
  Future<Result<void>> deleteDevice(String userId, String deviceId) async =>
      Result.success(null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeRoomsRepository fakeRoomsRepo;
  late FakeDevicesRepository fakeDevicesRepo;
  late RoomsCubit cubit;

  final sampleRooms = [
    const Room(
      id: 'living-room',
      name: 'Salon',
      iconName: 'chair',
      targetTemperature: 22.0,
      deviceCount: 3,
      activeDeviceCount: 2,
    ),
    const Room(
      id: 'bedroom',
      name: 'Yatak Odası',
      iconName: 'bed',
      targetTemperature: 20.5,
      deviceCount: 2,
      activeDeviceCount: 1,
    ),
    const Room(
      id: 'kitchen',
      name: 'Mutfak',
      iconName: 'kitchen',
      targetTemperature: 21.0,
      deviceCount: 1,
      activeDeviceCount: 0,
    ),
  ];

  setUp(() {
    fakeRoomsRepo = FakeRoomsRepository();
    fakeDevicesRepo = FakeDevicesRepository();
    cubit = RoomsCubit(
      roomsRepository: fakeRoomsRepo,
      devicesRepository: fakeDevicesRepo,
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  group('RoomsCubit Initialization & Stream Tests', () {
    test('initial state is RoomsLoaded in offline/demo simulation mode', () {
      expect(cubit.state, isA<RoomsLoaded>());
      final loaded = cubit.state as RoomsLoaded;
      expect(loaded.rooms.isNotEmpty, isTrue);
    });

    test('loadRooms with empty userId preserves loaded state', () {
      cubit.loadRooms('   ');
      expect(cubit.state, isA<RoomsLoaded>());
    });

    test('loadRooms updates RoomsLoaded with rooms list', () async {
      final states = <RoomsState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.loadRooms('user-1');

      fakeRoomsRepo.emitRooms(sampleRooms);
      await pumpEventQueue();

      final loaded = cubit.state as RoomsLoaded;
      expect(loaded.rooms.length, 3);
      expect(loaded.totalRooms, 3);

      await sub.cancel();
    });

    test('loadRooms maintains resilient loaded state on stream error', () async {
      cubit.loadRooms('user-1');
      fakeRoomsRepo.emitError('Bağlantı koptu');
      await pumpEventQueue();

      expect(cubit.state, isA<RoomsLoaded>());
    });
  });

  group('RoomsLoaded Helper & Search Tests', () {
    setUp(() async {
      cubit.loadRooms('user-1');
      fakeRoomsRepo.emitRooms(sampleRooms);
      await pumpEventQueue();
    });

    test('findRoomById returns matching room or null', () {
      final state = cubit.state as RoomsLoaded;
      expect(state.findRoomById('living-room')?.name, 'Salon');
      expect(state.findRoomById('non-existent'), isNull);
    });

    test('searchRooms filters room list case-insensitively and clearSearch resets it', () {
      cubit.searchRooms('sa');
      var state = cubit.state as RoomsLoaded;
      expect(state.filteredRooms.length, 1);
      expect(state.filteredRooms.first.name, 'Salon');

      cubit.searchRooms('Oda');
      state = cubit.state as RoomsLoaded;
      expect(state.filteredRooms.length, 1);
      expect(state.filteredRooms.first.name, 'Yatak Odası');

      cubit.clearSearch();
      state = cubit.state as RoomsLoaded;
      expect(state.filteredRooms.length, 3);
    });
  });

  group('RoomsCubit CRUD Operations Tests', () {
    setUp(() async {
      cubit.loadRooms('user-1');
      fakeRoomsRepo.emitRooms(sampleRooms);
      await pumpEventQueue();
    });

    test('createRoom rejects empty room name', () async {
      await cubit.createRoom(
        userId: 'user-1',
        name: '   ',
        iconName: 'chair',
      );

      final state = cubit.state as RoomsLoaded;
      expect(state.errorMessage, 'Oda adı boş bırakılamaz.');
    });

    test('createRoom successfully adds a room and emits feedback', () async {
      await cubit.createRoom(
        userId: 'user-1',
        name: 'Çalışma Odası',
        iconName: 'desk',
        targetTemperature: 21.5,
      );

      final state = cubit.state as RoomsLoaded;
      expect(state.feedbackMessage, 'Oda başarıyla eklendi.');
      expect(fakeRoomsRepo.rooms.length, 4);
      expect(fakeRoomsRepo.rooms.last.name, 'Çalışma Odası');
    });

    test('createRoom reports error on repository failure', () async {
      fakeRoomsRepo.shouldThrow = true;
      fakeRoomsRepo.errorMessage = 'Oda ekleme başarısız';

      await cubit.createRoom(
        userId: 'user-1',
        name: 'Balkon',
        iconName: 'deck',
      );

      final state = cubit.state as RoomsLoaded;
      expect(state.errorMessage, 'Oda ekleme başarısız');
    });

    test('updateRoom rejects empty room name', () async {
      final room = sampleRooms.first.copyWith(name: '  ');
      await cubit.updateRoom(userId: 'user-1', room: room);

      final state = cubit.state as RoomsLoaded;
      expect(state.errorMessage, 'Oda adı boş bırakılamaz.');
    });

    test('updateRoom successfully updates room details', () async {
      final updated = sampleRooms.first.copyWith(
        name: 'Büyük Salon',
        targetTemperature: 23.0,
      );
      await cubit.updateRoom(userId: 'user-1', room: updated);

      final state = cubit.state as RoomsLoaded;
      expect(state.feedbackMessage, 'Oda başarıyla güncellendi.');
      expect(fakeRoomsRepo.rooms.first.name, 'Büyük Salon');
      expect(fakeRoomsRepo.rooms.first.targetTemperature, 23.0);
    });
  });

  group('RoomsCubit Safe Room Deletion & Device Handling Tests', () {
    setUp(() async {
      cubit.loadRooms('user-1');
      fakeRoomsRepo.emitRooms(sampleRooms);
      await pumpEventQueue();
    });

    test('deleteRoom with moveToRoomId moves devices first then deletes room', () async {
      await cubit.deleteRoom(
        userId: 'user-1',
        roomId: 'living-room',
        moveToRoomId: 'bedroom',
      );

      expect(fakeDevicesRepo.movedFromRoomId, 'living-room');
      expect(fakeDevicesRepo.movedToRoomId, 'bedroom');
      expect(fakeRoomsRepo.rooms.any((r) => r.id == 'living-room'), isFalse);

      final state = cubit.state as RoomsLoaded;
      expect(state.feedbackMessage, contains('cihazlar başarıyla aktarıldı'));
    });

    test('deleteRoom without moveToRoomId deletes associated devices and room', () async {
      await cubit.deleteRoom(
        userId: 'user-1',
        roomId: 'living-room',
      );

      expect(fakeDevicesRepo.deletedRoomId, 'living-room');
      expect(fakeRoomsRepo.rooms.any((r) => r.id == 'living-room'), isFalse);

      final state = cubit.state as RoomsLoaded;
      expect(state.feedbackMessage, contains('ilişkili cihazlar başarıyla silindi'));
    });

    test('deleteRoom aborts and emits error if moving devices fails', () async {
      fakeDevicesRepo.shouldFailMove = true;

      await cubit.deleteRoom(
        userId: 'user-1',
        roomId: 'living-room',
        moveToRoomId: 'bedroom',
      );

      expect(fakeRoomsRepo.rooms.any((r) => r.id == 'living-room'), isTrue); // Not deleted!
      final state = cubit.state as RoomsLoaded;
      expect(state.errorMessage, contains('Cihazlar taşınamadığı için'));
    });

    test('deleteRoom aborts and emits error if deleting devices fails', () async {
      fakeDevicesRepo.shouldFailDelete = true;

      await cubit.deleteRoom(
        userId: 'user-1',
        roomId: 'living-room',
      );

      expect(fakeRoomsRepo.rooms.any((r) => r.id == 'living-room'), isTrue); // Not deleted!
      final state = cubit.state as RoomsLoaded;
      expect(state.errorMessage, contains('Oda cihazları silinemediği için'));
    });

    test('clearMessages clears feedback and error', () async {
      await cubit.createRoom(
        userId: 'user-1',
        name: 'Test Oda',
        iconName: 'chair',
      );

      var state = cubit.state as RoomsLoaded;
      expect(state.feedbackMessage, isNotNull);

      cubit.clearMessages();
      state = cubit.state as RoomsLoaded;
      expect(state.feedbackMessage, isNull);
      expect(state.errorMessage, isNull);
    });
  });

  group('ServiceLocator Registration for RoomsCubit', () {
    setUp(() async {
      sl.reset();
      SharedPreferences.setMockInitialValues({});
      final p = await SharedPreferences.getInstance();
      await initDependencies(sharedPreferences: p);
    });

    tearDown(() {
      sl.reset();
    });

    test('RoomsCubit is registered and resolvable from ServiceLocator', () {
      expect(sl.isRegistered<RoomsCubit>(), isTrue);
      final roomsCubit = sl<RoomsCubit>();
      expect(roomsCubit, isA<RoomsCubit>());
      roomsCubit.close();
    });
  });
}
