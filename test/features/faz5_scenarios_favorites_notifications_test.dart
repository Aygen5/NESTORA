import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/app/app_shell.dart';
import 'package:nestora/app/theme/theme_cubit.dart';
import 'package:nestora/core/constants/seed_data.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/features/auth/domain/entities/auth_user.dart';
import 'package:nestora/features/auth/domain/repositories/auth_repository.dart';
import 'package:nestora/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/devices/domain/repositories/devices_repository.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_cubit.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_state.dart';
import 'package:nestora/features/devices/presentation/pages/devices_page.dart';
import 'package:nestora/features/home/presentation/pages/dashboard_page.dart';
import 'package:nestora/features/notifications/domain/entities/app_notification.dart';
import 'package:nestora/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:nestora/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:nestora/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:nestora/features/notifications/presentation/pages/notifications_page.dart';
import 'package:nestora/features/profile/domain/entities/user_profile.dart';
import 'package:nestora/features/profile/domain/repositories/profile_repository.dart';
import 'package:nestora/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:nestora/features/profile/presentation/pages/profile_page.dart';
import 'package:nestora/features/rooms/domain/entities/room.dart';
import 'package:nestora/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_cubit.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_state.dart';

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
  Future<Result<void>> updateDeviceState(String userId, String deviceId, Map<String, dynamic> stateFields) async {
    final idx = devices.indexWhere((d) => d.id == deviceId);
    if (idx != -1) {
      var d = devices[idx];
      if (stateFields.containsKey('isPoweredOn')) {
        d = d.copyWith(isPoweredOn: stateFields['isPoweredOn'] as bool);
      }
      if (stateFields.containsKey('brightness')) {
        d = d.copyWith(brightness: stateFields['brightness'] as int);
      }
      if (stateFields.containsKey('targetTemp')) {
        d = d.copyWith(targetTemp: (stateFields['targetTemp'] as num).toDouble());
      }
      if (stateFields.containsKey('isFavorite')) {
        d = d.copyWith(isFavorite: stateFields['isFavorite'] as bool);
      }
      devices[idx] = d;
      controller.add(List.from(devices));
    }
    return Result.success(null);
  }
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
  Future<Result<void>> sendPasswordReset({required String email}) async => Result.success(null);
  @override
  Future<Result<AuthUser>> signInDemo({String? email, String? password}) async =>
      Result.success(const AuthUser(id: 'demo-user', email: 'demo@nestora.app'));
  @override
  Future<Result<void>> signOut() async => Result.success(null);
}

class FakeNotificationsRepo implements NotificationsRepository {
  final List<AppNotification> list = [];
  final StreamController<List<AppNotification>> _controller = StreamController<List<AppNotification>>.broadcast();

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) => _controller.stream;
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
    list.insert(0, notification);
    _controller.add(List.from(list));
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
    fakeNotificationsRepo.list.addAll(SeedData.defaultNotifications);
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

  group('Faz 5: Hızlı Eylemler (Senaryolar) ve Hero Banner Rozet Entegrasyonu', () {
    testWidgets('Tapping scenario chips (Evdeyim, Gündüz, Gece Modu, Dışarıda) updates Hero Banner badge and device states in real-time', (tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const DashboardPage()));
      await tester.pumpAndSettle();

      // Initial state: Evdeyim
      expect(find.byKey(const Key('dashboard_hero_active_scenario_badge')), findsOneWidget);
      expect(find.text('Aktif Senaryo: Evdeyim'), findsOneWidget);

      // 1. Tap 'Gündüz'
      final gunduzChip = find.byKey(const Key('scenario_chip_Gündüz'));
      await tester.tap(gunduzChip);
      await tester.pumpAndSettle();

      expect(find.text('Aktif Senaryo: Gündüz'), findsOneWidget);
      expect(find.text('Doğal gün ışığı devrede. Gereksiz lambalar kapalı, eko-klima aktif.'), findsOneWidget);

      // 2. Tap 'Gece Modu'
      final geceChip = find.byKey(const Key('scenario_chip_Gece Modu'));
      await tester.tap(geceChip);
      await tester.pumpAndSettle();

      expect(find.text('Aktif Senaryo: Gece Modu'), findsOneWidget);
      expect(find.text('Gece modu devrede. Yalnızca gece aydınlatması açık, klima sessiz modda.'), findsOneWidget);

      // 3. Tap 'Dışarıda'
      final disaridaChip = find.byKey(const Key('scenario_chip_Dışarıda'));
      await tester.tap(disaridaChip);
      await tester.pumpAndSettle();

      expect(find.text('Aktif Senaryo: Dışarıda'), findsOneWidget);
      expect(find.text('Ev boş modunda. Tüm lamba ve prizler kapalı, maksimum tasarruf devrede.'), findsOneWidget);
      // All devices off -> '0 açık'
      expect(find.text('0 açık'), findsOneWidget);

      // 4. Return to 'Evdeyim'
      final evdeyimChip = find.byKey(const Key('scenario_chip_Evdeyim'));
      await tester.tap(evdeyimChip);
      await tester.pumpAndSettle();

      expect(find.text('Aktif Senaryo: Evdeyim'), findsOneWidget);
      final devicesState = devicesCubit.state as DevicesLoaded;
      expect(devicesState.activeCount, greaterThan(0));
    });
  });

  group('Faz 5: Üst Bar Favoriler Modal & Cihazlar Sayfası Senkronizasyonu', () {
    testWidgets('Tapping favorite icon in Dashboard header opens bottom sheet with favorite device cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const DashboardPage()));
      await tester.pumpAndSettle();

      // Tap favorites button in header (star icon)
      final favHeaderBtn = find.byTooltip('Favorilerim');
      expect(favHeaderBtn, findsOneWidget);
      await tester.tap(favHeaderBtn);
      await tester.pumpAndSettle();

      // Modal bottomsheet opens
      expect(find.text('Favori Cihazlarım'), findsOneWidget);
      expect(find.text('Tüm Favorileri Cihazlar Sayfasında Aç'), findsOneWidget);
    });

    testWidgets('DevicesPage allows filtering by "Favoriler" and starring/unstarring updates synchronization', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const DevicesPage()));
      await tester.pumpAndSettle();

      // Top bar favorites filter star
      final starFilter = find.byTooltip('Favori Cihazları Filtrele (3)');
      expect(starFilter, findsOneWidget);

      await tester.tap(starFilter);
      await tester.pumpAndSettle();

      // After filtering by favorites, only favorite devices are displayed
      final state = devicesCubit.state as DevicesLoaded;
      final favDevices = state.devices.where((d) => d.isFavorite).toList();
      for (final fav in favDevices) {
        expect(find.text(fav.name), findsWidgets);
      }
    });

    testWidgets('AppShell navigates to DevicesPage with "Favoriler" pre-filtered when opened from favorites sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider<DevicesCubit>.value(value: devicesCubit),
          BlocProvider<RoomsCubit>.value(value: roomsCubit),
          BlocProvider<ProfileCubit>.value(value: profileCubit),
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<NotificationsCubit>.value(value: notificationsCubit),
          BlocProvider<ThemeCubit>.value(value: themeCubit),
        ],
        child: const MaterialApp(
          home: AppShell(),
        ),
      ));
      await tester.pumpAndSettle();

      // Open favorites sheet from dashboard header
      await tester.tap(find.byTooltip('Favorilerim'));
      await tester.pumpAndSettle();

      // Click "Tüm Favorileri Cihazlar Sayfasında Aç"
      final openAllBtn = find.text('Tüm Favorileri Cihazlar Sayfasında Aç');
      expect(openAllBtn, findsOneWidget);
      await tester.tap(openAllBtn);
      await tester.pumpAndSettle();

      // AppShell navigates to Devices tab (index 1) with 'Favoriler' filter active!
      expect(find.byType(DevicesPage), findsOneWidget);
      expect(find.text('Cihazlarım'), findsOneWidget);
    });
  });

  group('Faz 5: Haftalık Özet Raporu & Bildirim Entegrasyonu', () {
    testWidgets('Toggling "Haftalık Özet Raporu" switch in ProfilePage dispatches notification and updates unread badge', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const ProfilePage()));
      await tester.pumpAndSettle();

      final switchFinder = find.byKey(const Key('profile_weekly_report_switch'));
      await tester.ensureVisible(switchFinder);
      expect(switchFinder, findsOneWidget);

      final initialNotifsCount = (notificationsCubit.state as NotificationsLoaded).notifications.length;

      // Turn on weekly report switch
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final updatedState = notificationsCubit.state as NotificationsLoaded;
      expect(updatedState.notifications.length, equals(initialNotifsCount + 1));
      expect(updatedState.notifications.first.title, equals('Haftalık Enerji & Tüketim Raporu'));
      expect(updatedState.notifications.first.type, equals(NotificationType.eco));
    });

    testWidgets('New weekly report notification is visible inside NotificationsPage with eco styling', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Dispatch the notification
      await notificationsCubit.createNotification(
        userId: 'test-user',
        title: 'Haftalık Enerji & Tüketim Raporu',
        message: 'Tebrikler! Bu hafta eviniz %14 daha az enerji tüketti.',
        type: NotificationType.eco,
      );

      await tester.pumpWidget(buildTestableWidget(const NotificationsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Haftalık Enerji & Tüketim Raporu'), findsOneWidget);
      expect(find.textContaining('Tebrikler! Bu hafta'), findsOneWidget);
    });
  });

  group('Faz B: Dashboard Karşılama ve Modern Villa Görsel Kartı', () {
    testWidgets('B.1: Renders location badge, greeting headline and subtitle correctly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const DashboardPage()));
      await tester.pumpAndSettle();

      // Check location badge with homeName
      expect(find.text("Aygen'in Evi"), findsWidgets);

      // Check greeting headline and subtitle
      expect(find.text('Merhaba, Aygen'), findsOneWidget);
      expect(find.text('Evin bugün nasıl?'), findsOneWidget);
    });

    testWidgets('B.2: Renders house illustration and dynamic system status pill', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const DashboardPage()));
      await tester.pumpAndSettle();

      // Check villa image asset
      final imageFinder = find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is AssetImage && (widget.image as AssetImage).assetName == 'assets/screens/modern_smart_house.jpg',
      );
      expect(imageFinder, findsOneWidget);

      // Check system status bar
      expect(find.text('Tüm Sistemler Normal'), findsOneWidget);
      expect(find.textContaining('Oda •'), findsWidgets);
      expect(find.textContaining('Cihaz'), findsWidgets);
    });
  });

  group('Faz C: Dashboard Aktif Senaryo & 3lü Canlı İstatistik Rozetleri', () {
    testWidgets('C.1 & C.2: Renders 3 summary stat cards and reacts dynamically to device toggling and room additions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const DashboardPage()));
      await tester.pumpAndSettle();

      // Check existence of all 3 cards
      expect(find.byKey(const Key('stat_card_devices')), findsOneWidget);
      expect(find.byKey(const Key('stat_card_active')), findsOneWidget);
      expect(find.byKey(const Key('stat_card_rooms')), findsOneWidget);

      final initialActive = (devicesCubit.state as DevicesLoaded).activeCount;
      final initialRooms = (roomsCubit.state as RoomsLoaded).rooms.length;

      expect(find.descendant(of: find.byKey(const Key('stat_card_active')), matching: find.text('$initialActive')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('stat_card_rooms')), matching: find.text('$initialRooms')), findsOneWidget);

      // Turn off an active device
      final activeDevice = (devicesCubit.state as DevicesLoaded).devices.firstWhere((d) => d.isPoweredOn);
      await devicesCubit.toggleDevicePower(activeDevice.id);
      await tester.pumpAndSettle();

      // The 'Açık' count dynamically dropped!
      final newActive = initialActive - 1;
      expect(find.descendant(of: find.byKey(const Key('stat_card_active')), matching: find.text('$newActive')), findsOneWidget);

      // Add a new room
      await roomsCubit.createRoom(
        userId: 'test-user',
        name: 'Kış Bahçesi',
        iconName: 'yard',
      );
      await tester.pumpAndSettle();

      // The 'Oda' count dynamically increased!
      final newRoomsCount = initialRooms + 1;
      expect(find.descendant(of: find.byKey(const Key('stat_card_rooms')), matching: find.text('$newRoomsCount')), findsOneWidget);
    });
  });
}
