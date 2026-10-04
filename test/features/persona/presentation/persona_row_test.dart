import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/theme/app_colors.dart';
import 'package:spookymoove/core/theme/app_dimens.dart';
import 'package:spookymoove/features/persona/domain/persona_tier.dart';
import 'package:spookymoove/features/persona/presentation/widgets/persona_row.dart';

Future<void> pumpRow(
  WidgetTester tester, {
  double width = 360,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, 200);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: Column(children: [PersonaRow()])),
      ),
    ),
  );
}

Finder _key(PersonaTier tier) => find.byKey(PersonaRow.tierKey(tier));

BoxDecoration _decoration(WidgetTester tester, PersonaTier tier) =>
    tester
            .widget<DecoratedBox>(
              find.descendant(
                of: _key(tier),
                matching: find.byType(DecoratedBox),
              ),
            )
            .decoration
        as BoxDecoration;

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  testWidgets('shows the 7 tiers in order, none selected', (tester) async {
    await pumpRow(tester);

    final lefts = [
      for (final tier in PersonaTier.values) tester.getRect(_key(tier)).left,
    ];
    expect(lefts, [...lefts]..sort());
    for (final tier in PersonaTier.values) {
      expect(
        find.descendant(of: _key(tier), matching: find.text(tier.emoji)),
        findsOneWidget,
      );
      expect(_decoration(tester, tier).color, AppColors.keyNormal);
    }
  });

  testWidgets('a tap makes that tier the only amber key', (tester) async {
    await pumpRow(tester);

    await tester.tap(_key(PersonaTier.soft));
    await tester.pump();
    await tester.tap(_key(PersonaTier.baby));
    await tester.pump();

    for (final tier in PersonaTier.values) {
      expect(
        _decoration(tester, tier).color,
        tier == PersonaTier.baby ? AppColors.accentActive : AppColors.keyNormal,
        reason: tier.label,
      );
    }
  });

  testWidgets('keys use only flat design tokens', (tester) async {
    await pumpRow(tester);

    for (final tier in PersonaTier.values) {
      final decoration = _decoration(tester, tier);
      expect(decoration.boxShadow, isNull);
      expect(decoration.gradient, isNull);
      expect(
        decoration.borderRadius,
        const BorderRadius.all(Radius.circular(AppDimens.radius)),
      );
    }
    expect(find.byType(InkWell), findsNothing);
    expect(find.byType(AnimatedContainer), findsNothing);
  });

  testWidgets('screen readers get the tier name and selected state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpRow(tester);
    await tester.tap(_key(PersonaTier.god));
    await tester.pump();

    expect(
      tester.getSemantics(_key(PersonaTier.god)),
      matchesSemantics(
        label: 'God',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(_key(PersonaTier.baby)),
      matchesSemantics(
        label: 'Baby',
        isButton: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('keys are at least 44 x 48 dp on a 360 dp screen', (
    tester,
  ) async {
    await pumpRow(tester);

    Rect? previous;
    for (final tier in PersonaTier.values) {
      final rect = tester.getRect(_key(tier));
      expect(rect.width, greaterThanOrEqualTo(44), reason: tier.label);
      expect(
        rect.height,
        greaterThanOrEqualTo(AppDimens.minKeyHeight),
        reason: tier.label,
      );
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(360));
      if (previous != null) {
        expect(rect.left, greaterThanOrEqualTo(previous.right));
      }
      previous = rect;
    }
  });

  for (final (width, textScale) in [(360.0, 2.0), (320.0, 1.0), (320.0, 2.0)]) {
    testWidgets('no overflow at $width dp, text scale $textScale', (
      tester,
    ) async {
      await pumpRow(tester, width: width, textScale: textScale);
      expect(tester.takeException(), isNull);
    });
  }
}
