import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nestora/app/theme/theme_cubit.dart';
import 'package:nestora/core/constants/seed_data.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/core/widgets/nestora_button.dart';
import 'package:nestora/core/widgets/nestora_input.dart';
import 'package:nestora/features/auth/domain/entities/auth_user.dart';
import 'package:nestora/features/auth/domain/repositories/auth_repository.dart';
import 'package:nestora/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/devices/domain/repositories/devices_repository.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_cubit.dart';
import 'package:nestora/features/profile/data/datasources/profile_photo_service.dart';
import 'package:nestora/features/profile/domain/entities/user_profile.dart';
import 'package:nestora/features/profile/domain/repositories/profile_repository.dart';
import 'package:nestora/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:nestora/features/profile/presentation/pages/profile_page.dart';
import 'package:nestora/features/rooms/domain/entities/room.dart';
import 'package:nestora/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeProfileRepository implements ProfileRepository {
  UserProfile? storedProfile;
  final StreamController<UserProfile?> _controller =
      StreamController<UserProfile?>.broadcast();

  @override
  Stream<UserProfile?> watchProfile(String userId) async* {
    yield storedProfile;
    yield* _controller.stream;
  }

  @override
  Future<Result<UserProfile?>> getProfile(String userId) async =>
      Result.success(storedProfile);

  @override
  Future<Result<void>> updateProfile(String userId, UserProfile profile) async {
    storedProfile = profile;
    _controller.add(profile);
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateHomeName(String userId, String homeName) async {
    if (storedProfile != null) {
      storedProfile = storedProfile!.copyWith(homeName: homeName);
      _controller.add(storedProfile);
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateDisplayName(
      String userId, String displayName) async {
    if (storedProfile != null) {
      storedProfile = storedProfile!.copyWith(displayName: displayName);
      _controller.add(storedProfile);
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> updatePreferences(
      String userId, UserPreferences preferences) async {
    if (storedProfile != null) {
      storedProfile = storedProfile!.copyWith(preferences: preferences);
      _controller.add(storedProfile);
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> updatePhotoPath(String userId, String? photoPath) async {
    if (storedProfile != null) {
      storedProfile = storedProfile!.copyWith(photoPath: photoPath);
      _controller.add(storedProfile);
    }
    return Result.success(null);
  }
}

class FakeProfilePhotoService implements ProfilePhotoService {
  String? nextPhotoPath = '/mock/avatar.png';
  bool wasPickCalled = false;

  @override
  Future<String?> pickAndSaveImage({
    ImageSource source = ImageSource.gallery,
    String? userId,
  }) async {
    wasPickCalled = true;
    return nextPhotoPath;
  }

  @override
  Future<void> deleteLocalImage(String? path) async {}
}

class FakeAuthRepository implements AuthRepository {
  bool isSignedOut = false;
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  AuthUser? get currentUser => null;

  @override
  Future<Result<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      Result.success(AuthUser(id: 'test-user', email: email));

  @override
  Future<Result<AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async =>
      Result.success(AuthUser(id: 'test-user', email: email, displayName: displayName));

  @override
  Future<Result<void>> sendPasswordReset({required String email}) async =>
      Result.success(null);

  @override
  Future<Result<AuthUser>> signInDemo({String? email, String? password}) async =>
      Result.success(const AuthUser(id: 'demo-user', email: 'demo@nestora.app'));

  @override
  Future<Result<void>> signOut() async {
    isSignedOut = true;
    _controller.add(null);
    return Result.success(null);
  }
}

class FakeRoomsRepository implements RoomsRepository {
  @override
  Stream<List<Room>> watchRooms(String userId) async* {
    yield SeedData.defaultRooms;
  }

  @override
  Future<Result<List<Room>>> getRooms(String userId) async =>
      Result.success(SeedData.defaultRooms);

  @override
  Future<Result<Room>> getRoomById(String userId, String roomId) async =>
      Result.success(SeedData.defaultRooms.first);

  @override
  Future<Result<void>> createRoom(String userId, Room room) async =>
      Result.success(null);

  @override
  Future<Result<void>> updateRoom(String userId, Room room) async =>
      Result.success(null);

  @override
  Future<Result<void>> deleteRoom(String userId, String roomId) async =>
      Result.success(null);
}

class FakeDevicesRepository implements DevicesRepository {
  @override
  Stream<List<Device>> watchDevices(String userId) async* {
    yield SeedData.defaultDevices;
  }

  @override
  Stream<List<Device>> watchDevicesByRoom(String userId, String roomId) =>
      Stream.value(SeedData.defaultDevices);

  @override
  Future<Result<List<Device>>> getDevices(String userId) async =>
      Result.success(SeedData.defaultDevices);

  @override
  Future<Result<Device>> getDeviceById(String userId, String deviceId) async =>
      Result.success(SeedData.defaultDevices.first);

  @override
  Future<Result<void>> createDevice(String userId, Device device) async =>
      Result.success(null);

  @override
  Future<Result<void>> updateDevice(String userId, Device device) async =>
      Result.success(null);

  @override
  Future<Result<void>> updateDeviceState(
          String userId, String deviceId, Map<String, dynamic> stateUpdates) async =>
      Result.success(null);

  @override
  Future<Result<void>> deleteDevice(String userId, String deviceId) async =>
      Result.success(null);

  @override
  Future<Result<void>> deleteDevicesByRoom(String userId, String roomId) async =>
      Result.success(null);

  @override
  Future<Result<void>> moveDevicesToRoom(
          String userId, String fromRoomId, String toRoomId) async =>
      Result.success(null);
}

void main() {
  group('ProfilePage (Adım 6.9) Unit & Widget Tests', () {
    late FakeProfileRepository fakeProfileRepo;
    late FakeProfilePhotoService fakePhotoService;
    late FakeAuthRepository fakeAuthRepo;
    late FakeRoomsRepository fakeRoomsRepo;
    late FakeDevicesRepository fakeDevicesRepo;

    late ProfileCubit profileCubit;
    late AuthCubit authCubit;
    late RoomsCubit roomsCubit;
    late DevicesCubit devicesCubit;
    late ThemeCubit themeCubit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeProfileRepo = FakeProfileRepository();
      fakePhotoService = FakeProfilePhotoService();
      fakeAuthRepo = FakeAuthRepository();
      fakeRoomsRepo = FakeRoomsRepository();
      fakeDevicesRepo = FakeDevicesRepository();

      fakeProfileRepo.storedProfile = const UserProfile(
        uid: 'test-user',
        email: 'aygenyildirim27@gmail.com',
        displayName: 'Aygen Yıldırım',
        homeName: "Aygen'in Evi",
        preferences: UserPreferences(
          notificationsEnabled: true,
          ecoModeEnabled: true,
          temperatureUnit: 'C',
        ),
      );

      profileCubit = ProfileCubit(
        profileRepository: fakeProfileRepo,
        photoService: fakePhotoService,
      );
      authCubit = AuthCubit(authRepository: fakeAuthRepo);
      roomsCubit = RoomsCubit(
        roomsRepository: fakeRoomsRepo,
        devicesRepository: fakeDevicesRepo,
      );
      devicesCubit = DevicesCubit(devicesRepository: fakeDevicesRepo);
      themeCubit = ThemeCubit();

      profileCubit.loadProfile('test-user');
      roomsCubit.loadRooms('test-user');
      devicesCubit.loadDevices('test-user');
    });

    tearDown(() {
      profileCubit.close();
      authCubit.close();
      roomsCubit.close();
      devicesCubit.close();
      themeCubit.close();
    });

    Widget createTestApp({VoidCallback? onLogout}) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<ProfileCubit>.value(value: profileCubit),
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<RoomsCubit>.value(value: roomsCubit),
          BlocProvider<DevicesCubit>.value(value: devicesCubit),
          BlocProvider<ThemeCubit>.value(value: themeCubit),
        ],
        child: MaterialApp(
          home: ProfilePage(onLogout: onLogout),
        ),
      );
    }

    testWidgets('renders profile info, Ev Sahibi role, home name, and theme controls', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // User name & email
      expect(find.text('Aygen Yıldırım'), findsWidgets);
      expect(find.text('aygenyildirim27@gmail.com'), findsWidgets);

      // Ev Sahibi role badge
      expect(find.text('Ev Sahibi'), findsOneWidget);
      expect(find.text('Ev Sahibi (Yönetici)'), findsOneWidget);

      // Home name summary chip
      expect(find.text("Aygen'in Evi"), findsOneWidget);

      // Action buttons & Groups
      expect(find.text('Profili Düzenle'), findsOneWidget);
      expect(find.text('HESAP'), findsOneWidget);
      expect(find.text('UYGULAMA AYARLARI'), findsOneWidget);
      expect(find.text('Görünüm Modu'), findsOneWidget);
      expect(find.text('Açık'), findsOneWidget);
      expect(find.text('Koyu'), findsOneWidget);
      expect(find.text('Sistem'), findsOneWidget);
      expect(find.text('HAKKINDA'), findsOneWidget);
      expect(find.text('Çıkış Yap'), findsOneWidget);
    });

    testWidgets('tapping "Profili Düzenle" opens dialog and updates profile info', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 'Profili Düzenle'
      await tester.tap(find.text('Profili Düzenle'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Dialog is open
      expect(find.byType(AlertDialog), findsOneWidget);

      // Change name and home name
      final inputs = find.byType(NestoraInput);
      await tester.enterText(inputs.first, 'Aygen Yıldırım Güncel');
      await tester.enterText(inputs.last, 'Yeni Akıllı Evim');
      await tester.pump();

      // Tap 'Kaydet'
      await tester.tap(find.widgetWithText(NestoraButton, 'Kaydet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeProfileRepo.storedProfile?.displayName, equals('Aygen Yıldırım Güncel'));
      expect(fakeProfileRepo.storedProfile?.homeName, equals('Yeni Akıllı Evim'));
      expect(find.text('Aygen Yıldırım Güncel'), findsWidgets);
      expect(find.text('Yeni Akıllı Evim'), findsWidgets);
    });

    testWidgets('tapping avatar camera button triggers gallery photo picker', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap avatar camera icon (opens bottom sheet photo options modal)
      await tester.tap(find.byIcon(Icons.camera_alt_rounded));
      await tester.pumpAndSettle();

      // Tap 'Galeriden Seç' from the bottomsheet
      await tester.tap(find.text('Galeriden Seç'));
      await tester.pumpAndSettle();

      expect(fakePhotoService.wasPickCalled, isTrue);
      expect(fakeProfileRepo.storedProfile?.photoPath, equals('/mock/avatar.png'));
    });

    testWidgets('theme selector buttons update ThemeCubit state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Select 'Koyu'
      await tester.tap(find.text('Koyu'));
      await tester.pump();
      expect(themeCubit.state, equals(ThemeMode.dark));

      // Select 'Sistem'
      await tester.tap(find.text('Sistem'));
      await tester.pump();
      expect(themeCubit.state, equals(ThemeMode.system));

      // Select 'Açık'
      await tester.tap(find.text('Açık'));
      await tester.pump();
      expect(themeCubit.state, equals(ThemeMode.light));
    });

    testWidgets('temperature unit selector toggles between Celsius and Fahrenheit', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap '°F'
      await tester.tap(find.text('°F'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeProfileRepo.storedProfile?.preferences.temperatureUnit, equals('F'));

      // Tap '°C'
      await tester.tap(find.text('°C'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeProfileRepo.storedProfile?.preferences.temperatureUnit, equals('C'));
    });

    testWidgets('tapping logout shows confirmation dialog and triggers safe sign out', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool logoutCallbackCalled = false;

      await tester.pumpWidget(createTestApp(
        onLogout: () {
          logoutCallbackCalled = true;
        },
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Scroll down and tap 'Çıkış Yap'
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Çıkış Yap'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Çıkış Yap'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Confirmation dialog is shown
      expect(find.text('Oturumu Kapat'), findsOneWidget);

      // Confirm logout in dialog
      await tester.tap(find.widgetWithText(NestoraButton, 'Çıkış Yap'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeAuthRepo.isSignedOut, isTrue);
      expect(logoutCallbackCalled, isTrue);
    });
  });
}
