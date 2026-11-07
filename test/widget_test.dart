import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/app/app.dart';
import 'package:nestora/app/app_shell.dart';
import 'package:nestora/features/auth/presentation/pages/onboarding_page.dart';
import 'package:nestora/features/auth/presentation/pages/splash_page.dart';
import 'package:nestora/features/auth/presentation/pages/welcome_page.dart';
import 'package:nestora/features/devices/presentation/pages/devices_page.dart';
import 'package:nestora/features/home/presentation/pages/dashboard_page.dart';
import 'package:nestora/features/profile/presentation/pages/profile_page.dart';

void main() {
  testWidgets('Full End-to-End User Flow: Splash -> Onboarding -> Welcome -> AppShell/Dashboard', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const NestoraApp());

    // 1. Splash Page is visible
    expect(find.byType(SplashPage), findsOneWidget);

    // Fast forward splash timer (1800ms)
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();

    // 2. Onboarding Page is visible with Smart House & Big Headline
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.text('Evinizi Kolayca\nYönetin'), findsOneWidget);
    expect(find.text('Başla'), findsOneWidget);

    // Tap Başla / Slide to Start
    await tester.tap(find.text('Başla'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // 3. Welcome Page is visible with Watercolor Villa & Ambience badge
    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.text('Evinin dijital dünyasına hoş geldin.'), findsOneWidget);
    expect(find.text('Bağlı Ekosistem'), findsOneWidget);
    expect(find.text('24°C • Dengeli'), findsOneWidget);
    expect(find.text('Hemen Başla'), findsOneWidget);

    // Tap "Hemen Başla"
    await tester.tap(find.text('Hemen Başla'));
    await tester.pumpAndSettle();

    // 4. AppShell and DashboardPage are visible with complete layout
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(DashboardPage), findsOneWidget);
    expect(find.text('Eviniz, tek dokunuşla.'), findsOneWidget);
    expect(find.text('Bugün Tüketilen Enerji'), findsOneWidget);
    expect(find.text('Aktif Cihazlar'), findsOneWidget);

    // 5. Test Tab Navigation to Devices and Profile
    await tester.tap(find.text('Cihazlar'));
    await tester.pumpAndSettle();
    expect(find.byType(DevicesPage), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
  });
}
