import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/app/app.dart';
import 'package:nestora/app/app_shell.dart';
import 'package:nestora/app/router/app_router.dart';
import 'package:nestora/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:nestora/features/auth/presentation/pages/login_page.dart';
import 'package:nestora/features/auth/presentation/pages/onboarding_page.dart';
import 'package:nestora/features/auth/presentation/pages/register_page.dart';
import 'package:nestora/features/auth/presentation/pages/splash_page.dart';
import 'package:nestora/features/auth/presentation/pages/welcome_page.dart';
import 'package:nestora/features/components_preview/presentation/pages/components_preview_page.dart';
import 'package:nestora/features/devices/presentation/pages/ac_control_page.dart';
import 'package:nestora/features/devices/presentation/pages/add_edit_device_page.dart';
import 'package:nestora/features/devices/presentation/pages/devices_page.dart';
import 'package:nestora/features/devices/presentation/pages/lamp_control_page.dart';
import 'package:nestora/features/home/presentation/pages/dashboard_page.dart';
import 'package:nestora/features/notifications/presentation/pages/notifications_page.dart';
import 'package:nestora/features/profile/presentation/pages/profile_page.dart';
import 'package:nestora/features/rooms/presentation/pages/add_edit_room_page.dart';
import 'package:nestora/features/rooms/presentation/pages/room_detail_page.dart';
import 'package:nestora/features/rooms/presentation/pages/rooms_page.dart';

Widget _buildTestApp(String initialLocation) {
  final router = createAppRouter(initialLocation: initialLocation);
  return NestoraApp(router: router);
}

void _setTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1.0;
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('GoRouter AppRoutePaths & Navigation Tests', () {
    testWidgets('renders SplashPage at /splash', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(_buildTestApp(AppRoutePaths.splash));
      await tester.pump();
      expect(find.byType(SplashPage), findsOneWidget);
    });

    testWidgets('renders OnboardingPage at /onboarding', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(_buildTestApp(AppRoutePaths.onboarding));
      await tester.pump();
      expect(find.byType(OnboardingPage), findsOneWidget);
    });

    testWidgets('renders WelcomePage at /welcome', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(_buildTestApp(AppRoutePaths.welcome));
      await tester.pump();
      expect(find.byType(WelcomePage), findsOneWidget);
    });

    testWidgets('renders LoginPage at /login', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(_buildTestApp(AppRoutePaths.login));
      await tester.pump();
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('renders RegisterPage at /register', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(_buildTestApp(AppRoutePaths.register));
      await tester.pump();
      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('renders ForgotPasswordPage at /forgot-password', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(_buildTestApp(AppRoutePaths.forgotPassword));
      await tester.pump();
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });

    testWidgets('renders DashboardPage within AppShell at /dashboard', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(_buildTestApp(AppRoutePaths.dashboard));
      await tester.pump();
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(DashboardPage), findsOneWidget);
    });

    testWidgets('renders DevicesPage within AppShell at /devices', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(_buildTestApp(AppRoutePaths.devices));
      await tester.pump();
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(DevicesPage), findsOneWidget);
    });

    testWidgets('renders ProfilePage within AppShell at /profile', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(_buildTestApp(AppRoutePaths.profile));
      await tester.pump();
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('renders RoomsPage at /rooms', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(_buildTestApp(AppRoutePaths.rooms));
      await tester.pump();
      expect(find.byType(RoomsPage), findsOneWidget);
    });

    testWidgets('renders AddEditRoomPage at /rooms/add-edit', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(_buildTestApp(AppRoutePaths.addEditRoom));
      await tester.pump();
      expect(find.byType(AddEditRoomPage), findsOneWidget);
    });

    testWidgets('renders RoomDetailPage at /rooms/room-1', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(_buildTestApp('/rooms/room-1'));
      await tester.pump();
      expect(find.byType(RoomDetailPage), findsOneWidget);
    });

    testWidgets('renders LampControlPage at /devices/lamp/device-lamp-1', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(_buildTestApp('/devices/lamp/device-lamp-1'));
      await tester.pump();
      expect(find.byType(LampControlPage), findsOneWidget);
    });

    testWidgets('renders AcControlPage at /devices/climate/device-ac-1', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(_buildTestApp('/devices/climate/device-ac-1'));
      await tester.pump();
      expect(find.byType(AcControlPage), findsOneWidget);
    });

    testWidgets('renders AddEditDevicePage at /devices/add-edit', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(_buildTestApp(AppRoutePaths.addEditDevice));
      await tester.pump();
      expect(find.byType(AddEditDevicePage), findsOneWidget);
    });

    testWidgets('renders NotificationsPage at /notifications', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(_buildTestApp(AppRoutePaths.notifications));
      await tester.pump();
      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('renders ComponentsPreviewPage at /components-preview', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(_buildTestApp(AppRoutePaths.componentsPreview));
      await tester.pump();
      expect(find.byType(ComponentsPreviewPage), findsOneWidget);
    });
  });
}
