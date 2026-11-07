import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/app/theme/theme_cubit.dart';
import 'package:nestora/core/constants/seed_data.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/core/widgets/nestora_button.dart';
import 'package:nestora/core/widgets/nestora_input.dart';
import 'package:nestora/features/devices/domain/device_model.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/devices/domain/repositories/devices_repository.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_cubit.dart';
import 'package:nestora/features/devices/presentation/pages/add_edit_device_page.dart';
import 'package:nestora/features/rooms/domain/entities/room.dart';
import 'package:nestora/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_cubit.dart';

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
  Future<Result<void>> updateDeviceState(
      String userId, String deviceId, Map<String, dynamic> stateUpdates) async {
    final idx = devices.indexWhere((d) => d.id == deviceId);
    if (idx != -1) {
      final current = devices[idx];
      devices[idx] = current.copyWith(
        isPoweredOn: stateUpdates.containsKey('isPoweredOn')
            ? stateUpdates['isPoweredOn'] as bool
            : current.isPoweredOn,
        brightness: stateUpdates.containsKey('brightness')
            ? stateUpdates['brightness'] as int
            : current.brightness,
        targetTemp: stateUpdates.containsKey('targetTemp')
            ? (stateUpdates['targetTemp'] as num).toDouble()
            : current.targetTemp,
      );
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
  Future<Result<void>> moveDevicesToRoom(
      String userId, String fromRoomId, String toRoomId) async {
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
  Future<Result<void>> createRoom(String userId, Room room) async {
    rooms.add(room);
    controller.add(List.from(rooms));
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateRoom(String userId, Room room) async {
    final idx = rooms.indexWhere((r) => r.id == room.id);
    if (idx != -1) {
      rooms[idx] = room;
      controller.add(List.from(rooms));
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteRoom(String userId, String roomId) async {
    rooms.removeWhere((r) => r.id == roomId);
    controller.add(List.from(rooms));
    return Result.success(null);
  }
}

void main() {
  group('AddEditDevicePage (Adım 6.7) Unit & Widget Tests', () {
    late FakeDevicesRepository fakeDevicesRepo;
    late FakeRoomsRepository fakeRoomsRepo;
    late DevicesCubit devicesCubit;
    late RoomsCubit roomsCubit;
    late ThemeCubit themeCubit;

    setUp(() {
      fakeDevicesRepo = FakeDevicesRepository();
      fakeRoomsRepo = FakeRoomsRepository();

      // Seed standard rooms
      fakeRoomsRepo.rooms.addAll(SeedData.defaultRooms);
      fakeRoomsRepo.controller.add(List.from(fakeRoomsRepo.rooms));

      // Seed standard devices
      fakeDevicesRepo.devices.addAll(SeedData.defaultDevices);
      fakeDevicesRepo.controller.add(List.from(fakeDevicesRepo.devices));

      devicesCubit = DevicesCubit(devicesRepository: fakeDevicesRepo);
      roomsCubit = RoomsCubit(
        roomsRepository: fakeRoomsRepo,
        devicesRepository: fakeDevicesRepo,
      );
      themeCubit = ThemeCubit();

      devicesCubit.loadDevices('test-user');
      roomsCubit.loadRooms('test-user');
    });

    tearDown(() {
      devicesCubit.close();
      roomsCubit.close();
      themeCubit.close();
    });

    Widget createTestApp({
      bool isEditing = false,
      DeviceModel? device,
      String? initialRoom,
      String? deviceId,
    }) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<DevicesCubit>.value(value: devicesCubit),
          BlocProvider<RoomsCubit>.value(value: roomsCubit),
          BlocProvider<ThemeCubit>.value(value: themeCubit),
        ],
        child: MaterialApp(
          home: AddEditDevicePage(
            isEditing: isEditing,
            device: device,
            initialRoom: initialRoom,
            deviceId: deviceId,
          ),
        ),
      );
    }

    testWidgets('renders correctly in Add Mode by default with all sections', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp(initialRoom: 'Salon'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Title & Mode Switcher
      expect(find.text('Yeni Cihaz Ekle'), findsWidgets);
      expect(find.text('Cihazı Düzenle'), findsOneWidget);

      // Smart Pairing Banner
      expect(find.text('SANAL EŞLEŞTİRME'), findsOneWidget);
      expect(find.text('Sanal Cihaz Arama & Eşleştirme'), findsOneWidget);

      // Cihaz Adı Input
      expect(find.text('Cihaz Adı'), findsOneWidget);
      expect(find.byType(NestoraInput), findsOneWidget);

      // Device Type Buttons
      expect(find.text('Ampul'), findsOneWidget);
      expect(find.text('Priz'), findsOneWidget);
      expect(find.text('Klima'), findsOneWidget);
      expect(find.text('Fan'), findsOneWidget);
      expect(find.text('TV'), findsOneWidget);
      expect(find.text('Güvenlik'), findsOneWidget);

      // Dynamic Hardware Settings for Bulb (default)
      expect(find.text('Özel Donanım Ayarları'), findsOneWidget);
      expect(find.text('Parlaklık Düzeyi'), findsOneWidget);
      expect(find.text('Işık Rengi & Atmosfer'), findsOneWidget);

      // Room Selector
      expect(find.text('Oda Seç'), findsOneWidget);
      expect(find.text('Salon'), findsWidgets);

      // Favorite & Power Switchers
      expect(find.text('Favorilere Ekle'), findsOneWidget);
      expect(find.text('Başlangıç Durumu'), findsOneWidget);
      expect(find.text('Açık'), findsOneWidget);
      expect(find.text('Kapalı'), findsOneWidget);

      // Submit Button
      expect(find.widgetWithText(NestoraButton, 'Cihazı Ekle'), findsOneWidget);

      // Delete button must NOT exist in Add Mode
      expect(find.text('Cihazı Sil'), findsNothing);
    });

    testWidgets('form validation shows error when submitting empty device name', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Ensure name input is empty
      await tester.enterText(find.byType(NestoraInput), '');
      await tester.pump();

      // Tap 'Cihazı Ekle'
      await tester.tap(find.widgetWithText(NestoraButton, 'Cihazı Ekle'));
      await tester.pump();

      // Expect validation error
      expect(find.text('Lütfen cihaz adını giriniz.'), findsWidgets);
    });

    testWidgets('successfully creates and adds a new device entity to DevicesCubit', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final initialDeviceCount = fakeDevicesRepo.devices.length;

      // Enter device name
      await tester.enterText(find.byType(NestoraInput), 'Koridor Lambası');
      await tester.pump();

      // Select 'Yatak Odası' room
      await tester.tap(find.text('Yatak Odası').first);
      await tester.pump();

      // Tap submit button
      await tester.tap(find.widgetWithText(NestoraButton, 'Cihazı Ekle'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(fakeDevicesRepo.devices.length, equals(initialDeviceCount + 1));
      final newDev = fakeDevicesRepo.devices.firstWhere((d) => d.name == 'Koridor Lambası');
      expect(newDev.type, equals(DeviceType.bulb));
      expect(newDev.roomId, equals('room-2'));
    });

    testWidgets('smart pairing simulation scans network and populates form from discovered device', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Smart Pairing card
      await tester.tap(find.text('Sanal Cihaz Arama & Eşleştirme'));
      await tester.pump();
      // Wait for simulated scan timer
      await tester.pump(const Duration(milliseconds: 1000));

      // Discovered devices list appears
      expect(find.text('Keşfedilen Cihazlar'), findsOneWidget);
      expect(find.text('Nestora Inverter Klima'), findsOneWidget);

      // Tap 'Nestora Inverter Klima'
      await tester.tap(find.text('Nestora Inverter Klima'));
      await tester.pump();

      // Verify form auto-populated with AC settings
      final input = tester.widget<TextField>(find.descendant(
        of: find.byType(NestoraInput),
        matching: find.byType(TextField),
      ));
      expect(input.controller?.text, equals('Nestora Inverter Klima'));

      // Dynamic Hardware Panel switched to AC
      expect(find.text('Hedef Sıcaklık'), findsOneWidget);
      expect(find.text('Çalışma Modu'), findsOneWidget);
      expect(find.text('22.0°C'), findsOneWidget);
    });

    testWidgets('switching device types updates dynamic hardware settings panel', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 'Priz'
      await tester.tap(find.text('Priz'));
      await tester.pump();
      expect(find.text('Enerji Tasarruf Rölesi'), findsOneWidget);

      // Tap 'Fan'
      await tester.tap(find.text('Fan'));
      await tester.pump();
      expect(find.text('Hız Kademesi'), findsOneWidget);
      expect(find.text('Hafif'), findsOneWidget);

      // Tap 'TV'
      await tester.tap(find.text('TV'));
      await tester.pump();
      expect(find.text('Ses & Görüntü Modu'), findsOneWidget);
      expect(find.text('Sinema'), findsOneWidget);

      // Tap 'Güvenlik'
      await tester.tap(find.text('Güvenlik'));
      await tester.pump();
      expect(find.text('Hareket Algılama & Gece Görüşü'), findsOneWidget);
    });

    testWidgets('renders in Edit Mode with existing device values and delete button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final targetDev = SeedData.defaultDeviceModels.first;

      await tester.pumpWidget(createTestApp(
        device: targetDev,
        isEditing: true,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Title shows 'Cihazı Düzenle'
      expect(find.text('Cihazı Düzenle'), findsWidgets);

      // Name pre-filled
      final input = tester.widget<TextField>(find.descendant(
        of: find.byType(NestoraInput),
        matching: find.byType(TextField),
      ));
      expect(input.controller?.text, equals(targetDev.name));

      // Save changes button & Delete button
      expect(find.widgetWithText(NestoraButton, 'Değişiklikleri Kaydet'), findsOneWidget);
      expect(find.widgetWithText(NestoraButton, 'Cihazı Sil'), findsOneWidget);

      // Edit name and save
      await tester.enterText(find.byType(NestoraInput), 'Salon Lambası Düzenlendi');
      await tester.pump();

      await tester.tap(find.widgetWithText(NestoraButton, 'Değişiklikleri Kaydet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final updatedDev = fakeDevicesRepo.devices.firstWhere((d) => d.id == targetDev.id);
      expect(updatedDev.name, equals('Salon Lambası Düzenlendi'));
    });

    testWidgets('delete device displays confirmation dialog and triggers deletion', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final targetDev = SeedData.defaultDeviceModels.first;

      await tester.pumpWidget(createTestApp(
        device: targetDev,
        isEditing: true,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 'Cihazı Sil' button at bottom
      await tester.ensureVisible(find.widgetWithText(NestoraButton, 'Cihazı Sil'));
      await tester.tap(find.widgetWithText(NestoraButton, 'Cihazı Sil'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Confirmation dialog is displayed
      expect(find.text('"${targetDev.name}" Silinecek'), findsOneWidget);

      // Tap confirm button
      await tester.tap(find.widgetWithText(NestoraButton, 'Cihazı Sil').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeDevicesRepo.devices.any((d) => d.id == targetDev.id), isFalse);
    });
  });
}
