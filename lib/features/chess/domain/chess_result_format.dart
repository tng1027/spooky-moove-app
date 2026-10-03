import '../../../core/game/game_result.dart';
import 'chess_game_status.dart';
import 'chess_models.dart';

/// Chess game-end text for the suggestion card in plain language, from the
/// user's point of view (OB-024, no-chess-knowledge note 2026-10-02).
abstract final class ChessResultFormat {
  /// Null while the game is in progress.
  static GameResultHeadline? headline(
    ChessGameStatus status,
    PieceColor userSide,
  ) {
    return switch (status) {
      ChessInProgress() => null,
      ChessCheckmate(:final winner) when winner == userSide =>
        const GameResultHeadline('CHECKMATE — YOU WIN', ResultTone.win),
      ChessCheckmate() => const GameResultHeadline(
        'CHECKMATE — YOU LOSE',
        ResultTone.loss,
      ),
      ChessDraw(:final reason) => GameResultHeadline(
        _drawText(reason),
        ResultTone.draw,
      ),
    };
  }

  /// The non-blocking claimable-draw hint, or null.
  static String? hint(ChessGameStatus status) {
    return switch (status) {
      ChessInProgress(claimableDraw: ClaimableDraw.threefoldRepetition) =>
        'DRAW POSSIBLE — SAME POSITION 3 TIMES',
      ChessInProgress(claimableDraw: ClaimableDraw.fiftyMoveRule) =>
        'DRAW POSSIBLE — 50 MOVES WITHOUT CAPTURE OR PAWN MOVE',
      _ => null,
    };
  }

  static String _drawText(DrawReason reason) => switch (reason) {
    DrawReason.stalemate => 'STALEMATE — DRAW',
    DrawReason.insufficientMaterial => 'DRAW — NOT ENOUGH PIECES TO WIN',
    DrawReason.fivefoldRepetition => 'DRAW — SAME POSITION 5 TIMES',
    DrawReason.seventyFiveMoveRule =>
      'DRAW — 75 MOVES WITHOUT CAPTURE OR PAWN MOVE',
  };
}
