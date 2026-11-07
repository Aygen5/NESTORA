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
import 'package:nestora/features/devices/presentation/pages/ac_control_page.dart';
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
      if (stateFields.containsKey('targetTemp')) {
        d = d.copyWith(targetTemp: (stateFields['targetTemp'] as num).toDouble());
      }
      if (stateFields.containsKey('acMode')) {
        d = d.copyWith(acMode: AcMode.fromString(stateFields['acMode'] as String));
      }
      if (stateFields.containsKey('fanSpeed')) {
        d = d.copyWith(fanSpeed: FanSpeed.fromString(stateFields['fanSpeed'] as String));
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
  group('AcControlPage (Adım 6.6) Unit & Widget Tests', () {
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

    Widget createTestApp({String? deviceId}) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<DevicesCubit>.value(value: devicesCubit),
          BlocProvider<RoomsCubit>.value(value: roomsCubit),
          BlocProvider<ThemeCubit>.value(value: themeCubit),
        ],
        child: MaterialApp(
          home: AcControlPage(deviceId: deviceId),
        ),
      );
    }

    testWidgets('renders thermostat dial, ambient stats, 4 modes, 4 fan speeds, and presets', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Header & Device info
      expect(find.text('Yatak Odası Kliması'), findsOneWidget);
      expect(find.text('Yatak Odası'), findsOneWidget);
      expect(find.text('İklimlendirme'), findsOneWidget);

      // Hardware status
      expect(find.text('NESTORA CLIMATE PRO'), findsOneWidget);
      expect(find.textContaining('Aktif • 24'), findsOneWidget);

      // Thermostat Dial Readout
      expect(find.text('Hedef Sıcaklık'), findsOneWidget);
      expect(find.text('24'), findsWidgets);
      expect(find.textContaining('Oda: 24'), findsOneWidget); // from room-2 seed data

      // Floating +/- Buttons
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);

      // 4 Operational Modes & 4 Fan Speeds
      expect(find.text('Çalışma Modu'), findsOneWidget);
      expect(find.text('Soğutma'), findsOneWidget);
      expect(find.text('Isıtma'), findsOneWidget);
      expect(find.text('Fan'), findsOneWidget);

      expect(find.text('Fan Hızı'), findsOneWidget);
      expect(find.text('Düşük'), findsOneWidget);
      expect(find.text('Orta'), findsOneWidget);
      expect(find.text('Yüksek'), findsOneWidget);
      // 'Otomatik' appears in both mode and fan speed selectors
      expect(find.text('Otomatik'), findsNWidgets(2));

      // Preset Buttons
      expect(find.text('20°C Serin'), findsOneWidget);
      expect(find.text('22°C Dengeli'), findsOneWidget);
      expect(find.text('24°C Konfor'), findsOneWidget);
      expect(find.text('26°C Eko'), findsOneWidget);
    });

    testWidgets('plus and minus buttons adjust target temperature by 0.5°C steps', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap '+' button -> 24.0 becomes 24.5
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      var state = devicesCubit.state as DevicesLoaded;
      expect(state.findDeviceById('dev-5')!.targetTemp, equals(24.5));
      expect(find.text('24.5'), findsOneWidget);

      // Tap '+' button again -> 24.5 becomes 25.0
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      state = devicesCubit.state as DevicesLoaded;
      expect(state.findDeviceById('dev-5')!.targetTemp, equals(25.0));

      // Tap '-' button -> 25.0 becomes 24.5
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      state = devicesCubit.state as DevicesLoaded;
      expect(state.findDeviceById('dev-5')!.targetTemp, equals(24.5));

      // Flush debounce write timer
      await tester.pump(const Duration(milliseconds: 350));
    });

    testWidgets('quick preset buttons set specific target temperatures', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap '20°C Serin'
      await tester.tap(find.text('20°C Serin'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      var state = devicesCubit.state as DevicesLoaded;
      expect(state.findDeviceById('dev-5')!.targetTemp, equals(20.0));

      // Tap '26°C Eko'
      await tester.tap(find.text('26°C Eko'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      state = devicesCubit.state as DevicesLoaded;
      expect(state.findDeviceById('dev-5')!.targetTemp, equals(26.0));

      // Flush debounce write timer
      await tester.pump(const Duration(milliseconds: 350));
    });

    testWidgets('selecting operational mode updates AcMode in Cubit', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Select 'Soğutma' (Cool)
      await tester.tap(find.text('Soğutma'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      var state = devicesCubit.state as DevicesLoaded;
      expect(state.findDeviceById('dev-5')!.acMode, equals(AcMode.cool));

      // Select 'Isıtma' (Heat)
      await tester.tap(find.text('Isıtma'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      state = devicesCubit.state as DevicesLoaded;
      expect(state.findDeviceById('dev-5')!.acMode, equals(AcMode.heat));

      // Select 'Fan' (FanOnly)
      await tester.tap(find.text('Fan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      state = devicesCubit.state as DevicesLoaded;
      expect(state.findDeviceById('dev-5')!.acMode, equals(AcMode.fanOnly));
    });

    testWidgets('selecting fan speed updates FanSpeed in Cubit', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 'Düşük' (Low)
      await tester.tap(find.text('Düşük'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      var state = devicesCubit.state as DevicesLoaded;
      expect(state.findDeviceById('dev-5')!.fanSpeed, equals(FanSpeed.low));

      // Tap 'Yüksek' (High)
      await tester.tap(find.text('Yüksek'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      state = devicesCubit.state as DevicesLoaded;
      expect(state.findDeviceById('dev-5')!.fanSpeed, equals(FanSpeed.high));
    });

    testWidgets('master switch toggles power on and off and preserves target temperature', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Toggle switch to turn AC off
      final switchFinder = find.byType(NestoraSwitch).first;
      await tester.tap(switchFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      var state = devicesCubit.state as DevicesLoaded;
      expect(state.findDeviceById('dev-5')!.isPoweredOn, isFalse);
      expect(state.findDeviceById('dev-5')!.targetTemp, equals(24.0)); // Preserved!
      expect(find.text('Kapalı'), findsWidgets);
      expect(find.text('Standby'), findsOneWidget);

      // Toggle switch to turn AC back on
      await tester.tap(switchFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      state = devicesCubit.state as DevicesLoaded;
      expect(state.findDeviceById('dev-5')!.isPoweredOn, isTrue);
      expect(state.findDeviceById('dev-5')!.targetTemp, equals(24.0));
      expect(find.text('Açık'), findsWidgets);
    });

    testWidgets('delete AC displays confirmation dialog and triggers deletion', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 'Cihazı Sil' button at bottom
      await tester.ensureVisible(find.text('Cihazı Sil'));
      await tester.tap(find.text('Cihazı Sil'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Confirmation dialog is displayed
      expect(find.text('"Yatak Odası Kliması" Silinecek'), findsOneWidget);

      // Tap confirm button
      await tester.tap(find.widgetWithText(NestoraButton, 'Klimayı Sil'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeDevicesRepo.devices.any((d) => d.id == 'dev-5'), isFalse);
    });
  });
}
