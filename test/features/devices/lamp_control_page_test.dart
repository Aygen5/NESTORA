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
import 'package:nestora/features/devices/presentation/pages/lamp_control_page.dart';

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

void main() {
  group('LampControlPage (Adım 6.5) Unit & Widget Tests', () {
    late FakeDevicesRepository fakeDevicesRepo;
    late DevicesCubit devicesCubit;
    late ThemeCubit themeCubit;

    setUp(() {
      fakeDevicesRepo = FakeDevicesRepository();
      fakeDevicesRepo.devices.addAll(SeedData.defaultDevices);

      devicesCubit = DevicesCubit(devicesRepository: fakeDevicesRepo);
      themeCubit = ThemeCubit();

      devicesCubit.emit(
        DevicesLoaded(devices: SeedData.defaultDevices),
      );
    });

    tearDown(() {
      devicesCubit.close();
      themeCubit.close();
    });

    Widget createTestApp({String? deviceId}) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<DevicesCubit>.value(value: devicesCubit),
          BlocProvider<ThemeCubit>.value(value: themeCubit),
        ],
        child: MaterialApp(
          home: LampControlPage(deviceId: deviceId),
        ),
      );
    }

    testWidgets('renders all lighting controls: hero bulb, slider, presets, modes, timer', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Title & Room metadata
      expect(find.text('Salon Lambası'), findsOneWidget);
      expect(find.text('Salon'), findsOneWidget);
      expect(find.text('Akıllı Ampul'), findsOneWidget);
      expect(find.text('Açık • %72'), findsOneWidget);

      // Hero Bulb Painter
      expect(find.byType(CustomPaint), findsWidgets);

      // Brightness Slider Card
      expect(find.text('Parlaklık'), findsOneWidget);
      expect(find.text('%72'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('%25'), findsOneWidget);
      expect(find.text('%50'), findsOneWidget);
      expect(find.text('%75'), findsOneWidget);
      expect(find.text('%100'), findsWidgets);

      // Color Temperature Card
      expect(find.text('Renk Sıcaklığı & Ton'), findsOneWidget);
      expect(find.text('Sıcak Günışığı (2700K)'), findsOneWidget);

      // 4 Atmosphere Modes
      expect(find.text('Hazır Atmosfer Modları'), findsOneWidget);
      expect(find.text('Okuma'), findsOneWidget);
      expect(find.text('Dinlenme'), findsOneWidget);
      expect(find.text('Konsantrasyon'), findsOneWidget);
      expect(find.text('Gece Lambası'), findsOneWidget);

      // Timer Interface
      expect(find.text('Kapanma Zamanlayıcısı'), findsOneWidget);
      expect(find.text('15 dk'), findsOneWidget);
      expect(find.text('30 dk'), findsOneWidget);
      expect(find.text('60 dk'), findsOneWidget);

      // Management Buttons
      expect(find.text('Cihazı Yapılandır'), findsOneWidget);
      expect(find.text('Cihazı Kaldır'), findsOneWidget);
    });

    testWidgets('master power switch turns lamp off and on, preserving brightness and settings', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Açık • %72'), findsOneWidget);

      // Tap master switch
      final switchFinder = find.byType(NestoraSwitch).first;
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Now lamp is off
      final offState = devicesCubit.state as DevicesLoaded;
      final dev = offState.findDeviceById('dev-1')!;
      expect(dev.isPoweredOn, isFalse);
      expect(dev.brightness, equals(72)); // Preserved in memory!
      expect(find.text('Kapalı'), findsWidgets);

      // Tap master switch again to turn back on
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final onState = devicesCubit.state as DevicesLoaded;
      final devOn = onState.findDeviceById('dev-1')!;
      expect(devOn.isPoweredOn, isTrue);
      expect(devOn.brightness, equals(72)); // Restored accurately
      expect(find.text('Açık • %72'), findsOneWidget);
    });

    testWidgets('brightness presets adjust lamp brightness level in Cubit', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap %50 preset
      await tester.tap(find.text('%50'));
      await tester.pumpAndSettle();

      var state = devicesCubit.state as DevicesLoaded;
      expect(state.findDeviceById('dev-1')!.brightness, equals(50));
      expect(find.text('Açık • %50'), findsOneWidget);

      // Tap %100 preset
      await tester.tap(find.text('%100').first);
      await tester.pumpAndSettle();

      state = devicesCubit.state as DevicesLoaded;
      expect(state.findDeviceById('dev-1')!.brightness, equals(100));
      expect(find.text('Açık • %100'), findsOneWidget);
    });

    testWidgets('color swatch taps update active color and name in Cubit', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Initially 'Sıcak Günışığı (2700K)'
      expect(find.text('Sıcak Günışığı (2700K)'), findsOneWidget);

      // Tap second color swatch (Doğal Beyaz)
      // Find all check icons or circular containers
      final swatchesContainer = find.descendant(
        of: find.widgetWithText(Container, 'Renk Sıcaklığı & Ton'),
        matching: find.byType(GestureDetector),
      );
      // Tap the second swatch
      await tester.tap(swatchesContainer.at(1));
      await tester.pumpAndSettle();

      final state = devicesCubit.state as DevicesLoaded;
      final dev = state.findDeviceById('dev-1')!;
      expect(dev.colorHex, equals('#EAF0E6'));
      expect(dev.colorName, equals('Doğal Beyaz (4000K)'));
      expect(find.text('Doğal Beyaz (4000K)'), findsOneWidget);
    });

    testWidgets('atmosphere modes apply brightness and color tone in a single tap', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap 'Okuma' mode (%80, Doğal Beyaz)
      await tester.ensureVisible(find.text('Okuma'));
      await tester.tap(find.text('Okuma'));
      await tester.pumpAndSettle();

      var state = devicesCubit.state as DevicesLoaded;
      var dev = state.findDeviceById('dev-1')!;
      expect(dev.brightness, equals(80));
      expect(dev.colorHex, equals('#EAF0E6'));

      // Tap 'Gece Lambası' mode (%15, Gece Modu Köz)
      await tester.ensureVisible(find.text('Gece Lambası'));
      await tester.tap(find.text('Gece Lambası'));
      await tester.pumpAndSettle();

      state = devicesCubit.state as DevicesLoaded;
      dev = state.findDeviceById('dev-1')!;
      expect(dev.brightness, equals(15));
      expect(dev.colorHex, equals('#533E25'));
    });

    testWidgets('timer buttons select auto-off duration and display notification', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap '30 dk'
      await tester.ensureVisible(find.text('30 dk'));
      await tester.tap(find.text('30 dk'));
      await tester.pumpAndSettle();

      expect(find.text('30 dk sonra kapanacak'), findsOneWidget);
      expect(find.text('Lamba 30 dakika sonra otomatik olarak kapatılacak.'), findsOneWidget);

      // Tap 'Kapalı' to cancel timer
      await tester.tap(find.text('Kapalı').last);
      await tester.pumpAndSettle();

      expect(find.text('Zamanlayıcı aktif değil'), findsOneWidget);
    });

    testWidgets('delete device displays confirmation dialog and deletes device on confirmation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap 'Cihazı Kaldır' button
      await tester.ensureVisible(find.text('Cihazı Kaldır'));
      await tester.tap(find.text('Cihazı Kaldır'));
      await tester.pumpAndSettle();

      // Delete confirmation dialog is shown
      expect(find.text('"Salon Lambası" Silinecek'), findsOneWidget);

      // Tap confirm button in dialog
      await tester.tap(find.widgetWithText(NestoraButton, 'Cihazı Sil'));
      await tester.pumpAndSettle();

      // Device was deleted from Cubit repository
      expect(fakeDevicesRepo.devices.any((d) => d.id == 'dev-1'), isFalse);
    });
  });
}
