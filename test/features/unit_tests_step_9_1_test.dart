import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/core/constants/app_constants.dart';
import 'package:nestora/core/errors/failures.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/features/auth/domain/entities/auth_user.dart';
import 'package:nestora/features/auth/domain/repositories/auth_repository.dart';
import 'package:nestora/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nestora/features/auth/presentation/cubit/auth_state.dart';
import 'package:nestora/features/auth/presentation/widgets/password_validator_widget.dart';
import 'package:nestora/features/devices/data/models/device_model.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/devices/domain/repositories/devices_repository.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_cubit.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_state.dart';
import 'package:nestora/features/notifications/data/models/notification_model.dart';
import 'package:nestora/features/notifications/domain/entities/app_notification.dart';
import 'package:nestora/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:nestora/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:nestora/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:nestora/features/profile/data/models/user_profile_model.dart';
import 'package:nestora/features/profile/domain/entities/user_profile.dart';
import 'package:nestora/features/profile/domain/repositories/profile_repository.dart';
import 'package:nestora/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:nestora/features/profile/presentation/cubit/profile_state.dart';
import 'package:nestora/features/rooms/data/models/room_model.dart';
import 'package:nestora/features/rooms/domain/entities/room.dart';
import 'package:nestora/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_cubit.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Fakes for Cubit Unit Tests ---

class Step9FakeAuthRepository implements AuthRepository {
  final StreamController<AuthUser?> _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;
  bool shouldFail = false;
  String failMessage = 'Auth Error';

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  AuthUser? get currentUser => _user;

  void emitUser(AuthUser? user) {
    _user = user;
    _controller.add(user);
  }

  @override
  Future<Result<AuthUser>> signInWithEmail({required String email, required String password}) async {
    if (shouldFail) return Result.failure(AuthFailure(failMessage));
    final u = AuthUser(id: 'u-1', email: email, displayName: 'Test User');
    _user = u;
    _controller.add(u);
    return Result.success(u);
  }

  @override
  Future<Result<AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (shouldFail) return Result.failure(AuthFailure(failMessage));
    final u = AuthUser(id: 'u-new', email: email, displayName: displayName ?? 'New');
    _user = u;
    _controller.add(u);
    return Result.success(u);
  }

  @override
  Future<Result<void>> signOut() async {
    if (shouldFail) return Result.failure(AuthFailure(failMessage));
    _user = null;
    _controller.add(null);
    return Result.success(null);
  }

  @override
  Future<Result<void>> sendPasswordReset({required String email}) async {
    if (shouldFail) return Result.failure(AuthFailure(failMessage));
    return Result.success(null);
  }

  @override
  Future<Result<AuthUser>> signInDemo({String? email, String? password}) async {
    if (shouldFail) return Result.failure(AuthFailure(failMessage));
    const u = AuthUser(id: 'demo-u', email: 'demo@nestora.app', displayName: 'Demo');
    _user = u;
    _controller.add(u);
    return Result.success(u);
  }
}

class Step9FakeRoomsRepository implements RoomsRepository {
  final List<Room> rooms = [];
  final StreamController<List<Room>> _controller = StreamController<List<Room>>.broadcast();
  bool shouldFail = false;

  @override
  Stream<List<Room>> watchRooms(String userId) => _controller.stream;

  @override
  Future<Result<List<Room>>> getRooms(String userId) async {
    if (shouldFail) return Result.failure(const ServerFailure('Rooms fetch failed'));
    return Result.success(rooms);
  }

  @override
  Future<Result<Room>> getRoomById(String userId, String roomId) async =>
      Result.success(rooms.firstWhere((r) => r.id == roomId));

  @override
  Future<Result<void>> createRoom(String userId, Room room) async {
    if (shouldFail) return Result.failure(const ServerFailure('Create room failed'));
    rooms.add(room);
    _controller.add(List.from(rooms));
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateRoom(String userId, Room room) async {
    if (shouldFail) return Result.failure(const ServerFailure('Update room failed'));
    final idx = rooms.indexWhere((r) => r.id == room.id);
    if (idx != -1) {
      rooms[idx] = room;
      _controller.add(List.from(rooms));
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteRoom(String userId, String roomId) async {
    if (shouldFail) return Result.failure(const ServerFailure('Delete room failed'));
    rooms.removeWhere((r) => r.id == roomId);
    _controller.add(List.from(rooms));
    return Result.success(null);
  }
}

class Step9FakeDevicesRepository implements DevicesRepository {
  final List<Device> devices = [];
  final StreamController<List<Device>> _controller = StreamController<List<Device>>.broadcast();
  bool shouldFail = false;

  @override
  Stream<List<Device>> watchDevices(String userId) => _controller.stream;

  @override
  Stream<List<Device>> watchDevicesByRoom(String userId, String roomId) =>
      _controller.stream.map((list) => list.where((d) => d.roomId == roomId).toList());

  @override
  Future<Result<List<Device>>> getDevices(String userId) async => Result.success(devices);

  @override
  Future<Result<Device>> getDeviceById(String userId, String deviceId) async =>
      Result.success(devices.firstWhere((d) => d.id == deviceId));

  @override
  Future<Result<void>> createDevice(String userId, Device device) async {
    if (shouldFail) return Result.failure(const ServerFailure('Create device failed'));
    devices.add(device);
    _controller.add(List.from(devices));
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateDevice(String userId, Device device) async {
    if (shouldFail) return Result.failure(const ServerFailure('Update device failed'));
    final idx = devices.indexWhere((d) => d.id == device.id);
    if (idx != -1) {
      devices[idx] = device;
      _controller.add(List.from(devices));
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateDeviceState(
    String userId,
    String deviceId,
    Map<String, dynamic> stateUpdates,
  ) async {
    final idx = devices.indexWhere((d) => d.id == deviceId);
    if (idx != -1) {
      final old = devices[idx];
      devices[idx] = old.copyWith(
        brightness: stateUpdates['brightness'] as int? ?? old.brightness,
        targetTemp: (stateUpdates['targetTemp'] as num?)?.toDouble() ?? old.targetTemp,
        isPoweredOn: stateUpdates['isPoweredOn'] as bool? ?? old.isPoweredOn,
        colorHex: stateUpdates['color'] as String? ?? old.colorHex,
        acMode: stateUpdates['acMode'] != null
            ? AcMode.fromString(stateUpdates['acMode'] as String)
            : old.acMode,
        fanSpeed: stateUpdates['fanSpeed'] != null
            ? FanSpeed.fromString(stateUpdates['fanSpeed'] as String)
            : old.fanSpeed,
      );
      _controller.add(List.from(devices));
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteDevice(String userId, String deviceId) async {
    devices.removeWhere((d) => d.id == deviceId);
    _controller.add(List.from(devices));
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteDevicesByRoom(String userId, String roomId) async {
    devices.removeWhere((d) => d.roomId == roomId);
    _controller.add(List.from(devices));
    return Result.success(null);
  }

  @override
  Future<Result<void>> moveDevicesToRoom(String userId, String fromRoomId, String toRoomId) async {
    for (int i = 0; i < devices.length; i++) {
      if (devices[i].roomId == fromRoomId) {
        devices[i] = devices[i].copyWith(roomId: toRoomId);
      }
    }
    _controller.add(List.from(devices));
    return Result.success(null);
  }
}

class Step9FakeNotificationsRepository implements NotificationsRepository {
  final List<AppNotification> notifications = [];
  final StreamController<List<AppNotification>> _controller = StreamController<List<AppNotification>>.broadcast();

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) => _controller.stream;

  @override
  Future<Result<List<AppNotification>>> getNotifications(String userId) async =>
      Result.success(notifications);

  @override
  Future<Result<void>> markAsRead(String userId, String notificationId) async {
    final idx = notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      notifications[idx] = notifications[idx].copyWith(isRead: true);
      _controller.add(List.from(notifications));
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> markAllAsRead(String userId) async {
    for (int i = 0; i < notifications.length; i++) {
      notifications[i] = notifications[i].copyWith(isRead: true);
    }
    _controller.add(List.from(notifications));
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteNotification(String userId, String notificationId) async {
    notifications.removeWhere((n) => n.id == notificationId);
    _controller.add(List.from(notifications));
    return Result.success(null);
  }

  @override
  Future<Result<void>> createNotification(String userId, AppNotification notification) async {
    notifications.add(notification);
    _controller.add(List.from(notifications));
    return Result.success(null);
  }
}

class Step9FakeProfileRepository implements ProfileRepository {
  UserProfile? profile;
  final StreamController<UserProfile?> _controller = StreamController<UserProfile?>.broadcast();

  @override
  Stream<UserProfile?> watchProfile(String userId) => _controller.stream;

  @override
  Future<Result<UserProfile?>> getProfile(String userId) async => Result.success(profile);

  @override
  Future<Result<void>> updateProfile(String userId, UserProfile p) async {
    profile = p;
    _controller.add(profile);
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateHomeName(String userId, String homeName) async {
    if (profile != null) {
      profile = profile!.copyWith(homeName: homeName);
      _controller.add(profile);
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateDisplayName(String userId, String displayName) async {
    if (profile != null) {
      profile = profile!.copyWith(displayName: displayName);
      _controller.add(profile);
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> updatePreferences(String userId, UserPreferences prefs) async {
    if (profile != null) {
      profile = profile!.copyWith(preferences: prefs);
      _controller.add(profile);
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> updatePhotoPath(String userId, String? photoPath) async {
    if (profile != null) {
      profile = profile!.copyWith(photoPath: photoPath);
      _controller.add(profile);
    }
    return Result.success(null);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Faz 9 - Adım 9.1: Veri Modelleri ve DTO Parsing (Firestore DTOs & Serialization)', () {
    test('RoomModel.fromMap ve toFirestore eksiksiz ve dayanıklı çalışmalıdır', () {
      final rawData = {
        'name': 'Çalışma Odası',
        'icon': 'computer',
        'targetTemperature': 21.5,
        'humidity': 45,
        'deviceCount': 3,
        'activeDeviceCount': 1,
        'imageAsset': 'assets/screens/office.png',
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 8, 10, 0)),
      };

      final model = RoomModel.fromMap(rawData, id: 'room-office');

      expect(model.id, equals('room-office'));
      expect(model.name, equals('Çalışma Odası'));
      expect(model.iconName, equals('computer'));
      expect(model.targetTemperature, equals(21.5));
      expect(model.humidity, equals(45));
      expect(model.deviceCount, equals(3));
      expect(model.activeDeviceCount, equals(1));
      expect(model.imageAsset, equals('assets/screens/office.png'));

      // Eksik veya boş veri ile dayanıklılık testi
      final fallbackModel = RoomModel.fromMap(const {}, id: 'room-empty');
      expect(fallbackModel.id, equals('room-empty'));
      expect(fallbackModel.name, equals('Oda'));
      expect(fallbackModel.targetTemperature, equals(22.0));
      expect(fallbackModel.humidity, equals(50));

      // toFirestore doğrulaması
      final firestoreMap = model.toFirestore();
      expect(firestoreMap['name'], equals('Çalışma Odası'));
      expect(firestoreMap['icon'], equals('computer'));
      expect(firestoreMap['targetTemperature'], equals(21.5));
      expect(firestoreMap['updatedAt'], isA<FieldValue>());
    });

    test('DeviceModel.fromMap ve toFirestore farklı cihaz türlerini parse edebilmelidir', () {
      // 1. Bulb Device
      final bulbData = {
        'name': 'Tavan Lambası',
        'roomId': 'room-1',
        'type': 'bulb',
        'isOn': true,
        'brightness': 85,
        'color': '#FFD700',
        'currentPowerWatts': 14.5,
      };
      final bulbModel = DeviceModel.fromMap(bulbData, id: 'dev-bulb-1');
      expect(bulbModel.id, equals('dev-bulb-1'));
      expect(bulbModel.type, equals(DeviceType.bulb));
      expect(bulbModel.brightness, equals(85));
      expect(bulbModel.colorHex, equals('#FFD700'));
      expect(bulbModel.isPoweredOn, isTrue);

      // 2. AC Device
      final acData = {
        'name': 'Salon Kliması',
        'roomId': 'room-1',
        'type': 'ac',
        'isOn': true,
        'targetTemperature': 23.0,
        'mode': 'cool',
        'fanSpeed': 'high',
      };
      final acModel = DeviceModel.fromMap(acData, id: 'dev-ac-1');
      expect(acModel.id, equals('dev-ac-1'));
      expect(acModel.type, equals(DeviceType.ac));
      expect(acModel.isClimate, isTrue);
      expect(acModel.acMode, equals(AcMode.cool));
      expect(acModel.fanSpeed, equals(FanSpeed.high));

      // 3. Fallback / Default Değerler
      final fallbackDev = DeviceModel.fromMap(const {}, id: 'dev-corrupt');
      expect(fallbackDev.id, equals('dev-corrupt'));
      expect(fallbackDev.name, equals('Cihaz'));
      expect(fallbackDev.type, equals(DeviceType.bulb));
      expect(fallbackDev.brightness, equals(72));
    });

    test('NotificationModel.fromMap bildirim tiplerini ve okundu durumunu parse etmelidir', () {
      final notifData = {
        'title': 'Güvenlik Alarmı',
        'message': 'Hareket algılandı',
        'type': 'security',
        'isRead': false,
        'relatedRoomId': 'room-garden',
        'createdAt': Timestamp.now(),
      };
      final model = NotificationModel.fromMap(notifData, id: 'notif-1');

      expect(model.id, equals('notif-1'));
      expect(model.title, equals('Güvenlik Alarmı'));
      expect(model.type, equals(NotificationType.security));
      expect(model.isRead, isFalse);
      expect(model.relatedRoomId, equals('room-garden'));

      final firestoreMap = model.toFirestore();
      expect(firestoreMap['title'], equals('Güvenlik Alarmı'));
      expect(firestoreMap['type'], equals('security'));
      expect(firestoreMap['isRead'], isFalse);
    });

    test('UserProfileModel.fromMap iç içe kullanıcı tercihlerini ve baş harfleri türetmelidir', () {
      final profileData = {
        'displayName': 'Aygen Yıldırım',
        'homeName': "Aygen'in Akıllı Evi",
        'email': 'aygen@nestora.app',
        'photoPath': '/local/path/avatar.png',
        'preferences': {
          'notificationsEnabled': true,
          'ecoModeEnabled': true,
          'temperatureUnit': 'C',
        },
      };
      final model = UserProfileModel.fromMap(profileData, uid: 'user-100');

      expect(model.uid, equals('user-100'));
      expect(model.displayName, equals('Aygen Yıldırım'));
      expect(model.initials, equals('AY'));
      expect(model.homeName, equals("Aygen'in Akıllı Evi"));
      expect(model.preferences.ecoModeEnabled, isTrue);
      expect(model.preferences.temperatureUnit, equals('C'));

      final firestoreMap = model.toFirestore();
      expect(firestoreMap['displayName'], equals('Aygen Yıldırım'));
      expect((firestoreMap['preferences'] as Map)['ecoModeEnabled'], isTrue);
    });

    test('Model <-> Entity dönüşümleri ve copyWith/equality doğrulanmalıdır', () {
      const room = Room(
        id: 'r-test',
        name: 'Oda Test',
        iconName: 'bed',
        targetTemperature: 20.0,
      );
      final roomModel = RoomModel.fromEntity(room);
      expect(roomModel.toEntity(), equals(room));

      const device = Device(
        id: 'd-test',
        name: 'Test Cihaz',
        roomId: 'r-test',
        type: DeviceType.bulb,
        brightness: 50,
      );
      final devModel = DeviceModel.fromEntity(device);
      expect(devModel.toEntity(), equals(device));
      expect(device.copyWith(brightness: 60).brightness, equals(60));
    });
  });

  group('Faz 9 - Adım 9.1: Şifre ve E-posta Doğrulama Kuralları Testleri', () {
    test('E-posta format doğrulama regex kuralları geçerli ve geçersizleri doğru ayrıştırmalıdır', () {
      // Geçerli formatlar
      expect(AppConstants.emailRegex.hasMatch('test@nestora.app'), isTrue);
      expect(AppConstants.emailRegex.hasMatch('aygen.yildirim@domain.com.tr'), isTrue);
      expect(AppConstants.emailRegex.hasMatch('user+tag123@sub.host.co'), isTrue);

      // Geçersiz formatlar
      expect(AppConstants.emailRegex.hasMatch(''), isFalse);
      expect(AppConstants.emailRegex.hasMatch('plainaddress'), isFalse);
      expect(AppConstants.emailRegex.hasMatch(r'#@%^%#$@#$@#.com'), isFalse);
      expect(AppConstants.emailRegex.hasMatch('@missinguser.com'), isFalse);
      expect(AppConstants.emailRegex.hasMatch('user@missingtld'), isFalse);
      expect(AppConstants.emailRegex.hasMatch('user@domain.'), isFalse);
      expect(AppConstants.emailRegex.hasMatch('user with spaces@domain.com'), isFalse);
    });

    test('Şifre karmaşıklık kuralları (En az 8 karakter, büyük harf, rakam, özel karakter) doğrulanmalıdır', () {
      // 1. En az 8 karakter kuralı
      final shortRes = PasswordValidationResult.evaluate('Nest1!');
      expect(shortRes.hasMin8Chars, isFalse);
      expect(shortRes.isStrong, isFalse);

      // 2. Büyük harf eksikliği
      final noUpperRes = PasswordValidationResult.evaluate('nestora2026!');
      expect(noUpperRes.hasUppercase, isFalse);
      expect(noUpperRes.isStrong, isFalse);

      // 3. Rakam eksikliği
      final noNumRes = PasswordValidationResult.evaluate('NestoraApp!');
      expect(noNumRes.hasNumber, isFalse);
      expect(noNumRes.isStrong, isFalse);

      // 4. Özel karakter eksikliği
      final noSpecialRes = PasswordValidationResult.evaluate('Nestora2026');
      expect(noSpecialRes.hasSpecialChar, isFalse);
      expect(noSpecialRes.isStrong, isFalse);

      // 5. Türkçe büyük harf desteği (Ç, Ğ, İ, Ö, Ş, Ü)
      final turkishUpperRes = PasswordValidationResult.evaluate('şifreŞifre2026!');
      expect(turkishUpperRes.hasUppercase, isTrue);

      // 6. Şifre tekrar eşleşmesi (isMatching)
      final matchRes = PasswordValidationResult.evaluate('Nestora2026!', 'Nestora2026!');
      expect(matchRes.isMatching, isTrue);

      final mismatchRes = PasswordValidationResult.evaluate('Nestora2026!', 'FarkliSifre2026!');
      expect(mismatchRes.isMatching, isFalse);

      // 7. Tam güçlü şifre
      final strongRes = PasswordValidationResult.evaluate('Nestora2026!');
      expect(strongRes.hasMin8Chars, isTrue);
      expect(strongRes.hasUppercase, isTrue);
      expect(strongRes.hasNumber, isTrue);
      expect(strongRes.hasSpecialChar, isTrue);
      expect(strongRes.isStrong, isTrue);
    });
  });

  group('Faz 9 - Adım 9.1: AuthCubit Durum Geçiş (State Transition) Testleri', () {
    late Step9FakeAuthRepository fakeAuthRepo;
    late AuthCubit authCubit;

    setUp(() {
      fakeAuthRepo = Step9FakeAuthRepository();
      authCubit = AuthCubit(authRepository: fakeAuthRepo);
    });

    tearDown(() {
      authCubit.close();
    });

    test('Initial state ve checkAuthStatus geçişleri', () {
      expect(authCubit.state, equals(const AuthInitial()));

      authCubit.checkAuthStatus();
      expect(authCubit.state, equals(const Unauthenticated()));

      fakeAuthRepo._user = const AuthUser(id: 'u-cached', email: 'cached@nestora.app');
      authCubit.checkAuthStatus();
      expect(authCubit.state, isA<Authenticated>());
    });

    test('signInWithEmail geçersiz e-posta veya şifrede AuthError üretmelidir', () async {
      await authCubit.signInWithEmail(email: 'hatali-eposta', password: 'Password123!');
      expect(authCubit.state, isA<AuthError>());

      await authCubit.signInWithEmail(email: 'valid@nestora.app', password: '');
      expect(authCubit.state, isA<AuthError>());
    });

    test('signInWithEmail başarılı oturum açmada [AuthLoading, Authenticated] durumlarına geçmelidir', () async {
      final states = <AuthState>[];
      final sub = authCubit.stream.listen(states.add);

      await authCubit.signInWithEmail(email: 'user@nestora.app', password: 'Password123!');
      await pumpEventQueue();

      expect(states.length, equals(2));
      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<Authenticated>());
      await sub.cancel();
    });

    test('signUpWithEmail şifre eşleşmediğinde veya zayıf olduğunda AuthError üretmelidir', () async {
      // Şifre eşleşmiyor
      await authCubit.signUpWithEmail(
        email: 'user@nestora.app',
        password: 'Password123!',
        passwordConfirm: 'Mismatch123!',
      );
      expect(authCubit.state, isA<AuthError>());
      expect((authCubit.state as AuthError).message, contains('eşleşmiyor'));

      // Şifre zayıf (özel karakter yok)
      await authCubit.signUpWithEmail(
        email: 'user@nestora.app',
        password: 'WeakPassword1',
        passwordConfirm: 'WeakPassword1',
      );
      expect(authCubit.state, isA<AuthError>());
      expect((authCubit.state as AuthError).message, contains('özel karakter'));
    });

    test('sendPasswordReset başarılı olduğunda AuthPasswordResetSent üretmelidir', () async {
      await authCubit.sendPasswordReset(email: 'forgot@nestora.app');
      expect(authCubit.state, isA<AuthPasswordResetSent>());
      final sentState = authCubit.state as AuthPasswordResetSent;
      expect(sentState.email, equals('forgot@nestora.app'));
    });

    test('signInDemo hızlı demo girişi Authenticated üretmelidir', () async {
      await authCubit.signInDemo();
      expect(authCubit.state, isA<Authenticated>());
      final authState = authCubit.state as Authenticated;
      expect(authState.user.email, equals('demo@nestora.app'));
    });

    test('signOut Unauthenticated durumuna geçirmelidir', () async {
      await authCubit.signInDemo();
      expect(authCubit.state, isA<Authenticated>());

      await authCubit.signOut();
      expect(authCubit.state, equals(const Unauthenticated()));
    });

    test('clearError hata durumunu temizlemelidir', () async {
      await authCubit.signInWithEmail(email: 'bad', password: '');
      expect(authCubit.state, isA<AuthError>());

      authCubit.clearError();
      expect(authCubit.state, equals(const Unauthenticated()));
    });
  });

  group('Faz 9 - Adım 9.1: RoomsCubit Durum Geçiş (State Transition) Testleri', () {
    late Step9FakeRoomsRepository fakeRoomsRepo;
    late Step9FakeDevicesRepository fakeDevicesRepo;
    late RoomsCubit roomsCubit;

    setUp(() {
      fakeRoomsRepo = Step9FakeRoomsRepository();
      fakeDevicesRepo = Step9FakeDevicesRepository();
      roomsCubit = RoomsCubit(
        roomsRepository: fakeRoomsRepo,
        devicesRepository: fakeDevicesRepo,
      );
    });

    tearDown(() {
      roomsCubit.close();
    });

    test('loadRooms [RoomsLoading, RoomsLoaded] geçişini yapmalıdır', () async {
      expect(roomsCubit.state, equals(const RoomsInitial()));

      roomsCubit.loadRooms('user-1');
      expect(roomsCubit.state, isA<RoomsLoading>());

      final room1 = Room(id: 'r1', name: 'Salon', iconName: 'chair', createdAt: DateTime.now(), updatedAt: DateTime.now());
      fakeRoomsRepo._controller.add([room1]);
      await pumpEventQueue();

      expect(roomsCubit.state, isA<RoomsLoaded>());
      final loaded = roomsCubit.state as RoomsLoaded;
      expect(loaded.rooms.length, equals(1));
      expect(loaded.rooms.first.name, equals('Salon'));
    });

    test('createRoom oda ekleme ve search filtering kontrolü', () async {
      roomsCubit.loadRooms('user-1');
      await roomsCubit.createRoom(
        userId: 'user-1',
        name: 'Mutfak',
        iconName: 'restaurant',
      );
      await pumpEventQueue();

      expect(roomsCubit.state, isA<RoomsLoaded>());
      final loaded = roomsCubit.state as RoomsLoaded;
      expect(loaded.rooms.any((r) => r.name == 'Mutfak'), isTrue);

      // Arama filtresi testi
      roomsCubit.setSearchQuery('mut');
      final filteredState = roomsCubit.state as RoomsLoaded;
      expect(filteredState.filteredRooms.length, equals(1));
      expect(filteredState.filteredRooms.first.name, equals('Mutfak'));

      roomsCubit.setSearchQuery('banyo');
      final emptyFiltered = roomsCubit.state as RoomsLoaded;
      expect(emptyFiltered.filteredRooms.isEmpty, isTrue);
    });

    test('updateRoom ve deleteRoom durum geçişleri', () async {
      final initialRoom = Room(id: 'r-edit', name: 'Eski Ad', iconName: 'chair', createdAt: DateTime.now(), updatedAt: DateTime.now());
      fakeRoomsRepo.rooms.add(initialRoom);
      roomsCubit.loadRooms('user-1');
      fakeRoomsRepo._controller.add([initialRoom]);
      await pumpEventQueue();

      // Güncelleme
      final updatedRoom = initialRoom.copyWith(name: 'Yeni Ad');
      await roomsCubit.updateRoom(userId: 'user-1', room: updatedRoom);
      await pumpEventQueue();

      var loaded = roomsCubit.state as RoomsLoaded;
      expect(loaded.rooms.first.name, equals('Yeni Ad'));

      // Silme
      await roomsCubit.deleteRoom(userId: 'user-1', roomId: 'r-edit');
      await pumpEventQueue();

      loaded = roomsCubit.state as RoomsLoaded;
      expect(loaded.rooms.isEmpty, isTrue);
    });
  });

  group('Faz 9 - Adım 9.1: DevicesCubit Durum Geçiş (State Transition) Testleri', () {
    late Step9FakeDevicesRepository fakeDevicesRepo;
    late DevicesCubit devicesCubit;

    setUp(() {
      fakeDevicesRepo = Step9FakeDevicesRepository();
      devicesCubit = DevicesCubit(
        devicesRepository: fakeDevicesRepo,
        debounceDuration: const Duration(milliseconds: 50),
      );
    });

    tearDown(() {
      devicesCubit.close();
    });

    test('loadDevices, togglePower ve optimistic UI durum geçişleri', () async {
      expect(devicesCubit.state, equals(const DevicesInitial()));

      final testDevice = Device(
        id: 'dev-1',
        name: 'Salon Lambası',
        roomId: 'room-1',
        type: DeviceType.bulb,
        isPoweredOn: false,
        brightness: 70,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      fakeDevicesRepo.devices.add(testDevice);

      devicesCubit.loadDevices('user-dev');
      fakeDevicesRepo._controller.add([testDevice]);
      await pumpEventQueue();

      expect(devicesCubit.state, isA<DevicesLoaded>());
      var loaded = devicesCubit.state as DevicesLoaded;
      expect(loaded.devices.first.isPoweredOn, isFalse);

      // Güç açma / kapatma
      await devicesCubit.togglePower('user-dev', 'dev-1');
      await pumpEventQueue();

      loaded = devicesCubit.state as DevicesLoaded;
      expect(loaded.devices.first.isPoweredOn, isTrue);
    });

    test('Klima modu ve fan hızı ayarları durum geçişleri', () async {
      final acDevice = Device(
        id: 'dev-ac',
        name: 'Klima',
        roomId: 'room-1',
        type: DeviceType.ac,
        targetTemp: 22.0,
        acMode: AcMode.auto,
        fanSpeed: FanSpeed.mid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      fakeDevicesRepo.devices.add(acDevice);

      devicesCubit.loadDevices('user-dev');
      fakeDevicesRepo._controller.add([acDevice]);
      await pumpEventQueue();

      // Mod değiştir
      await devicesCubit.setAcMode('user-dev', 'dev-ac', AcMode.cool);
      await pumpEventQueue();
      var loaded = devicesCubit.state as DevicesLoaded;
      expect(loaded.devices.first.acMode, equals(AcMode.cool));

      // Fan hızını değiştir
      await devicesCubit.setFanSpeed('user-dev', 'dev-ac', FanSpeed.high);
      await pumpEventQueue();
      loaded = devicesCubit.state as DevicesLoaded;
      expect(loaded.devices.first.fanSpeed, equals(FanSpeed.high));
    });

    test('Hızlı Senaryolar (Evdeyim, Gece Modu, vb.) çoklu cihazları yönetmelidir', () async {
      final lamba = Device(id: 'd-lamp', name: 'Lamba', roomId: 'room-1', type: DeviceType.bulb, isPoweredOn: false, createdAt: DateTime.now(), updatedAt: DateTime.now());
      final klima = Device(id: 'd-ac', name: 'Klima', roomId: 'room-1', type: DeviceType.ac, isPoweredOn: false, createdAt: DateTime.now(), updatedAt: DateTime.now());
      fakeDevicesRepo.devices.addAll([lamba, klima]);

      devicesCubit.loadDevices('user-dev');
      fakeDevicesRepo._controller.add([lamba, klima]);
      await pumpEventQueue();

      // 'Evdeyim' senaryosu
      await devicesCubit.applyScene(userId: 'user-dev', sceneKey: 'Evdeyim');
      await pumpEventQueue();

      final loaded = devicesCubit.state as DevicesLoaded;
      expect(loaded.devices.every((d) => d.isPoweredOn), isTrue);
    });
  });

  group('Faz 9 - Adım 9.1: NotificationsCubit Durum Geçiş (State Transition) Testleri', () {
    late Step9FakeNotificationsRepository fakeNotifRepo;
    late NotificationsCubit notifsCubit;

    setUp(() {
      fakeNotifRepo = Step9FakeNotificationsRepository();
      notifsCubit = NotificationsCubit(notificationsRepository: fakeNotifRepo);
    });

    tearDown(() {
      notifsCubit.close();
    });

    test('loadNotifications ve unreadCount hesabı doğru çalışmalıdır', () async {
      expect(notifsCubit.state, equals(const NotificationsInitial()));

      final n1 = AppNotification(id: 'n1', title: 'Bildirim 1', message: 'M1', isRead: false, createdAt: DateTime.now());
      final n2 = AppNotification(id: 'n2', title: 'Bildirim 2', message: 'M2', isRead: true, createdAt: DateTime.now());
      fakeNotifRepo.notifications.addAll([n1, n2]);

      notifsCubit.loadNotifications('user-notif');
      fakeNotifRepo._controller.add([n1, n2]);
      await pumpEventQueue();

      expect(notifsCubit.state, isA<NotificationsLoaded>());
      var loaded = notifsCubit.state as NotificationsLoaded;
      expect(loaded.notifications.length, equals(2));
      expect(loaded.unreadCount, equals(1));

      // Tek okundu işaretleme
      await notifsCubit.markAsRead(userId: 'user-notif', notificationId: 'n1');
      await pumpEventQueue();

      loaded = notifsCubit.state as NotificationsLoaded;
      expect(loaded.unreadCount, equals(0));
    });

    test('markAllAsRead ve clearAllNotifications tüm bildirimleri işlemelidir', () async {
      final n1 = AppNotification(id: 'n1', title: 'B1', message: 'M1', isRead: false, createdAt: DateTime.now());
      final n2 = AppNotification(id: 'n2', title: 'B2', message: 'M2', isRead: false, createdAt: DateTime.now());
      fakeNotifRepo.notifications.addAll([n1, n2]);

      notifsCubit.loadNotifications('user-notif');
      fakeNotifRepo._controller.add([n1, n2]);
      await pumpEventQueue();

      await notifsCubit.markAllAsRead(userId: 'user-notif');
      await pumpEventQueue();

      var loaded = notifsCubit.state as NotificationsLoaded;
      expect(loaded.unreadCount, equals(0));

      await notifsCubit.clearAllNotifications(userId: 'user-notif');
      await pumpEventQueue();

      loaded = notifsCubit.state as NotificationsLoaded;
      expect(loaded.notifications.isEmpty, isTrue);
    });
  });

  group('Faz 9 - Adım 9.1: ProfileCubit Durum Geçiş (State Transition) Testleri', () {
    late Step9FakeProfileRepository fakeProfileRepo;
    late ProfileCubit profileCubit;

    setUp(() {
      fakeProfileRepo = Step9FakeProfileRepository();
      profileCubit = ProfileCubit(profileRepository: fakeProfileRepo);
    });

    tearDown(() {
      profileCubit.close();
    });

    test('loadProfile, updateHomeName ve updateDisplayName durum geçişleri', () async {
      expect(profileCubit.state, equals(const ProfileInitial()));

      const initialProfile = UserProfile(
        uid: 'user-prof',
        email: 'prof@nestora.app',
        displayName: 'Eski İsim',
        homeName: "Eski Ev Adı",
      );
      fakeProfileRepo.profile = initialProfile;

      profileCubit.loadProfile('user-prof');
      fakeProfileRepo._controller.add(initialProfile);
      await pumpEventQueue();

      expect(profileCubit.state, isA<ProfileLoaded>());
      var loaded = profileCubit.state as ProfileLoaded;
      expect(loaded.profile.displayName, equals('Eski İsim'));

      // Ev adını güncelle
      await profileCubit.updateHomeName("Aygen'in Akıllı Köşkü");
      await pumpEventQueue();
      loaded = profileCubit.state as ProfileLoaded;
      expect(loaded.profile.homeName, equals("Aygen'in Akıllı Köşkü"));
      expect(loaded.feedbackMessage, contains('başarıyla güncellendi'));

      // Kullanıcı adını güncelle
      await profileCubit.updateDisplayName("Aygen Hanım");
      await pumpEventQueue();
      loaded = profileCubit.state as ProfileLoaded;
      expect(loaded.profile.displayName, equals("Aygen Hanım"));
    });

    test('toggleNotifications, toggleEcoMode ve setTemperatureUnit kullanıcı tercihlerini güncellemelidir', () async {
      const p = UserProfile(uid: 'user-pref', email: 'p@nestora.app', displayName: 'P', homeName: 'H');
      fakeProfileRepo.profile = p;

      profileCubit.loadProfile('user-pref');
      fakeProfileRepo._controller.add(p);
      await pumpEventQueue();

      // Bildirimleri kapat
      await profileCubit.toggleNotifications(false);
      await pumpEventQueue();
      var loaded = profileCubit.state as ProfileLoaded;
      expect(loaded.profile.preferences.notificationsEnabled, isFalse);

      // Eko modu aç
      await profileCubit.toggleEcoMode(true);
      await pumpEventQueue();
      loaded = profileCubit.state as ProfileLoaded;
      expect(loaded.profile.preferences.ecoModeEnabled, isTrue);

      // Sıcaklık birimini F yap
      await profileCubit.setTemperatureUnit('F');
      await pumpEventQueue();
      loaded = profileCubit.state as ProfileLoaded;
      expect(loaded.profile.preferences.temperatureUnit, equals('F'));
    });
  });
}
