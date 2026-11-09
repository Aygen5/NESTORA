import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/app/theme/theme_cubit.dart';
import 'package:nestora/core/constants/seed_data.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/features/devices/domain/entities/device.dart';
import 'package:nestora/features/devices/domain/repositories/devices_repository.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_cubit.dart';
import 'package:nestora/features/devices/presentation/cubit/devices_state.dart';
import 'package:nestora/features/devices/presentation/pages/security_camera_control_page.dart';
import 'package:nestora/features/notifications/domain/entities/app_notification.dart';
import 'package:nestora/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:nestora/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:nestora/features/notifications/presentation/cubit/notifications_state.dart';

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
      final current = devices[idx];
      devices[idx] = current.copyWith(
        isPoweredOn: (stateFields['isPoweredOn'] ?? stateFields['isOn']) as bool? ?? current.isPoweredOn,
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

class FakeNotificationsRepo implements NotificationsRepository {
  final List<AppNotification> notifs = [];

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) => Stream.value(notifs);

  @override
  Future<Result<List<AppNotification>>> getNotifications(String userId) async => Result.success(notifs);

  @override
  Future<Result<void>> createNotification(String userId, AppNotification notification) async {
    notifs.insert(0, notification);
    return Result.success(null);
  }

  @override
  Future<Result<void>> markAsRead(String userId, String notificationId) async => Result.success(null);

  @override
  Future<Result<void>> markAllAsRead(String userId) async => Result.success(null);

  @override
  Future<Result<void>> deleteNotification(String userId, String notificationId) async => Result.success(null);
}

void main() {
  group('SecurityCameraControlPage Widget & Integration Tests', () {
    late FakeDevicesRepo fakeDevicesRepo;
    late DevicesCubit devicesCubit;
    late FakeNotificationsRepo fakeNotificationsRepo;
    late NotificationsCubit notificationsCubit;
    late ThemeCubit themeCubit;

    setUp(() {
      fakeDevicesRepo = FakeDevicesRepo();
      fakeDevicesRepo.devices.addAll(SeedData.defaultDevices);

      devicesCubit = DevicesCubit(devicesRepository: fakeDevicesRepo);
      fakeNotificationsRepo = FakeNotificationsRepo();
      notificationsCubit = NotificationsCubit(notificationsRepository: fakeNotificationsRepo);
      notificationsCubit.emit(NotificationsLoaded(notifications: SeedData.defaultNotifications));

      themeCubit = ThemeCubit();

      devicesCubit.emit(
        DevicesLoaded(devices: SeedData.defaultDevices),
      );
    });

    tearDown(() {
      devicesCubit.close();
      notificationsCubit.close();
      themeCubit.close();
    });

    Widget createTestApp({String? deviceId}) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<DevicesCubit>.value(value: devicesCubit),
          BlocProvider<NotificationsCubit>.value(value: notificationsCubit),
          BlocProvider<ThemeCubit>.value(value: themeCubit),
        ],
        child: MaterialApp(
          home: SecurityCameraControlPage(deviceId: deviceId ?? 'dev-8'),
        ),
      );
    }

    testWidgets('renders all camera HUD elements, status bar, and PTZ controllers', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Title & Room metadata
      expect(find.text('Giriş Güvenlik Kamerası'), findsWidgets);
      expect(find.text('CANLI'), findsOneWidget);
      expect(find.text('1080p • 30fps'), findsOneWidget);

      // PTZ D-pad and Direction Buttons
      expect(find.text('PTZ Motor Kontrolü'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_right_rounded), findsOneWidget);

      // Quick action toolbar
      expect(find.text('Fotoğraf'), findsOneWidget);
      expect(find.text('Konuş'), findsOneWidget);
      expect(find.text('Gece Görüşü'), findsOneWidget);
      expect(find.text('Hareket'), findsOneWidget);
      expect(find.text('Siren'), findsOneWidget);
    });

    testWidgets('PTZ direction buttons adjust pan and tilt angles', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Initial Pan: 0, Tilt: 15
      expect(find.text('P: 0° / T: 15°'), findsOneWidget);

      // Scroll to PTZ controller
      final rightButton = find.byIcon(Icons.keyboard_arrow_right_rounded);
      await tester.ensureVisible(rightButton);
      await tester.pumpAndSettle();

      // Tap Right button
      await tester.tap(rightButton);
      await tester.pumpAndSettle();
      expect(find.text('P: 15° / T: 15°'), findsOneWidget);

      // Tap Up button
      final upButton = find.byIcon(Icons.keyboard_arrow_up_rounded);
      await tester.tap(upButton);
      await tester.pumpAndSettle();
      expect(find.text('P: 15° / T: 25°'), findsOneWidget);

      // Tap Center Home button ('0°') to reset
      await tester.tap(find.text('0°'));
      await tester.pumpAndSettle();
      expect(find.text('P: 0° / T: 15°'), findsOneWidget);
    });

    testWidgets('Night vision switch toggles infrared filter display', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Initially night vision HUD badge is off
      expect(find.text('GECE GÖRÜŞÜ'), findsNothing);

      // Tap Gece Görüşü action button in toolbar
      await tester.tap(find.text('Gece Görüşü'));
      await tester.pumpAndSettle();

      // Now GECE GÖRÜŞÜ HUD badge is rendered
      expect(find.text('GECE GÖRÜŞÜ'), findsOneWidget);
    });

    testWidgets('Power toggle turns camera off and updates DevicesCubit', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap master power switch in AppBar
      final powerButton = find.byTooltip('Kamerayı Kapat');
      expect(powerButton, findsOneWidget);

      await tester.tap(powerButton);
      await tester.pumpAndSettle();

      // Device in cubit is now powered off
      final state = devicesCubit.state as DevicesLoaded;
      final dev8 = state.devices.firstWhere((d) => d.id == 'dev-8');
      expect(dev8.isPoweredOn, isFalse);

      // Offline banner is displayed
      expect(find.text('Kamera Kapalı (Gizlilik Modu)'), findsWidgets);
      expect(find.text('Akışı Başlat'), findsOneWidget);
    });
  });
}
