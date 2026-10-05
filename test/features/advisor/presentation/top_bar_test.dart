import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/engine/engine_models.dart';
import 'package:spookymoove/core/theme/app_colors.dart';
import 'package:spookymoove/core/theme/app_dimens.dart';
import 'package:spookymoove/features/advisor/domain/eval_format.dart';
import 'package:spookymoove/features/advisor/presentation/suggestion_controller.dart';
import 'package:spookymoove/features/advisor/presentation/turn_status.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/top_bar.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/undo_key.dart';
import 'package:spookymoove/features/chess/data/chess_package_rules.dart';
import 'package:spookymoove/features/chess/presentation/chess_board_controller.dart';
import 'package:spookymoove/features/new_game/presentation/widgets/new_game_key.dart';
import 'package:spookymoove/features/persona/application/persona_suggester.dart';

class FixedSuggestionController extends SuggestionController {
  FixedSuggestionController(this.fixed);

  final SuggestionState fixed;

  @override
  SuggestionState build() => fixed;
}

SuggestionReady ready({
  EngineScore score = const CentipawnScore(40),
  double winChance = 62,
}) => SuggestionReady(
  suggestion: PersonaSuggestion(
    move: 'e2e4',
    score: score,
    winChance: winChance,
  ),
);

void main() {
  Future<void> pumpTopBar(
    WidgetTester tester, {
    TurnStatus? turn = TurnStatus.yourMove,
    SuggestionState suggestion = const SuggestionWaiting(),
    String fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          turnStatusProvider.overrideWithValue(turn),
          suggestionControllerProvider.overrideWith(
            () => FixedSuggestionController(suggestion),
          ),
          chessRulesProvider.overrideWithValue(ChessPackageRules(fen: fen)),
        ],
        child: const MaterialApp(home: Scaffold(body: TopBar())),
      ),
    );
  }

  Color? colorOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.color;

  testWidgets('a favorable suggestion: WIN RATE over a green value', (
    tester,
  ) async {
    await pumpTopBar(tester, suggestion: ready());

    final caption = find.text('WIN RATE');
    final value = find.text('62%');
    expect(colorOf(tester, 'WIN RATE'), AppColors.textSecondary);
    expect(colorOf(tester, '62%'), AppColors.accentGreen);
    expect(tester.widget<Text>(value).style?.fontSize, 24);
    expect(
      tester.getRect(caption).bottom,
      lessThanOrEqualTo(tester.getRect(value).top),
    );
    final bar = tester.getRect(find.byKey(TopBar.regionKey));
    expect(tester.getCenter(value).dx, closeTo(bar.center.dx, 0.5));
    expect(tester.getRect(value).bottom, lessThanOrEqualTo(bar.bottom));
  });

  testWidgets('the win rate is spoken as one label', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpTopBar(tester, suggestion: ready());

    expect(find.bySemanticsLabel('Win rate 62 percent'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('below 50 % the win rate is red', (tester) async {
    await pumpTopBar(
      tester,
      suggestion: ready(score: const CentipawnScore(-130), winChance: 38),
    );
    expect(colorOf(tester, '38%'), AppColors.accentRed);
  });

  testWidgets('a forced mate is spelled out', (tester) async {
    await pumpTopBar(
      tester,
      suggestion: ready(score: const MateScore(-4), winChance: 0),
    );
    expect(find.text('OPPONENT MATES IN'), findsOneWidget);
    expect(colorOf(tester, '4'), AppColors.accentRed);
  });

  testWidgets('no suggestion yet: WIN RATE / -- in textSecondary', (
    tester,
  ) async {
    for (final (turn, state) in [
      (TurnStatus.opponentToMove, const SuggestionWaiting()),
      (TurnStatus.yourMove, const SuggestionThinking()),
      (TurnStatus.yourMove, const SuggestionNoTier()),
      (TurnStatus.yourMove, const SuggestionFailed()),
    ]) {
      await pumpTopBar(tester, turn: turn, suggestion: state);
      expect(find.text(EvalFormat.winRateCaption), findsOneWidget);
      expect(
        colorOf(tester, EvalFormat.unknownValue),
        AppColors.textSecondary,
        reason: '$state',
      );
    }
  });

  testWidgets('a finished game reads GAME OVER', (tester) async {
    await pumpTopBar(tester, turn: null, fen: '8/8/8/4k3/8/8/8/4KN2 w - - 0 1');

    expect(find.text(TopBar.gameOverLabel), findsOneWidget);
    expect(find.text(EvalFormat.unknownValue), findsNothing);
  });

  testWidgets('no game: no label', (tester) async {
    await pumpTopBar(tester, turn: null);

    expect(find.text(EvalFormat.unknownValue), findsNothing);
    expect(find.text(TopBar.gameOverLabel), findsNothing);
  });

  testWidgets('NEW GAME top-left, UNDO top-right', (tester) async {
    await pumpTopBar(tester);

    final bar = tester.getRect(find.byKey(TopBar.regionKey));
    final undo = tester.getRect(find.byKey(UndoKey.regionKey));
    final newGame = tester.getRect(find.byKey(NewGameKey.regionKey));
    expect(newGame.left, bar.left + AppDimens.spacingSmall);
    expect(undo.right, bar.right - AppDimens.spacingSmall);
  });

  for (final textScale in [1.0, 2.0]) {
    testWidgets('no overflow at 360 dp, text scale $textScale', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpTopBar(
        tester,
        suggestion: ready(score: const MateScore(-4), winChance: 0),
      );
      expect(tester.takeException(), isNull);
      final label = tester.getRect(find.text('OPPONENT MATES IN'));
      final undo = tester.getRect(find.byKey(UndoKey.regionKey));
      final newGame = tester.getRect(find.byKey(NewGameKey.regionKey));
      expect(label.left, greaterThanOrEqualTo(newGame.right));
      expect(label.right, lessThanOrEqualTo(undo.left));
    });
  }
}
