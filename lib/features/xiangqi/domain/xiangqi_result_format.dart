import '../../../core/game/game_result.dart';
import '../../../core/game/player_side.dart';
import 'xiangqi_game_status.dart';

/// Xiangqi game-end text for the suggestion card, from the user's point of
/// view (OB-047). Never "STALEMATE": in Xiangqi it is a loss (BR-003).
abstract final class XiangqiResultFormat {
  /// Null while the game is in progress.
  static GameResultHeadline? headline(
    XiangqiGameStatus status,
    PlayerSide userSide,
  ) {
    return switch (status) {
      XiangqiInProgress() => null,
      XiangqiLoss(:final winner, :final reason) =>
        winner == userSide
            ? GameResultHeadline(
                '${_reasonText(reason)} — YOU WIN',
                ResultTone.win,
              )
            : GameResultHeadline(
                '${_reasonText(reason)} — YOU LOSE',
                ResultTone.loss,
              ),
    };
  }

  static String _reasonText(XiangqiEndReason reason) => switch (reason) {
    XiangqiEndReason.checkmate => 'CHECKMATE',
    XiangqiEndReason.noMoves => 'NO MOVES',
  };
}
