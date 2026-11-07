import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/app/app.dart';
import 'package:nestora/app/router/app_router.dart';
import 'package:nestora/features/auth/presentation/pages/welcome_page.dart';
import 'package:nestora/features/home/presentation/pages/dashboard_page.dart';

Widget _buildGuardedApp({
  required String initialLocation,
  required AppAuthListenable authListenable,
}) {
  final router = createAppRouter(
    initialLocation: initialLocation,
    authListenable: authListenable,
  );

  return NestoraApp(router: router);
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('defaultRedirectGuard Unit Tests', () {
    test('Unauthenticated user is allowed on public auth & entry routes', () {
      expect(
        defaultRedirectGuard(location: AppRoutePaths.splash, isAuthenticated: false),
        isNull,
      );
      expect(
        defaultRedirectGuard(location: AppRoutePaths.onboarding, isAuthenticated: false),
        isNull,
      );
      expect(
        defaultRedirectGuard(location: AppRoutePaths.welcome, isAuthenticated: false),
        isNull,
      );
      expect(
        defaultRedirectGuard(location: AppRoutePaths.login, isAuthenticated: false),
        isNull,
      );
      expect(
        defaultRedirectGuard(location: AppRoutePaths.register, isAuthenticated: false),
        isNull,
      );
      expect(
        defaultRedirectGuard(location: AppRoutePaths.forgotPassword, isAuthenticated: false),
        isNull,
      );
      expect(
        defaultRedirectGuard(location: AppRoutePaths.componentsPreview, isAuthenticated: false),
        isNull,
      );
    });

    test('Unauthenticated user is redirected to /welcome when accessing protected routes', () {
      final protectedRoutes = [
        AppRoutePaths.dashboard,
        AppRoutePaths.devices,
        AppRoutePaths.profile,
        AppRoutePaths.rooms,
        '/rooms/room-1',
        AppRoutePaths.addEditRoom,
        '/devices/lamp/device-1',
        '/devices/climate/device-2',
        AppRoutePaths.addEditDevice,
        AppRoutePaths.notifications,
      ];

      for (final route in protectedRoutes) {
        expect(
          defaultRedirectGuard(location: route, isAuthenticated: false),
          equals(AppRoutePaths.welcome),
          reason: 'Expected $route to redirect unauthenticated user to /welcome',
        );
      }
    });

    test('Authenticated user is redirected to /dashboard when accessing login/welcome/register', () {
      final authRoutes = [
        AppRoutePaths.welcome,
        AppRoutePaths.login,
        AppRoutePaths.register,
        AppRoutePaths.forgotPassword,
      ];

      for (final route in authRoutes) {
        expect(
          defaultRedirectGuard(location: route, isAuthenticated: true),
          equals(AppRoutePaths.dashboard),
          reason: 'Expected authenticated user on $route to redirect to /dashboard',
        );
      }
    });

    test('Authenticated user is allowed on protected routes', () {
      final allowedRoutes = [
        AppRoutePaths.dashboard,
        AppRoutePaths.devices,
        AppRoutePaths.profile,
        AppRoutePaths.rooms,
        '/rooms/room-1',
        AppRoutePaths.addEditRoom,
        AppRoutePaths.notifications,
      ];

      for (final route in allowedRoutes) {
        expect(
          defaultRedirectGuard(location: route, isAuthenticated: true),
          isNull,
        );
      }
    });
  });

  group('AppAuthListenable Unit Tests', () {
    test('notifies listeners when auth status toggles', () {
      final authListenable = AppAuthListenable(initialAuthState: false);
      int notificationCount = 0;
      authListenable.addListener(() => notificationCount++);

      expect(authListenable.isAuthenticated, isFalse);

      authListenable.setAuthenticated(true);
      expect(authListenable.isAuthenticated, isTrue);
      expect(notificationCount, equals(1));

      // Same value should not trigger redundant notification
      authListenable.setAuthenticated(true);
      expect(notificationCount, equals(1));

      authListenable.setAuthenticated(false);
      expect(authListenable.isAuthenticated, isFalse);
      expect(notificationCount, equals(2));

      authListenable.dispose();
    });
  });

  group('GoRouter Redirect Integration Widget Tests', () {
    testWidgets('Unauthenticated user requesting /dashboard is redirected to WelcomePage', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authListenable = AppAuthListenable(initialAuthState: false);

      await tester.pumpWidget(
        _buildGuardedApp(
          initialLocation: AppRoutePaths.dashboard,
          authListenable: authListenable,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WelcomePage), findsOneWidget);
      expect(find.byType(DashboardPage), findsNothing);
    });

    testWidgets('Authenticated user requesting /login is redirected to DashboardPage', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authListenable = AppAuthListenable(initialAuthState: true);

      await tester.pumpWidget(
        _buildGuardedApp(
          initialLocation: AppRoutePaths.login,
          authListenable: authListenable,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DashboardPage), findsOneWidget);
    });

    testWidgets('Dynamic auth change from unauthenticated to authenticated redirects to /dashboard', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authListenable = AppAuthListenable(initialAuthState: false);

      await tester.pumpWidget(
        _buildGuardedApp(
          initialLocation: AppRoutePaths.welcome,
          authListenable: authListenable,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WelcomePage), findsOneWidget);

      // Simulate successful login event
      authListenable.setAuthenticated(true);
      await tester.pumpAndSettle();

      expect(find.byType(DashboardPage), findsOneWidget);
    });

    testWidgets('Dynamic auth change from authenticated to unauthenticated redirects to /welcome', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authListenable = AppAuthListenable(initialAuthState: true);

      await tester.pumpWidget(
        _buildGuardedApp(
          initialLocation: AppRoutePaths.dashboard,
          authListenable: authListenable,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DashboardPage), findsOneWidget);

      // Simulate logout event
      authListenable.setAuthenticated(false);
      await tester.pumpAndSettle();

      expect(find.byType(WelcomePage), findsOneWidget);
      expect(find.byType(DashboardPage), findsNothing);
    });
  });
}

