import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nestora/app/theme/app_theme.dart';
import 'package:nestora/core/widgets/nestora_bottom_nav.dart';
import 'package:nestora/core/widgets/nestora_button.dart';
import 'package:nestora/core/widgets/nestora_switch.dart';

Widget _buildAppWithReducedMotion({
  required Widget child,
  required bool disableAnimations,
}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    home: MediaQuery(
      data: MediaQueryData(
        disableAnimations: disableAnimations,
      ),
      child: Scaffold(
        body: Center(child: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Faz 7.4: Mikro Etkileşimler ve Reduced-Motion Desteği Testleri', () {
    testWidgets('Normal modda: NestoraSwitch 200–300ms arasında (240ms) akıcı animasyon sunar', (tester) async {
      bool switchVal = false;

      await tester.pumpWidget(
        _buildAppWithReducedMotion(
          disableAnimations: false,
          child: StatefulBuilder(
            builder: (context, setState) {
              return NestoraSwitch(
                value: switchVal,
                onChanged: (v) => setState(() => switchVal = v),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final animatedContainer = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(animatedContainer.duration, const Duration(milliseconds: 240));
      expect(animatedContainer.duration.inMilliseconds, inInclusiveRange(150, 300));

      final animatedAlign = tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
      expect(animatedAlign.duration, const Duration(milliseconds: 240));

      // Toggle switch
      await tester.tap(find.byType(NestoraSwitch));
      await tester.pump(); // Start animation
      expect(switchVal, isTrue);

      await tester.pumpAndSettle(); // Complete transition
    });

    testWidgets('Reduced-Motion modunda (disableAnimations: true): NestoraSwitch animasyon süresini sıfırlar', (tester) async {
      await tester.pumpWidget(
        _buildAppWithReducedMotion(
          disableAnimations: true,
          child: const NestoraSwitch(
            value: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final animatedContainer = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(animatedContainer.duration, Duration.zero);

      final animatedAlign = tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
      expect(animatedAlign.duration, Duration.zero);
    });

    testWidgets('Normal modda: NestoraButton 150ms mikro-etkileşim ve basma ölçeklemesi uygular', (tester) async {
      await tester.pumpWidget(
        _buildAppWithReducedMotion(
          disableAnimations: false,
          child: NestoraButton(
            text: 'Test Buton',
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final animatedScale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(animatedScale.duration, const Duration(milliseconds: 150));
      expect(animatedScale.scale, 1.0);
    });

    testWidgets('Reduced-Motion modunda: NestoraButton animasyon süresini sıfırlar', (tester) async {
      await tester.pumpWidget(
        _buildAppWithReducedMotion(
          disableAnimations: true,
          child: NestoraButton(
            text: 'Test Buton',
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final animatedScale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(animatedScale.duration, Duration.zero);
      expect(animatedScale.scale, 1.0);
    });

    testWidgets('NestoraBottomNav reduced-motion modunda animasyonu anında tamamlar', (tester) async {
      await tester.pumpWidget(
        _buildAppWithReducedMotion(
          disableAnimations: true,
          child: NestoraBottomNav(
            currentIndex: 0,
            onTap: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final animatedContainers = find.descendant(
        of: find.byType(NestoraBottomNav),
        matching: find.byType(AnimatedContainer),
      );
      expect(animatedContainers, findsWidgets);

      final firstContainer = tester.widget<AnimatedContainer>(animatedContainers.first);
      expect(firstContainer.duration, Duration.zero);
    });
  });
}
