import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/core/constants/app_constants.dart';
import 'package:nestora/core/constants/seed_data.dart';
import 'package:nestora/core/errors/failures.dart';
import 'package:nestora/core/services/local_cache_service.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/devices/domain/repositories/devices_repository.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_cubit.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_state.dart';
import 'package:nestora/features/profile/domain/entities/user_profile.dart';
import 'package:nestora/features/profile/domain/repositories/profile_repository.dart';
import 'package:nestora/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:nestora/features/profile/presentation/cubit/profile_state.dart';
import 'package:nestora/features/rooms/domain/entities/room.dart';
import 'package:nestora/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_cubit.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockProfileRepo implements ProfileRepository {
  final Map<String, UserProfile> userProfiles = {};

  @override
  Stream<UserProfile?> watchProfile(String userId) {
    return Stream.value(userProfiles[userId]);
  }

  @override
  Future<Result<UserProfile>> getProfile(String userId) async {
    final p = userProfiles[userId];
    if (p != null) return Result.success(p);
    return Result.failure(const ServerFailure('Profile not found'));
  }

  @override
  Future<Result<void>> updatePhotoPath(String userId, String? path) async {
    final current = userProfiles[userId] ??
        UserProfile(
          uid: userId,
          email: '$userId@example.com',
          displayName: userId,
          homeName: "$userId'in Evi",
          preferences: const UserPreferences(),
        );
    userProfiles[userId] = current.copyWith(photoPath: path);
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateProfile(String userId, UserProfile profile) async {
    userProfiles[userId] = profile;
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateDisplayName(String userId, String name) async => Result.success(null);
  @override
  Future<Result<void>> updateHomeName(String userId, String name) async => Result.success(null);
  @override
  Future<Result<void>> updatePreferences(String userId, UserPreferences prefs) async => Result.success(null);
}

class _MockRoomsRepo implements RoomsRepository {
  final Map<String, List<Room>> userRooms = {};

  @override
  Stream<List<Room>> watchRooms(String userId) {
    return Stream.value(userRooms[userId] ?? []);
  }

  @override
  Future<Result<List<Room>>> getRooms(String userId) async {
    return Result.success(userRooms[userId] ?? []);
  }

  @override
  Future<Result<Room>> getRoomById(String userId, String roomId) async {
    final found = (userRooms[userId] ?? []).firstWhere((r) => r.id == roomId);
    return Result.success(found);
  }

  @override
  Future<Result<void>> createRoom(String userId, Room room) async {
    userRooms[userId] = [...(userRooms[userId] ?? []), room];
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateRoom(String userId, Room room) async {
    userRooms[userId] = (userRooms[userId] ?? []).map((r) => r.id == room.id ? room : r).toList();
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteRoom(String userId, String roomId) async {
    userRooms[userId] = (userRooms[userId] ?? []).where((r) => r.id != roomId).toList();
    return Result.success(null);
  }
}

class _MockDevicesRepo implements DevicesRepository {
  final Map<String, List<Device>> userDevices = {};

  @override
  Stream<List<Device>> watchDevices(String userId) {
    return Stream.value(userDevices[userId] ?? []);
  }

  @override
  Stream<List<Device>> watchDevicesByRoom(String userId, String roomId) {
    return Stream.value((userDevices[userId] ?? []).where((d) => d.roomId == roomId).toList());
  }

  @override
  Future<Result<List<Device>>> getDevices(String userId) async => Result.success(userDevices[userId] ?? []);

  @override
  Future<Result<Device>> getDeviceById(String userId, String deviceId) async {
    final dev = (userDevices[userId] ?? []).firstWhere((d) => d.id == deviceId);
    return Result.success(dev);
  }

  @override
  Future<Result<void>> createDevice(String userId, Device device) async {
    userDevices[userId] = [...(userDevices[userId] ?? []), device];
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateDevice(String userId, Device device) async {
    userDevices[userId] = (userDevices[userId] ?? []).map((d) => d.id == device.id ? device : d).toList();
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateDeviceState(String userId, String deviceId, Map<String, dynamic> stateUpdates) async {
    userDevices[userId] = (userDevices[userId] ?? []).map((d) {
      if (d.id == deviceId) {
        return d.copyWith(
          isPoweredOn: stateUpdates['isPoweredOn'] as bool? ?? d.isPoweredOn,
          brightness: stateUpdates['brightness'] as int? ?? d.brightness,
        );
      }
      return d;
    }).toList();
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteDevice(String userId, String deviceId) async {
    userDevices[userId] = (userDevices[userId] ?? []).where((d) => d.id != deviceId).toList();
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteDevicesByRoom(String userId, String roomId) async {
    userDevices[userId] = (userDevices[userId] ?? []).where((d) => d.roomId != roomId).toList();
    return Result.success(null);
  }

  @override
  Future<Result<void>> moveDevicesToRoom(String userId, String fromRoomId, String toRoomId) async {
    userDevices[userId] = (userDevices[userId] ?? []).map((d) => d.roomId == fromRoomId ? d.copyWith(roomId: toRoomId) : d).toList();
    return Result.success(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late LocalCacheService localCacheService;
  late _MockProfileRepo profileRepo;
  late _MockRoomsRepo roomsRepo;
  late _MockDevicesRepo devicesRepo;
  late ProfileCubit profileCubit;
  late RoomsCubit roomsCubit;
  late DevicesCubit devicesCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    localCacheService = LocalCacheService(prefs: prefs);

    profileRepo = _MockProfileRepo();
    roomsRepo = _MockRoomsRepo();
    devicesRepo = _MockDevicesRepo();

    profileCubit = ProfileCubit(
      profileRepository: profileRepo,
      sharedPreferences: prefs,
      localCacheService: localCacheService,
    );

    roomsCubit = RoomsCubit(
      roomsRepository: roomsRepo,
      devicesRepository: devicesRepo,
      localCacheService: localCacheService,
    );

    devicesCubit = DevicesCubit(
      devicesRepository: devicesRepo,
      localCacheService: localCacheService,
    );
  });

  group('Multi-User Data Isolation Tests (Emirhan vs. Aygen Demo)', () {
    test('Emirhan profile photo NEVER leaks into Aygen demo profile', () async {
      const emirhanUid = 'emirhan_uid_123';
      const emirhanPhoto = 'data:image/png;base64,EMIRHAN_PHOTO_BYTES';

      // 1. Emirhan logs in and sets a custom profile photo
      profileCubit.loadProfile(emirhanUid);
      await pumpEventQueue();

      await profileCubit.setPhotoPath(emirhanPhoto);
      expect((profileCubit.state as ProfileLoaded).profile.photoPath, equals(emirhanPhoto));

      // SharedPreferences should only have the user-scoped key
      expect(prefs.getString('${AppConstants.prefProfilePhotoPath}_$emirhanUid'), equals(emirhanPhoto));
      expect(prefs.containsKey(AppConstants.prefProfilePhotoPath), isFalse);

      // 2. Emirhan logs out -> ProfileCubit.reset() is called
      profileCubit.reset();
      expect((profileCubit.state as ProfileLoaded).profile.uid, equals('usr-1'));

      // 3. Aygen logs in via Demo (usr-1)
      profileCubit.loadProfile('usr-1');
      await pumpEventQueue();

      final aygenProfile = (profileCubit.state as ProfileLoaded).profile;
      // Aygen MUST have Aygen's original photo, NOT Emirhan's!
      expect(aygenProfile.photoPath, equals(SeedData.defaultProfile.photoPath));
      expect(aygenProfile.photoPath, isNot(equals(emirhanPhoto)));
      expect(aygenProfile.displayName, equals('Aygen Yıldırım'));

      // 4. Aygen logs out and Emirhan logs back in
      profileCubit.reset();
      profileCubit.loadProfile(emirhanUid);
      await pumpEventQueue();

      final emirhanReloaded = (profileCubit.state as ProfileLoaded).profile;
      expect(emirhanReloaded.photoPath, equals(emirhanPhoto));
    });

    test('Emirhan rooms & devices do NOT leak into Aygen rooms & devices', () async {
      const emirhanUid = 'emirhan_uid_123';

      // 1. Seed Aygen's initial data
      roomsRepo.userRooms['usr-1'] = List.from(SeedData.defaultRooms);
      devicesRepo.userDevices['usr-1'] = List.from(SeedData.defaultDevices);

      // 2. Emirhan logs in (initially has empty rooms and devices)
      roomsRepo.userRooms[emirhanUid] = [];
      devicesRepo.userDevices[emirhanUid] = [];

      roomsCubit.loadRooms(emirhanUid);
      devicesCubit.loadDevices(emirhanUid);
      await pumpEventQueue();

      expect((roomsCubit.state as RoomsLoaded).rooms, isEmpty);
      expect((devicesCubit.state as DevicesLoaded).devices, isEmpty);

      // 3. Emirhan creates a room and a device
      await roomsCubit.createRoom(
        userId: emirhanUid,
        name: "Emirhan'ın Çalışma Odası",
        iconName: 'desk',
      );

      await devicesCubit.createDevice(
        userId: emirhanUid,
        name: 'Emirhan Özel PC Prizi',
        roomId: 'room-emirhan-1',
        type: DeviceType.plug,
        isPoweredOn: true,
      );
      await pumpEventQueue();

      expect((roomsCubit.state as RoomsLoaded).rooms.length, equals(1));
      expect((roomsCubit.state as RoomsLoaded).rooms.first.name, equals("Emirhan'ın Çalışma Odası"));
      expect((devicesCubit.state as DevicesLoaded).devices.length, equals(1));
      expect((devicesCubit.state as DevicesLoaded).devices.first.name, equals('Emirhan Özel PC Prizi'));

      // 4. Emirhan logs out -> reset()
      roomsCubit.reset();
      devicesCubit.reset();

      // 5. Aygen logs in via Demo (usr-1)
      roomsCubit.loadRooms('usr-1');
      devicesCubit.loadDevices('usr-1');
      await pumpEventQueue();

      final aygenRooms = (roomsCubit.state as RoomsLoaded).rooms;
      final aygenDevices = (devicesCubit.state as DevicesLoaded).devices;

      // Aygen MUST have exactly 4 default rooms and 8 default devices, with NO trace of Emirhan!
      expect(aygenRooms.length, equals(SeedData.defaultRooms.length));
      expect(aygenRooms.any((r) => r.name.contains('Emirhan')), isFalse);

      expect(aygenDevices.length, equals(SeedData.defaultDevices.length));
      expect(aygenDevices.any((d) => d.name.contains('Emirhan')), isFalse);

      // 6. Aygen logs out and Emirhan logs back in
      roomsCubit.reset();
      devicesCubit.reset();

      roomsCubit.loadRooms(emirhanUid);
      devicesCubit.loadDevices(emirhanUid);
      await pumpEventQueue();

      expect((roomsCubit.state as RoomsLoaded).rooms.length, equals(1));
      expect((roomsCubit.state as RoomsLoaded).rooms.first.name, equals("Emirhan'ın Çalışma Odası"));
      expect((devicesCubit.state as DevicesLoaded).devices.length, equals(1));
      expect((devicesCubit.state as DevicesLoaded).devices.first.name, equals('Emirhan Özel PC Prizi'));
    });

    test('LocalCacheService cleanly isolates user-scoped keys', () async {
      const u1 = 'user_alpha';
      const u2 = 'user_beta';

      await localCacheService.saveDevices([SeedData.defaultDevices.first], userId: u1);
      await localCacheService.saveDevices(SeedData.defaultDevices, userId: u2);

      final u1Devices = localCacheService.loadDevices(userId: u1);
      final u2Devices = localCacheService.loadDevices(userId: u2);

      expect(u1Devices.length, equals(1));
      expect(u2Devices.length, equals(SeedData.defaultDevices.length));

      // Clearing u1 does not affect u2
      await localCacheService.clearUserCache(u1);
      expect(localCacheService.loadDevices(userId: u1), isEmpty);
      expect(localCacheService.loadDevices(userId: u2).length, equals(SeedData.defaultDevices.length));
    });
  });
}
