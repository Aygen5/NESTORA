import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/core/widgets/nestora_logo.dart';

void main() {
  group('NestoraLogo Widget Tests', () {
    testWidgets('renders circular logo with ClipOval and asset', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: NestoraLogo(size: 64),
            ),
          ),
        ),
      );

      expect(find.byType(NestoraLogo), findsOneWidget);
      expect(find.byType(ClipOval), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders with glow effect when showGlow is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: NestoraLogo(size: 80, showGlow: true),
            ),
          ),
        ),
      );

      expect(find.byType(NestoraLogo), findsOneWidget);
      expect(find.byType(AnimatedOpacity), findsOneWidget);
    });

    testWidgets('when enableNavigation is false, no click cursor or tooltip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: NestoraLogo(size: 40, enableNavigation: false),
            ),
          ),
        ),
      );

      final clickCursorFinder = find.byWidgetPredicate(
        (w) => w is MouseRegion && w.cursor == SystemMouseCursors.click,
      );
      expect(clickCursorFinder, findsNothing);
      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('when enableNavigation is true or onTap is provided, handles tap and shows click cursor', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NestoraLogo(
                size: 48,
                enableNavigation: true,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      final clickCursorFinder = find.byWidgetPredicate(
        (w) => w is MouseRegion && w.cursor == SystemMouseCursors.click,
      );
      expect(clickCursorFinder, findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);

      await tester.tap(find.byType(NestoraLogo));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
