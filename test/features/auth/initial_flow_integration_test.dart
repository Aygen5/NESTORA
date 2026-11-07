import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/app/app_shell.dart';
import 'package:nestora/app/app_state.dart';
import 'package:nestora/app/di/injection.dart';
import 'package:nestora/app/router/app_router.dart';
import 'package:nestora/app/theme/theme_cubit.dart';
import 'package:nestora/core/constants/app_constants.dart';
import 'package:nestora/features/auth/presentation/pages/login_page.dart';
import 'package:nestora/features/auth/presentation/pages/onboarding_page.dart';
import 'package:nestora/features/auth/presentation/pages/splash_page.dart';
import 'package:nestora/features/auth/presentation/pages/welcome_page.dart';
import 'package:nestora/features/home/presentation/pages/dashboard_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildInitialFlowTestApp({
  required String initialLocation,
  required AppAuthListenable authListenable,
}) {
  final router = createAppRouter(
    initialLocation: initialLocation,
    authListenable: authListenable,
  );

  return BlocProvider<ThemeCubit>(
    create: (_) => ThemeCubit(),
    child: AppStateScope(
      notifier: AppState(),
      child: MaterialApp.router(
        routerConfig: router,
      ),
    ),
  );
}

void _setTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1.0;
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sl.reset();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    sl.registerSingleton<SharedPreferences>(prefs);
  });

  tearDown(() {
    sl.reset();
  });

  group('SplashPage Flow Tests', () {
    testWidgets('unauthenticated user without onboarding seen routes to OnboardingPage', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final authListenable = AppAuthListenable(initialAuthState: false);

      await tester.pumpWidget(
        _buildInitialFlowTestApp(
          initialLocation: AppRoutePaths.splash,
          authListenable: authListenable,
        ),
      );

      expect(find.byType(SplashPage), findsOneWidget);

      // Fast-forward 1800ms splash timer
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingPage), findsOneWidget);
    });

    testWidgets('unauthenticated user who previously completed onboarding routes directly to WelcomePage', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      // Set hasSeenOnboarding = true
      await sl<SharedPreferences>().setBool(AppConstants.prefHasSeenOnboarding, true);

      final authListenable = AppAuthListenable(initialAuthState: false);

      await tester.pumpWidget(
        _buildInitialFlowTestApp(
          initialLocation: AppRoutePaths.splash,
          authListenable: authListenable,
        ),
      );

      expect(find.byType(SplashPage), findsOneWidget);

      // Fast-forward 1800ms splash timer
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomePage), findsOneWidget);
    });

    testWidgets('authenticated user routes directly from Splash to DashboardPage', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final authListenable = AppAuthListenable(initialAuthState: true);

      await tester.pumpWidget(
        _buildInitialFlowTestApp(
          initialLocation: AppRoutePaths.splash,
          authListenable: authListenable,
        ),
      );

      expect(find.byType(SplashPage), findsOneWidget);

      // Fast-forward 1800ms splash timer
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(DashboardPage), findsOneWidget);
    });
  });

  group('OnboardingPage Interaction Tests', () {
    testWidgets('tapping start button navigates to WelcomePage and records prefHasSeenOnboarding', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final authListenable = AppAuthListenable(initialAuthState: false);

      await tester.pumpWidget(
        _buildInitialFlowTestApp(
          initialLocation: AppRoutePaths.onboarding,
          authListenable: authListenable,
        ),
      );

      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.text('Evinizi Kolayca\nYönetin'), findsOneWidget);
      expect(find.text('Başla'), findsOneWidget);

      // Tap Başla / Slide button
      await tester.tap(find.text('Başla'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomePage), findsOneWidget);
      expect(
        sl<SharedPreferences>().getBool(AppConstants.prefHasSeenOnboarding),
        isTrue,
      );
    });
  });

  group('WelcomePage Controls Tests', () {
    testWidgets('tapping Giriş Yap navigates to LoginPage', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final authListenable = AppAuthListenable(initialAuthState: false);

      await tester.pumpWidget(
        _buildInitialFlowTestApp(
          initialLocation: AppRoutePaths.welcome,
          authListenable: authListenable,
        ),
      );

      expect(find.byType(WelcomePage), findsOneWidget);
      expect(find.text('Evinin dijital dünyasına hoş geldin.'), findsOneWidget);
      expect(find.text('Zaten hesabın var mı? Giriş Yap'), findsOneWidget);

      await tester.tap(find.text('Zaten hesabın var mı? Giriş Yap'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('tapping Hemen Başla transitions into application', (tester) async {
      _setTestViewport(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final authListenable = AppAuthListenable(initialAuthState: false);

      await tester.pumpWidget(
        _buildInitialFlowTestApp(
          initialLocation: AppRoutePaths.welcome,
          authListenable: authListenable,
        ),
      );

      expect(find.byType(WelcomePage), findsOneWidget);
      expect(find.text('Hemen Başla'), findsOneWidget);

      await tester.tap(find.text('Hemen Başla'));
      await tester.pumpAndSettle();

      expect(find.byType(DashboardPage), findsOneWidget);
    });
  });
}
