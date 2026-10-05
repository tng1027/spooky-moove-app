import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/features/new_game/presentation/widgets/level_card.dart';
import 'package:spookymoove/features/persona/domain/persona_tier.dart';
import 'package:spookymoove/features/persona/domain/persona_tier_copy.dart';

/// The Vietnamese copy can't be selected in the app until OB-053, so its
/// layout is checked on the card directly.
void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    PersonaTier tier, {
    required double width,
    required double textScale,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.topCenter,
              child: LevelCard(tier: tier, copy: PersonaTierCopy.vietnamese),
            ),
          ),
        ),
      ),
    );
  }

  for (final width in const [320.0, 360.0]) {
    for (final textScale in const [1.0, 2.0]) {
      testWidgets('VI at $width dp, scale $textScale: no overflow, '
          'constant height', (tester) async {
        final heights = <double>{};
        for (final tier in PersonaTier.values) {
          await pumpCard(tester, tier, width: width, textScale: textScale);
          expect(tester.takeException(), isNull, reason: tier.name);
          expect(
            find.text(PersonaTierCopy.vietnamese[tier]!.name),
            findsOneWidget,
          );
          heights.add(tester.getSize(find.byType(LevelCard)).height);
        }
        expect(heights, hasLength(1));
      });
    }
  }
}
