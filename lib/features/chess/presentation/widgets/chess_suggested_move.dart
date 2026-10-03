import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/game/move_text.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/chess_models.dart';
import '../../domain/chess_move_format.dart';
import '../chess_board_controller.dart';
import 'chess_piece_pictogram.dart';

/// The suggestion card's move area for Chess (OB-007): the move in plain
/// coordinates with any promotion pictogram, plus the extra physical action
/// of castling or en passant.
class ChessSuggestedMove extends ConsumerWidget {
  const ChessSuggestedMove({required this.engineMove, super.key});

  static const double _mainPictogramSize = 48;
  static const double _instructionPictogramSize = 24;

  final String engineMove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (move, side) = ref.watch(
      chessBoardControllerProvider.select(
        (board) => (
          board.legalMoves.where((m) => m.uci == engineMove).firstOrNull,
          board.userSide,
        ),
      ),
    );
    if (move == null) {
      return const Text(MoveText.emptyLine, style: AppTypography.suggestion);
    }
    final promotion = move.promotion;
    final instruction = ChessMoveFormat.instructionFor(move);
    final instructionPictogram = instruction?.pictogram;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppDimens.spacingSmall,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppDimens.spacing,
          children: [
            Text(
              ChessMoveFormat.moveLine(move),
              style: AppTypography.suggestion,
            ),
            if (promotion != null)
              SizedBox.square(
                dimension: _mainPictogramSize,
                child: ChessPiecePictogram(ChessPiece(side, promotion)),
              ),
          ],
        ),
        if (instruction != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppDimens.spacingSmall,
            children: [
              if (instructionPictogram != null)
                SizedBox.square(
                  dimension: _instructionPictogramSize,
                  child: ChessPiecePictogram(
                    ChessPiece(side, instructionPictogram),
                  ),
                ),
              Text(instruction.text, style: AppTypography.primary),
            ],
          ),
      ],
    );
  }
}
