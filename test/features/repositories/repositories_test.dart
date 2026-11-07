import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/app/di/injection.dart';
import 'package:nestora/core/errors/exceptions.dart';
import 'package:nestora/core/errors/failures.dart';
import 'package:nestora/features/devices/data/datasources/devices_remote_data_source.dart';
import 'package:nestora/features/devices/data/models/device_model.dart';
import 'package:nestora/features/devices/data/repositories/devices_repository_impl.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/devices/domain/repositories/devices_repository.dart';
import 'package:nestora/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:nestora/features/notifications/data/models/notification_model.dart';
import 'package:nestora/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:nestora/features/notifications/domain/entities/app_notification.dart';
import 'package:nestora/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:nestora/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:nestora/features/profile/data/models/user_profile_model.dart';
import 'package:nestora/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:nestora/features/profile/domain/entities/user_profile.dart';
import 'package:nestora/features/profile/domain/repositories/profile_repository.dart';
import 'package:nestora/features/rooms/data/datasources/rooms_remote_data_source.dart';
import 'package:nestora/features/rooms/data/models/room_model.dart';
import 'package:nestora/features/rooms/data/repositories/rooms_repository_impl.dart';
import 'package:nestora/features/rooms/domain/entities/room.dart';
import 'package:nestora/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==========================================
// FAKE DATA SOURCES
// ==========================================

class FakeRoomsRemoteDataSource implements RoomsRemoteDataSource {
  bool shouldThrow = false;
  String errorMessage = 'Oda sunucu hatası';
  String? errorCode = 'server-error';

  final List<RoomModel> items = [];
  final StreamController<List<RoomModel>> _controller =
      StreamController<List<RoomModel>>.broadcast();

  void emit(List<RoomModel> list) {
    _controller.add(list);
  }

  @override
  Stream<List<RoomModel>> watchRooms(String userId) => _controller.stream;

  @override
  Future<List<RoomModel>> getRooms(String userId) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    return items;
  }

  @override
  Future<RoomModel> getRoomById(String userId, String roomId) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    final room = items.firstWhere(
      (r) => r.id == roomId,
      orElse: () => throw const ServerException('Bulunamadı', code: 'not-found'),
    );
    return room;
  }

  @override
  Future<void> createRoom(String userId, RoomModel room) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    items.add(room);
  }

  @override
  Future<void> updateRoom(String userId, RoomModel room) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    final idx = items.indexWhere((r) => r.id == room.id);
    if (idx != -1) items[idx] = room;
  }

  @override
  Future<void> deleteRoom(String userId, String roomId) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    items.removeWhere((r) => r.id == roomId);
  }
}

class FakeDevicesRemoteDataSource implements DevicesRemoteDataSource {
  bool shouldThrow = false;
  String errorMessage = 'Cihaz sunucu hatası';
  String? errorCode = 'server-error';

  final List<DeviceModel> items = [];
  final StreamController<List<DeviceModel>> _allController =
      StreamController<List<DeviceModel>>.broadcast();
  final StreamController<List<DeviceModel>> _roomController =
      StreamController<List<DeviceModel>>.broadcast();

  void emitAll(List<DeviceModel> list) => _allController.add(list);
  void emitRoom(List<DeviceModel> list) => _roomController.add(list);

  @override
  Stream<List<DeviceModel>> watchDevices(String userId) => _allController.stream;

  @override
  Stream<List<DeviceModel>> watchDevicesByRoom(String userId, String roomId) =>
      _roomController.stream;

  @override
  Future<List<DeviceModel>> getDevices(String userId) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    return items;
  }

  @override
  Future<DeviceModel> getDeviceById(String userId, String deviceId) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    final device = items.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => throw const ServerException('Bulunamadı', code: 'not-found'),
    );
    return device;
  }

  @override
  Future<void> createDevice(String userId, DeviceModel device) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    items.add(device);
  }

  @override
  Future<void> updateDevice(String userId, DeviceModel device) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    final idx = items.indexWhere((d) => d.id == device.id);
    if (idx != -1) items[idx] = device;
  }

  @override
  Future<void> updateDeviceState(
    String userId,
    String deviceId,
    Map<String, dynamic> stateUpdates,
  ) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    final idx = items.indexWhere((d) => d.id == deviceId);
    if (idx != -1) {
      final existing = items[idx];
      items[idx] = DeviceModel(
        id: existing.id,
        name: existing.name,
        type: existing.type,
        roomId: stateUpdates['roomId'] as String? ?? existing.roomId,
        isPoweredOn: stateUpdates['isPoweredOn'] as bool? ?? existing.isPoweredOn,
        brightness: stateUpdates['brightness'] as int? ?? existing.brightness,
        colorHex: stateUpdates['colorHex'] as String? ?? existing.colorHex,
        colorName: stateUpdates['colorName'] as String? ?? existing.colorName,
        targetTemp:
            (stateUpdates['targetTemp'] as num?)?.toDouble() ?? existing.targetTemp,
        acMode: existing.acMode,
        fanSpeed: existing.fanSpeed,
        currentPowerWatts: (stateUpdates['currentPowerWatts'] as num?)?.toDouble() ??
            existing.currentPowerWatts,
        isFavorite: stateUpdates['isFavorite'] as bool? ?? existing.isFavorite,
      );
    }
  }

  @override
  Future<void> deleteDevice(String userId, String deviceId) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    items.removeWhere((d) => d.id == deviceId);
  }

  @override
  Future<void> deleteDevicesByRoom(String userId, String roomId) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    items.removeWhere((d) => d.roomId == roomId);
  }

  @override
  Future<void> moveDevicesToRoom(
    String userId,
    String fromRoomId,
    String toRoomId,
  ) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    for (int i = 0; i < items.length; i++) {
      if (items[i].roomId == fromRoomId) {
        items[i] = DeviceModel(
          id: items[i].id,
          name: items[i].name,
          type: items[i].type,
          roomId: toRoomId,
          isPoweredOn: items[i].isPoweredOn,
          brightness: items[i].brightness,
          colorHex: items[i].colorHex,
          colorName: items[i].colorName,
          targetTemp: items[i].targetTemp,
          acMode: items[i].acMode,
          fanSpeed: items[i].fanSpeed,
          currentPowerWatts: items[i].currentPowerWatts,
          isFavorite: items[i].isFavorite,
        );
      }
    }
  }
}

class FakeNotificationsRemoteDataSource implements NotificationsRemoteDataSource {
  bool shouldThrow = false;
  String errorMessage = 'Bildirim sunucu hatası';
  String? errorCode = 'server-error';

  final List<NotificationModel> items = [];
  final StreamController<List<NotificationModel>> _controller =
      StreamController<List<NotificationModel>>.broadcast();

  void emit(List<NotificationModel> list) => _controller.add(list);

  @override
  Stream<List<NotificationModel>> watchNotifications(String userId) =>
      _controller.stream;

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    return items;
  }

  @override
  Future<void> markAsRead(String userId, String notificationId) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    final idx = items.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      final existing = items[idx];
      items[idx] = NotificationModel(
        id: existing.id,
        title: existing.title,
        message: existing.message,
        type: existing.type,
        isRead: true,
        createdAt: existing.createdAt,
        relatedRoomId: existing.relatedRoomId,
        relatedDeviceId: existing.relatedDeviceId,
      );
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    for (int i = 0; i < items.length; i++) {
      final existing = items[i];
      items[i] = NotificationModel(
        id: existing.id,
        title: existing.title,
        message: existing.message,
        type: existing.type,
        isRead: true,
        createdAt: existing.createdAt,
        relatedRoomId: existing.relatedRoomId,
        relatedDeviceId: existing.relatedDeviceId,
      );
    }
  }

  @override
  Future<void> deleteNotification(String userId, String notificationId) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    items.removeWhere((n) => n.id == notificationId);
  }

  @override
  Future<void> createNotification(
    String userId,
    NotificationModel notification,
  ) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    items.add(notification);
  }
}

class FakeProfileRemoteDataSource implements ProfileRemoteDataSource {
  bool shouldThrow = false;
  String errorMessage = 'Profil sunucu hatası';
  String? errorCode = 'server-error';

  UserProfileModel? currentProfile;
  final StreamController<UserProfileModel?> _controller =
      StreamController<UserProfileModel?>.broadcast();

  void emit(UserProfileModel? profile) => _controller.add(profile);

  @override
  Stream<UserProfileModel?> watchProfile(String userId) => _controller.stream;

  @override
  Future<UserProfileModel?> getProfile(String userId) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    return currentProfile;
  }

  @override
  Future<void> updateProfile(String userId, UserProfileModel profile) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    currentProfile = profile;
  }

  @override
  Future<void> updateHomeName(String userId, String homeName) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    if (currentProfile != null) {
      currentProfile = UserProfileModel(
        uid: currentProfile!.uid,
        email: currentProfile!.email,
        displayName: currentProfile!.displayName,
        homeName: homeName,
        photoPath: currentProfile!.photoPath,
        preferences: currentProfile!.preferences,
        createdAt: currentProfile!.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> updateDisplayName(String userId, String displayName) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    if (currentProfile != null) {
      currentProfile = UserProfileModel(
        uid: currentProfile!.uid,
        email: currentProfile!.email,
        displayName: displayName,
        homeName: currentProfile!.homeName,
        photoPath: currentProfile!.photoPath,
        preferences: currentProfile!.preferences,
        createdAt: currentProfile!.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> updatePreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    if (currentProfile != null) {
      currentProfile = UserProfileModel(
        uid: currentProfile!.uid,
        email: currentProfile!.email,
        displayName: currentProfile!.displayName,
        homeName: currentProfile!.homeName,
        photoPath: currentProfile!.photoPath,
        preferences: UserPreferences(
          notificationsEnabled:
              preferences['notificationsEnabled'] as bool? ?? true,
          ecoModeEnabled: preferences['ecoModeEnabled'] as bool? ?? true,
          temperatureUnit: preferences['temperatureUnit'] as String? ?? 'C',
        ),
        createdAt: currentProfile!.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> updatePhotoPath(String userId, String? photoPath) async {
    if (shouldThrow) throw ServerException(errorMessage, code: errorCode);
    if (currentProfile != null) {
      currentProfile = UserProfileModel(
        uid: currentProfile!.uid,
        email: currentProfile!.email,
        displayName: currentProfile!.displayName,
        homeName: currentProfile!.homeName,
        photoPath: photoPath,
        preferences: currentProfile!.preferences,
        createdAt: currentProfile!.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }
}

// ==========================================
// TESTS
// ==========================================

void main() {
  group('RoomsRepositoryImpl Tests', () {
    late FakeRoomsRemoteDataSource fakeDataSource;
    late RoomsRepository repository;

    final testRoomModel = RoomModel(
      id: 'living-room',
      name: 'Salon',
      iconName: 'weekend_rounded',
      targetTemperature: 22.5,
      deviceCount: 3,
      activeDeviceCount: 2,
      humidity: 48,
    );

    setUp(() {
      fakeDataSource = FakeRoomsRemoteDataSource();
      repository = RoomsRepositoryImpl(remoteDataSource: fakeDataSource);
    });

    test('watchRooms emits pure Room entities mapped from RoomModel', () async {
      final expectation = expectLater(
        repository.watchRooms('user123'),
        emits([
          predicate<Room>((r) => r.id == 'living-room' && r.name == 'Salon'),
        ]),
      );

      fakeDataSource.emit([testRoomModel]);
      await expectation;
    });

    test('getRooms returns Result.success on success', () async {
      fakeDataSource.items.add(testRoomModel);

      final result = await repository.getRooms('user123');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.length, 1);
      expect(result.dataOrNull?.first.name, 'Salon');
    });

    test('getRooms returns Result.failure on ServerException', () async {
      fakeDataSource.shouldThrow = true;
      fakeDataSource.errorMessage = 'Sunucu bağlantı hatası';

      final result = await repository.getRooms('user123');
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.message, 'Sunucu bağlantı hatası');
    });

    test('getRoomById returns Result.success for existing room', () async {
      fakeDataSource.items.add(testRoomModel);

      final result = await repository.getRoomById('user123', 'living-room');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.name, 'Salon');
    });

    test('getRoomById returns Result.failure when room not found', () async {
      final result = await repository.getRoomById('user123', 'non-existent');
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.code, 'not-found');
    });

    test('createRoom converts Room to RoomModel and returns Result.success', () async {
      final newRoom = const Room(
        id: 'kitchen',
        name: 'Mutfak',
        iconName: 'kitchen_rounded',
      );

      final result = await repository.createRoom('user123', newRoom);
      expect(result.isSuccess, isTrue);
      expect(fakeDataSource.items.length, 1);
      expect(fakeDataSource.items.first.id, 'kitchen');
    });

    test('createRoom returns Result.failure on ServerException', () async {
      fakeDataSource.shouldThrow = true;

      final newRoom = const Room(
        id: 'kitchen',
        name: 'Mutfak',
        iconName: 'kitchen_rounded',
      );

      final result = await repository.createRoom('user123', newRoom);
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test('updateRoom updates existing item and returns Result.success', () async {
      fakeDataSource.items.add(testRoomModel);

      final updatedRoom = testRoomModel.copyWith(name: 'Geniş Salon');
      final result = await repository.updateRoom('user123', updatedRoom);

      expect(result.isSuccess, isTrue);
      expect(fakeDataSource.items.first.name, 'Geniş Salon');
    });

    test('deleteRoom removes item and returns Result.success', () async {
      fakeDataSource.items.add(testRoomModel);

      final result = await repository.deleteRoom('user123', 'living-room');
      expect(result.isSuccess, isTrue);
      expect(fakeDataSource.items, isEmpty);
    });
  });

  group('DevicesRepositoryImpl Tests', () {
    late FakeDevicesRemoteDataSource fakeDataSource;
    late DevicesRepository repository;

    final testDeviceModel = DeviceModel(
      id: 'lamp-1',
      name: 'Salon Lambası',
      type: DeviceType.bulb,
      roomId: 'living-room',
      isPoweredOn: true,
      brightness: 75,
      colorHex: '#FFFAF0',
      colorName: 'Sıcak Beyaz',
      currentPowerWatts: 12.5,
    );

    setUp(() {
      fakeDataSource = FakeDevicesRemoteDataSource();
      repository = DevicesRepositoryImpl(remoteDataSource: fakeDataSource);
    });

    test('watchDevices emits list of Device entities', () async {
      final expectation = expectLater(
        repository.watchDevices('user123'),
        emits([
          predicate<Device>((d) => d.id == 'lamp-1' && d.brightness == 75),
        ]),
      );

      fakeDataSource.emitAll([testDeviceModel]);
      await expectation;
    });

    test('watchDevicesByRoom emits room-specific devices', () async {
      final expectation = expectLater(
        repository.watchDevicesByRoom('user123', 'living-room'),
        emits([
          predicate<Device>((d) => d.roomId == 'living-room'),
        ]),
      );

      fakeDataSource.emitRoom([testDeviceModel]);
      await expectation;
    });

    test('getDevices returns Result.success with items', () async {
      fakeDataSource.items.add(testDeviceModel);

      final result = await repository.getDevices('user123');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.length, 1);
      expect(result.dataOrNull?.first.name, 'Salon Lambası');
    });

    test('getDevices returns Result.failure on error', () async {
      fakeDataSource.shouldThrow = true;

      final result = await repository.getDevices('user123');
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test('getDeviceById returns Result.success', () async {
      fakeDataSource.items.add(testDeviceModel);

      final result = await repository.getDeviceById('user123', 'lamp-1');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.id, 'lamp-1');
    });

    test('createDevice and updateDevice return Result.success', () async {
      final newDevice = const Device(
        id: 'ac-1',
        name: 'Klima',
        type: DeviceType.ac,
        roomId: 'living-room',
      );

      final createRes = await repository.createDevice('user123', newDevice);
      expect(createRes.isSuccess, isTrue);
      expect(fakeDataSource.items.length, 1);

      final updateRes = await repository.updateDevice(
        'user123',
        newDevice.copyWith(name: 'Salon Kliması'),
      );
      expect(updateRes.isSuccess, isTrue);
      expect(fakeDataSource.items.first.name, 'Salon Kliması');
    });

    test('updateDeviceState partially modifies device state', () async {
      fakeDataSource.items.add(testDeviceModel);

      final result = await repository.updateDeviceState(
        'user123',
        'lamp-1',
        {'brightness': 40, 'isPoweredOn': false},
      );

      expect(result.isSuccess, isTrue);
      expect(fakeDataSource.items.first.brightness, 40);
      expect(fakeDataSource.items.first.isPoweredOn, isFalse);
    });

    test('deleteDevice and deleteDevicesByRoom remove devices', () async {
      fakeDataSource.items.add(testDeviceModel);

      final deleteRes = await repository.deleteDevice('user123', 'lamp-1');
      expect(deleteRes.isSuccess, isTrue);
      expect(fakeDataSource.items, isEmpty);

      fakeDataSource.items.add(testDeviceModel);
      final roomDeleteRes =
          await repository.deleteDevicesByRoom('user123', 'living-room');
      expect(roomDeleteRes.isSuccess, isTrue);
      expect(fakeDataSource.items, isEmpty);
    });

    test('moveDevicesToRoom updates roomId of matching devices', () async {
      fakeDataSource.items.add(testDeviceModel);

      final result = await repository.moveDevicesToRoom(
        'user123',
        'living-room',
        'bedroom',
      );

      expect(result.isSuccess, isTrue);
      expect(fakeDataSource.items.first.roomId, 'bedroom');
    });
  });

  group('NotificationsRepositoryImpl Tests', () {
    late FakeNotificationsRemoteDataSource fakeDataSource;
    late NotificationsRepository repository;

    final testNotifModel = NotificationModel(
      id: 'n-1',
      title: 'Güvenlik Uyarısı',
      message: 'Ön kapı açıldı.',
      type: NotificationType.security,
      isRead: false,
      createdAt: DateTime.now(),
    );

    setUp(() {
      fakeDataSource = FakeNotificationsRemoteDataSource();
      repository =
          NotificationsRepositoryImpl(remoteDataSource: fakeDataSource);
    });

    test('watchNotifications emits AppNotification entities', () async {
      final expectation = expectLater(
        repository.watchNotifications('user123'),
        emits([
          predicate<AppNotification>((n) => n.id == 'n-1' && !n.isRead),
        ]),
      );

      fakeDataSource.emit([testNotifModel]);
      await expectation;
    });

    test('getNotifications returns Result.success', () async {
      fakeDataSource.items.add(testNotifModel);

      final result = await repository.getNotifications('user123');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.first.title, 'Güvenlik Uyarısı');
    });

    test('markAsRead and markAllAsRead update isRead to true', () async {
      fakeDataSource.items.add(testNotifModel);

      final markRes = await repository.markAsRead('user123', 'n-1');
      expect(markRes.isSuccess, isTrue);
      expect(fakeDataSource.items.first.isRead, isTrue);

      fakeDataSource.items[0] = NotificationModel(
        id: 'n-1',
        title: 'Başlık',
        message: 'Mesaj',
        type: NotificationType.system,
        isRead: false,
        createdAt: DateTime.now(),
      );

      final markAllRes = await repository.markAllAsRead('user123');
      expect(markAllRes.isSuccess, isTrue);
      expect(fakeDataSource.items.first.isRead, isTrue);
    });

    test('deleteNotification and createNotification work correctly', () async {
      final createRes =
          await repository.createNotification('user123', testNotifModel);
      expect(createRes.isSuccess, isTrue);
      expect(fakeDataSource.items.length, 1);

      final deleteRes = await repository.deleteNotification('user123', 'n-1');
      expect(deleteRes.isSuccess, isTrue);
      expect(fakeDataSource.items, isEmpty);
    });
  });

  group('ProfileRepositoryImpl Tests', () {
    late FakeProfileRemoteDataSource fakeDataSource;
    late ProfileRepository repository;

    final testProfile = UserProfileModel(
      uid: 'user123',
      email: 'aygen@nestora.com',
      displayName: 'Aygen Yıldırım',
      homeName: "Aygen'in Evi",
      preferences: const UserPreferences(
        notificationsEnabled: true,
        ecoModeEnabled: true,
        temperatureUnit: 'C',
      ),
    );

    setUp(() {
      fakeDataSource = FakeProfileRemoteDataSource();
      fakeDataSource.currentProfile = testProfile;
      repository = ProfileRepositoryImpl(remoteDataSource: fakeDataSource);
    });

    test('watchProfile emits UserProfile entity', () async {
      final expectation = expectLater(
        repository.watchProfile('user123'),
        emits(
          predicate<UserProfile?>((p) => p?.displayName == 'Aygen Yıldırım'),
        ),
      );

      fakeDataSource.emit(testProfile);
      await expectation;
    });

    test('getProfile returns Result.success with UserProfile', () async {
      final result = await repository.getProfile('user123');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.displayName, 'Aygen Yıldırım');
      expect(result.dataOrNull?.homeName, "Aygen'in Evi");
    });

    test('getProfile returns Result.failure on error', () async {
      fakeDataSource.shouldThrow = true;

      final result = await repository.getProfile('user123');
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test('updateProfile updates entire profile', () async {
      final updated = testProfile.copyWith(displayName: 'Aygen Y.');
      final result = await repository.updateProfile('user123', updated);

      expect(result.isSuccess, isTrue);
      expect(fakeDataSource.currentProfile?.displayName, 'Aygen Y.');
    });

    test('updateHomeName updates homeName', () async {
      final result = await repository.updateHomeName('user123', 'Villa Nestora');
      expect(result.isSuccess, isTrue);
      expect(fakeDataSource.currentProfile?.homeName, 'Villa Nestora');
    });

    test('updateDisplayName updates displayName', () async {
      final result = await repository.updateDisplayName('user123', 'M. Aygen');
      expect(result.isSuccess, isTrue);
      expect(fakeDataSource.currentProfile?.displayName, 'M. Aygen');
    });

    test('updatePreferences updates user preferences', () async {
      const newPrefs = UserPreferences(
        notificationsEnabled: false,
        ecoModeEnabled: false,
        temperatureUnit: 'F',
      );

      final result = await repository.updatePreferences('user123', newPrefs);
      expect(result.isSuccess, isTrue);
      expect(fakeDataSource.currentProfile?.preferences.notificationsEnabled, isFalse);
      expect(fakeDataSource.currentProfile?.preferences.temperatureUnit, 'F');
    });

    test('updatePhotoPath updates photo path', () async {
      final result =
          await repository.updatePhotoPath('user123', '/local/path/avatar.png');
      expect(result.isSuccess, isTrue);
      expect(fakeDataSource.currentProfile?.photoPath, '/local/path/avatar.png');
    });
  });

  group('ServiceLocator Repositories Registration Tests', () {
    setUp(() async {
      sl.reset();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await initDependencies(sharedPreferences: prefs);
    });

    tearDown(() {
      sl.reset();
    });

    test('All 4 feature repositories are registered and resolvable in ServiceLocator', () {
      expect(sl.isRegistered<RoomsRepository>(), isTrue);
      expect(sl<RoomsRepository>(), isA<RoomsRepositoryImpl>());

      expect(sl.isRegistered<DevicesRepository>(), isTrue);
      expect(sl<DevicesRepository>(), isA<DevicesRepositoryImpl>());

      expect(sl.isRegistered<NotificationsRepository>(), isTrue);
      expect(sl<NotificationsRepository>(), isA<NotificationsRepositoryImpl>());

      expect(sl.isRegistered<ProfileRepository>(), isTrue);
      expect(sl<ProfileRepository>(), isA<ProfileRepositoryImpl>());
    });
  });
}
