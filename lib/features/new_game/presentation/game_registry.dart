/// The one place that maps a [GameKind] to its implementation (OB-042
/// REQ-008). Shared code goes through the active-game providers.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../../../core/game/active_game.dart';
import '../../../core/game/player_side.dart';
import '../../../core/theme/app_typography.dart';
import '../../chess/domain/chess_models.dart';
import '../../chess/presentation/chess_board_controller.dart';
import '../../chess/presentation/widgets/chess_board.dart';
import '../../chess/presentation/widgets/chess_piece_pictogram.dart';
import '../../chess/presentation/widgets/chess_suggested_move.dart';
import '../../xiangqi/domain/xiangqi_models.dart';
import '../../xiangqi/presentation/widgets/xiangqi_board.dart';
import '../../xiangqi/presentation/widgets/xiangqi_expert_line.dart';
import '../../xiangqi/presentation/widgets/xiangqi_piece_disc.dart';
import '../../xiangqi/presentation/widgets/xiangqi_suggested_move.dart';
import '../../xiangqi/presentation/xiangqi_board_controller.dart';
import '../domain/game_kind.dart';
import 'game_session_controller.dart';

/// The current game; Chess until a session starts.
final activeGameKindProvider = Provider<GameKind>((ref) {
  return ref.watch(gameSessionProvider.select((session) => session?.game)) ??
      GameKind.chess;
});

final gameControllerProvider = Provider.family<ActiveGameController, GameKind>(
  (ref, game) => switch (game) {
    GameKind.chess => ref.watch(chessBoardControllerProvider.notifier),
    GameKind.xiangqi => ref.watch(xiangqiBoardControllerProvider.notifier),
  },
);

/// The current game's state, to be watched, listened to or read with
/// `select`. It is a selector on the game's own notifier rather than a
/// derived provider, so listeners hear a board change synchronously (derived
/// providers notify on the next scheduler flush).
final activeGameStateSourceProvider =
    Provider<ProviderListenable<ActiveGameState>>(
      (ref) => switch (ref.watch(activeGameKindProvider)) {
        GameKind.chess => chessBoardControllerProvider.select(
          chessActiveGameState,
        ),
        GameKind.xiangqi => xiangqiBoardControllerProvider.select(
          xiangqiActiveGameState,
        ),
      },
    );

final activeGameControllerProvider = Provider<ActiveGameController>(
  (ref) => ref.watch(gameControllerProvider(ref.watch(activeGameKindProvider))),
);

/// The engine variant the next search must run in (OB-042 REQ-005).
final activeEngineVariantProvider = Provider<String>(
  (ref) => ref.watch(activeGameKindProvider).engineVariant,
);

/// Per-game widgets placed by shared screens.
abstract final class GameWidgets {
  /// The tap board, sized by `AdvisorScreen.boardSizeFor`.
  static Widget board(GameKind game, Size size) => switch (game) {
    GameKind.chess => ChessBoard(size: size.width),
    GameKind.xiangqi => XiangqiBoard(size: size),
  };

  /// The suggestion card's move area for [engineMove].
  static Widget suggestedMove(GameKind game, String engineMove) =>
      switch (game) {
        GameKind.chess => ChessSuggestedMove(engineMove: engineMove),
        GameKind.xiangqi => XiangqiSuggestedMove(engineMove: engineMove),
      };

  /// The card's expert line for [engineMove]; [evalLine] is the shared
  /// `EVAL … | DEPTH … | … nps` text.
  static Widget expertLine(GameKind game, String engineMove, String evalLine) =>
      switch (game) {
        GameKind.chess => Text(evalLine, style: AppTypography.secondary),
        GameKind.xiangqi => XiangqiExpertLine(
          engineMove: engineMove,
          evalLine: evalLine,
        ),
      };

  /// The pictogram on the new-game side key.
  static Widget sidePictogram(GameKind game, PlayerSide side) => switch (game) {
    GameKind.chess => ChessPiecePictogram(
      ChessPiece(PieceColor.of(side), PieceKind.king),
    ),
    GameKind.xiangqi => XiangqiPieceDisc(
      XiangqiPiece(side, XiangqiPieceKind.general),
    ),
  };
}
