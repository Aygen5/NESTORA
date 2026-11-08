import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nestora/app/app.dart';
import 'package:nestora/app/app_shell.dart';
import 'package:nestora/app/router/app_router.dart';
import 'package:nestora/app/theme/theme_cubit.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/core/widgets/nestora_button.dart';
import 'package:nestora/core/widgets/nestora_input.dart';
import 'package:nestora/features/auth/domain/entities/auth_user.dart';
import 'package:nestora/features/auth/domain/repositories/auth_repository.dart';
import 'package:nestora/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nestora/features/auth/presentation/pages/login_page.dart';
import 'package:nestora/features/auth/presentation/pages/onboarding_page.dart';
import 'package:nestora/features/auth/presentation/pages/register_page.dart';
import 'package:nestora/features/auth/presentation/pages/splash_page.dart';
import 'package:nestora/features/auth/presentation/pages/welcome_page.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/devices/domain/repositories/devices_repository.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_cubit.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_state.dart';
import 'package:nestora/features/home/presentation/pages/dashboard_page.dart';
import 'package:nestora/features/notifications/domain/entities/app_notification.dart';
import 'package:nestora/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:nestora/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:nestora/features/profile/domain/entities/user_profile.dart';
import 'package:nestora/features/profile/domain/repositories/profile_repository.dart';
import 'package:nestora/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:nestora/features/rooms/domain/entities/room.dart';
import 'package:nestora/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Fakes for End-to-End Integration Tests ---

class _E2EAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<Result<AuthUser>> signInWithEmail({required String email, required String password}) async {
    final u = AuthUser(id: 'e2e-user', email: email, displayName: 'Test User');
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
    final u = AuthUser(id: 'e2e-user', email: email, displayName: displayName ?? 'Yeni Kullanıcı');
    _user = u;
    _controller.add(u);
    return Result.success(u);
  }

  @override
  Future<Result<AuthUser>> signInDemo({String? email, String? password}) async {
    const u = AuthUser(id: 'demo-user', email: 'demo@nestora.app', displayName: 'Demo Kullanıcı');
    _user = u;
    _controller.add(u);
    return Result.success(u);
  }

  @override
  Future<Result<void>> sendPasswordReset({required String email}) async => Result.success(null);

  @override
  Future<Result<void>> signOut() async {
    _user = null;
    _controller.add(null);
    return Result.success(null);
  }
}

class _E2EDevicesRepository implements DevicesRepository {
  final List<Device> devices = [];
  final StreamController<List<Device>> controller = StreamController<List<Device>>.broadcast();

  @override
  Stream<List<Device>> watchDevices(String userId) {
    scheduleMicrotask(() {
      if (!controller.isClosed) {
        controller.add(List.from(devices));
      }
    });
    return controller.stream;
  }

  @override
  Stream<List<Device>> watchDevicesByRoom(String userId, String roomId) =>
      controller.stream.map((list) => list.where((d) => d.roomId == roomId).toList());

  @override
  Future<Result<List<Device>>> getDevices(String userId) async => Result.success(devices);

  @override
  Future<Result<Device>> getDeviceById(String userId, String deviceId) async =>
      Result.success(devices.firstWhere((d) => d.id == deviceId));

  @override
  Future<Result<void>> createDevice(String userId, Device device) async {
    devices.add(device);
    controller.add(List.from(devices));
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateDevice(String userId, Device device) async {
    final idx = devices.indexWhere((d) => d.id == device.id);
    if (idx != -1) {
      devices[idx] = device;
      controller.add(List.from(devices));
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
        isFavorite: stateUpdates['isFavorite'] as bool? ?? old.isFavorite,
      );
      controller.add(List.from(devices));
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteDevice(String userId, String deviceId) async => Result.success(null);

  @override
  Future<Result<void>> deleteDevicesByRoom(String userId, String roomId) async => Result.success(null);

  @override
  Future<Result<void>> moveDevicesToRoom(String userId, String fromRoomId, String toRoomId) async => Result.success(null);
}

class _E2ERoomsRepository implements RoomsRepository {
  final List<Room> rooms = [];
  final StreamController<List<Room>> controller = StreamController<List<Room>>.broadcast();

  @override
  Stream<List<Room>> watchRooms(String userId) {
    scheduleMicrotask(() {
      if (!controller.isClosed) {
        controller.add(List.from(rooms));
      }
    });
    return controller.stream;
  }

  @override
  Future<Result<List<Room>>> getRooms(String userId) async => Result.success(rooms);

  @override
  Future<Result<Room>> getRoomById(String userId, String roomId) async =>
      Result.success(rooms.firstWhere((r) => r.id == roomId));

  @override
  Future<Result<void>> createRoom(String userId, Room room) async {
    rooms.add(room);
    controller.add(List.from(rooms));
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateRoom(String userId, Room room) async {
    final idx = rooms.indexWhere((r) => r.id == room.id);
    if (idx != -1) {
      rooms[idx] = room;
      controller.add(List.from(rooms));
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteRoom(String userId, String roomId) async => Result.success(null);
}

class _E2EProfileRepository implements ProfileRepository {
  UserProfile? profile;
  final StreamController<UserProfile?> controller = StreamController<UserProfile?>.broadcast();

  @override
  Stream<UserProfile?> watchProfile(String userId) {
    scheduleMicrotask(() {
      if (!controller.isClosed) {
        controller.add(profile);
      }
    });
    return controller.stream;
  }

  @override
  Future<Result<UserProfile?>> getProfile(String userId) async => Result.success(profile);

  @override
  Future<Result<void>> updateProfile(String userId, UserProfile p) async => Result.success(null);

  @override
  Future<Result<void>> updateHomeName(String userId, String homeName) async => Result.success(null);

  @override
  Future<Result<void>> updateDisplayName(String userId, String displayName) async => Result.success(null);

  @override
  Future<Result<void>> updatePreferences(String userId, UserPreferences prefs) async => Result.success(null);

  @override
  Future<Result<void>> updatePhotoPath(String userId, String? photoPath) async => Result.success(null);
}

class _E2ENotificationsRepository implements NotificationsRepository {
  final List<AppNotification> notifications = [];
  final StreamController<List<AppNotification>> controller = StreamController<List<AppNotification>>.broadcast();

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    scheduleMicrotask(() {
      if (!controller.isClosed) {
        controller.add(List.from(notifications));
      }
    });
    return controller.stream;
  }

  @override
  Future<Result<List<AppNotification>>> getNotifications(String userId) async => Result.success(notifications);

  @override
  Future<Result<void>> markAsRead(String userId, String notificationId) async => Result.success(null);

  @override
  Future<Result<void>> markAllAsRead(String userId) async => Result.success(null);

  @override
  Future<Result<void>> deleteNotification(String userId, String notificationId) async => Result.success(null);

  @override
  Future<Result<void>> createNotification(String userId, AppNotification notification) async => Result.success(null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late _E2EAuthRepository authRepo;
  late _E2EDevicesRepository devicesRepo;
  late _E2ERoomsRepository roomsRepo;
  late _E2EProfileRepository profileRepo;
  late _E2ENotificationsRepository notifsRepo;

  late AuthCubit authCubit;
  late DevicesCubit devicesCubit;
  late RoomsCubit roomsCubit;
  late ProfileCubit profileCubit;
  late NotificationsCubit notifsCubit;
  late ThemeCubit themeCubit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    authRepo = _E2EAuthRepository();
    devicesRepo = _E2EDevicesRepository();
    roomsRepo = _E2ERoomsRepository();
    profileRepo = _E2EProfileRepository();
    notifsRepo = _E2ENotificationsRepository();

    authCubit = AuthCubit(authRepository: authRepo);
    devicesCubit = DevicesCubit(devicesRepository: devicesRepo, debounceDuration: const Duration(milliseconds: 50));
    roomsCubit = RoomsCubit(roomsRepository: roomsRepo, devicesRepository: devicesRepo);
    profileCubit = ProfileCubit(profileRepository: profileRepo);
    notifsCubit = NotificationsCubit(notificationsRepository: notifsRepo);
    themeCubit = ThemeCubit();
  });

  tearDown(() {
    authCubit.close();
    devicesCubit.close();
    roomsCubit.close();
    profileCubit.close();
    notifsCubit.close();
    themeCubit.close();
  });

  Widget buildE2EApp({
    String initialLocation = AppRoutePaths.splash,
    AppAuthListenable? customAuthListenable,
  }) {
    final authListenable = customAuthListenable ?? AppAuthListenable(initialAuthState: false);
    final router = createAppRouter(
      initialLocation: initialLocation,
      authListenable: authListenable,
    );

    return NestoraApp(
      router: router,
      themeCubit: themeCubit,
      authCubit: authCubit,
      profileCubit: profileCubit,
      roomsCubit: roomsCubit,
      devicesCubit: devicesCubit,
      notificationsCubit: notifsCubit,
    );
  }

  group('Faz 9 - Adım 9.3: Uçtan Uca Entegrasyon Testleri (E2E Integration Flows)', () {
    testWidgets('Akış 1: Splash -> Onboarding -> Welcome -> Login -> Register -> Dashboard tam kullanıcı başlangıç akışı', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authListenable = AppAuthListenable(initialAuthState: false);

      await tester.pumpWidget(buildE2EApp(
        initialLocation: AppRoutePaths.splash,
        customAuthListenable: authListenable,
      ));

      // 1. Splash Page görünür
      expect(find.byType(SplashPage), findsOneWidget);

      // Splash ekran süresini (4000ms, Faz 2.2) ileri sar
      await tester.pump(const Duration(milliseconds: 4200));
      await tester.pumpAndSettle();

      // 2. Onboarding Page açılır
      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.text('Evinizi Kolayca\nYönetin'), findsOneWidget);

      // "Başla" butonuna tıkla
      await tester.tap(find.text('Başla'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // 3. Welcome Page açılır
      expect(find.byType(WelcomePage), findsOneWidget);
      expect(find.text('Evinin dijital dünyasına hoş geldin.'), findsOneWidget);

      // "Zaten hesabın var mı? Giriş Yap" butonuna tıkla
      await tester.tap(find.text('Zaten hesabın var mı? Giriş Yap'));
      await tester.pumpAndSettle();

      // 4. Kimliği doğrulanmamış kullanıcı Login ekranına gelir
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Giriş Yap'), findsWidgets);

      // "Kayıt Ol" yönlendirmesine tıkla
      final registerLink = find.text('Kayıt Ol');
      expect(registerLink, findsOneWidget);
      await tester.tap(registerLink);
      await tester.pumpAndSettle();

      // 5. RegisterPage açılır
      expect(find.byType(RegisterPage), findsOneWidget);
      expect(find.text('Aramıza Katıl'), findsOneWidget);

      // Form alanlarını doldur
      final nameField = find.descendant(of: find.widgetWithText(NestoraInput, 'Ad Soyad'), matching: find.byType(TextField));
      final emailField = find.descendant(of: find.widgetWithText(NestoraInput, 'E-posta'), matching: find.byType(TextField));
      final passField = find.descendant(of: find.widgetWithText(NestoraInput, 'Şifre'), matching: find.byType(TextField));
      final passConfirmField = find.descendant(of: find.widgetWithText(NestoraInput, 'Şifre Tekrar'), matching: find.byType(TextField));

      await tester.enterText(nameField, 'Aygen Yıldırım');
      await tester.enterText(emailField, 'aygen@nestora.app');
      await tester.enterText(passField, 'Nestora2026!');
      await tester.enterText(passConfirmField, 'Nestora2026!');
      await tester.pumpAndSettle();

      // "Hesap Oluştur" butonuna bas
      final submitButton = find.widgetWithText(NestoraButton, 'Hesap Oluştur');
      await tester.tap(submitButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Auth durumunu doğrulanmış olarak güncelle
      authListenable.setAuthenticated(true);
      await tester.pumpAndSettle();

      // 6. Kullanıcı AppShell ve Dashboard ana sayfasına ulaşmıştır
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(DashboardPage), findsOneWidget);
      expect(find.text('Bugün Tüketilen Enerji'), findsOneWidget);
    });

    testWidgets('Akış 2: Hızlı Demo ile Giriş Yap seçeneği demo verilerini yükleyip doğrudan Dashboarda aktarır', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authListenable = AppAuthListenable(initialAuthState: false);

      await tester.pumpWidget(buildE2EApp(
        initialLocation: AppRoutePaths.login,
        customAuthListenable: authListenable,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      final demoButton = find.text('Hızlı Demo ile Giriş Yap');
      expect(demoButton, findsOneWidget);

      // Demo butonuna tıkla
      await tester.tap(demoButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Oturumu doğrulanmışa çevir
      authListenable.setAuthenticated(true);
      await tester.pumpAndSettle();

      // Dashboard ana ekranına başarılı geçiş
      expect(find.byType(DashboardPage), findsOneWidget);
      expect(find.text('Bugün Tüketilen Enerji'), findsOneWidget);
      expect(find.text('Aktif Cihazlar'), findsOneWidget);
    });

    testWidgets('Akış 3: Yeni Oda Ekleme, Cihaza Bağlama, Cihaz Durumunu Değiştirme ve Dashboardda Anlık Senkronizasyon', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Oturumu açık kullanıcı
      final authListenable = AppAuthListenable(initialAuthState: true);

      // Başlangıç profili
      const userProfile = UserProfile(
        uid: 'user-e2e',
        email: 'aygen@nestora.app',
        displayName: 'Aygen',
        homeName: "Aygen'in Akıllı Evi",
      );
      profileRepo.profile = userProfile;
      profileCubit.loadProfile('user-e2e');
      profileRepo.controller.add(userProfile);

      // Başlangıç odaları ve cihazları
      final salon = Room(id: 'room-salon', name: 'Salon', iconName: 'chair', createdAt: DateTime.now(), updatedAt: DateTime.now());
      roomsRepo.rooms.add(salon);
      roomsCubit.loadRooms('user-e2e');
      roomsRepo.controller.add([salon]);

      final salonLambasi = Device(
        id: 'dev-salon-lamba',
        name: 'Salon Lambası',
        roomId: 'room-salon',
        type: DeviceType.bulb,
        isPoweredOn: false,
        brightness: 70,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      devicesRepo.devices.add(salonLambasi);
      devicesCubit.loadDevices('user-e2e');
      devicesRepo.controller.add([salonLambasi]);

      await tester.pumpWidget(buildE2EApp(
        initialLocation: AppRoutePaths.dashboard,
        customAuthListenable: authListenable,
      ));
      await tester.pumpAndSettle();

      // 1. Dashboard ilk hali: Salon odası var, Salon Lambası kapalı
      expect(find.byType(DashboardPage), findsOneWidget);
      expect(find.text('Salon'), findsWidgets);

      // 2. Yeni Oda Ekleme: AddEditRoomPage
      await roomsCubit.createRoom(
        userId: 'user-e2e',
        name: 'Teras',
        iconName: 'deck',
        targetTemperature: 23.5,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Dashboard odalar listesinde yeni oda (Teras) anında görünür!
      expect(find.text('Teras'), findsWidgets);

      // 3. Yeni Cihaz Ekleme: AddEditDevicePage
      await devicesCubit.createDevice(
        userId: 'user-e2e',
        name: 'Teras Lambası',
        roomId: 'room-salon',
        type: DeviceType.bulb,
        brightness: 85,
        isPoweredOn: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 4. Cihaz Durumunu Değiştirme (Teras Lambasını Açma)
      final createdDevice = (devicesCubit.state as DevicesLoaded).devices.firstWhere((d) => d.name == 'Teras Lambası');
      await devicesCubit.togglePower('user-e2e', createdDevice.id);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 5. Dashboard'da Gerçek Zamanlı Güncelleme Doğrulaması
      final updatedDevicesState = devicesCubit.state as DevicesLoaded;
      final terasLambasiState = updatedDevicesState.devices.firstWhere((d) => d.name == 'Teras Lambası');
      expect(terasLambasiState.isPoweredOn, isTrue);
      expect(terasLambasiState.brightness, equals(85));

      // Aktif cihaz sayısı ve cihaz adının Dashboard üzerinde anında senkronize olduğu doğrulanır
      expect(updatedDevicesState.activeDevices.any((d) => d.name == 'Teras Lambası'), isTrue);
      expect(find.text('Teras Lambası'), findsWidgets);
    });
  });
}
