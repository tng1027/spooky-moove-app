import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/theme/app_colors.dart';
import 'package:spookymoove/core/theme/app_dimens.dart';
import 'package:spookymoove/core/widgets/app_block.dart';
import 'package:spookymoove/core/widgets/app_key.dart';
import 'package:spookymoove/features/advisor/presentation/status_line_content.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/confirm_played_key.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/status_line.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/undo_key.dart';
import 'package:spookymoove/features/new_game/presentation/new_game_screen.dart';
import 'package:spookymoove/features/new_game/presentation/widgets/new_game_key.dart';

class FixedContent extends Notifier<StatusLineContent> {
  FixedContent(this.initial);

  final StatusLineContent initial;

  @override
  StatusLineContent build() => initial;

  void set(StatusLineContent content) => state = content;
}

final _contentProvider = NotifierProvider<FixedContent, StatusLineContent>(
  () => FixedContent(StatusLineContent.none),
);

void main() {
  late ProviderContainer container;

  Future<void> pumpStatusLine(
    WidgetTester tester,
    StatusLineContent content,
  ) async {
    container = ProviderContainer(
      overrides: [
        _contentProvider.overrideWith(() => FixedContent(content)),
        statusLineContentProvider.overrideWith(
          (ref) => ref.watch(_contentProvider),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: StatusLine())),
      ),
    );
  }

  void setContent(StatusLineContent content) =>
      container.read(_contentProvider.notifier).set(content);

  AppKey appKeyIn(WidgetTester tester, Finder region) => tester.widget<AppKey>(
    find.descendant(of: region, matching: find.byType(AppKey)),
  );

  Rect buttonRect(WidgetTester tester) => tester.getRect(
    find.descendant(
      of: find.byKey(StatusLine.regionKey),
      matching: find.byType(AppKey),
    ),
  );

  testWidgets("opponent's turn: disabled WAITING FOR OPPONENT", (tester) async {
    await pumpStatusLine(tester, StatusLineContent.waitingForOpponent);

    expect(find.text(StatusLine.waitingLabel), findsOneWidget);
    expect(appKeyIn(tester, find.byKey(StatusLine.regionKey)).onTap, isNull);
  });

  testWidgets('no tier: disabled PICK A LEVEL ABOVE', (tester) async {
    await pumpStatusLine(tester, StatusLineContent.pickLevel);

    expect(find.text(StatusLine.pickLevelLabel), findsOneWidget);
    expect(appKeyIn(tester, find.byKey(StatusLine.regionKey)).onTap, isNull);
  });

  testWidgets('no game: no button', (tester) async {
    await pumpStatusLine(tester, StatusLineContent.none);

    expect(find.byType(AppKey), findsNothing);
  });

  testWidgets('a pending suggestion shows the key, disabled', (tester) async {
    await pumpStatusLine(tester, StatusLineContent.confirmDisabled);

    expect(
      appKeyIn(tester, find.byKey(ConfirmPlayedKey.regionKey)).onTap,
      isNull,
    );
  });

  testWidgets('a ready suggestion: enabled, green with dark text', (
    tester,
  ) async {
    await pumpStatusLine(tester, StatusLineContent.confirmEnabled);

    final key = find.byKey(ConfirmPlayedKey.regionKey);
    expect(appKeyIn(tester, key).onTap, isNotNull);
    final block = tester.widget<AppBlock>(
      find.descendant(of: key, matching: find.byType(AppBlock)),
    );
    expect(block.face, AppColors.accentGreen);
    expect(block.side, AppColors.accentGreenSide);
    expect(
      tester.widget<Text>(find.text(ConfirmPlayedKey.label)).style?.color,
      AppColors.bgDark,
    );
  });

  testWidgets('the button sits below a top margin', (tester) async {
    await pumpStatusLine(tester, StatusLineContent.confirmEnabled);

    final line = tester.getRect(find.byKey(StatusLine.regionKey));
    expect(buttonRect(tester).top, line.top + AppDimens.spacingSmall);
    expect(buttonRect(tester).height, AppDimens.minKeyHeight);
  });

  testWidgets('the button is full width and keeps its size in every state', (
    tester,
  ) async {
    await pumpStatusLine(tester, StatusLineContent.waitingForOpponent);
    final line = tester.getRect(find.byKey(StatusLine.regionKey));
    final first = buttonRect(tester);
    expect(first.width, line.width - 2 * AppDimens.spacingSmall);

    for (final content in [
      StatusLineContent.pickLevel,
      StatusLineContent.confirmDisabled,
      StatusLineContent.confirmEnabled,
      StatusLineContent.newGame,
    ]) {
      setContent(content);
      await tester.pump();
      expect(buttonRect(tester), first, reason: '$content');
    }
  });

  testWidgets('UNDO and NEW GAME keys are not in the status line', (
    tester,
  ) async {
    await pumpStatusLine(tester, StatusLineContent.confirmEnabled);

    expect(find.byKey(UndoKey.regionKey), findsNothing);
    expect(find.byKey(NewGameKey.regionKey), findsNothing);
  });

  group('game over', () {
    testWidgets('NEW GAME opens the new-game screen without a dialog', (
      tester,
    ) async {
      await pumpStatusLine(tester, StatusLineContent.newGame);
      final label = tester.widget<Text>(find.text(StatusLine.newGameLabel));
      expect(label.style?.color, AppColors.textPrimary);

      await tester.tap(find.byKey(StatusLine.newGameKey));
      await tester.pumpAndSettle();
      expect(find.byType(NewGameConfirmDialog), findsNothing);
      expect(find.byType(NewGameScreen), findsOneWidget);
    });

    testWidgets('taps right after NEW GAME appears are ignored', (
      tester,
    ) async {
      await pumpStatusLine(tester, StatusLineContent.confirmEnabled);
      setContent(StatusLineContent.newGame);
      await tester.pump();

      await tester.tap(find.byKey(StatusLine.newGameKey));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.byType(NewGameScreen), findsNothing);

      await tester.pump(StatusLine.newGameTapGuard);
      await tester.tap(find.byKey(StatusLine.newGameKey));
      await tester.pumpAndSettle();
      expect(find.byType(NewGameScreen), findsOneWidget);
    });
  });

  for (final textScale in [1.0, 2.0]) {
    for (final content in [
      StatusLineContent.waitingForOpponent,
      StatusLineContent.pickLevel,
      StatusLineContent.confirmEnabled,
      StatusLineContent.newGame,
    ]) {
      testWidgets('no overflow at 360 dp, text scale $textScale, $content', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await pumpStatusLine(tester, content);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
