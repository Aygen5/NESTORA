import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/core/errors/failures.dart';
import 'package:nestora/core/services/analytics_service.dart';
import 'package:nestora/core/services/crashlytics_service.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/features/auth/domain/entities/auth_user.dart';
import 'package:nestora/features/auth/domain/repositories/auth_repository.dart';
import 'package:nestora/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/devices/domain/repositories/devices_repository.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_cubit.dart';
import 'package:nestora/features/rooms/domain/entities/room.dart';
import 'package:nestora/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_cubit.dart';

class MockAuthRepository implements AuthRepository {
  AuthUser? mockUser;
  bool shouldFail = false;

  @override
  AuthUser? get currentUser => mockUser;

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(mockUser);

  @override
  Future<Result<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (shouldFail) {
      return Result.failure(const AuthFailure('Invalid credentials', code: 'invalid-credential'));
    }
    mockUser = const AuthUser(id: 'usr-123', email: 'test@nestora.com');
    return Result.success(mockUser!);
  }

  @override
  Future<Result<AuthUser>> signInDemo({String? email, String? password}) async {
    mockUser = const AuthUser(id: 'demo-usr', email: 'demo@nestora.com');
    return Result.success(mockUser!);
  }

  @override
  Future<Result<AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    mockUser = const AuthUser(id: 'usr-new', email: 'new@nestora.com');
    return Result.success(mockUser!);
  }

  @override
  Future<Result<void>> signOut() async {
    mockUser = null;
    return Result.success(null);
  }

  @override
  Future<Result<void>> sendPasswordReset({required String email}) async {
    return Result.success(null);
  }
}

class MockRoomsRepository implements RoomsRepository {
  final List<Room> rooms = [];

  @override
  Future<Result<void>> createRoom(String userId, Room room) async {
    rooms.add(room);
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteRoom(String userId, String roomId) async {
    rooms.removeWhere((r) => r.id == roomId);
    return Result.success(null);
  }

  @override
  Future<Result<List<Room>>> getRooms(String userId) async {
    return Result.success(rooms);
  }

  @override
  Future<Result<Room>> getRoomById(String userId, String roomId) async {
    final room = rooms.firstWhere((r) => r.id == roomId);
    return Result.success(room);
  }

  @override
  Future<Result<void>> updateRoom(String userId, Room room) async {
    return Result.success(null);
  }

  @override
  Stream<List<Room>> watchRooms(String userId) {
    return Stream.value(rooms);
  }
}

class MockDevicesRepository implements DevicesRepository {
  final List<Device> devices = [];

  @override
  Future<Result<void>> createDevice(String userId, Device device) async {
    devices.add(device);
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteDevice(String userId, String deviceId) async {
    devices.removeWhere((d) => d.id == deviceId);
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteDevicesByRoom(String userId, String roomId) async {
    devices.removeWhere((d) => d.roomId == roomId);
    return Result.success(null);
  }

  @override
  Future<Result<List<Device>>> getDevices(String userId) async {
    return Result.success(devices);
  }

  @override
  Future<Result<Device>> getDeviceById(String userId, String deviceId) async {
    final dev = devices.firstWhere((d) => d.id == deviceId);
    return Result.success(dev);
  }

  @override
  Future<Result<void>> moveDevicesToRoom(String userId, String sourceRoomId, String targetRoomId) async {
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateDevice(String userId, Device device) async {
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateDeviceState(String userId, String deviceId, Map<String, dynamic> stateUpdates) async {
    return Result.success(null);
  }

  @override
  Stream<List<Device>> watchDevices(String userId) {
    return Stream.value(devices);
  }

  @override
  Stream<List<Device>> watchDevicesByRoom(String userId, String roomId) {
    return Stream.value(devices.where((d) => d.roomId == roomId).toList());
  }
}

void main() {
  group('CrashlyticsService Unit Tests', () {
    late CrashlyticsService crashlyticsService;

    setUp(() {
      crashlyticsService = CrashlyticsService(enableDebugLogs: false);
    });

    test('initializes global error handlers safely', () async {
      await crashlyticsService.initialize();
      expect(FlutterError.onError, isNotNull);
    });

    test('records non-fatal and fatal exceptions with stack trace', () async {
      await crashlyticsService.recordError(
        Exception('Network timeout'),
        StackTrace.current,
        reason: 'API timeout during device sync',
        fatal: false,
      );

      expect(crashlyticsService.recordedErrors.length, 1);
      final entry = crashlyticsService.recordedErrors.first;
      expect(entry['exception'], contains('Network timeout'));
      expect(entry['reason'], 'API timeout during device sync');
      expect(entry['fatal'], isFalse);
    });

    test('sanitizes passwords and sensitive tokens from log messages', () async {
      await crashlyticsService.log('Connecting with password: MySecretPassword123! to server');
      await crashlyticsService.log('User email aygen@nestora.com authorized with token=jwt_token_999');

      expect(crashlyticsService.recordedLogs.length, 2);
      expect(crashlyticsService.recordedLogs[0], isNot(contains('MySecretPassword123!')));
      expect(crashlyticsService.recordedLogs[0], contains('password=[REDACTED]'));

      expect(crashlyticsService.recordedLogs[1], isNot(contains('aygen@nestora.com')));
      expect(crashlyticsService.recordedLogs[1], contains('[EMAIL_REDACTED]'));
      expect(crashlyticsService.recordedLogs[1], contains('token=[REDACTED]'));
    });

    test('sets custom diagnostic keys and user id identifier', () async {
      await crashlyticsService.setCustomKey('app_version', '1.0.0+1');
      await crashlyticsService.setUserId('user-888');

      expect(crashlyticsService.customKeys['app_version'], '1.0.0+1');
      expect(crashlyticsService.currentUserId, 'user-888');

      await crashlyticsService.setUserId(null);
      expect(crashlyticsService.currentUserId, isNull);
    });

    test('records framework FlutterErrorDetails gracefully', () async {
      final details = FlutterErrorDetails(
        exception: Exception('Widget layout failure'),
        library: 'widgets library',
      );

      await crashlyticsService.recordFlutterError(details, fatal: false);
      expect(crashlyticsService.recordedErrors.length, 1);
      expect(crashlyticsService.recordedErrors.first['library'], 'widgets library');
    });
  });

  group('AnalyticsService Unit Tests', () {
    late AnalyticsService analyticsService;

    setUp(() {
      analyticsService = AnalyticsService(enableDebugLogs: false);
    });

    test('logs user login and sign-up with method strictly without PII', () async {
      await analyticsService.logLogin(method: 'email');
      await analyticsService.logSignUp(method: 'email');
      await analyticsService.logLogin(method: 'demo');
      await analyticsService.logLogout();

      expect(analyticsService.recordedEvents.length, 4);

      expect(analyticsService.recordedEvents[0]['name'], 'login');
      expect(analyticsService.recordedEvents[0]['parameters']['login_method'], 'email');

      expect(analyticsService.recordedEvents[1]['name'], 'sign_up');
      expect(analyticsService.recordedEvents[1]['parameters']['sign_up_method'], 'email');

      expect(analyticsService.recordedEvents[2]['name'], 'login');
      expect(analyticsService.recordedEvents[2]['parameters']['login_method'], 'demo');

      expect(analyticsService.recordedEvents[3]['name'], 'logout');
    });

    test('logs screen views, room creation/deletion, and device actions', () async {
      await analyticsService.logScreenView(screenName: 'DashboardPage');
      await analyticsService.logRoomCreated(roomType: 'living_room');
      await analyticsService.logRoomDeleted(roomId: 'room-101');
      await analyticsService.logDeviceCreated(deviceType: 'bulb');
      await analyticsService.logDeviceToggle(deviceType: 'bulb', isPoweredOn: true);
      await analyticsService.logDeviceStateChanged(deviceType: 'ac', property: 'temperature');
      await analyticsService.logScenarioActivated(scenarioName: 'Gece Modu');
      await analyticsService.logThemeChanged(themeMode: 'dark');

      final eventNames = analyticsService.recordedEvents.map((e) => e['name']).toList();
      expect(eventNames, [
        'screen_view',
        'room_created',
        'room_deleted',
        'device_created',
        'device_power_toggle',
        'device_state_changed',
        'scenario_activated',
        'theme_changed',
      ]);
    });

    test('sanitizes any forbidden sensitive parameters from event payload', () async {
      await analyticsService.logLogin(method: 'email');
      await analyticsService.setUserId('user-456');

      expect(analyticsService.currentUserId, 'user-456');
    });

    test('provides navigator observer without throwing', () {
      final observer = analyticsService.getAnalyticsObserver();
      expect(observer, isNotNull);
    });
  });

  group('Cubit Integration with Analytics & Crashlytics Tests', () {
    late AnalyticsService analytics;
    late CrashlyticsService crashlytics;
    late MockAuthRepository authRepo;
    late MockRoomsRepository roomsRepo;
    late MockDevicesRepository devicesRepo;

    setUp(() {
      analytics = AnalyticsService();
      crashlytics = CrashlyticsService();
      authRepo = MockAuthRepository();
      roomsRepo = MockRoomsRepository();
      devicesRepo = MockDevicesRepository();
    });

    test('AuthCubit dispatches login/signup/logout analytics and associates user ID', () async {
      final authCubit = AuthCubit(
        authRepository: authRepo,
        analyticsService: analytics,
        crashlyticsService: crashlytics,
      );

      // Successful Email Sign In
      await authCubit.signInWithEmail(email: 'test@nestora.com', password: 'Password123!');
      expect(analytics.recordedEvents.any((e) => e['name'] == 'login'), isTrue);
      expect(analytics.currentUserId, 'usr-123');
      expect(crashlytics.currentUserId, 'usr-123');

      // Sign Out
      await authCubit.signOut();
      expect(analytics.recordedEvents.any((e) => e['name'] == 'logout'), isTrue);
      expect(analytics.currentUserId, isNull);
      expect(crashlytics.currentUserId, isNull);

      // Failed Sign In
      authRepo.shouldFail = true;
      await authCubit.signInWithEmail(email: 'test@nestora.com', password: 'WrongPassword!');
      expect(crashlytics.recordedErrors.any((e) => (e['reason'] as String).contains('signInWithEmail failure')), isTrue);

      await authCubit.close();
    });

    test('RoomsCubit dispatches room creation and deletion analytics', () async {
      final roomsCubit = RoomsCubit(
        roomsRepository: roomsRepo,
        devicesRepository: devicesRepo,
        analyticsService: analytics,
        crashlyticsService: crashlytics,
      );

      await roomsCubit.createRoom(
        userId: 'usr-123',
        name: 'Mutfak',
        iconName: 'kitchen',
      );

      expect(analytics.recordedEvents.any((e) => e['name'] == 'room_created'), isTrue);

      await roomsCubit.deleteRoom(
        userId: 'usr-123',
        roomId: 'room-1',
      );

      expect(analytics.recordedEvents.any((e) => e['name'] == 'room_deleted'), isTrue);

      await roomsCubit.close();
    });

    test('DevicesCubit dispatches scenario activation and power toggle analytics', () async {
      final devicesCubit = DevicesCubit(
        devicesRepository: devicesRepo,
        analyticsService: analytics,
        crashlyticsService: crashlytics,
      );

      devicesRepo.devices.add(
        Device(
          id: 'dev-1',
          name: 'Salon Lambası',
          roomId: 'room-1',
          type: DeviceType.bulb,
          isPoweredOn: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      devicesCubit.loadDevices('usr-123');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Toggle Power
      await devicesCubit.togglePower('usr-123', 'dev-1');
      expect(analytics.recordedEvents.any((e) => e['name'] == 'device_power_toggle'), isTrue);

      // Quick Scenario
      await devicesCubit.applyQuickScene('Evdeyim', userId: 'usr-123');
      expect(analytics.recordedEvents.any((e) => e['name'] == 'scenario_activated'), isTrue);

      await devicesCubit.close();
    });
  });
}
