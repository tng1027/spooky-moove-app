import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cataland/features/advisor/presentation/suggestion_providers.dart';

import '../persona/fake_game_engine.dart';

import 'package:cataland/app.dart';
import 'package:cataland/core/board/tap_board.dart';
import 'package:cataland/core/theme/app_colors.dart';
import 'package:cataland/core/theme/app_dimens.dart';
import 'package:cataland/core/theme/app_theme.dart';
import 'package:cataland/core/theme/app_typography.dart';
import 'package:cataland/features/chess/presentation/widgets/chess_board.dart';
import 'package:cataland/features/new_game/presentation/new_game_screen.dart';
import 'package:cataland/features/fair_play/domain/fair_play_notice.dart';
import 'package:cataland/features/fair_play/presentation/fair_play_controller.dart';
import 'package:cataland/features/persona/domain/persona_tier.dart';
import 'package:cataland/features/persona/presentation/persona_tier_controller.dart';
import 'package:cataland/features/persona/presentation/widgets/persona_row.dart';
import 'package:cataland/features/advisor/presentation/widgets/status_line.dart';
import 'package:cataland/features/advisor/presentation/widgets/suggestion_card.dart';
import 'package:cataland/features/advisor/presentation/widgets/top_bar.dart';
import 'package:cataland/features/advisor/presentation/widgets/undo_key.dart';
import 'package:cataland/features/new_game/presentation/widgets/new_game_key.dart';

Future<void> pumpApp(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  SharedPreferences.setMockInitialValues({
    FairPlayController.acknowledgedVersionKey: fairPlayNoticeVersion,
  });
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        gameEngineProvider.overrideWithValue(FakeGameEngine()),
      ],
      child: const CatalandApp(),
    ),
  );
  await tester.tap(find.byKey(NewGameScreen.startKey));
  await tester.pump();
}

void main() {
  const smallPhone = Size(360, 640);
  const commonPhone = Size(392, 800);

  testWidgets('renders the five regions top to bottom', (tester) async {
    await pumpApp(tester, size: commonPhone);

    final top = tester.getRect(find.byKey(TopBar.regionKey));
    final card = tester.getRect(find.byKey(SuggestionCard.regionKey));
    final persona = tester.getRect(find.byKey(PersonaRow.regionKey));
    final board = tester.getRect(find.byKey(ChessBoard.regionKey));
    final status = tester.getRect(find.byKey(StatusLine.regionKey));

    expect(top.bottom, lessThanOrEqualTo(persona.top));
    expect(persona.bottom, lessThanOrEqualTo(card.top));
    expect(card.bottom, lessThanOrEqualTo(board.top));
    expect(board.bottom, lessThanOrEqualTo(status.top));
  });

  testWidgets('UNDO is top-left, NEW GAME top-right', (tester) async {
    await pumpApp(tester, size: commonPhone);

    final top = tester.getRect(find.byKey(TopBar.regionKey));
    final undo = tester.getRect(find.byKey(UndoKey.regionKey));
    final newGame = tester.getRect(find.byKey(NewGameKey.regionKey));
    expect(top.contains(undo.center), isTrue);
    expect(top.contains(newGame.center), isTrue);
    expect(undo.left, top.left + AppDimens.spacingSmall);
    expect(newGame.right, top.right - AppDimens.spacingSmall);
  });

  testWidgets('fixed rows have their design heights', (tester) async {
    await pumpApp(tester, size: commonPhone);

    expect(
      tester.getSize(find.byKey(TopBar.regionKey)).height,
      AppDimens.topBarHeight,
    );
    expect(
      tester.getSize(find.byKey(PersonaRow.regionKey)).height,
      AppDimens.personaRowHeight,
    );
    expect(
      tester.getSize(find.byKey(StatusLine.regionKey)).height,
      AppDimens.statusLineHeight,
    );
  });

  for (final (size, minSquare) in [
    (smallPhone, AppDimens.minBoardSquare),
    (commonPhone, AppDimens.minKeyHeight),
  ]) {
    testWidgets('board is square with squares >= $minSquare dp at $size', (
      tester,
    ) async {
      await pumpApp(tester, size: size);

      final board = tester.getSize(find.byKey(ChessBoard.regionKey));
      expect(board.width, board.height);
      expect(
        board.width / AppDimens.boardFiles,
        greaterThanOrEqualTo(minSquare),
      );
      for (final (file, rank) in [(0, 0), (7, 7)]) {
        final square = tester.getSize(
          find.byKey(TapBoard.squareKey(file, rank)),
        );
        expect(square.width, greaterThanOrEqualTo(minSquare));
        expect(square.height, greaterThanOrEqualTo(minSquare));
      }
    });
  }

  testWidgets('suggestion card keeps its minimum height on a small phone', (
    tester,
  ) async {
    await pumpApp(tester, size: smallPhone);

    expect(
      tester.getSize(find.byKey(SuggestionCard.regionKey)).height,
      greaterThanOrEqualTo(AppDimens.minSuggestionCardHeight),
    );
  });

  testWidgets('a game starts at the default Even level, no tier prompt', (
    tester,
  ) async {
    await pumpApp(tester, size: commonPhone);
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(TopBar.regionKey)),
    );

    expect(container.read(personaTierProvider), PersonaTier.even);
    expect(find.text(SuggestionCard.pickTierPrompt), findsNothing);
  });

  testWidgets('no overflow at text scale 2.0 on a small phone', (tester) async {
    await pumpApp(tester, size: smallPhone, textScale: 2.0);

    expect(tester.takeException(), isNull);
  });

  test('theme is dark with the bundled font and tabular figures', () {
    final theme = AppTheme.dark();

    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppColors.bgDark);

    final styles = [
      theme.textTheme.bodyMedium,
      theme.textTheme.displayLarge,
      theme.textTheme.labelSmall,
      AppTypography.suggestion,
      AppTypography.secondary,
    ];
    for (final style in styles) {
      expect(style?.fontFamily, AppTypography.fontFamily);
      expect(style?.fontFeatures, contains(const FontFeature.tabularFigures()));
    }
  });
}
