import '../../../core/game/game_result.dart';
import '../../../core/l10n/app_strings.dart';
import 'chess_game_status.dart';
import 'chess_models.dart';

/// Chess game-end text for the suggestion card in plain language, from the
/// user's point of view (OB-024, no-chess-knowledge note 2026-10-02).
abstract final class ChessResultFormat {
  /// Null while the game is in progress.
  static GameResultHeadline? headline(
    ChessGameStatus status,
    PieceColor userSide,
    AppStrings strings,
  ) {
    return switch (status) {
      ChessInProgress() => null,
      ChessCheckmate(:final winner) when winner == userSide =>
        GameResultHeadline(
          '${strings.checkmate}${GameResultHeadline.separator}'
          '${strings.youWin}',
          ResultTone.win,
        ),
      ChessCheckmate() => GameResultHeadline(
        '${strings.checkmate}${GameResultHeadline.separator}'
        '${strings.youLose}',
        ResultTone.loss,
      ),
      ChessDraw(:final reason) => GameResultHeadline(
        _drawText(reason, strings),
        ResultTone.draw,
      ),
    };
  }

  /// The non-blocking claimable-draw hint, or null.
  static String? hint(ChessGameStatus status, AppStrings strings) {
    return switch (status) {
      ChessInProgress(claimableDraw: ClaimableDraw.threefoldRepetition) =>
        strings.hintThreefold,
      ChessInProgress(claimableDraw: ClaimableDraw.fiftyMoveRule) =>
        strings.hintFiftyMoves,
      _ => null,
    };
  }

  static String _drawText(DrawReason reason, AppStrings strings) =>
      switch (reason) {
        DrawReason.stalemate => strings.stalemateDraw,
        DrawReason.insufficientMaterial => strings.drawInsufficientMaterial,
        DrawReason.fivefoldRepetition => strings.drawFivefold,
        DrawReason.seventyFiveMoveRule => strings.drawSeventyFiveMoves,
      };
}
