import '../../../core/engine/engine_models.dart';
import '../../../core/game/player_side.dart';
import 'xiangqi_models.dart';

/// Xiangqi rules for one game, mutable through [apply], [undo] and [reset]
/// (OB-043).
///
/// Only exposes facts; game end is composed elsewhere (OB-047). No
/// repetition or draw facts (XQ6, XQ9).
abstract interface class XiangqiRules {
  /// Strictly legal moves of the side to move, computed once per position.
  List<XiangqiMove> get legalMoves;

  XiangqiPiece? pieceAt(XiangqiPoint point);

  PlayerSide get sideToMove;

  /// The side to move's general is attacked.
  bool get isCheck;

  /// The side to move has no legal move (a loss, check or not).
  bool get hasNoLegalMoves;

  /// Fairy-Stockfish Xiangqi FEN, for tests and debugging.
  String get fen;

  /// Number of moves applied since the start position (undo depth).
  int get moveCount;

  /// Applies a legal move. Throws [ArgumentError] if [move] is not legal.
  void apply(XiangqiMove move);

  /// Undoes the last move with full state restore; null if none.
  XiangqiMove? undo();

  /// Back to the start position with an empty history.
  void reset();

  /// The game so far, for the engine.
  EnginePosition toEnginePosition();

  /// The legal move matching engine notation (e.g. `h10g8`), or null.
  XiangqiMove? moveFromUci(String uci);
}
