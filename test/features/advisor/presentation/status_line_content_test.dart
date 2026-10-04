import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/engine/engine_models.dart';
import 'package:spookymoove/core/game/game_result.dart';
import 'package:spookymoove/features/advisor/presentation/status_line_content.dart';
import 'package:spookymoove/features/advisor/presentation/suggestion_controller.dart';
import 'package:spookymoove/features/advisor/presentation/turn_status.dart';
import 'package:spookymoove/features/persona/application/persona_suggester.dart';

void main() {
  const ready = SuggestionReady(
    suggestion: PersonaSuggestion(
      move: 'e2e4',
      winChance: 0.55,
      score: CentipawnScore(30),
      depth: 12,
    ),
  );
  const gameOver = SuggestionGameOver(
    headline: GameResultHeadline('CHECKMATE — YOU WIN', ResultTone.win),
  );

  StatusLineContent contentFor(
    TurnStatus? turn,
    SuggestionState suggestion, {
    bool isEntryBlocked = false,
  }) => statusLineContentFor(turn, suggestion, isEntryBlocked: isEntryBlocked);

  test('no game: nothing', () {
    expect(contentFor(null, const SuggestionWaiting()), StatusLineContent.none);
  });

  test('game over: NEW GAME', () {
    expect(contentFor(null, gameOver), StatusLineContent.newGame);
  });

  test("opponent's turn: waiting for the opponent", () {
    for (final state in [
      const SuggestionWaiting(),
      const SuggestionThinking(),
      const SuggestionNoTier(),
    ]) {
      expect(
        contentFor(TurnStatus.opponentToMove, state),
        StatusLineContent.waitingForOpponent,
      );
    }
  });

  test("user's turn without a tier: pick a level", () {
    expect(
      contentFor(TurnStatus.yourMove, const SuggestionNoTier()),
      StatusLineContent.pickLevel,
    );
  });

  test("user's turn, thinking: disabled key", () {
    expect(
      contentFor(TurnStatus.yourMove, const SuggestionThinking()),
      StatusLineContent.confirmDisabled,
    );
  });

  test("user's turn, ready: enabled key", () {
    expect(
      contentFor(TurnStatus.yourMove, ready),
      StatusLineContent.confirmEnabled,
    );
  });

  test('ready but the promotion chooser is open: disabled key', () {
    expect(
      contentFor(TurnStatus.yourMove, ready, isEntryBlocked: true),
      StatusLineContent.confirmDisabled,
    );
  });

  test('engine error: disabled key (the card offers Retry)', () {
    expect(
      contentFor(TurnStatus.yourMove, const SuggestionFailed()),
      StatusLineContent.confirmDisabled,
    );
  });
}
