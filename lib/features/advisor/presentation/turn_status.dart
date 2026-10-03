import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../new_game/presentation/game_registry.dart';
import '../../new_game/presentation/game_session_controller.dart';

/// Whose move is being entered on the board (OB-025 REQ-003).
enum TurnStatus { yourMove, opponentToMove }

/// Null when there is no game or the game is over (the card shows the
/// result, OB-024).
final turnStatusProvider = Provider<TurnStatus?>((ref) {
  final session = ref.watch(gameSessionProvider);
  if (session == null) return null;
  final (sideToMove, isOver) = ref.watch(
    ref
        .watch(activeGameStateSourceProvider)
        .select((game) => (game.sideToMove, game.isOver)),
  );
  if (isOver) return null;
  return sideToMove == session.userSide
      ? TurnStatus.yourMove
      : TurnStatus.opponentToMove;
});
