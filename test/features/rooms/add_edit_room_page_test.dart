import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/app/theme/theme_cubit.dart';
import 'package:nestora/core/constants/seed_data.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/core/widgets/nestora_button.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/devices/domain/repositories/devices_repository.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_cubit.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_state.dart';
import 'package:nestora/features/rooms/domain/entities/room.dart';
import 'package:nestora/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_cubit.dart';
import 'package:nestora/features/rooms/presentation/cubit/rooms_state.dart';
import 'package:nestora/features/rooms/presentation/pages/add_edit_room_page.dart';

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
  Future<Result<void>> createDevice(String userId, Device device) async => Result.success(null);
  @override
  Future<Result<void>> updateDevice(String userId, Device device) async => Result.success(null);
  @override
  Future<Result<void>> updateDeviceState(String userId, String deviceId, Map<String, dynamic> stateFields) async => Result.success(null);
  @override
  Future<Result<void>> deleteDevice(String userId, String deviceId) async => Result.success(null);
  @override
  Future<Result<void>> deleteDevicesByRoom(String userId, String roomId) async => Result.success(null);
  @override
  Future<Result<void>> moveDevicesToRoom(String userId, String fromRoomId, String toRoomId) async => Result.success(null);
}

class FakeRoomsRepository implements RoomsRepository {
  final List<Room> rooms = [];
  final StreamController<List<Room>> controller = StreamController<List<Room>>.broadcast();
  Room? lastCreatedRoom;
  Room? lastUpdatedRoom;
  String? lastDeletedRoomId;

  @override
  Stream<List<Room>> watchRooms(String userId) => controller.stream;
  @override
  Future<Result<List<Room>>> getRooms(String userId) async => Result.success(rooms);
  @override
  Future<Result<Room>> getRoomById(String userId, String roomId) async =>
      Result.success(rooms.firstWhere((r) => r.id == roomId));

  @override
  Future<Result<void>> createRoom(String userId, Room room) async {
    lastCreatedRoom = room;
    rooms.add(room);
    controller.add(List.from(rooms));
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateRoom(String userId, Room room) async {
    lastUpdatedRoom = room;
    final idx = rooms.indexWhere((r) => r.id == room.id);
    if (idx != -1) {
      rooms[idx] = room;
      controller.add(List.from(rooms));
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteRoom(String userId, String roomId) async {
    lastDeletedRoomId = roomId;
    rooms.removeWhere((r) => r.id == roomId);
    controller.add(List.from(rooms));
    return Result.success(null);
  }
}

void main() {
  group('AddEditRoomPage (Adım 6.3) Unit & Widget Tests', () {
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

    testWidgets('renders create mode with all controls: inputs, temperature, icons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp(const AddEditRoomPage(isEditing: false)));
      await tester.pumpAndSettle();

      expect(find.text('Oda Ekle'), findsOneWidget);
      expect(find.text('Oda Adı'), findsOneWidget);
      expect(find.text('Varsayılan Hedef Sıcaklık'), findsOneWidget);
      expect(find.text('Oda Türü'), findsOneWidget);
      expect(find.text('Oda İkonu Seçimi'), findsOneWidget);
      expect(find.text('8 Simge'), findsOneWidget);
      expect(find.text('Odayı Oluştur'), findsOneWidget);
    });

    testWidgets('validates required room name and prevents empty submission', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp(const AddEditRoomPage(isEditing: false)));
      await tester.pumpAndSettle();

      // Clear input and tap save
      await tester.enterText(find.byType(TextField).first, '');
      await tester.ensureVisible(find.text('Odayı Oluştur'));
      await tester.tap(find.text('Odayı Oluştur'));
      await tester.pumpAndSettle();

      expect(find.text('Oda adı boş bırakılamaz.'), findsOneWidget);
      expect(fakeRoomsRepo.lastCreatedRoom, isNull);

      // Enter 1 char and tap save
      await tester.enterText(find.byType(TextField).first, 'A');
      await tester.ensureVisible(find.text('Odayı Oluştur'));
      await tester.tap(find.text('Odayı Oluştur'));
      await tester.pumpAndSettle();

      expect(find.text('Oda adı en az 2 karakter olmalıdır.'), findsOneWidget);
      expect(fakeRoomsRepo.lastCreatedRoom, isNull);
    });

    testWidgets('creates new room with custom name, temperature, and icon', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp(const AddEditRoomPage(isEditing: false)));
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(find.byType(TextField).first, 'Balkon Bahçesi');

      // Adjust temperature (+0.5°C)
      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.pumpAndSettle();

      // Select 'Balkon' icon
      await tester.tap(find.text('Balkon'));
      await tester.pumpAndSettle();

      // Tap Odayı Oluştur
      await tester.ensureVisible(find.text('Odayı Oluştur'));
      await tester.tap(find.text('Odayı Oluştur'));
      await tester.pumpAndSettle();

      expect(fakeRoomsRepo.lastCreatedRoom, isNotNull);
      expect(fakeRoomsRepo.lastCreatedRoom!.name, equals('Balkon Bahçesi'));
      expect(fakeRoomsRepo.lastCreatedRoom!.iconName, equals('deck'));
      expect(fakeRoomsRepo.lastCreatedRoom!.targetTemperature, equals(22.5));
    });

    testWidgets('renders edit mode and updates existing room data', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final existingRoom = SeedData.defaultRoomModels.first; // Salon
      await tester.pumpWidget(
        createTestApp(
          AddEditRoomPage(isEditing: true, room: existingRoom),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Odayı Düzenle'), findsOneWidget);
      expect(find.text('Değişiklikleri Kaydet'), findsOneWidget);
      expect(find.text('Odayı Sil'), findsOneWidget);

      // Edit name
      await tester.enterText(find.byType(TextField).first, 'Büyük Salon');
      await tester.ensureVisible(find.text('Değişiklikleri Kaydet'));
      await tester.tap(find.text('Değişiklikleri Kaydet'));
      await tester.pumpAndSettle();

      expect(fakeRoomsRepo.lastUpdatedRoom, isNotNull);
      expect(fakeRoomsRepo.lastUpdatedRoom!.name, equals('Büyük Salon'));
    });

    testWidgets('delete room button displays confirmation dialog and triggers deletion', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final existingRoom = SeedData.defaultRoomModels.first; // Salon
      await tester.pumpWidget(
        createTestApp(
          AddEditRoomPage(isEditing: true, room: existingRoom),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Odayı Sil' button at bottom
      await tester.ensureVisible(find.text('Odayı Sil'));
      await tester.tap(find.text('Odayı Sil'));
      await tester.pumpAndSettle();

      // Confirmation dialog is shown
      expect(find.text('"Salon" Odasını Sil'), findsOneWidget);
      expect(find.text('Bu oda silindiğinde kayıtlı 3 cihazınız silinmez; korunur ve Atanmamış Cihazlar havuzuna aktarılır.'), findsOneWidget);

      // Tap confirm button in dialog
      await tester.tap(find.widgetWithText(NestoraButton, 'Odayı Sil'));
      await tester.pumpAndSettle();

      expect(fakeRoomsRepo.lastDeletedRoomId, equals('room-1'));
    });
  });
}
