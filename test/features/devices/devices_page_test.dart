import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/app/theme/theme_cubit.dart';
import 'package:nestora/core/constants/seed_data.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/core/widgets/nestora_switch.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/devices/domain/repositories/devices_repository.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_cubit.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_state.dart';
import 'package:nestora/features/devices/presentation/pages/ac_control_page.dart';
import 'package:nestora/features/devices/presentation/pages/add_edit_device_page.dart';
import 'package:nestora/features/devices/presentation/pages/devices_page.dart';
import 'package:nestora/features/devices/presentation/pages/lamp_control_page.dart';
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

void main() {
  group('DevicesPage (Adım 6.4) Unit & Widget Tests', () {
    late FakeDevicesRepository fakeDevicesRepo;
    late FakeRoomsRepository fakeRoomsRepo;
    late DevicesCubit devicesCubit;
    late RoomsCubit roomsCubit;
    late ThemeCubit themeCubit;

    setUp(() {
      fakeDevicesRepo = FakeDevicesRepository();
      fakeDevicesRepo.devices.addAll(SeedData.defaultDevices);

      fakeRoomsRepo = FakeRoomsRepository();
      fakeRoomsRepo.rooms.addAll(SeedData.defaultRooms);

      devicesCubit = DevicesCubit(devicesRepository: fakeDevicesRepo);
      roomsCubit = RoomsCubit(
        roomsRepository: fakeRoomsRepo,
        devicesRepository: fakeDevicesRepo,
      );
      themeCubit = ThemeCubit();

      devicesCubit.emit(
        DevicesLoaded(devices: SeedData.defaultDevices),
      );
      roomsCubit.emit(
        RoomsLoaded(rooms: SeedData.defaultRooms),
      );
    });

    tearDown(() {
      devicesCubit.close();
      roomsCubit.close();
      themeCubit.close();
    });

    Widget createTestApp({VoidCallback? onNavigateToProfile}) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<DevicesCubit>.value(value: devicesCubit),
          BlocProvider<RoomsCubit>.value(value: roomsCubit),
          BlocProvider<ThemeCubit>.value(value: themeCubit),
        ],
        child: MaterialApp(
          home: DevicesPage(onNavigateToProfile: onNavigateToProfile),
        ),
      );
    }

    testWidgets('renders header, live sync, status insight summary, search bar, and add button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Header & Subtitle
      expect(find.text('Cihazlarım'), findsWidgets);
      expect(find.text('Evindeki tüm akıllı cihazları tek merkezden yönet.'), findsOneWidget);
      expect(find.text('Canlı Senkron'), findsOneWidget);

      // Status Overview Card
      expect(find.text('Durum Özeti'), findsOneWidget);
      expect(find.textContaining('cihaz •'), findsOneWidget);

      // Search Bar & Add Button
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Cihaz veya oda ara...'), findsOneWidget);
      expect(find.text('Cihaz Ekle'), findsOneWidget);
    });

    testWidgets('renders all 5 category tabs (Tümü, Aydınlatma, İklimlendirme, Güvenlik, Prizler)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('Tümü ('), findsOneWidget);
      expect(find.textContaining('Aydınlatma ('), findsOneWidget);
      expect(find.textContaining('İklimlendirme ('), findsOneWidget);
      expect(find.textContaining('Güvenlik ('), findsOneWidget);
      expect(find.textContaining('Prizler ('), findsOneWidget);
    });

    testWidgets('category tabs filter devices correctly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Default: all devices visible
      expect(find.text('Salon Lambası'), findsWidgets);
      expect(find.text('Yatak Odası Kliması'), findsWidgets);

      // Select 'Aydınlatma'
      await tester.tap(find.textContaining('Aydınlatma ('));
      await tester.pumpAndSettle();

      expect(find.text('Salon Lambası'), findsWidgets);
      expect(find.text('Masa Lambası'), findsWidgets);
      expect(find.text('Yatak Odası Kliması'), findsNothing);
      expect(find.text('Kahve Makinesi'), findsNothing);

      // Select 'İklimlendirme'
      await tester.ensureVisible(find.textContaining('İklimlendirme ('));
      await tester.tap(find.textContaining('İklimlendirme ('));
      await tester.pumpAndSettle();

      expect(find.text('Yatak Odası Kliması'), findsWidgets);
      expect(find.text('Salon Lambası'), findsNothing);

      // Select 'Prizler'
      await tester.ensureVisible(find.textContaining('Prizler ('));
      await tester.tap(find.textContaining('Prizler ('));
      await tester.pumpAndSettle();

      expect(find.text('Akıllı Priz'), findsWidgets);
      expect(find.text('Kahve Makinesi'), findsWidgets);
      expect(find.text('Salon Lambası'), findsNothing);

      // Select 'Güvenlik'
      await tester.ensureVisible(find.textContaining('Güvenlik ('));
      await tester.tap(find.textContaining('Güvenlik ('));
      await tester.pumpAndSettle();

      expect(find.text('Giriş Güvenlik Kamerası'), findsWidgets);
      expect(find.text('Salon Lambası'), findsNothing);

      // Restore 'Tümü'
      await tester.ensureVisible(find.textContaining('Tümü ('));
      await tester.tap(find.textContaining('Tümü ('));
      await tester.pumpAndSettle();

      expect(find.text('Salon Lambası'), findsWidgets);
      expect(find.text('Yatak Odası Kliması'), findsWidgets);
    });

    testWidgets('status filter chips filter by power and favorite states', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap 'Kapalı' status chip
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Kapalı'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Kapalı'));
      await tester.pumpAndSettle();

      // Off devices should be visible, on devices should not
      expect(find.text('Televizyon'), findsWidgets);
      expect(find.text('Kahve Makinesi'), findsWidgets);
      expect(find.text('Salon Lambası'), findsNothing);

      // Tap 'Favoriler' status chip
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Favoriler'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Favoriler'));
      await tester.pumpAndSettle();

      expect(find.text('Salon Lambası'), findsWidgets);
      expect(find.text('Akıllı Priz'), findsWidgets);
      expect(find.text('Televizyon'), findsNothing);
    });

    testWidgets('search query filters device list and clear button resets query', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Klima');
      await tester.pumpAndSettle();

      expect(find.text('Yatak Odası Kliması'), findsWidgets);
      expect(find.text('Salon Lambası'), findsNothing);

      // Tap clear icon
      await tester.tap(find.byIcon(Icons.cancel_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Salon Lambası'), findsWidgets);
      expect(find.text('Yatak Odası Kliması'), findsWidgets);
    });

    testWidgets('switch toggle triggers instant power toggle on Cubit', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Find first switch (Salon Lambası, currently ON)
      final switches = find.byType(NestoraSwitch);
      expect(switches, findsWidgets);

      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      final loadedState = devicesCubit.state as DevicesLoaded;
      final salonLamp = loadedState.findDeviceById('dev-1');
      expect(salonLamp, isNotNull);
      expect(salonLamp!.isPoweredOn, isFalse);
    });

    testWidgets('favorite star toggle updates device favorite status in Cubit', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap first favorite star inside GridView
      final starFinder = find.descendant(
        of: find.byType(GridView),
        matching: find.byIcon(Icons.star_rounded),
      ).first;
      expect(starFinder, findsOneWidget);

      await tester.tap(starFinder);
      await tester.pumpAndSettle();

      final loadedState = devicesCubit.state as DevicesLoaded;
      final dev1 = loadedState.findDeviceById('dev-1');
      expect(dev1!.isFavorite, isFalse);
    });

    testWidgets('empty state displays when no match and reset button clears all filters', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'OlmayanCihazXYZ');
      await tester.pumpAndSettle();

      expect(find.text('Cihaz Bulunamadı'), findsOneWidget);
      expect(find.text('Filtreleri Temizle'), findsOneWidget);

      await tester.tap(find.text('Filtreleri Temizle'));
      await tester.pumpAndSettle();

      expect(find.text('Salon Lambası'), findsWidgets);
    });

    testWidgets('tapping device card navigates to LampControlPage', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap 'Salon Lambası' card pushes LampControlPage
      await tester.tap(find.text('Salon Lambası').first);
      await tester.pumpAndSettle();
      expect(find.byType(LampControlPage), findsOneWidget);
    });

    testWidgets('tapping climate device card navigates to AcControlPage', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap 'Yatak Odası Kliması' card pushes AcControlPage
      await tester.tap(find.text('Yatak Odası Kliması').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AcControlPage), findsOneWidget);
    });

    testWidgets('tapping add device button navigates to AddEditDevicePage', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap 'Cihaz Ekle' button pushes AddEditDevicePage
      await tester.tap(find.text('Cihaz Ekle'));
      await tester.pumpAndSettle();
      expect(find.byType(AddEditDevicePage), findsOneWidget);
    });
  });
}
