import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/app/di/injection.dart';
import 'package:nestora/core/constants/app_constants.dart';
import 'package:nestora/core/services/crashlytics_service.dart';
import 'package:nestora/core/services/remote_config_service.dart';
import 'package:nestora/core/services/spark_quota_service.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/devices/domain/repositories/devices_repository.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_cubit.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_state.dart';
import 'package:nestora/features/notifications/domain/entities/app_notification.dart';
import 'package:nestora/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:nestora/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:nestora/features/profile/domain/entities/user_profile.dart';
import 'package:nestora/features/profile/domain/repositories/profile_repository.dart';
import 'package:nestora/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:nestora/features/rooms/domain/entities/room.dart';
import 'package:nestora/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_cubit.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Mocks & Fakes for Quota Safeguard Tests ---

class MockDevicesRepository implements DevicesRepository {
  final List<Device> devices = [];
  final StreamController<List<Device>> controller =
      StreamController<List<Device>>.broadcast();
  int updateDeviceStateCalls = 0;
  int createDeviceCalls = 0;

  @override
  Stream<List<Device>> watchDevices(String userId) => controller.stream;

  @override
  Stream<List<Device>> watchDevicesByRoom(String userId, String roomId) =>
      controller.stream.map((list) => list.where((d) => d.roomId == roomId).toList());

  @override
  Future<Result<List<Device>>> getDevices(String userId) async =>
      Result.success(devices);

  @override
  Future<Result<Device>> getDeviceById(String userId, String deviceId) async =>
      Result.success(devices.firstWhere((d) => d.id == deviceId));

  @override
  Future<Result<void>> createDevice(String userId, Device device) async {
    createDeviceCalls++;
    devices.add(device);
    controller.add(List.from(devices));
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateDevice(String userId, Device device) async =>
      Result.success(null);

  @override
  Future<Result<void>> updateDeviceState(
    String userId,
    String deviceId,
    Map<String, dynamic> stateUpdates,
  ) async {
    updateDeviceStateCalls++;
    final idx = devices.indexWhere((d) => d.id == deviceId);
    if (idx != -1) {
      final old = devices[idx];
      devices[idx] = old.copyWith(
        brightness: stateUpdates['brightness'] as int? ?? old.brightness,
        targetTemp: (stateUpdates['targetTemp'] as num?)?.toDouble() ?? old.targetTemp,
        isPoweredOn: stateUpdates['isPoweredOn'] as bool? ?? old.isPoweredOn,
      );
      controller.add(List.from(devices));
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteDevice(String userId, String deviceId) async =>
      Result.success(null);

  @override
  Future<Result<void>> deleteDevicesByRoom(String userId, String roomId) async =>
      Result.success(null);

  @override
  Future<Result<void>> moveDevicesToRoom(
    String userId,
    String fromRoomId,
    String toRoomId,
  ) async =>
      Result.success(null);
}

class MockRoomsRepository implements RoomsRepository {
  final List<Room> rooms = [];
  final StreamController<List<Room>> controller =
      StreamController<List<Room>>.broadcast();
  int createRoomCalls = 0;

  @override
  Stream<List<Room>> watchRooms(String userId) => controller.stream;

  @override
  Future<Result<List<Room>>> getRooms(String userId) async =>
      Result.success(rooms);

  @override
  Future<Result<Room>> getRoomById(String userId, String roomId) async =>
      Result.success(rooms.firstWhere((r) => r.id == roomId));

  @override
  Future<Result<void>> createRoom(String userId, Room room) async {
    createRoomCalls++;
    rooms.add(room);
    controller.add(List.from(rooms));
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateRoom(String userId, Room room) async =>
      Result.success(null);

  @override
  Future<Result<void>> deleteRoom(String userId, String roomId) async =>
      Result.success(null);
}

class MockNotificationsRepository implements NotificationsRepository {
  final List<AppNotification> notifications = [];
  final StreamController<List<AppNotification>> controller =
      StreamController<List<AppNotification>>.broadcast();

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) =>
      controller.stream;

  @override
  Future<Result<List<AppNotification>>> getNotifications(String userId) async =>
      Result.success(notifications);

  @override
  Future<Result<void>> markAsRead(String userId, String notificationId) async =>
      Result.success(null);

  @override
  Future<Result<void>> markAllAsRead(String userId) async =>
      Result.success(null);

  @override
  Future<Result<void>> deleteNotification(String userId, String notificationId) async =>
      Result.success(null);

  @override
  Future<Result<void>> createNotification(String userId, AppNotification notification) async =>
      Result.success(null);
}

class MockProfileRepository implements ProfileRepository {
  UserProfile? profile;
  final StreamController<UserProfile?> controller =
      StreamController<UserProfile?>.broadcast();

  @override
  Stream<UserProfile?> watchProfile(String userId) => controller.stream;

  @override
  Future<Result<UserProfile?>> getProfile(String userId) async =>
      Result.success(profile ?? UserProfile(
        uid: userId,
        email: 'test@nestora.app',
        displayName: 'Test User',
        homeName: "Test'in Evi",
      ));

  @override
  Future<Result<void>> updateProfile(String userId, UserProfile profile) async =>
      Result.success(null);

  @override
  Future<Result<void>> updatePreferences(String userId, UserPreferences prefs) async =>
      Result.success(null);

  @override
  Future<Result<void>> updateHomeName(String userId, String homeName) async =>
      Result.success(null);

  @override
  Future<Result<void>> updateDisplayName(String userId, String displayName) async =>
      Result.success(null);

  @override
  Future<Result<void>> updatePhotoPath(String userId, String? photoPath) async =>
      Result.success(null);
}

void main() {
  group('Adım 8.3: Spark Plan Kota Koruması & Güvenlik Testleri', () {
    late SparkQuotaService quotaService;
    late CrashlyticsService crashlyticsService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      crashlyticsService = CrashlyticsService(crashlytics: null);
      quotaService = SparkQuotaService(crashlyticsService: crashlyticsService);
    });

    test('1. SparkLimits sabitleri ve kota kuralları doğrulanmalıdır', () {
      expect(SparkLimits.maxDailyReads, equals(50000));
      expect(SparkLimits.maxDailyWrites, equals(20000));
      expect(SparkLimits.maxDailyDeletes, equals(20000));
      expect(SparkLimits.maxDailyPasswordResetEmails, equals(150));
      expect(SparkLimits.maxSimultaneousConnections, equals(100));
      expect(SparkLimits.defaultSliderDebounce.inMilliseconds, equals(300));
      expect(SparkLimits.defaultMaxRoomsPerUser, equals(20));
      expect(SparkLimits.defaultMaxDevicesPerRoom, equals(50));
    });

    test('2. Sıfır maliyet (Zero-Cost) mimari doğrulaması teyit edilmelidir', () {
      expect(quotaService.isCloudStorageUsed, isFalse);
      expect(quotaService.isCloudFunctionsUsed, isFalse);
      expect(quotaService.sliderDebounceDuration.inMilliseconds, greaterThanOrEqualTo(300));
      expect(quotaService.verifyZeroCostCompliance(), isTrue);

      final report = quotaService.getQuotaHealthReport();
      expect(report['sparkPlan'], equals('Spark (Free Tier)'));
      expect(report['zeroCostCompliant'], isTrue);
      expect(report['cloudStorageUsed'], isFalse);
      expect(report['cloudFunctionsUsed'], isFalse);
      expect(report['profilePhotoStorage'], contains('Local Sandbox'));
    });

    test('3. Oda ve cihaz kota koruma sınırları (canCreateRoom, canAddDevice) doğrulanmalıdır', () {
      // Varsayılan maxRooms: 20
      expect(quotaService.canCreateRoom(0), isTrue);
      expect(quotaService.canCreateRoom(19), isTrue);
      expect(quotaService.canCreateRoom(20), isFalse);
      expect(quotaService.canCreateRoom(25), isFalse);

      // Varsayılan maxDevicesPerRoom: 50
      expect(quotaService.canAddDevice(0), isTrue);
      expect(quotaService.canAddDevice(49), isTrue);
      expect(quotaService.canAddDevice(50), isFalse);
      expect(quotaService.canAddDevice(51), isFalse);
    });

    test('4. Şifre sıfırlama e-posta doğrulaması (150 e-posta/gün kota koruması) çalışmalıdır', () {
      // Geçersiz formatlar Firestore / Auth isteği atmadan filtrelenmelidir
      expect(quotaService.validatePasswordResetEmail(''), isFalse);
      expect(quotaService.validatePasswordResetEmail('not-an-email'), isFalse);
      expect(quotaService.validatePasswordResetEmail('demo@'), isFalse);
      expect(quotaService.validatePasswordResetEmail('@test.com'), isFalse);

      // Geçerli formatlar kabul edilmelidir
      expect(quotaService.validatePasswordResetEmail('user@nestora.app'), isTrue);
      expect(quotaService.validatePasswordResetEmail('aygen@gmail.com'), isTrue);
    });

    test('5. Dinleyici (Stream Listener) yaşam döngüsü ve sızıntı denetimi çalışmalıdır', () {
      expect(quotaService.activeListenerCount, equals(0));

      quotaService.registerListener('RoomsCubit_user1');
      quotaService.registerListener('DevicesCubit_user1');
      quotaService.registerListener('NotificationsCubit_user1');

      expect(quotaService.activeListenerCount, equals(3));
      expect(quotaService.activeListeners.contains('RoomsCubit_user1'), isTrue);

      quotaService.unregisterListener('RoomsCubit_user1');
      expect(quotaService.activeListenerCount, equals(2));
      expect(quotaService.activeListeners.contains('RoomsCubit_user1'), isFalse);

      // Aşırı listener açılma uyarısı (> 10)
      for (int i = 0; i < 12; i++) {
        quotaService.registerListener('DynamicListener_$i');
      }
      expect(crashlyticsService.recordedLogs.isNotEmpty, isTrue);
      expect(crashlyticsService.recordedLogs.first, contains('Excessive active listeners detected'));

      quotaService.clearAllListeners();
      expect(quotaService.activeListenerCount, equals(0));
    });

    test('6. Tahmini günlük yazma ve okuma kota sayaçları aşım uyarısı vermelidir', () {
      quotaService.recordWriteOperation(count: 100);
      expect(quotaService.estimatedDailyWrites, equals(100));

      quotaService.recordReadOperation(count: 200);
      expect(quotaService.estimatedDailyReads, equals(200));

      // Limit aşımında Crashlytics'e bildirim
      quotaService.recordWriteOperation(count: SparkLimits.maxDailyWrites);
      expect(crashlyticsService.recordedErrors.isNotEmpty, isTrue);
      expect(
        crashlyticsService.recordedErrors.first['exception'].toString(),
        contains('Spark write limit approached'),
      );
    });

    testWidgets('7. DevicesCubit: 300ms debounce koruması ile yüksek frekanslı slider hareketleri tek yazmaya indirgenmelidir', (tester) async {
      final mockRepo = MockDevicesRepository();
      final testDevice = Device(
        id: 'dev-slider',
        name: 'Salon Lambası',
        roomId: 'room-1',
        type: DeviceType.bulb,
        brightness: 10,
        isPoweredOn: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRepo.devices.add(testDevice);

      final cubit = DevicesCubit(
        devicesRepository: mockRepo,
        debounceDuration: const Duration(milliseconds: 300),
        quotaService: quotaService,
      );

      cubit.loadDevices('test-user');
      mockRepo.controller.add([testDevice]);
      await tester.pump();

      expect(cubit.state, isA<DevicesLoaded>());
      expect((cubit.state as DevicesLoaded).devices.first.brightness, equals(10));
      expect(mockRepo.updateDeviceStateCalls, equals(0));

      // Kullanıcı slider'ı hızla 10 kez kaydırıyor
      for (int i = 11; i <= 20; i++) {
        cubit.setBrightness('test-user', 'dev-slider', i);
        await tester.pump(const Duration(milliseconds: 20));
      }

      // Arayüz state'i anında güncellenmiştir (0 gecikme)
      expect((cubit.state as DevicesLoaded).devices.first.brightness, equals(20));

      // Ancak henüz 300ms dolmadığı için Firestore'a HİÇ yazma yapılmamıştır!
      expect(mockRepo.updateDeviceStateCalls, equals(0));

      // Debounce süresinin (300ms) dolmasını bekliyoruz
      await tester.pump(const Duration(milliseconds: 350));

      // 10 adet ara değer tek bir Firestore güncellemesine indirgenmiştir (9 yazma tasarrufu)
      expect(mockRepo.updateDeviceStateCalls, equals(1));
      expect(mockRepo.devices.first.brightness, equals(20));

      await cubit.close();
    });

    test('8. DevicesCubit, RoomsCubit, NotificationsCubit, ProfileCubit close() ile tüm listener ve timer ları iptal etmelidir', () {
      final mockDevicesRepo = MockDevicesRepository();
      final mockRoomsRepo = MockRoomsRepository();
      final mockNotifsRepo = MockNotificationsRepository();
      final mockProfileRepo = MockProfileRepository();

      final devicesCubit = DevicesCubit(
        devicesRepository: mockDevicesRepo,
        quotaService: quotaService,
      );
      final roomsCubit = RoomsCubit(
        roomsRepository: mockRoomsRepo,
        devicesRepository: mockDevicesRepo,
        quotaService: quotaService,
      );
      final notifsCubit = NotificationsCubit(
        notificationsRepository: mockNotifsRepo,
        quotaService: quotaService,
      );
      final profileCubit = ProfileCubit(
        profileRepository: mockProfileRepo,
        quotaService: quotaService,
      );

      // Dinleyicileri başlat
      devicesCubit.loadDevices('user-xyz');
      roomsCubit.loadRooms('user-xyz');
      notifsCubit.loadNotifications('user-xyz');
      profileCubit.loadProfile('user-xyz');

      expect(quotaService.activeListenerCount, equals(4));

      // Tüm cubit'leri kapat (ekran kapanışı simülasyonu)
      devicesCubit.close();
      roomsCubit.close();
      notifsCubit.close();
      profileCubit.close();

      // Tüm dinleyiciler unregister edilmiş olmalıdır
      expect(quotaService.activeListenerCount, equals(0));
    });

    test('9. RoomsCubit: Kota sınırına ulaşıldığında yeni oda oluşturulması engellenmelidir', () async {
      final mockRoomsRepo = MockRoomsRepository();
      final mockDevicesRepo = MockDevicesRepository();

      // RemoteConfig üzerinden maxRoomsPerUser: 2 olarak sınırlayalım
      final mockRemoteConfigService = RemoteConfigService();
      mockRemoteConfigService.setOverride(
        AppConstants.remoteConfigMaxRoomsPerUser,
        2,
      );

      final customQuotaService = SparkQuotaService(
        remoteConfigService: mockRemoteConfigService,
      );

      final roomsCubit = RoomsCubit(
        roomsRepository: mockRoomsRepo,
        devicesRepository: mockDevicesRepo,
        quotaService: customQuotaService,
      );

      // 2 oda yüklenmiş durumda olsun
      final room1 = Room(id: 'r1', name: 'Salon', iconName: 'chair', createdAt: DateTime.now(), updatedAt: DateTime.now());
      final room2 = Room(id: 'r2', name: 'Yatak Odası', iconName: 'bed', createdAt: DateTime.now(), updatedAt: DateTime.now());
      roomsCubit.loadRooms('user-quota');
      mockRoomsRepo.controller.add([room1, room2]);
      await pumpEventQueue();

      // 3. odayı eklemeye çalış
      await roomsCubit.createRoom(
        userId: 'user-quota',
        name: 'Mutfak',
        iconName: 'kitchen',
      );

      // Firestore yazması yapılmamalıdır
      expect(mockRoomsRepo.createRoomCalls, equals(0));
      expect(roomsCubit.state, isA<RoomsLoaded>());
      final loadedState = roomsCubit.state as RoomsLoaded;
      expect(loadedState.errorMessage, contains('Maksimum oda sınırına'));

      await roomsCubit.close();
    });

    test('10. DevicesCubit: Odadaki maksimum cihaz kotasına ulaşıldığında ekleme engellenmelidir', () async {
      final mockDevicesRepo = MockDevicesRepository();

      // RemoteConfig ile maxDevicesPerRoom: 2 yapalım
      final mockRemoteConfigService = RemoteConfigService();
      mockRemoteConfigService.setOverride(
        AppConstants.remoteConfigMaxDevicesPerRoom,
        2,
      );

      final customQuotaService = SparkQuotaService(
        remoteConfigService: mockRemoteConfigService,
      );

      final devicesCubit = DevicesCubit(
        devicesRepository: mockDevicesRepo,
        quotaService: customQuotaService,
      );

      // Odada zaten 2 cihaz olsun
      final d1 = Device(id: 'd1', name: 'Lamba 1', roomId: 'room-1', type: DeviceType.bulb, createdAt: DateTime.now(), updatedAt: DateTime.now());
      final d2 = Device(id: 'd2', name: 'Lamba 2', roomId: 'room-1', type: DeviceType.bulb, createdAt: DateTime.now(), updatedAt: DateTime.now());
      devicesCubit.loadDevices('user-dev-quota');
      mockDevicesRepo.controller.add([d1, d2]);
      await pumpEventQueue();

      // 3. cihazı eklemeye çalış
      await devicesCubit.createDevice(
        userId: 'user-dev-quota',
        name: 'Lamba 3',
        roomId: 'room-1',
        type: DeviceType.bulb,
      );

      // Firestore yazması engellenmeli ve hata mesajı gösterilmelidir
      expect(mockDevicesRepo.createDeviceCalls, equals(0));
      expect(devicesCubit.state, isA<DevicesLoaded>());
      final loaded = devicesCubit.state as DevicesLoaded;
      expect(loaded.errorMessage, contains('Bu odadaki maksimum cihaz sınırına'));

      await devicesCubit.close();
    });

    test('11. Statik Kod Analizi: pubspec.yaml içinde Cloud Storage veya Cloud Functions bulunmamalıdır', () {
      final pubspecFile = File('pubspec.yaml');
      expect(pubspecFile.existsSync(), isTrue, reason: 'pubspec.yaml mevcut olmalıdır.');
      final content = pubspecFile.readAsStringSync();

      expect(content.contains('firebase_storage'), isFalse,
          reason: 'Firebase Spark planında Cloud Storage kullanılmamalıdır.');
      expect(content.contains('cloud_functions'), isFalse,
          reason: 'Firebase Spark planında Cloud Functions kullanılmamalıdır.');
      expect(content.contains('firebase_functions'), isFalse,
          reason: 'Firebase Spark planında Cloud Functions paketleri bulunmamalıdır.');
    });

    test('12. ServiceLocator dependency injection SparkQuotaService singleton doğrulaması', () async {
      await initDependencies(
        sparkQuotaService: quotaService,
      );

      expect(sl.isRegistered<SparkQuotaService>(), isTrue);
      final retrieved = sl<SparkQuotaService>();
      expect(retrieved, equals(quotaService));
      expect(retrieved.verifyZeroCostCompliance(), isTrue);
    });
  });
}
