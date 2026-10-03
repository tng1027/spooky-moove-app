import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../new_game/presentation/game_registry.dart';
import 'suggestion_controller.dart';
import 'turn_status.dart';

/// What the always-visible bottom button shows (OB-041, revised 2026-10-03).
enum StatusLineContent {
  /// No game yet.
  none,
  waitingForOpponent,
  pickLevel,
  confirmDisabled,
  confirmEnabled,
  newGame,
}

/// The button table of OB-041: guidance while the user can't confirm, the
/// "I PLAYED IT" key on the user's turn, NEW GAME once the game is over.
StatusLineContent statusLineContentFor(
  TurnStatus? turn,
  SuggestionState suggestion, {
  required bool isEntryBlocked,
}) {
  if (suggestion is SuggestionGameOver) return StatusLineContent.newGame;
  return switch (turn) {
    null => StatusLineContent.none,
    TurnStatus.opponentToMove => StatusLineContent.waitingForOpponent,
    TurnStatus.yourMove => switch (suggestion) {
      SuggestionNoTier() => StatusLineContent.pickLevel,
      SuggestionReady() when !isEntryBlocked =>
        StatusLineContent.confirmEnabled,
      _ => StatusLineContent.confirmDisabled,
    },
  };
}

final statusLineContentProvider = Provider<StatusLineContent>((ref) {
  return statusLineContentFor(
    ref.watch(turnStatusProvider),
    ref.watch(suggestionControllerProvider),
    isEntryBlocked: ref.watch(
      ref
          .watch(activeGameStateSourceProvider)
          .select((game) => game.isEntryBlocked),
    ),
  );
});
