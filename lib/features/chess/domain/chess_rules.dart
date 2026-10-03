import '../../../core/engine/engine_models.dart';
import 'chess_models.dart';

/// FIDE Chess rules for one game, mutable through [apply], [undo] and [reset].
///
/// Only exposes facts; `ChessGameStatus.of` composes the game end from them.
abstract interface class ChessRules {
  /// Legal moves of the side to move. Promotions appear once per piece kind.
  List<ChessMove> get legalMoves;

  ChessPiece? pieceAt(ChessSquare square);

  PieceColor get sideToMove;

  bool get isCheck;

  bool get isCheckmate;

  bool get isStalemate;

  /// K v K, K v K+N, K v K+B, or only same-colored bishops.
  bool get hasInsufficientMaterial;

  /// How many times the current position (placement, side to move, castling
  /// rights, en passant square) has occurred in this game, including now.
  int get repetitionCount;

  /// Half-moves since the last capture or pawn move.
  int get halfmoveClock;

  String get fen;

  /// Number of moves applied since the start position (undo depth).
  int get moveCount;

  /// Applies a legal move. Throws [ArgumentError] if [move] is not legal.
  void apply(ChessMove move);

  /// Undoes the last move with full state restore; null if none.
  ChessMove? undo();

  /// Back to the start position with an empty history.
  void reset();

  /// The game so far, for the engine.
  EnginePosition toEnginePosition();

  /// The legal move matching engine notation (e.g. `e7e8q`), or null.
  ChessMove? moveFromUci(String uci);
}
