import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/board/tap_board.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../domain/chess_models.dart';
import '../../domain/chess_move_format.dart';
import '../../domain/move_entry.dart';
import '../chess_board_controller.dart';
import 'chess_piece_pictogram.dart';
import 'promotion_chooser.dart';

/// Legal-only Chess tap board (OB-006), user's side at the bottom.
class ChessBoard extends ConsumerWidget {
  const ChessBoard({required this.size, super.key = regionKey});

  static const Key regionKey = Key('advisor.board');

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chessBoardControllerProvider);
    final controller = ref.read(chessBoardControllerProvider.notifier);
    final entry = state.entry;
    final suggested = _suggestedSquares(state.suggestedMove);
    final suggestedMove = state.suggestedMove;
    final removed = suggestedMove == null
        ? null
        : ChessMoveFormat.enPassantCapturedSquare(suggestedMove);

    BoardSquareState squareState(int file, int rank) {
      final square = ChessSquare(file, rank);
      return switch (entry) {
        SourceSelected(:final source) when source == square =>
          BoardSquareState.selected,
        DestinationSelected(:final destination) when destination == square =>
          BoardSquareState.selected,
        PromotionPending(:final from, :final to)
            when from == square || to == square =>
          BoardSquareState.selected,
        SourceSelected(:final destinations)
            when destinations.contains(square) =>
          BoardSquareState.candidate,
        DestinationSelected(:final sources) when sources.contains(square) =>
          BoardSquareState.candidate,
        _ when square == removed => BoardSquareState.suggestedCapture,
        _ when !state.activeSquares.contains(square) => BoardSquareState.dimmed,
        _ when square == state.checkedKing => BoardSquareState.check,
        _ when suggested.contains(square) => BoardSquareState.suggested,
        _ => BoardSquareState.normal,
      };
    }

    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          TapBoard(
            files: AppDimens.boardFiles,
            ranks: AppDimens.boardRanks,
            flipped: state.userSide == PieceColor.black,
            squareState: squareState,
            onTap: (file, rank) => controller.tap(ChessSquare(file, rank)),
            fileLabel: (file) => String.fromCharCode('A'.codeUnitAt(0) + file),
            rankLabel: (rank) => '${rank + 1}',
            pieceBuilder: (file, rank) {
              final piece = state.pieces[ChessSquare(file, rank)];
              return piece == null ? null : ChessPiecePictogram(piece);
            },
          ),
          if (entry is PromotionPending)
            Positioned.fill(
              child: PromotionChooser(
                color: state.sideToMove,
                keySize: size / AppDimens.boardFiles,
                highlighted: _suggestedPromotion(state.suggestedMove, entry),
                onChosen: controller.choosePromotion,
                onCancel: controller.cancelEntry,
              ),
            ),
        ],
      ),
    );
  }

  static Set<ChessSquare> _suggestedSquares(ChessMove? move) {
    if (move == null) return const {};
    final rook = move.castlingRookMove;
    return {move.from, move.to, ?rook?.from, ?rook?.to};
  }

  static PieceKind? _suggestedPromotion(
    ChessMove? suggestion,
    PromotionPending entry,
  ) {
    if (suggestion == null) return null;
    final matches = suggestion.from == entry.from && suggestion.to == entry.to;
    return matches ? suggestion.promotion : null;
  }
}
