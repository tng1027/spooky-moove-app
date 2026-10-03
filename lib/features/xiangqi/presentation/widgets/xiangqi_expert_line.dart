import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/xiangqi_wxf.dart';
import '../xiangqi_board_controller.dart';

/// The expert line for Xiangqi (OB-046 REQ-005, XQ4): WXF from the mover's
/// side, then the shared evaluation text
/// (`C2.5 · EVAL +0.3 | DEPTH 16 | 850k nps`).
class XiangqiExpertLine extends ConsumerWidget {
  const XiangqiExpertLine({
    required this.engineMove,
    required this.evalLine,
    super.key,
  });

  static const String separator = ' · ';

  final String engineMove;
  final String evalLine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notation = ref.watch(
      xiangqiBoardControllerProvider.select((board) {
        final move = board.legalMoves
            .where((m) => m.uci == engineMove)
            .firstOrNull;
        return move == null ? null : XiangqiWxf.format(board.pieces, move);
      }),
    );
    return Text(
      notation == null ? evalLine : '$notation$separator$evalLine',
      style: AppTypography.secondary,
    );
  }
}
