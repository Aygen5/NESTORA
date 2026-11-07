import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestora/app/theme/theme_cubit.dart';
import 'package:nestora/core/constants/seed_data.dart';
import 'package:nestora/core/utils/result.dart';
import 'package:nestora/core/widgets/nestora_button.dart';
import 'package:nestora/features/notifications/domain/entities/app_notification.dart';
import 'package:nestora/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:nestora/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:nestora/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:nestora/features/notifications/presentation/pages/notifications_page.dart';

class FakeNotificationsRepository implements NotificationsRepository {
  final List<AppNotification> notifications = [];
  final StreamController<List<AppNotification>> controller =
      StreamController<List<AppNotification>>.broadcast();

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) async* {
    yield List.from(notifications);
    yield* controller.stream;
  }

  @override
  Future<Result<List<AppNotification>>> getNotifications(String userId) async =>
      Result.success(notifications);

  @override
  Future<Result<void>> markAsRead(String userId, String notificationId) async {
    final idx = notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      notifications[idx] = notifications[idx].copyWith(isRead: true);
      controller.add(List.from(notifications));
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> markAllAsRead(String userId) async {
    for (int i = 0; i < notifications.length; i++) {
      notifications[i] = notifications[i].copyWith(isRead: true);
    }
    controller.add(List.from(notifications));
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteNotification(String userId, String notificationId) async {
    notifications.removeWhere((n) => n.id == notificationId);
    controller.add(List.from(notifications));
    return Result.success(null);
  }

  @override
  Future<Result<void>> createNotification(
      String userId, AppNotification notification) async {
    notifications.insert(0, notification);
    controller.add(List.from(notifications));
    return Result.success(null);
  }
}

void main() {
  group('NotificationsPage (Adım 6.8) Unit & Widget Tests', () {
    late FakeNotificationsRepository fakeNotificationsRepo;
    late NotificationsCubit notificationsCubit;
    late ThemeCubit themeCubit;
    late GoRouter testRouter;

    setUp(() {
      fakeNotificationsRepo = FakeNotificationsRepository();
      fakeNotificationsRepo.notifications.addAll(SeedData.defaultNotifications);
      fakeNotificationsRepo.controller.add(List.from(fakeNotificationsRepo.notifications));

      notificationsCubit = NotificationsCubit(notificationsRepository: fakeNotificationsRepo);
      themeCubit = ThemeCubit();

      notificationsCubit.loadNotifications('test-user');

      testRouter = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsPage(),
          ),
          GoRoute(
            path: '/devices/climate/:deviceId',
            builder: (context, state) => Scaffold(
              body: Text('Climate Route: ${state.pathParameters['deviceId']}'),
            ),
          ),
          GoRoute(
            path: '/devices/lamp/:deviceId',
            builder: (context, state) => Scaffold(
              body: Text('Lamp Route: ${state.pathParameters['deviceId']}'),
            ),
          ),
          GoRoute(
            path: '/rooms/:roomId',
            builder: (context, state) => Scaffold(
              body: Text('Room Route: ${state.pathParameters['roomId']}'),
            ),
          ),
          GoRoute(
            path: '/devices',
            builder: (context, state) => const Scaffold(
              body: Text('Devices Page Route'),
            ),
          ),
          GoRoute(
            path: '/rooms',
            builder: (context, state) => const Scaffold(
              body: Text('Rooms Page Route'),
            ),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const Scaffold(
              body: Text('Dashboard Route'),
            ),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const Scaffold(
              body: Text('Profile Route'),
            ),
          ),
        ],
      );
    });

    tearDown(() {
      notificationsCubit.close();
      themeCubit.close();
      testRouter.dispose();
    });

    Widget createTestApp() {
      return MultiBlocProvider(
        providers: [
          BlocProvider<NotificationsCubit>.value(value: notificationsCubit),
          BlocProvider<ThemeCubit>.value(value: themeCubit),
        ],
        child: MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
    }

    testWidgets('renders notifications grouped by date (Bugün, Dün, Geçen Hafta)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // App bar & status
      expect(find.text('Bildirimler'), findsOneWidget);
      expect(find.text('3 Okunmamış Bildirim'), findsOneWidget);
      expect(find.text('Tümünü Okundu İşaretle'), findsOneWidget);

      // Date Group Headers
      expect(find.text('BUGÜN'), findsOneWidget);
      expect(find.text('DÜN'), findsOneWidget);
      expect(find.text('GEÇEN HAFTA'), findsOneWidget);

      // Notification titles inside groups
      expect(find.text('Salon Lambası açıldı.'), findsOneWidget);
      expect(find.text('Masa Lambası parlaklığı %85 olarak değiştirildi.'), findsOneWidget);
      expect(find.text('Yeni cihaz eklendi.'), findsOneWidget);
      expect(find.text('Yatak Odası Kliması için sıcaklık hedefi güncellendi.'), findsOneWidget);
      expect(find.text('Yeni oda oluşturuldu.'), findsOneWidget);
      expect(find.text('Sanal güvenlik kontrolü tamamlandı.'), findsOneWidget);
      expect(find.text('Haftalık enerji özeti hazırlandı.'), findsOneWidget);

      // Ambient insight card
      expect(find.text('Doğal Yaşam Ritmi'), findsOneWidget);
    });

    testWidgets('tapping "Tümünü Okundu İşaretle" marks all unread notifications as read', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('3 Okunmamış Bildirim'), findsOneWidget);

      // Tap 'Tümünü Okundu İşaretle'
      await tester.tap(find.text('Tümünü Okundu İşaretle'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Status chip updates to 'Tüm Bildirimler Okundu'
      expect(find.text('Tüm Bildirimler Okundu'), findsOneWidget);
      final state = notificationsCubit.state as NotificationsLoaded;
      expect(state.unreadCount, equals(0));
    });

    testWidgets('tapping lamp notification triggers smart navigation to lamp control', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 'Salon Lambası açıldı.' notification
      await tester.tap(find.text('Salon Lambası açıldı.'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Navigated to Lamp Route
      expect(find.text('Lamp Route: dev-1'), findsOneWidget);
    });

    testWidgets('tapping climate notification triggers smart navigation to climate control', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 'Yeni cihaz eklendi.' (related to dev-5 Yatak Odası Kliması)
      await tester.tap(find.text('Yeni cihaz eklendi.'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Navigated to Climate Route
      expect(find.text('Climate Route: dev-5'), findsOneWidget);
    });

    testWidgets('tapping room notification triggers smart navigation to room detail', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 'Yeni oda oluşturuldu.' (related to room-4)
      await tester.tap(find.text('Yeni oda oluşturuldu.'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Navigated to Room Route
      expect(find.text('Room Route: room-4'), findsOneWidget);
    });

    testWidgets('deleting a single notification removes it from list and cubit', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final initialCount = fakeNotificationsRepo.notifications.length;
      expect(find.text('Salon Lambası açıldı.'), findsOneWidget);

      // Tap trailing delete icon on first card
      final deleteIconFinder = find.byIcon(Icons.close_rounded).first;
      await tester.tap(deleteIconFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeNotificationsRepo.notifications.length, equals(initialCount - 1));
      expect(find.text('Salon Lambası açıldı.'), findsNothing);
    });

    testWidgets('tapping clear all button displays confirmation dialog and deletes all notifications', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap clear all action button in AppBar
      await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Confirmation dialog is shown
      expect(find.text('Tüm Bildirimler Silinecek'), findsOneWidget);

      // Tap 'Tümünü Temizle' inside dialog
      await tester.tap(find.widgetWithText(NestoraButton, 'Tümünü Temizle'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // All notifications deleted
      expect(fakeNotificationsRepo.notifications, isEmpty);

      // Empty State appears
      expect(find.text('Henüz bildirimin yok.'), findsOneWidget);
      expect(find.text('Tüm Bildirimler Okundu'), findsOneWidget);
    });
  });
}
