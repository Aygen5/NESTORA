import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nestora/app/theme/app_theme.dart';
import 'package:nestora/core/widgets/nestora_bottom_nav.dart';
import 'package:nestora/features/auth/presentation/pages/login_page.dart';
import 'package:nestora/features/components_preview/presentation/pages/components_preview_page.dart';

Widget _buildResponsiveApp(Widget child, {Size screenSize = const Size(390, 844)}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    home: MediaQuery(
      data: MediaQueryData(
        size: screenSize,
        devicePixelRatio: 1.0,
      ),
      child: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Faz 7.3: Responsive & Web Uyumluluğu Testleri', () {
    testWidgets('Mobil (360px) küçük ekran: Formlar taşmasız render edilir', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildResponsiveApp(
        const LoginPage(),
        screenSize: const Size(360, 640),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsWidgets);
      // Zero overflow check: no FlutterError caught
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tablet (768px): Form ve gezinme düzeni dengeli kalır', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildResponsiveApp(
        const LoginPage(),
        screenSize: const Size(768, 1024),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      final constrainedBoxFinder = find.byType(ConstrainedBox);
      expect(constrainedBoxFinder, findsWidgets);

      // Verify that auth form has maxWidth: 480 and does not stretch beyond 480px
      bool foundMax480 = false;
      for (final element in constrainedBoxFinder.evaluate()) {
        final widget = element.widget as ConstrainedBox;
        if (widget.constraints.maxWidth == 480) {
          foundMax480 = true;
          final renderBox = tester.renderObject(find.byWidget(widget)) as RenderBox;
          expect(renderBox.size.width, lessThanOrEqualTo(480));
          break;
        }
      }
      expect(foundMax480, isTrue);
    });

    testWidgets('Geniş Masaüstü (1440px): maxWidth sınırlayıcısı içerik yayılmasını önler', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildResponsiveApp(
        const ComponentsPreviewPage(),
        screenSize: const Size(1440, 900),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ComponentsPreviewPage), findsOneWidget);

      final constrainedBoxes = find.byType(ConstrainedBox);
      expect(constrainedBoxes, findsWidgets);

      // Find the root maxWidth: 820 container
      bool foundMax820 = false;
      for (final element in constrainedBoxes.evaluate()) {
        final widget = element.widget as ConstrainedBox;
        if (widget.constraints.maxWidth == 820) {
          foundMax820 = true;
          break;
        }
      }
      expect(foundMax820, isTrue, reason: 'Geniş ekranda içerik maxWidth: 820 ile sınırlandırılmalıdır');
    });

    testWidgets('NestoraBottomNav geniş ekranda sınırlı genişlikle ortalanır', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildResponsiveApp(
        Scaffold(
          bottomNavigationBar: NestoraBottomNav(
            currentIndex: 0,
            onTap: (_) {},
          ),
        ),
        screenSize: const Size(1440, 900),
      ));
      await tester.pumpAndSettle();

      final navConstrained = find.descendant(
        of: find.byType(NestoraBottomNav),
        matching: find.byType(ConstrainedBox),
      );
      expect(navConstrained, findsWidgets);

      bool foundNavMax820 = false;
      for (final element in navConstrained.evaluate()) {
        final widget = element.widget as ConstrainedBox;
        if (widget.constraints.maxWidth == 820) {
          foundNavMax820 = true;
          final renderBox = tester.renderObject(find.byWidget(widget)) as RenderBox;
          expect(renderBox.size.width, lessThanOrEqualTo(820));
          break;
        }
      }
      expect(foundNavMax820, isTrue);
    });

    testWidgets('Form Scaffold resizeToAvoidBottomInset yapılandırması etkindir', (tester) async {
      await tester.pumpWidget(_buildResponsiveApp(const LoginPage()));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.resizeToAvoidBottomInset, isTrue);
    });
  });
}
