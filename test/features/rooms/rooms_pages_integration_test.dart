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
import 'package:nestora/features/rooms/domain/entities/room.dart';
import 'package:nestora/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_cubit.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_state.dart';
import 'package:nestora/features/rooms/presentation/pages/room_detail_page.dart';
import 'package:nestora/features/rooms/presentation/pages/rooms_page.dart';

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

void main() {
  group('RoomsPage & RoomDetailPage (Adım 6.2) Integration Tests', () {
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

    Widget createTestApp(Widget child) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<RoomsCubit>.value(value: roomsCubit),
          BlocProvider<DevicesCubit>.value(value: devicesCubit),
          BlocProvider<ThemeCubit>.value(value: themeCubit),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('RoomsPage renders room list, summary pill, search bar, and device chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp(const RoomsPage()));
      await tester.pumpAndSettle();

      // Title & Add button
      expect(find.text('Odalarım'), findsWidgets);
      expect(find.text('Oda Ekle'), findsOneWidget);

      // Summary status pill
      expect(find.textContaining('Oda •'), findsOneWidget);

      // Search bar
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Oda veya alan ara...'), findsOneWidget);

      // Room cards
      expect(find.text('Salon'), findsWidgets);
      expect(find.text('Yatak Odası'), findsWidgets);
      expect(find.text('Mutfak'), findsWidgets);
      expect(find.text('Çalışma Odası'), findsWidgets);
    });

    testWidgets('RoomsPage search bar filters rooms in real time and clears cleanly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp(const RoomsPage()));
      await tester.pumpAndSettle();

      // Enter search query 'Mutfak'
      await tester.enterText(find.byType(TextField), 'Mutfak');
      await tester.pumpAndSettle();

      expect(find.text('Mutfak'), findsWidgets);
      expect(find.text('Salon'), findsNothing);
      expect(find.text('Yatak Odası'), findsNothing);

      // Clear search button appears and works
      final clearButtonFinder = find.byIcon(Icons.close_rounded);
      expect(clearButtonFinder, findsOneWidget);
      await tester.tap(clearButtonFinder);
      await tester.pumpAndSettle();

      // All rooms restored
      expect(find.text('Salon'), findsWidgets);
      expect(find.text('Mutfak'), findsWidgets);
    });

    testWidgets('RoomDetailPage renders environmental metrics (temp, humidity, air quality) and devices', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testRoom = SeedData.defaultRoomModels.first; // Salon
      await tester.pumpWidget(createTestApp(RoomDetailPage(room: testRoom)));
      await tester.pumpAndSettle();

      // Environmental metrics
      expect(find.text('Canlı İzleme'), findsOneWidget);
      expect(find.text('YAŞAM ALANI'), findsOneWidget);
      expect(find.text('Salon'), findsWidgets);
      expect(find.textContaining('°C'), findsWidgets);
      expect(find.textContaining('Nem %'), findsWidgets);
      expect(find.text('Hava: Temiz'), findsOneWidget);

      // Ribbon with device counts & bulk action button (not all on initially)
      expect(find.text('Tümünü Aç'), findsOneWidget);

      // Devices in room
      expect(find.text('Salon Lambası'), findsOneWidget);
      expect(find.text('Akıllı Priz'), findsOneWidget);

      // Buttons
      expect(find.text('+ Cihaz Ekle'), findsOneWidget);
      expect(find.text('Odayı Düzenle'), findsOneWidget);
      expect(find.text('Odayı Sil'), findsOneWidget);
    });

    testWidgets('RoomDetailPage bulk action button toggles all devices in the room', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testRoom = SeedData.defaultRoomModels.first; // Salon
      await tester.pumpWidget(createTestApp(RoomDetailPage(room: testRoom)));
      await tester.pumpAndSettle();

      // Initially some are off, so button is 'Tümünü Aç'
      expect(find.text('Tümünü Aç'), findsOneWidget);
      await tester.tap(find.text('Tümünü Aç'));
      await tester.pumpAndSettle();

      // Devices in Salon should now all be powered on
      final loadedState = devicesCubit.state as DevicesLoaded;
      final salonDevices = loadedState.devices.where((d) => d.roomId == 'room-1').toList();
      for (final dev in salonDevices) {
        expect(dev.isPoweredOn, isTrue);
      }

      // Button now changes to 'Tümünü Kapat'
      expect(find.text('Tümünü Kapat'), findsOneWidget);

      // Tap 'Tümünü Kapat' to turn them all off
      await tester.tap(find.text('Tümünü Kapat'));
      await tester.pumpAndSettle();

      final loadedStateAfter = devicesCubit.state as DevicesLoaded;
      final salonDevicesAfter = loadedStateAfter.devices.where((d) => d.roomId == 'room-1').toList();
      for (final dev in salonDevicesAfter) {
        expect(dev.isPoweredOn, isFalse);
      }
      expect(find.text('Tümünü Aç'), findsOneWidget);
      expect(find.text('Tümünü Aç'), findsOneWidget);
    });

    testWidgets('RoomDetailPage device NestoraSwitch toggles individual device power', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testRoom = SeedData.defaultRoomModels.first; // Salon
      await tester.pumpWidget(createTestApp(RoomDetailPage(room: testRoom)));
      await tester.pumpAndSettle();

      final switchFinder = find.byType(NestoraSwitch);
      expect(switchFinder, findsWidgets);

      // Toggle first device switch
      await tester.tap(switchFinder.first);
      await tester.pumpAndSettle();

      final state = devicesCubit.state as DevicesLoaded;
      expect(state.devices.first.isPoweredOn, isFalse);
    });
  });
}
