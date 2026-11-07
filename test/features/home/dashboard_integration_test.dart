import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nestora/app/theme/theme_cubit.dart';
import 'package:nestora/core/constants/seed_data.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/core/widgets/nestora_switch.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/devices/domain/repositories/devices_repository.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_cubit.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_state.dart';
import 'package:nestora/features/home/presentation/pages/dashboard_page.dart';
import 'package:nestora/features/notifications/domain/entities/app_notification.dart';
import 'package:nestora/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:nestora/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:nestora/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:nestora/features/profile/data/datasources/profile_photo_service.dart';
import 'package:nestora/features/profile/domain/entities/user_profile.dart';
import 'package:nestora/features/profile/domain/repositories/profile_repository.dart';
import 'package:nestora/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:nestora/features/profile/presentation/cubit/profile_state.dart';
import 'package:nestora/features/rooms/domain/entities/room.dart';
import 'package:nestora/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_cubit.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_state.dart';

class FakeDevicesRepository implements DevicesRepository {
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
  Future<Result<void>> deleteDevicesByRoom(String userId, String roomId) async {
    devices.removeWhere((d) => d.roomId == roomId);
    controller.add(List.from(devices));
    return Result.success(null);
  }

  @override
  Future<Result<void>> moveDevicesToRoom(String userId, String fromRoomId, String toRoomId) async {
    for (int i = 0; i < devices.length; i++) {
      if (devices[i].roomId == fromRoomId) {
        devices[i] = devices[i].copyWith(roomId: toRoomId);
      }
    }
    controller.add(List.from(devices));
    return Result.success(null);
  }
}

class FakeRoomsRepository implements RoomsRepository {
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

class FakeProfileRepository implements ProfileRepository {
  @override
  Stream<UserProfile?> watchProfile(String userId) => const Stream.empty();
  @override
  Future<Result<UserProfile?>> getProfile(String userId) async => Result.success(null);
  @override
  Future<Result<void>> updateProfile(String userId, UserProfile profile) async => Result.success(null);
  @override
  Future<Result<void>> updateHomeName(String userId, String homeName) async => Result.success(null);
  @override
  Future<Result<void>> updateDisplayName(String userId, String displayName) async => Result.success(null);
  @override
  Future<Result<void>> updatePreferences(String userId, UserPreferences preferences) async => Result.success(null);
  @override
  Future<Result<void>> updatePhotoPath(String userId, String? photoPath) async => Result.success(null);
}

class FakeProfilePhotoService implements ProfilePhotoService {
  @override
  Future<String?> pickAndSaveImage({
    ImageSource source = ImageSource.gallery,
    String? userId,
  }) async => null;

  @override
  Future<void> deleteLocalImage(String? path) async {}
}

class FakeNotificationsRepository implements NotificationsRepository {
  @override
  Stream<List<AppNotification>> watchNotifications(String userId) => const Stream.empty();
  @override
  Future<Result<List<AppNotification>>> getNotifications(String userId) async => Result.success([]);
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
  group('DashboardPage (Adım 6.1) Real Cubits Integration Tests', () {
    late FakeDevicesRepository fakeDevicesRepo;
    late DevicesCubit devicesCubit;
    late ProfileCubit profileCubit;
    late RoomsCubit roomsCubit;
    late NotificationsCubit notificationsCubit;
    late ThemeCubit themeCubit;

    setUp(() {
      fakeDevicesRepo = FakeDevicesRepository();
      fakeDevicesRepo.devices.addAll(SeedData.defaultDevices);

      devicesCubit = DevicesCubit(devicesRepository: fakeDevicesRepo);
      profileCubit = ProfileCubit(
        profileRepository: FakeProfileRepository(),
        photoService: FakeProfilePhotoService(),
      );
      roomsCubit = RoomsCubit(
        roomsRepository: FakeRoomsRepository(),
        devicesRepository: fakeDevicesRepo,
      );
      notificationsCubit = NotificationsCubit(
        notificationsRepository: FakeNotificationsRepository(),
      );
      themeCubit = ThemeCubit();

      // Seed cubits with realistic data
      profileCubit.emit(
        const ProfileLoaded(
          profile: UserProfile(
            uid: 'test-user',
            email: 'aygen@nestora.app',
            displayName: 'Aygen',
            homeName: "Aygen'in Evi",
          ),
        ),
      );

      roomsCubit.emit(
        RoomsLoaded(rooms: SeedData.defaultRooms),
      );

      devicesCubit.emit(
        DevicesLoaded(devices: SeedData.defaultDevices),
      );

      notificationsCubit.emit(
        NotificationsLoaded(
          notifications: [
            AppNotification(
              id: 'n-1',
              title: 'Lamba Açıldı',
              message: 'Salon Lambası açıldı.',
              isRead: false,
              createdAt: DateTime.now(),
            ),
            AppNotification(
              id: 'n-2',
              title: 'Klima Hedefi',
              message: '22°C ayarlandı.',
              isRead: true,
              createdAt: DateTime.now(),
            ),
          ],
        ),
      );
    });

    tearDown(() {
      devicesCubit.close();
      profileCubit.close();
      roomsCubit.close();
      notificationsCubit.close();
      themeCubit.close();
    });

    Widget createTestApp() {
      return MultiBlocProvider(
        providers: [
          BlocProvider<ProfileCubit>.value(value: profileCubit),
          BlocProvider<RoomsCubit>.value(value: roomsCubit),
          BlocProvider<DevicesCubit>.value(value: devicesCubit),
          BlocProvider<NotificationsCubit>.value(value: notificationsCubit),
          BlocProvider<ThemeCubit>.value(value: themeCubit),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DashboardPage(),
          ),
        ),
      );
    }

    testWidgets('renders all major sections: header, hero, energy, scenarios, rooms, devices', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Top Bar / Header
      expect(find.text('Nestora'), findsOneWidget);
      // Unread notification badge count (1 unread)
      expect(find.text('1'), findsOneWidget);
      // Profile initial avatar ('A' for Aygen)
      expect(find.text('A'), findsOneWidget);

      // Hero Banner
      expect(find.text("Aygen'in Evi"), findsOneWidget);
      expect(find.text('Eviniz, tek dokunuşla.'), findsOneWidget);
      expect(find.textContaining('Aygen'), findsWidgets);

      // Energy Overview
      expect(find.text('Bugün Tüketilen Enerji'), findsOneWidget);
      expect(find.text('7,8 kWh'), findsWidgets);
      expect(find.text('Hedef %68'), findsOneWidget);

      // Quick Scenarios
      expect(find.text('Evdeyim'), findsOneWidget);
      expect(find.text('Gündüz'), findsOneWidget);
      expect(find.text('Gece Modu'), findsOneWidget);
      expect(find.text('Dışarıda'), findsOneWidget);

      // Rooms Carousel
      expect(find.text('Odalar'), findsOneWidget);
      expect(find.text('Tümünü Gör'), findsOneWidget);
      expect(find.text('Salon'), findsWidgets);

      // Compact Active Devices
      expect(find.text('Aktif Cihazlar'), findsOneWidget);
      expect(find.textContaining('cihaz açık'), findsOneWidget);
      expect(find.text('Salon Lambası'), findsOneWidget);
    });

    testWidgets('scenario chip taps trigger applyQuickScene and update devices', (tester) async {
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap 'Dışarıda' scenario -> all devices turn off
      await tester.ensureVisible(find.text('Dışarıda'));
      await tester.tap(find.text('Dışarıda'));
      await tester.pumpAndSettle();

      final state = devicesCubit.state as DevicesLoaded;
      expect(state.activeCount, equals(0));
      expect(find.text('0 cihaz açık'), findsOneWidget);
      expect(find.text('Dışarıda senaryosu uygulandı.'), findsOneWidget);

      // Tap 'Evdeyim' scenario -> devices turn on
      await tester.tap(find.text('Evdeyim'));
      await tester.pumpAndSettle();

      final state2 = devicesCubit.state as DevicesLoaded;
      expect(state2.activeCount, greaterThan(0));
      expect(find.text('Evdeyim senaryosu uygulandı.'), findsOneWidget);
    });

    testWidgets('toggling a device switch on Dashboard directly toggles power in DevicesCubit', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Find NestoraSwitch instances on the screen
      final switchFinder = find.byType(NestoraSwitch);
      expect(switchFinder, findsWidgets);

      // Tap the first device switch
      await tester.tap(switchFinder.first);
      await tester.pumpAndSettle();

      // The device power state in DevicesCubit toggled
      final loadedState = devicesCubit.state as DevicesLoaded;
      expect(loadedState.devices.first.isPoweredOn, isFalse);
    });
  });
}
