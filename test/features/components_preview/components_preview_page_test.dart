import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/app/app_shell.dart';
import 'package:nestora/app/theme/app_theme.dart';
import 'package:nestora/core/widgets/nestora_bottom_nav.dart';
import 'package:nestora/core/widgets/nestora_switch.dart';
import 'package:nestora/features/components_preview/presentation/pages/components_preview_page.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    home: child,
  );
}

void main() {
  group('ComponentsPreviewPage (Adım 6.10) İzolasyon ve Bileşen Testleri', () {
    testWidgets('renders isolation notice banner and section headers correctly', (tester) async {
      await tester.pumpWidget(_buildTestApp(const ComponentsPreviewPage()));
      await tester.pumpAndSettle();

      // Check title and isolation banner
      expect(find.text('Bileşen Önizleme'), findsOneWidget);
      expect(find.text('Tasarım Kontrolü & İzolasyon'), findsOneWidget);
      expect(
        find.textContaining('Bu ekran son kullanıcı navigasyonunda yer almaz'),
        findsOneWidget,
      );

      // Check section headers
      expect(find.text('1. Hızlı Cihaz Kontrolü'), findsOneWidget);
      expect(find.text('2. Ekleme Seçim Çekmecesi'), findsOneWidget);
    });

    testWidgets('interactive demo controls respond to user interaction', (tester) async {
      await tester.pumpWidget(_buildTestApp(const ComponentsPreviewPage()));
      await tester.pumpAndSettle();

      // Verify NestoraSwitch presence and interaction
      final switchFinder = find.byType(NestoraSwitch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Verify slider presence and interaction
      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);
      await tester.tap(sliderFinder);
      await tester.pumpAndSettle();
    });

    testWidgets('back button operates safely', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ComponentsPreviewPage()),
                  );
                },
                child: const Text('Open Preview'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Preview'));
      await tester.pumpAndSettle();

      expect(find.byType(ComponentsPreviewPage), findsOneWidget);

      // Tap back button
      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(ComponentsPreviewPage), findsNothing);
      expect(find.text('Open Preview'), findsOneWidget);
    });

    testWidgets('NestoraBottomNav strictly contains 4 main items (Ana Sayfa, Odalar, Cihazlar, Profil) and excludes ComponentsPreview', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          Scaffold(
            bottomNavigationBar: NestoraBottomNav(
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure the 4 user-facing tabs exist
      expect(find.text('Ana Sayfa'), findsOneWidget);
      expect(find.text('Odalar'), findsOneWidget);
      expect(find.text('Cihazlar'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);

      // Verify no preview or dev items are exposed in user navigation
      expect(find.text('Bileşenler'), findsNothing);
      expect(find.text('Önizleme'), findsNothing);
      expect(find.text('Preview'), findsNothing);
    });

    testWidgets('AppShell debug floating action button is completely removed (Faz 2.3)', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const AppShell(
            child: SizedBox(key: Key('shell_child')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In accordance with Faz 2.3, FAB and 16 Ekran Galerisi are permanently removed
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('16 Ekran Galerisi'), findsNothing);
    });
  });
}
