import '../../../core/game/game_result.dart';
import '../../../core/game/player_side.dart';
import '../../../core/l10n/app_strings.dart';
import 'xiangqi_game_status.dart';

/// Xiangqi game-end text for the suggestion card, from the user's point of
/// view (OB-047). Never "STALEMATE": in Xiangqi it is a loss (BR-003).
abstract final class XiangqiResultFormat {
  /// Null while the game is in progress.
  static GameResultHeadline? headline(
    XiangqiGameStatus status,
    PlayerSide userSide,
    AppStrings strings,
  ) {
    return switch (status) {
      XiangqiInProgress() => null,
      XiangqiLoss(:final winner, :final reason) =>
        winner == userSide
            ? GameResultHeadline(
                '${_reasonText(reason, strings)}'
                '${GameResultHeadline.separator}${strings.youWin}',
                ResultTone.win,
              )
            : GameResultHeadline(
                '${_reasonText(reason, strings)}'
                '${GameResultHeadline.separator}${strings.youLose}',
                ResultTone.loss,
              ),
    };
  }

  static String _reasonText(XiangqiEndReason reason, AppStrings strings) =>
      switch (reason) {
        XiangqiEndReason.checkmate => strings.checkmate,
        XiangqiEndReason.noMoves => strings.noMoves,
      };
}
