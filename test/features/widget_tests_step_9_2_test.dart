import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nestora/app/theme/app_theme.dart';
import 'package:nestora/app/theme/theme_cubit.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/core/widgets/nestora_button.dart';
import 'package:nestora/core/widgets/nestora_input.dart';
import 'package:nestora/core/widgets/nestora_switch.dart';
import 'package:nestora/features/auth/domain/entities/auth_user.dart';
import 'package:nestora/features/auth/domain/repositories/auth_repository.dart';
import 'package:nestora/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nestora/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:nestora/features/auth/presentation/pages/login_page.dart';
import 'package:nestora/features/auth/presentation/pages/register_page.dart';
import 'package:nestora/features/auth/presentation/widgets/password_validator_widget.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/devices/domain/repositories/devices_repository.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_cubit.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_state.dart';
import 'package:nestora/features/devices/presentation/pages/devices_page.dart';
import 'package:nestora/features/devices/presentation/pages/lamp_control_page.dart';
import 'package:nestora/features/profile/domain/entities/user_profile.dart';
import 'package:nestora/features/profile/domain/repositories/profile_repository.dart';
import 'package:nestora/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:nestora/features/profile/presentation/pages/profile_page.dart';
import 'package:nestora/features/rooms/domain/entities/room.dart';
import 'package:nestora/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Fake Repositories for Step 9.2 Widget Tests ---

class _WidgetTestAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;

  String? lastSubmittedEmail;
  String? lastSubmittedPassword;
  String? lastSubmittedName;
  String? lastResetEmail;
  bool demoTriggered = false;

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<Result<AuthUser>> signInWithEmail({required String email, required String password}) async {
    lastSubmittedEmail = email;
    lastSubmittedPassword = password;
    final u = AuthUser(id: 'w-uid-1', email: email, displayName: 'Test User');
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
    lastSubmittedEmail = email;
    lastSubmittedPassword = password;
    lastSubmittedName = displayName;
    final u = AuthUser(id: 'w-uid-2', email: email, displayName: displayName);
    _user = u;
    _controller.add(u);
    return Result.success(u);
  }

  @override
  Future<Result<AuthUser>> signInDemo({String? email, String? password}) async {
    demoTriggered = true;
    const u = AuthUser(id: 'demo-uid', email: 'demo@nestora.app', displayName: 'Demo');
    _user = u;
    _controller.add(u);
    return Result.success(u);
  }

  @override
  Future<Result<void>> sendPasswordReset({required String email}) async {
    lastResetEmail = email;
    return Result.success(null);
  }

  @override
  Future<Result<void>> signOut() async {
    _user = null;
    _controller.add(null);
    return Result.success(null);
  }
}

class _WidgetTestDevicesRepository implements DevicesRepository {
  final List<Device> devices = [];
  final StreamController<List<Device>> controller = StreamController<List<Device>>.broadcast();

  @override
  Stream<List<Device>> watchDevices(String userId) => controller.stream;

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
        colorHex: stateUpdates['colorHex'] as String? ?? stateUpdates['color'] as String? ?? old.colorHex,
        colorName: stateUpdates['colorName'] as String? ?? old.colorName,
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

class _WidgetTestRoomsRepository implements RoomsRepository {
  final List<Room> rooms = [];
  final StreamController<List<Room>> controller = StreamController<List<Room>>.broadcast();

  @override
  Stream<List<Room>> watchRooms(String userId) => controller.stream;

  @override
  Future<Result<List<Room>>> getRooms(String userId) async => Result.success(rooms);

  @override
  Future<Result<Room>> getRoomById(String userId, String roomId) async =>
      Result.success(rooms.firstWhere((r) => r.id == roomId));

  @override
  Future<Result<void>> createRoom(String userId, Room room) async => Result.success(null);

  @override
  Future<Result<void>> updateRoom(String userId, Room room) async => Result.success(null);

  @override
  Future<Result<void>> deleteRoom(String userId, String roomId) async => Result.success(null);
}

class _WidgetTestProfileRepository implements ProfileRepository {
  UserProfile? profile;
  final StreamController<UserProfile?> controller = StreamController<UserProfile?>.broadcast();

  @override
  Stream<UserProfile?> watchProfile(String userId) => controller.stream;

  @override
  Future<Result<UserProfile?>> getProfile(String userId) async => Result.success(profile);

  @override
  Future<Result<void>> updateProfile(String userId, UserProfile p) async {
    profile = p;
    controller.add(profile);
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateHomeName(String userId, String homeName) async {
    if (profile != null) {
      profile = profile!.copyWith(homeName: homeName);
      controller.add(profile);
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateDisplayName(String userId, String displayName) async {
    if (profile != null) {
      profile = profile!.copyWith(displayName: displayName);
      controller.add(profile);
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> updatePreferences(String userId, UserPreferences prefs) async {
    if (profile != null) {
      profile = profile!.copyWith(preferences: prefs);
      controller.add(profile);
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> updatePhotoPath(String userId, String? photoPath) async => Result.success(null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late _WidgetTestAuthRepository fakeAuthRepo;
  late _WidgetTestDevicesRepository fakeDevicesRepo;
  late _WidgetTestRoomsRepository fakeRoomsRepo;
  late _WidgetTestProfileRepository fakeProfileRepo;

  late AuthCubit authCubit;
  late DevicesCubit devicesCubit;
  late RoomsCubit roomsCubit;
  late ProfileCubit profileCubit;
  late ThemeCubit themeCubit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeAuthRepo = _WidgetTestAuthRepository();
    fakeDevicesRepo = _WidgetTestDevicesRepository();
    fakeRoomsRepo = _WidgetTestRoomsRepository();
    fakeProfileRepo = _WidgetTestProfileRepository();

    authCubit = AuthCubit(authRepository: fakeAuthRepo);
    devicesCubit = DevicesCubit(
      devicesRepository: fakeDevicesRepo,
      debounceDuration: const Duration(milliseconds: 50),
    );
    roomsCubit = RoomsCubit(
      roomsRepository: fakeRoomsRepo,
      devicesRepository: fakeDevicesRepo,
    );
    profileCubit = ProfileCubit(profileRepository: fakeProfileRepo);
    themeCubit = ThemeCubit();
  });

  tearDown(() {
    authCubit.close();
    devicesCubit.close();
    roomsCubit.close();
    profileCubit.close();
    themeCubit.close();
  });

  Widget buildTestableApp(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<DevicesCubit>.value(value: devicesCubit),
        BlocProvider<RoomsCubit>.value(value: roomsCubit),
        BlocProvider<ProfileCubit>.value(value: profileCubit),
        BlocProvider<ThemeCubit>.value(value: themeCubit),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, currentMode) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: currentMode,
            home: Scaffold(body: child),
          );
        },
      ),
    );
  }

  group('Faz 9 - Adım 9.2: 1. Login, Register & Forgot Password Form Alanları ve Doğrulama Hata Mesajları', () {
    testWidgets('LoginPage form alanları render edilir, boş/geçersiz formatlarda hata mesajı gösterir', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableApp(LoginPage(authCubit: authCubit)));
      await tester.pumpAndSettle();

      // Form elemanlarının varlığı
      expect(find.byType(NestoraInput), findsNWidgets(2)); // E-posta ve Şifre
      expect(find.text('Giriş Yap'), findsWidgets);
      expect(find.text('Hızlı Demo ile Giriş Yap'), findsOneWidget);
      expect(find.text('Şifremi Unuttum?'), findsOneWidget);
      expect(find.text('Beni Hatırla'), findsOneWidget);

      // 1. Boş alanlarla Giriş Yap butonuna tıklama
      final loginButton = find.widgetWithText(NestoraButton, 'Giriş Yap');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Hata mesajı doğrulama (E-posta zorunlu)
      expect(find.text('Lütfen e-posta adresinizi giriniz.'), findsOneWidget);

      // 2. Geçersiz e-posta formatı girme
      final emailInput = find.byType(TextField).first;
      await tester.enterText(emailInput, 'gecersiz-eposta');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.text('Lütfen geçerli bir e-posta adresi giriniz.'), findsOneWidget);

      // 3. Geçerli e-posta ancak boş şifre ile deneme
      await tester.enterText(emailInput, 'aygen@nestora.app');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.text('Lütfen şifrenizi giriniz.'), findsOneWidget);

      // 4. Şifre gizleme / gösterme (Obscure text) toggle etkileşimi
      final passwordInput = find.byType(TextField).last;
      expect((tester.widget(passwordInput) as TextField).obscureText, isTrue);

      final visibilityIcon = find.byIcon(Icons.visibility_outlined);
      expect(visibilityIcon, findsOneWidget);
      await tester.tap(visibilityIcon);
      await tester.pumpAndSettle();

      expect((tester.widget(passwordInput) as TextField).obscureText, isFalse);

      // 5. Başarılı form gönderimi
      await tester.enterText(passwordInput, 'ValidPass2026!');
      await tester.tap(loginButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeAuthRepo.lastSubmittedEmail, equals('aygen@nestora.app'));
      expect(fakeAuthRepo.lastSubmittedPassword, equals('ValidPass2026!'));
    });

    testWidgets('RegisterPage şifre karmaşıklık kartını (PasswordValidatorWidget) dinamik olarak günceller ve eşleşme hatasını gösterir', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableApp(RegisterPage(authCubit: authCubit)));
      await tester.pumpAndSettle();

      expect(find.text('Aramıza Katıl'), findsOneWidget);

      // Şifre alanını hedefle
      final passwordInputFinder = find.descendant(
        of: find.widgetWithText(NestoraInput, 'Şifre'),
        matching: find.byType(TextField),
      );
      final repeatInputFinder = find.descendant(
        of: find.widgetWithText(NestoraInput, 'Şifre Tekrar'),
        matching: find.byType(TextField),
      );

      // 1. Şifre henüz girilmemişken PasswordValidatorWidget render edilmez
      expect(find.byType(PasswordValidatorWidget), findsNothing);

      // Ad Soyad ve E-posta alanlarını doldur
      final nameInputFinder = find.descendant(
        of: find.widgetWithText(NestoraInput, 'Ad Soyad'),
        matching: find.byType(TextField),
      );
      final emailInputFinder = find.descendant(
        of: find.widgetWithText(NestoraInput, 'E-posta'),
        matching: find.byType(TextField),
      );
      await tester.enterText(nameInputFinder, 'Aygen Yıldırım');
      await tester.enterText(emailInputFinder, 'aygen@nestora.app');

      // 2. Şifre girilmeye başlandığında PasswordValidatorWidget belirir
      await tester.enterText(passwordInputFinder, 'abc');
      await tester.pumpAndSettle();

      expect(find.byType(PasswordValidatorWidget), findsOneWidget);
      expect(find.text('En az 8 karakter'), findsOneWidget);
      expect(find.text('Güçlü şifre'), findsNothing);

      // 3. Güçlü şifre girildiğinde "Güçlü şifre" rozeti görünür
      await tester.enterText(passwordInputFinder, 'Nestora2026!');
      await tester.pumpAndSettle();

      expect(find.text('Güçlü şifre'), findsOneWidget);

      // 4. Şifre tekrarı uyuşmazlığı kontrolü
      await tester.enterText(repeatInputFinder, 'FarkliSifre2026!');
      await tester.pumpAndSettle();

      final registerButton = find.widgetWithText(NestoraButton, 'Hesap Oluştur');
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(find.text('Girdiğiniz şifreler eşleşmiyor.'), findsOneWidget);
    });

    testWidgets('ForgotPasswordPage e-posta doğrulaması ve şifre sıfırlama tetikleyicisi', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableApp(ForgotPasswordPage(authCubit: authCubit)));
      await tester.pumpAndSettle();

      expect(find.text('Şifre Sıfırlama'), findsWidgets);

      // Boş e-posta ile butona basma
      final sendButton = find.widgetWithText(NestoraButton, 'Sıfırlama Bağlantısı Gönder');
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      expect(find.text('Lütfen e-posta adresinizi giriniz.'), findsOneWidget);

      // Geçerli e-posta girme
      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'forgot@nestora.app');
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      expect(fakeAuthRepo.lastResetEmail, equals('forgot@nestora.app'));
    });
  });

  group('Faz 9 - Adım 9.2: 2. Cihaz Kartları, Lamba Parlaklık Sliderı ve Toggle Anahtarları', () {
    testWidgets('DevicesPage üzerindeki cihaz kartı toggle anahtarı ve favori butonuna tıklandığında Cubit state anında güncellenir', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testRoom = Room(id: 'r1', name: 'Salon', iconName: 'chair', createdAt: DateTime.now(), updatedAt: DateTime.now());
      fakeRoomsRepo.rooms.add(testRoom);
      roomsCubit.loadRooms('w-user');
      fakeRoomsRepo.controller.add([testRoom]);

      final testDevice = Device(
        id: 'dev-bulb-test',
        name: 'Köşe Lambası',
        roomId: 'r1',
        type: DeviceType.bulb,
        isPoweredOn: false,
        isFavorite: false,
        brightness: 72,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      fakeDevicesRepo.devices.add(testDevice);
      devicesCubit.loadDevices('w-user');
      fakeDevicesRepo.controller.add([testDevice]);

      await tester.pumpWidget(buildTestableApp(const DevicesPage()));
      await tester.pumpAndSettle();

      expect(find.text('Köşe Lambası'), findsOneWidget);
      expect(find.byType(NestoraSwitch), findsWidgets);

      // Cihaz kartındaki güç anahtarını (NestoraSwitch) aç
      final switchFinder = find.byType(NestoraSwitch).first;
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      var loaded = devicesCubit.state as DevicesLoaded;
      expect(loaded.findDeviceById('dev-bulb-test')!.isPoweredOn, isTrue);

      // Favori yıldızına tıklama
      final starFinder = find.byIcon(Icons.star_border_rounded).first;
      await tester.tap(starFinder);
      await tester.pumpAndSettle();

      loaded = devicesCubit.state as DevicesLoaded;
      expect(loaded.findDeviceById('dev-bulb-test')!.isFavorite, isTrue);
    });

    testWidgets('LampControlPage parlaklık sliderı ve hızlı hazır ayar butonları (%25, %50, %75, %100) parlaklığı değiştirir', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final lampDev = Device(
        id: 'dev-lamp-1',
        name: 'Tavan Lambası',
        roomId: 'room-1',
        type: DeviceType.bulb,
        isPoweredOn: true,
        brightness: 72,
        colorHex: '#E1C1A0',
        colorName: 'Sıcak Günışığı (2700K)',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      fakeDevicesRepo.devices.add(lampDev);
      devicesCubit.loadDevices('w-user');
      fakeDevicesRepo.controller.add([lampDev]);

      await tester.pumpWidget(buildTestableApp(const LampControlPage(deviceId: 'dev-lamp-1')));
      await tester.pumpAndSettle();

      expect(find.text('Açık • %72'), findsOneWidget);
      expect(find.text('Parlaklık'), findsWidgets);

      // %50 preset butonuna dokun
      await tester.tap(find.text('%50'));
      await tester.pumpAndSettle();

      var loaded = devicesCubit.state as DevicesLoaded;
      expect(loaded.findDeviceById('dev-lamp-1')!.brightness, equals(50));
      expect(find.text('Açık • %50'), findsOneWidget);

      // %100 preset butonuna dokun
      await tester.tap(find.text('%100').first);
      await tester.pumpAndSettle();

      loaded = devicesCubit.state as DevicesLoaded;
      expect(loaded.findDeviceById('dev-lamp-1')!.brightness, equals(100));
      expect(find.text('Açık • %100'), findsOneWidget);

      // Slider kaydırma etkileşimi (Slider widget'ı üzerinde yatay sürükleme)
      final sliderFinder = find.byType(Slider);
      if (sliderFinder.evaluate().isNotEmpty) {
        await tester.drag(sliderFinder.first, const Offset(-100, 0));
        await tester.pumpAndSettle();
        loaded = devicesCubit.state as DevicesLoaded;
        expect(loaded.findDeviceById('dev-lamp-1')!.brightness, lessThan(100));
      }
    });

    testWidgets('NestoraSwitch bileşeni akıcı animasyon ve tıklama durumunu doğru yansıtır', (tester) async {
      bool switchState = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return NestoraSwitch(
                  value: switchState,
                  onChanged: (val) {
                    setState(() {
                      switchState = val;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(switchState, isFalse);

      // Anahtara dokun
      await tester.tap(find.byType(NestoraSwitch));
      await tester.pumpAndSettle();

      expect(switchState, isTrue);

      // Tekrar dokunarak kapat
      await tester.tap(find.byType(NestoraSwitch));
      await tester.pumpAndSettle();

      expect(switchState, isFalse);
    });
  });

  group('Faz 9 - Adım 9.2: 3. Tema Değiştirme Etkileşimleri (Açık, Koyu, Sistem)', () {
    testWidgets('ProfilePage üzerinden Açık ve Koyu tema seçeneklerine tıklandığında tüm arayüz teması anında güncellenir', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const initialProfile = UserProfile(
        uid: 'user-theme',
        email: 'theme@nestora.app',
        displayName: 'Aygen',
        homeName: "Aygen'in Evi",
      );
      fakeProfileRepo.profile = initialProfile;
      profileCubit.loadProfile('user-theme');
      fakeProfileRepo.controller.add(initialProfile);

      final dummyRoom = Room(id: 'r1', name: 'Salon', iconName: 'chair', createdAt: DateTime.now(), updatedAt: DateTime.now());
      fakeRoomsRepo.rooms.add(dummyRoom);
      roomsCubit.loadRooms('user-theme');
      fakeRoomsRepo.controller.add([dummyRoom]);

      devicesCubit.loadDevices('user-theme');
      fakeDevicesRepo.controller.add([]);

      await tester.pumpWidget(buildTestableApp(const ProfilePage()));
      await tester.pumpAndSettle();

      // Başlangıçta Açık mod (ThemeMode.light)
      expect(themeCubit.state, equals(ThemeMode.light));
      expect(Theme.of(tester.element(find.byType(ProfilePage))).brightness, equals(Brightness.light));

      // 'Koyu' tema butonuna tıkla
      final darkOption = find.text('Koyu');
      expect(darkOption, findsOneWidget);
      await tester.tap(darkOption);
      await tester.pumpAndSettle();

      // Tema Koyu (ThemeMode.dark) olarak güncellenmeli
      expect(themeCubit.state, equals(ThemeMode.dark));
      expect(Theme.of(tester.element(find.byType(ProfilePage))).brightness, equals(Brightness.dark));

      // 'Açık' tema butonuna tekrar tıkla
      final lightOption = find.text('Açık');
      expect(lightOption, findsOneWidget);
      await tester.tap(lightOption);
      await tester.pumpAndSettle();

      // Tekrar Açık mod
      expect(themeCubit.state, equals(ThemeMode.light));
      expect(Theme.of(tester.element(find.byType(ProfilePage))).brightness, equals(Brightness.light));

      // 'Sistem' tema butonuna tıkla
      final systemOption = find.text('Sistem');
      expect(systemOption, findsOneWidget);
      await tester.tap(systemOption);
      await tester.pumpAndSettle();

      expect(themeCubit.state, equals(ThemeMode.system));
    });
  });
}
