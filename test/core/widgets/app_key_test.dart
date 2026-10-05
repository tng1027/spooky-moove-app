import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/theme/app_colors.dart';
import 'package:spookymoove/core/theme/app_dimens.dart';
import 'package:spookymoove/core/widgets/app_block.dart';
import 'package:spookymoove/core/widgets/app_key.dart';

const Key _key = Key('key');

Future<void> pumpKey(
  WidgetTester tester, {
  VoidCallback? onTap,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 200,
                  child: AppKey(key: _key, label: 'KEY', onTap: onTap),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Finder _fill(Color? color) => find.descendant(
  of: find.byType(AppBlock),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is DecoratedBox &&
        (widget.decoration as BoxDecoration).color == color,
  ),
);

Rect _faceRect(WidgetTester tester, Color face) => tester.getRect(_fill(face));

void main() {
  testWidgets('rest: face above a 4 dp side, 48 dp box', (tester) async {
    await pumpKey(tester, onTap: () {});

    final box = tester.getRect(find.byKey(_key));
    final face = _faceRect(tester, AppColors.keyNormal);
    final side = tester.getRect(_fill(AppColors.keyNormalSide));
    expect(box.height, AppDimens.minKeyHeight);
    expect(face.top, box.top);
    expect(face.bottom, box.bottom - AppDimens.blockDepth);
    expect(side.bottom, box.bottom);
  });

  testWidgets('press sinks the face, release restores it and taps once', (
    tester,
  ) async {
    var taps = 0;
    await pumpKey(tester, onTap: () => taps++);
    final box = tester.getRect(find.byKey(_key));

    final gesture = await tester.startGesture(box.center);
    await tester.pumpAndSettle();
    expect(
      _faceRect(tester, AppColors.keyNormal).top,
      box.top + AppDimens.blockDepth,
    );
    expect(tester.getRect(find.byKey(_key)), box);
    expect(taps, 0);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_faceRect(tester, AppColors.keyNormal).top, box.top);
    expect(taps, 1);
  });

  testWidgets('dragging off returns to rest without tapping', (tester) async {
    var taps = 0;
    await pumpKey(tester, onTap: () => taps++);
    final box = tester.getRect(find.byKey(_key));

    final gesture = await tester.startGesture(box.center);
    await tester.pumpAndSettle();
    await gesture.moveBy(const Offset(0, 200));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_faceRect(tester, AppColors.keyNormal).top, box.top);
    expect(taps, 0);
  });

  testWidgets('reduce motion: the press shows at once', (tester) async {
    await pumpKey(tester, onTap: () {}, disableAnimations: true);
    final box = tester.getRect(find.byKey(_key));

    final gesture = await tester.startGesture(box.center);
    await tester.pump();
    expect(
      _faceRect(tester, AppColors.keyNormal).top,
      box.top + AppDimens.blockDepth,
    );
    await gesture.up();
  });

  testWidgets('disabled: lowered, no side face, no press feedback', (
    tester,
  ) async {
    await pumpKey(tester);
    final box = tester.getRect(find.byKey(_key));
    final block = tester.widget<AppBlock>(find.byType(AppBlock));

    expect(box.height, AppDimens.minKeyHeight);
    expect(block.side, isNull);
    expect(_fill(AppColors.keyNormalSide), findsNothing);
    final lowered = box.top + AppDimens.blockDepth;
    expect(_faceRect(tester, AppColors.keyDisabled).top, lowered);

    final gesture = await tester.startGesture(box.center);
    await tester.pumpAndSettle();
    expect(_faceRect(tester, AppColors.keyDisabled).top, lowered);
    await gesture.up();
  });

  testWidgets('disabled mid-press, then re-enabled: back at rest', (
    tester,
  ) async {
    await pumpKey(tester, onTap: () {});
    final box = tester.getRect(find.byKey(_key));

    final gesture = await tester.startGesture(box.center);
    await tester.pumpAndSettle();
    await pumpKey(tester);
    await tester.pumpAndSettle();
    await gesture.up();
    await pumpKey(tester, onTap: () {});
    await tester.pumpAndSettle();

    expect(_faceRect(tester, AppColors.keyNormal).top, box.top);
  });

  testWidgets('selected stays amber over an accent', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppKey(
          label: 'KEY',
          onTap: () {},
          isSelected: true,
          accentColor: AppColors.accentChess,
          accentSideColor: AppColors.accentChessSide,
        ),
      ),
    );

    final block = tester.widget<AppBlock>(find.byType(AppBlock));
    expect(block.face, AppColors.accentActive);
    expect(block.side, AppColors.accentActiveSide);
    expect(block.hasHighlight, isFalse);
  });

  testWidgets('accent key: accent block with dark text, no highlight', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppKey(
          label: 'KEY',
          onTap: () {},
          accentColor: AppColors.accentXiangqi,
          accentSideColor: AppColors.accentXiangqiSide,
        ),
      ),
    );

    final block = tester.widget<AppBlock>(find.byType(AppBlock));
    expect(block.face, AppColors.accentXiangqi);
    expect(block.side, AppColors.accentXiangqiSide);
    expect(block.hasHighlight, isFalse);
    expect(
      tester.widget<Text>(find.text('KEY')).style?.color,
      AppColors.bgDark,
    );
  });
}
