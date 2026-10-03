import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/game/move_text.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/xiangqi_move_format.dart';
import '../xiangqi_board_controller.dart';
import 'xiangqi_piece_disc.dart';

/// The suggestion card's move area for Xiangqi (OB-046, XQ4): the moving
/// piece's disc and `H3 ➔ E3` in Red's frame, `✕` for a capture.
class XiangqiSuggestedMove extends ConsumerWidget {
  const XiangqiSuggestedMove({required this.engineMove, super.key});

  static const double discSize = 48;

  final String engineMove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (move, piece) = ref.watch(
      xiangqiBoardControllerProvider.select((board) {
        final move = board.legalMoves
            .where((m) => m.uci == engineMove)
            .firstOrNull;
        return (move, move == null ? null : board.pieces[move.from]);
      }),
    );
    if (move == null || piece == null) {
      return const Text(MoveText.emptyLine, style: AppTypography.suggestion);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppDimens.spacing,
      children: [
        SizedBox.square(dimension: discSize, child: XiangqiPieceDisc(piece)),
        Text(XiangqiMoveFormat.moveLine(move), style: AppTypography.suggestion),
      ],
    );
  }
}
