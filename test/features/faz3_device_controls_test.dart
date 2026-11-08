import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/app/theme/theme_cubit.dart';
import 'package:nestora/core/constants/seed_data.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/core/widgets/nestora_button.dart';
import 'package:nestora/core/widgets/nestora_switch.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/devices/domain/repositories/devices_repository.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_cubit.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_state.dart';
import 'package:nestora/features/devices/presentation/pages/coffee_machine_control_page.dart';
import 'package:nestora/features/devices/presentation/pages/devices_page.dart';
import 'package:nestora/features/devices/presentation/pages/lamp_control_page.dart';
import 'package:nestora/features/devices/presentation/pages/plug_control_page.dart';
import 'package:nestora/features/devices/presentation/pages/tv_control_page.dart';
import 'package:nestora/features/notifications/domain/entities/app_notification.dart';
import 'package:nestora/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:nestora/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:nestora/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:nestora/features/profile/domain/entities/user_profile.dart';
import 'package:nestora/features/profile/domain/repositories/profile_repository.dart';
import 'package:nestora/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:nestora/features/rooms/domain/entities/room.dart';
import 'package:nestora/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_cubit.dart';

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
      if (stateFields.containsKey('colorHex')) {
        d = d.copyWith(colorHex: stateFields['colorHex'] as String);
      }
      if (stateFields.containsKey('colorName')) {
        d = d.copyWith(colorName: stateFields['colorName'] as String);
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
  @override
  Stream<List<Room>> watchRooms(String userId) => Stream.value(SeedData.defaultRooms);
  @override
  Future<Result<List<Room>>> getRooms(String userId) async => Result.success(SeedData.defaultRooms);
  @override
  Future<Result<Room>> getRoomById(String userId, String roomId) async =>
      Result.success(SeedData.defaultRooms.firstWhere((r) => r.id == roomId));
  @override
  Future<Result<void>> createRoom(String userId, Room room) async => Result.success(null);
  @override
  Future<Result<void>> updateRoom(String userId, Room room) async => Result.success(null);
  @override
  Future<Result<void>> deleteRoom(String userId, String roomId) async => Result.success(null);
}

class FakeNotificationsRepo implements NotificationsRepository {
  final List<AppNotification> notifs = [];
  final StreamController<List<AppNotification>> controller = StreamController<List<AppNotification>>.broadcast();

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) => controller.stream;
  @override
  Future<Result<List<AppNotification>>> getNotifications(String userId) async => Result.success(notifs);
  @override
  Future<Result<void>> createNotification(String userId, AppNotification notification) async {
    notifs.insert(0, notification);
    controller.add(List.from(notifs));
    return Result.success(null);
  }
  @override
  Future<Result<void>> markAsRead(String userId, String notificationId) async => Result.success(null);
  @override
  Future<Result<void>> markAllAsRead(String userId) async => Result.success(null);
  @override
  Future<Result<void>> deleteNotification(String userId, String notificationId) async => Result.success(null);
}

class FakeProfileRepo implements ProfileRepository {
  UserProfile profile = SeedData.defaultProfile;
  @override
  Stream<UserProfile?> watchProfile(String userId) => Stream.value(profile);
  @override
  Future<Result<UserProfile?>> getProfile(String userId) async => Result.success(profile);
  @override
  Future<Result<void>> updateProfile(String userId, UserProfile profile) async {
    this.profile = profile;
    return Result.success(null);
  }
  @override
  Future<Result<void>> updateDisplayName(String userId, String displayName) async {
    profile = profile.copyWith(displayName: displayName);
    return Result.success(null);
  }
  @override
  Future<Result<void>> updateHomeName(String userId, String homeName) async {
    profile = profile.copyWith(homeName: homeName);
    return Result.success(null);
  }
  @override
  Future<Result<void>> updatePhotoPath(String userId, String? photoPath) async => Result.success(null);
  @override
  Future<Result<void>> updatePreferences(String userId, UserPreferences preferences) async {
    profile = profile.copyWith(preferences: preferences);
    return Result.success(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDevicesRepo fakeDevicesRepo;
  late DevicesCubit devicesCubit;
  late FakeNotificationsRepo fakeNotificationsRepo;
  late NotificationsCubit notificationsCubit;
  late FakeRoomsRepo fakeRoomsRepo;
  late RoomsCubit roomsCubit;
  late FakeProfileRepo fakeProfileRepo;
  late ProfileCubit profileCubit;
  late ThemeCubit themeCubit;

  setUp(() {
    fakeDevicesRepo = FakeDevicesRepo();
    fakeDevicesRepo.devices.addAll(SeedData.defaultDevices);
    devicesCubit = DevicesCubit(devicesRepository: fakeDevicesRepo);

    fakeNotificationsRepo = FakeNotificationsRepo();
    fakeNotificationsRepo.notifs.addAll(SeedData.defaultNotifications);
    notificationsCubit = NotificationsCubit(notificationsRepository: fakeNotificationsRepo);

    fakeRoomsRepo = FakeRoomsRepo();
    roomsCubit = RoomsCubit(
      roomsRepository: fakeRoomsRepo,
      devicesRepository: fakeDevicesRepo,
    );

    fakeProfileRepo = FakeProfileRepo();
    profileCubit = ProfileCubit(profileRepository: fakeProfileRepo);

    themeCubit = ThemeCubit();
  });

  tearDown(() {
    devicesCubit.close();
    notificationsCubit.close();
    roomsCubit.close();
    profileCubit.close();
    themeCubit.close();
  });

  Widget buildApp(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DevicesCubit>.value(value: devicesCubit),
        BlocProvider<NotificationsCubit>.value(value: notificationsCubit),
        BlocProvider<RoomsCubit>.value(value: roomsCubit),
        BlocProvider<ProfileCubit>.value(value: profileCubit),
        BlocProvider<ThemeCubit>.value(value: themeCubit),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Faz 3: TvControlPage Tests', () {
    testWidgets('renders TV screen, standby indicator, power switch, and wattage', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildApp(const TvControlPage(deviceId: 'dev-2')));
      await tester.pumpAndSettle();

      // Check header and device name
      expect(find.text('Televizyon'), findsWidgets);
      expect(find.textContaining('Akıllı Televizyon'), findsOneWidget);

      // Initially dev-2 is powered off
      expect(find.text('Kapalı • 0.0 W'), findsOneWidget);
      expect(find.text('Standby (LED Kırmızı)'), findsOneWidget);
      expect(find.text('Güç Kapalı'), findsOneWidget);

      // Tap power switch to turn TV on
      final switchFinder = find.byType(NestoraSwitch).first;
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Check TV is powered on
      final state = devicesCubit.state as DevicesLoaded;
      final tv = state.findDeviceById('dev-2')!;
      expect(tv.isPoweredOn, isTrue);

      // Screen displays active status
      expect(find.text('Güç Açık'), findsOneWidget);
      expect(find.text('Aktif (LED Yeşil)'), findsOneWidget);
      expect(find.textContaining('TRT Belgesel'), findsWidgets);
    });

    testWidgets('volume adjustment, mute toggle, channel switching, and remote D-pad', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildApp(const TvControlPage(deviceId: 'dev-2')));
      await tester.pumpAndSettle();

      // Volume controls
      expect(find.text('Hoparlör: %32'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Hoparlör: %37'), findsOneWidget);

      // Mute toggle
      await tester.tap(find.text('Sustur'));
      await tester.pumpAndSettle();
      expect(find.text('Sessiz mod etkin'), findsOneWidget);

      // Channel selection (e.g. BBC Earth)
      await tester.ensureVisible(find.text('BBC Earth'));
      await tester.tap(find.text('BBC Earth'));
      await tester.pumpAndSettle();
      expect(find.text('BBC Earth'), findsWidgets);

      // Virtual remote D-pad button taps
      await tester.ensureVisible(find.text('OK'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Secondary remote button (Ana Menü)
      await tester.ensureVisible(find.text('Ana Menü'));
      await tester.tap(find.text('Ana Menü'));
      await tester.pumpAndSettle();
    });
  });

  group('Faz 3: PlugControlPage Tests', () {
    testWidgets('renders Schuko socket figure, relay toggle, live wattage, and child lock', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildApp(const PlugControlPage(deviceId: 'dev-3')));
      await tester.pumpAndSettle();

      // Header and device name
      expect(find.text('Akıllı Priz'), findsWidgets);
      expect(find.textContaining('Akıllı Priz & Güç Ölçer'), findsOneWidget);

      // dev-3 is initially powered ON with 120.0 W
      expect(find.text('Röle Açık'), findsOneWidget);
      expect(find.text('120.0 W'), findsOneWidget);
      expect(find.text('230 V'), findsOneWidget);
      expect(find.text('Canlı Ölçüm'), findsOneWidget);

      // Child lock toggle
      await tester.ensureVisible(find.text('Çocuk Kilidi'));
      final childLockSwitch = find.descendant(
        of: find.widgetWithText(Container, 'Çocuk Kilidi'),
        matching: find.byType(NestoraSwitch),
      );
      await tester.tap(childLockSwitch);
      await tester.pumpAndSettle();
      expect(find.text('Fiziksel tuş & soket koruması aktif'), findsOneWidget);

      // Auto-off timer preset
      await tester.ensureVisible(find.text('30 dk'));
      await tester.tap(find.text('30 dk'));
      await tester.pumpAndSettle();
      expect(find.textContaining('30 dk sonra'), findsWidgets);
    });
  });

  group('Faz 3: CoffeeMachineControlPage Tests', () {
    testWidgets('renders espresso machine, recipe selection, strength, cup size and brewing flow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildApp(const CoffeeMachineControlPage(deviceId: 'dev-7')));
      await tester.pumpAndSettle();

      expect(find.text('Kahve Makinesi'), findsWidgets);
      expect(find.textContaining('Akıllı Espresso Makinesi'), findsOneWidget);

      // Select Americano recipe
      await tester.ensureVisible(find.text('Americano'));
      await tester.tap(find.text('Americano'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Seçilen: Americano'), findsOneWidget);

      // Select Yoğun strength
      await tester.ensureVisible(find.text('Yoğun'));
      await tester.tap(find.text('Yoğun'));
      await tester.pumpAndSettle();

      // Select Büyük cup size
      await tester.ensureVisible(find.text('Büyük (240 ml)'));
      await tester.tap(find.text('Büyük (240 ml)'));
      await tester.pumpAndSettle();

      // Tap 'Demlemeyi Başlat'
      await tester.ensureVisible(find.byType(NestoraButton));
      await tester.tap(find.byType(NestoraButton));
      await tester.pump();

      // Advances timer through brewing
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Notification was dispatched
      final notifState = notificationsCubit.state as NotificationsLoaded;
      expect(notifState.notifications.any((n) => n.title.contains('Kahve')), isTrue);
    });
  });

  group('Faz 3: LampControlPage Dynamic Lighting & Swatches Tests', () {
    testWidgets('all 5 exact swatches are present and update lamp color dynamically', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildApp(const LampControlPage(deviceId: 'dev-1')));
      await tester.pumpAndSettle();

      // Verify initially Sıcak Günışığı
      expect(find.text('Sıcak Günışığı (2700K)'), findsOneWidget);

      // Tap Doğal Beyaz (swatch 1)
      final swatchesContainer = find.descendant(
        of: find.widgetWithText(Container, 'Renk Sıcaklığı & Ton'),
        matching: find.byType(GestureDetector),
      );
      await tester.tap(swatchesContainer.at(1));
      await tester.pumpAndSettle();

      var state = devicesCubit.state as DevicesLoaded;
      expect(state.findDeviceById('dev-1')!.colorHex, equals('#EAF0E6'));

      // Tap Sıcak Sarı (swatch 2)
      await tester.tap(swatchesContainer.at(2));
      await tester.pumpAndSettle();
      state = devicesCubit.state as DevicesLoaded;
      expect(state.findDeviceById('dev-1')!.colorHex, equals('#FFD54F'));

      // Tap Yumuşak Yeşil (swatch 3)
      await tester.tap(swatchesContainer.at(3));
      await tester.pumpAndSettle();
      state = devicesCubit.state as DevicesLoaded;
      expect(state.findDeviceById('dev-1')!.colorHex, equals('#81C784'));

      // Tap Gece Mavisi (swatch 4)
      await tester.tap(swatchesContainer.at(4));
      await tester.pumpAndSettle();
      state = devicesCubit.state as DevicesLoaded;
      expect(state.findDeviceById('dev-1')!.colorHex, equals('#64B5F6'));
    });
  });

  group('Faz 3: DevicesPage Navigation to Dedicated Control Pages', () {
    testWidgets('tapping TV, Plug, and Lamp navigates to their dedicated control screens', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildApp(const DevicesPage()));
      await tester.pumpAndSettle();

      // Tap 'Televizyon' card
      await tester.ensureVisible(find.text('Televizyon'));
      await tester.tap(find.text('Televizyon'));
      await tester.pumpAndSettle();

      // Successfully opened TvControlPage
      expect(find.byType(TvControlPage), findsOneWidget);

      // Pop back
      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Tap 'Akıllı Priz' card
      await tester.ensureVisible(find.text('Akıllı Priz'));
      await tester.tap(find.text('Akıllı Priz'));
      await tester.pumpAndSettle();

      // Successfully opened PlugControlPage
      expect(find.byType(PlugControlPage), findsOneWidget);

      // Pop back
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      // Tap 'Kahve Makinesi' card
      await tester.ensureVisible(find.text('Kahve Makinesi'));
      await tester.tap(find.text('Kahve Makinesi'));
      await tester.pumpAndSettle();

      // Successfully opened CoffeeMachineControlPage
      expect(find.byType(CoffeeMachineControlPage), findsOneWidget);
    });
  });
}
