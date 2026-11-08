import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/core/widgets/nestora_logo.dart';
import 'package:nestora/features/auth/presentation/pages/splash_page.dart';

void main() {
  group('SplashPage Explicit Animation Choreography Tests', () {
    testWidgets('executes two-stage choreography and calls onFinish', (tester) async {
      bool finished = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SplashPage(
            onFinish: () {
              finished = true;
            },
          ),
        ),
      );

      // Verify initial frame
      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.byType(SlideTransition), findsWidgets);
      expect(find.byType(NestoraLogo), findsOneWidget);
      expect(finished, isFalse);

      // Stage 1: Advance by 800ms (within 0.0 - 0.20, logo sliding down)
      await tester.pump(const Duration(milliseconds: 800));
      expect(finished, isFalse);

      // Center Hold: Advance to 2500ms (within 0.20 - 0.80, logo at center)
      await tester.pump(const Duration(milliseconds: 1700));
      expect(finished, isFalse);

      // Stage 2: Advance to 3600ms (within 0.80 - 1.00)
      await tester.pump(const Duration(milliseconds: 1100));
      expect(finished, isFalse);

      // Advance past 4000ms to completion
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(finished, isTrue);
    });

    testWidgets('respects reduced motion and navigates immediately when disableAnimations is true', (tester) async {
      bool finished = false;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: SplashPage(
              onFinish: () {
                finished = true;
              },
            ),
          ),
        ),
      );

      // Pump single frame for post-frame callback
      await tester.pump();
      await tester.pumpAndSettle();

      expect(finished, isTrue);
    });
  });
}

