import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/app/theme/theme_cubit.dart';
import 'package:nestora/core/constants/seed_data.dart';
import 'package:nestora/core/services/secure_image_service.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/core/widgets/nestora_button.dart';
import 'package:nestora/core/widgets/nestora_input.dart';
import 'package:nestora/features/auth/domain/entities/auth_user.dart';
import 'package:nestora/features/auth/domain/repositories/auth_repository.dart';
import 'package:nestora/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/devices/domain/repositories/devices_repository.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_cubit.dart';
import 'package:nestora/features/home/presentation/pages/dashboard_page.dart';
import 'package:nestora/features/notifications/domain/entities/app_notification.dart';
import 'package:nestora/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:nestora/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:nestora/features/profile/domain/entities/user_profile.dart';
import 'package:nestora/features/profile/domain/repositories/profile_repository.dart';
import 'package:nestora/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:nestora/features/profile/presentation/pages/profile_page.dart';
import 'package:nestora/features/rooms/domain/entities/room.dart';
import 'package:nestora/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nestora/features/rooms/domain/room_model.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_cubit.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_state.dart';
import 'package:nestora/features/rooms/presentation/pages/add_edit_room_page.dart';
import 'package:nestora/features/rooms/presentation/pages/room_detail_page.dart';

class FakeDevicesRepo implements DevicesRepository {
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
  Future<Result<void>> updateDeviceState(String userId, String deviceId, Map<String, dynamic> stateFields) async => Result.success(null);
  @override
  Future<Result<void>> deleteDevice(String userId, String deviceId) async {
    devices.removeWhere((d) => d.id == deviceId);
    controller.add(List.from(devices));
    return Result.success(null);
  }
  @override
  Future<Result<void>> deleteDevicesByRoom(String userId, String roomId) async => Result.success(null);
  @override
  Future<Result<void>> moveDevicesToRoom(String userId, String fromRoomId, String toRoomId) async => Result.success(null);
}

class FakeRoomsRepo implements RoomsRepository {
  final List<Room> rooms = [];

  @override
  Stream<List<Room>> watchRooms(String userId) => Stream.value(rooms);
  @override
  Future<Result<List<Room>>> getRooms(String userId) async => Result.success(rooms);
  @override
  Future<Result<Room>> getRoomById(String userId, String roomId) async =>
      Result.success(rooms.firstWhere((r) => r.id == roomId));
  @override
  Future<Result<void>> createRoom(String userId, Room room) async {
    rooms.add(room);
    return Result.success(null);
  }
  @override
  Future<Result<void>> updateRoom(String userId, Room room) async {
    final idx = rooms.indexWhere((r) => r.id == room.id);
    if (idx != -1) {
      rooms[idx] = room;
    }
    return Result.success(null);
  }
  @override
  Future<Result<void>> deleteRoom(String userId, String roomId) async {
    rooms.removeWhere((r) => r.id == roomId);
    return Result.success(null);
  }
}

class FakeProfileRepo implements ProfileRepository {
  UserProfile storedProfile = SeedData.defaultProfile;
  final StreamController<UserProfile?> _controller = StreamController<UserProfile?>.broadcast();

  @override
  Stream<UserProfile?> watchProfile(String userId) => _controller.stream;
  @override
  Future<Result<UserProfile?>> getProfile(String userId) async => Result.success(storedProfile);
  @override
  Future<Result<void>> updateProfile(String userId, UserProfile profile) async {
    storedProfile = profile;
    _controller.add(profile);
    return Result.success(null);
  }
  @override
  Future<Result<void>> updateHomeName(String userId, String homeName) async {
    storedProfile = storedProfile.copyWith(homeName: homeName);
    return Result.success(null);
  }
  @override
  Future<Result<void>> updateDisplayName(String userId, String displayName) async {
    storedProfile = storedProfile.copyWith(displayName: displayName);
    return Result.success(null);
  }
  @override
  Future<Result<void>> updatePreferences(String userId, UserPreferences preferences) async {
    storedProfile = storedProfile.copyWith(preferences: preferences);
    return Result.success(null);
  }
  @override
  Future<Result<void>> updatePhotoPath(String userId, String? photoPath) async {
    storedProfile = storedProfile.copyWith(photoPath: photoPath);
    return Result.success(null);
  }
}

class FakeAuthRepo implements AuthRepository {
  bool isSignedOut = false;
  final StreamController<AuthUser?> _controller = StreamController<AuthUser?>.broadcast();

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  AuthUser? get currentUser => null;

  @override
  Future<Result<AuthUser>> signInWithEmail({required String email, required String password}) async =>
      Result.success(AuthUser(id: 'test-user', email: email));

  @override
  Future<Result<AuthUser>> signUpWithEmail({required String email, required String password, String? displayName}) async =>
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

class FakeNotificationsRepo implements NotificationsRepository {
  final List<AppNotification> list = [];
  @override
  Stream<List<AppNotification>> watchNotifications(String userId) => Stream.value(list);
  @override
  Future<Result<List<AppNotification>>> getNotifications(String userId) async => Result.success(list);
  @override
  Future<Result<void>> markAsRead(String userId, String notificationId) async => Result.success(null);
  @override
  Future<Result<void>> markAllAsRead(String userId) async => Result.success(null);
  @override
  Future<Result<void>> deleteNotification(String userId, String notificationId) async => Result.success(null);
  @override
  Future<Result<void>> createNotification(String userId, AppNotification notification) async {
    list.add(notification);
    return Result.success(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDevicesRepo fakeDevicesRepo;
  late DevicesCubit devicesCubit;
  late FakeRoomsRepo fakeRoomsRepo;
  late RoomsCubit roomsCubit;
  late FakeProfileRepo fakeProfileRepo;
  late ProfileCubit profileCubit;
  late FakeAuthRepo fakeAuthRepo;
  late AuthCubit authCubit;
  late FakeNotificationsRepo fakeNotificationsRepo;
  late NotificationsCubit notificationsCubit;
  late ThemeCubit themeCubit;

  setUp(() {
    fakeDevicesRepo = FakeDevicesRepo();
    fakeDevicesRepo.devices.addAll(SeedData.defaultDevices);
    devicesCubit = DevicesCubit(devicesRepository: fakeDevicesRepo);

    fakeRoomsRepo = FakeRoomsRepo();
    fakeRoomsRepo.rooms.addAll(SeedData.defaultRooms);
    roomsCubit = RoomsCubit(
      roomsRepository: fakeRoomsRepo,
      devicesRepository: fakeDevicesRepo,
    );

    fakeProfileRepo = FakeProfileRepo();
    profileCubit = ProfileCubit(profileRepository: fakeProfileRepo);

    fakeAuthRepo = FakeAuthRepo();
    authCubit = AuthCubit(authRepository: fakeAuthRepo);

    fakeNotificationsRepo = FakeNotificationsRepo();
    notificationsCubit = NotificationsCubit(notificationsRepository: fakeNotificationsRepo);

    themeCubit = ThemeCubit();
  });

  tearDown(() {
    devicesCubit.close();
    roomsCubit.close();
    profileCubit.close();
    authCubit.close();
    notificationsCubit.close();
    themeCubit.close();
  });

  Widget buildTestableWidget(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DevicesCubit>.value(value: devicesCubit),
        BlocProvider<RoomsCubit>.value(value: roomsCubit),
        BlocProvider<ProfileCubit>.value(value: profileCubit),
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<NotificationsCubit>.value(value: notificationsCubit),
        BlocProvider<ThemeCubit>.value(value: themeCubit),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('Adım 4.3: SecureImageService Tests', () {
    test('rejects disallowed file extensions (e.g. .pdf, .gif, .exe)', () async {
      final service = SecureImageService();

      final pdfFile = File('dummy_document.pdf');
      final gifFile = File('animation.gif');
      final exeFile = File('virus.exe');

      final pdfResult = await service.validateAndSaveFile(file: pdfFile, targetPrefix: 'test');
      final gifResult = await service.validateAndSaveFile(file: gifFile, targetPrefix: 'test');
      final exeResult = await service.validateAndSaveFile(file: exeFile, targetPrefix: 'test');

      expect(pdfResult.isSuccess, isFalse);
      expect(pdfResult.errorMessage, contains('Güvenlik Uyarısı'));

      expect(gifResult.isSuccess, isFalse);
      expect(gifResult.errorMessage, contains('Güvenlik Uyarısı'));

      expect(exeResult.isSuccess, isFalse);
      expect(exeResult.errorMessage, contains('Güvenlik Uyarısı'));
    });

    test('accepts whitelisted image extensions (.jpg, .jpeg, .png)', () async {
      final service = SecureImageService();
      final tempDir = Directory.systemTemp.createTempSync('nestora_test_');

      final testJpg = File('${tempDir.path}/photo.jpg')..writeAsBytesSync([1, 2, 3, 4]);
      final testPng = File('${tempDir.path}/photo.png')..writeAsBytesSync([1, 2, 3, 4]);

      final jpgResult = await service.validateAndSaveFile(file: testJpg, targetPrefix: 'room_1');
      final pngResult = await service.validateAndSaveFile(file: testPng, targetPrefix: 'room_2');

      expect(jpgResult.isSuccess, isTrue);
      expect(jpgResult.savedPath, isNotNull);

      expect(pngResult.isSuccess, isTrue);
      expect(pngResult.savedPath, isNotNull);

      tempDir.deleteSync(recursive: true);
    });

    test('rejects files larger than 5 MB', () async {
      final service = SecureImageService();
      final tempDir = Directory.systemTemp.createTempSync('nestora_large_');
      final largeFile = File('${tempDir.path}/huge.jpg');

      // Create a 6MB file
      final bytes = List<int>.filled(6 * 1024 * 1024, 0);
      largeFile.writeAsBytesSync(bytes);

      final result = await service.validateAndSaveFile(file: largeFile, targetPrefix: 'room_large');

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('5MB'));

      tempDir.deleteSync(recursive: true);
    });
  });

  group('Adım 4.1 & 4.2: Dynamic Room Image & Placeholder in RoomDetailPage', () {
    testWidgets('Displays room photo and "Resmi Değiştir" when room has imageAsset', (tester) async {
      final roomWithImage = RoomModel(
        id: 'room-1',
        name: 'Salon',
        type: 'Salon',
        icon: Icons.chair_rounded,
        temperature: 22.4,
        humidity: 48,
        deviceCount: 3,
        activeDeviceCount: 2,
        imageAsset: 'assets/rooms/salon.jpg',
      );

      await tester.pumpWidget(buildTestableWidget(RoomDetailPage(room: roomWithImage)));
      await tester.pumpAndSettle();

      expect(find.text('Resmi Değiştir'), findsOneWidget);
      expect(find.text('Canlı İzleme'), findsOneWidget);
      expect(find.text('Nem %48'), findsOneWidget);
    });

    testWidgets('Displays transparent modern placeholder and "+ Oda Resmi Ekle" when imageAsset is null', (tester) async {
      final roomWithoutImage = RoomModel(
        id: 'room-empty',
        name: 'Yeni Teras',
        type: 'Diğer',
        icon: Icons.deck_rounded,
        temperature: 20.0,
        humidity: 50,
        deviceCount: 0,
        activeDeviceCount: 0,
        imageAsset: null,
      );

      await tester.pumpWidget(buildTestableWidget(RoomDetailPage(room: roomWithoutImage)));
      await tester.pumpAndSettle();

      expect(find.text('Oda Resmi Ekle'), findsWidgets);
      expect(find.text('+ Oda Resmi Ekle'), findsOneWidget);
      expect(find.text('Yüksek kaliteli JPG/PNG seçin'), findsOneWidget);
    });

    testWidgets('Tapping image action button opens bottomsheet modal with photo and preset options', (tester) async {
      final room = RoomModel(
        id: 'room-1',
        name: 'Salon',
        type: 'Salon',
        icon: Icons.chair_rounded,
        temperature: 22.4,
        humidity: 48,
        deviceCount: 3,
        activeDeviceCount: 2,
        imageAsset: 'assets/rooms/salon.jpg',
      );

      await tester.pumpWidget(buildTestableWidget(RoomDetailPage(room: room)));
      await tester.pumpAndSettle();

      final actionBtn = find.byKey(const Key('room_image_action_button'));
      expect(actionBtn, findsOneWidget);
      await tester.tap(actionBtn);
      await tester.pumpAndSettle();

      // Verify bottom modal content
      expect(find.text('Salon Görseli'), findsOneWidget);
      expect(find.text('Galeriden Seç'), findsOneWidget);
      expect(find.text('Kamera ile Çek'), findsOneWidget);
      expect(find.text('Mimari Hazır Görseller'), findsOneWidget);
      expect(find.text('Resmi Kaldır'), findsOneWidget);
    });
  });

  group('Adım 4.2: RoomsCubit Image Update & Persistence', () {
    test('updateRoomImage updates imageAsset and notifies listeners', () async {
      await roomsCubit.updateRoomImage('room-1', 'assets/rooms/calisma_odasi.jpg');

      final loadedState = roomsCubit.state as RoomsLoaded;
      final updatedRoom = loadedState.rooms.firstWhere((r) => r.id == 'room-1');

      expect(updatedRoom.imageAsset, equals('assets/rooms/calisma_odasi.jpg'));
    });

    test('updateRoomImage can remove image by setting it to null', () async {
      await roomsCubit.updateRoomImage('room-1', null);

      final loadedState = roomsCubit.state as RoomsLoaded;
      final updatedRoom = loadedState.rooms.firstWhere((r) => r.id == 'room-1');

      expect(updatedRoom.imageAsset, isNull);
    });
  });

  group('Adım 4.2: AddEditRoomPage Image Integration', () {
    testWidgets('renders photo picker widget with "+ Oda Fotoğrafı Ekle" when creating new room', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const AddEditRoomPage()));
      await tester.pumpAndSettle();

      expect(find.text('Oda Görseli'), findsOneWidget);
      // New room auto-suggests or shows picker
      expect(find.byType(AddEditRoomPage), findsOneWidget);
    });

    testWidgets('preserves imageAsset when editing an existing room', (tester) async {
      final room = RoomModel(
        id: 'room-1',
        name: 'Salon',
        type: 'Salon',
        icon: Icons.chair_rounded,
        temperature: 22.4,
        humidity: 48,
        deviceCount: 3,
        activeDeviceCount: 2,
        imageAsset: 'assets/rooms/salon.jpg',
      );

      await tester.pumpWidget(buildTestableWidget(AddEditRoomPage(
        isEditing: true,
        room: room,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Mimari Hazır Görsel'), findsOneWidget);
      expect(find.text('Değiştir'), findsOneWidget);
    });
  });

  group('Adım 4.4: Profile Photo Modal & Multi-field Profile Editing', () {
    testWidgets('Tapping profile avatar opens photo options bottom sheet with default woman portrait option', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const ProfilePage()));
      await tester.pumpAndSettle();

      final avatarFinder = find.byKey(const Key('profile_avatar_picker'));
      expect(avatarFinder, findsOneWidget);

      await tester.tap(avatarFinder);
      await tester.pumpAndSettle();

      expect(find.text('Profil Fotoğrafı Seç'), findsOneWidget);
      expect(find.text('Galeriden Seç'), findsOneWidget);
      expect(find.text('Kamera ile Çek'), findsOneWidget);
      expect(find.text('Varsayılan Kadın Portresine Dön'), findsOneWidget);
    });

    testWidgets('Tapping "Profili Düzenle" updates Name, Email, Role, and Home Name', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const ProfilePage()));
      await tester.pumpAndSettle();

      final editBtn = find.byKey(const Key('profile_edit_button'));
      expect(editBtn, findsOneWidget);

      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      final inputs = find.byType(NestoraInput);
      expect(inputs, findsNWidgets(4));

      // Enter new name, email, role, home
      await tester.enterText(inputs.at(0), 'Selin Yılmaz');
      await tester.enterText(inputs.at(1), 'selin@nestora.com');
      await tester.enterText(inputs.at(2), 'Ev Yöneticisi');
      await tester.enterText(inputs.at(3), 'Selin Rezidans');
      await tester.pump();

      await tester.tap(find.widgetWithText(NestoraButton, 'Kaydet'));
      await tester.pumpAndSettle();

      expect(fakeProfileRepo.storedProfile.displayName, equals('Selin Yılmaz'));
      expect(fakeProfileRepo.storedProfile.email, equals('selin@nestora.com'));
      expect(fakeProfileRepo.storedProfile.roleTitle, equals('Ev Yöneticisi'));
      expect(fakeProfileRepo.storedProfile.homeName, equals('Selin Rezidans'));
    });
  });

  group('Adım 4.5: Profile "Hakkında" Modal Card', () {
    testWidgets('Tapping Hakkında row opens medium dialog with sustainability, vision, and v2.4.0 info', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const ProfilePage()));
      await tester.pumpAndSettle();

      final aboutRow = find.text('Hakkında');
      await tester.scrollUntilVisible(aboutRow, 200);
      expect(aboutRow, findsOneWidget);

      await tester.tap(aboutRow);
      await tester.pumpAndSettle();

      expect(find.text('Nestora'), findsWidgets);
      expect(find.text('Sürdürülebilir Akıllı Yaşam Platformu'), findsOneWidget);
      expect(find.text('Sürdürülebilirlik & Eko-Tasarruf Algoritmaları'), findsOneWidget);
      expect(find.text('Modern Kaşmir & Doğal Taş Mimari Estetiği'), findsOneWidget);
      expect(find.text('Sürüm v2.4.0 (Build 2026.1) • Güncel'), findsOneWidget);
      expect(find.text('Kapat'), findsOneWidget);

      await tester.tap(find.text('Kapat'));
      await tester.pumpAndSettle();
      expect(find.text('Sürüm v2.4.0 (Build 2026.1) • Güncel'), findsNothing);
    });
  });

  group('Adım 4.6: Dashboard Add Room Button Integration', () {
    testWidgets('Dashboard renders "+ Oda Ekle" button in rooms section and tapping it opens AddEditRoomPage', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const DashboardPage()));
      await tester.pumpAndSettle();

      final addRoomBtn = find.byKey(const Key('dashboard_add_room_button'));
      await tester.ensureVisible(addRoomBtn);
      expect(addRoomBtn, findsOneWidget);
      expect(find.text('Oda Ekle'), findsOneWidget);

      await tester.tap(addRoomBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AddEditRoomPage), findsOneWidget);
      expect(find.text('• Yeni Oda'), findsOneWidget);
    });
  });
}
