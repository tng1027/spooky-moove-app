import '../engine/engine_models.dart';
import 'game_result.dart';
import 'player_side.dart';

/// What the advisor layer reads about the current game (OB-042 REQ-002).
/// Each game derives it from its own board state.
final class ActiveGameState {
  const ActiveGameState({
    required this.sideToMove,
    required this.positionId,
    required this.legalMoveCount,
    this.isInCheck = false,
    this.canUndo = false,
    this.isEntryBlocked = false,
    this.headline,
    this.hint,
  });

  final PlayerSide sideToMove;

  /// Changes (by identity) whenever the position changes.
  final Object positionId;
  final int legalMoveCount;

  /// The side to move's king or general is in check.
  final bool isInCheck;

  /// UNDO has something to take back or close.
  final bool canUndo;

  /// Board entry is mid-way through a choice (Chess promotion chooser), so
  /// the suggestion can't be confirmed.
  final bool isEntryBlocked;

  /// The result when the game is over, else null.
  final GameResultHeadline? headline;

  /// A non-blocking note under the card (Chess claimable draw), or null.
  final String? hint;

  bool get isOver => headline != null;

  @override
  bool operator ==(Object other) =>
      other is ActiveGameState &&
      other.sideToMove == sideToMove &&
      identical(other.positionId, positionId) &&
      other.legalMoveCount == legalMoveCount &&
      other.isInCheck == isInCheck &&
      other.canUndo == canUndo &&
      other.isEntryBlocked == isEntryBlocked &&
      other.headline == headline &&
      other.hint == hint;

  @override
  int get hashCode => Object.hash(
    sideToMove,
    identityHashCode(positionId),
    legalMoveCount,
    isInCheck,
    canUndo,
    isEntryBlocked,
    headline,
    hint,
  );
}

/// The actions the advisor layer takes on the current game. Moves are in
/// engine notation, so shared code never sees a game's move type.
abstract interface class ActiveGameController {
  /// Back to the start position with [userSide] at the bottom.
  void newGame(PlayerSide userSide);

  void undo();

  /// Commits [engineMove] as if it had been entered on the board. Ignored
  /// when it is not legal in the current position.
  void commitEngineMove(String engineMove);

  /// Highlights [engineMove] on the board; null clears the highlight.
  /// Returns false (and clears) when the move is not legal here.
  bool showSuggestion(String? engineMove);

  /// The game so far, for the engine.
  EnginePosition enginePosition();
}
