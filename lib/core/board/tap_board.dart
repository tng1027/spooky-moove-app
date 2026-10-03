import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';

/// Visual state of one board square (designSystem.md, "Tap board").
enum BoardSquareState {
  normal,

  /// Not part of any legal move: `keyDisabled`, ignores taps.
  dimmed,

  /// The tapped square of a pending selection.
  selected,

  /// A square that completes the pending selection.
  candidate,

  /// Part of the engine suggestion.
  suggested,

  /// A piece the suggestion removes away from its destination (Chess en
  /// passant): suggestion outline plus a capture mark.
  suggestedCapture,

  /// King in check.
  check,
}

/// Game-agnostic grid of tappable squares with edge labels.
///
/// Coordinates are board coordinates: file 0 is the left file and rank 0 the
/// bottom rank from the first player's point of view. [flipped] shows the
/// board from the other side.
class TapBoard extends StatelessWidget {
  const TapBoard({
    required this.files,
    required this.ranks,
    required this.squareState,
    required this.onTap,
    required this.fileLabel,
    required this.rankLabel,
    this.pieceBuilder,
    this.flipped = false,
    super.key,
  });

  final int files;
  final int ranks;
  final BoardSquareState Function(int file, int rank) squareState;
  final void Function(int file, int rank) onTap;
  final String Function(int file) fileLabel;
  final String Function(int rank) rankLabel;
  final Widget? Function(int file, int rank)? pieceBuilder;
  final bool flipped;

  static Key squareKey(int file, int rank) => Key('board.square.$file.$rank');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < ranks; row++)
          Expanded(
            child: Row(
              children: [
                for (var column = 0; column < files; column++)
                  Expanded(child: _buildSquare(row, column)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSquare(int row, int column) {
    final file = flipped ? files - 1 - column : column;
    final rank = flipped ? row : ranks - 1 - row;
    final state = squareState(file, rank);
    return _Square(
      key: squareKey(file, rank),
      state: state,
      isLight: (file + rank).isOdd,
      rankLabel: column == 0 ? rankLabel(rank) : null,
      fileLabel: row == ranks - 1 ? fileLabel(file) : null,
      piece: pieceBuilder?.call(file, rank),
      onTap: state == BoardSquareState.dimmed ? null : () => onTap(file, rank),
    );
  }
}

class _Square extends StatelessWidget {
  const _Square({
    required this.state,
    required this.isLight,
    required this.rankLabel,
    required this.fileLabel,
    required this.piece,
    required this.onTap,
    super.key,
  });

  static const double _outlineWidth = 3;

  final BoardSquareState state;
  final bool isLight;
  final String? rankLabel;
  final String? fileLabel;
  final Widget? piece;
  final VoidCallback? onTap;

  Color get _fill => switch (state) {
    BoardSquareState.dimmed => AppColors.keyDisabled,
    BoardSquareState.selected => AppColors.accentActive,
    BoardSquareState.check => AppColors.accentRed,
    BoardSquareState.normal ||
    BoardSquareState.candidate ||
    BoardSquareState.suggested ||
    BoardSquareState.suggestedCapture =>
      isLight ? AppColors.boardLight : AppColors.boardDark,
  };

  Color? get _outline => switch (state) {
    BoardSquareState.candidate => AppColors.accentActive,
    BoardSquareState.suggested ||
    BoardSquareState.suggestedCapture => AppColors.accentGreen,
    _ => null,
  };

  static const TextStyle _captureMarkStyle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.accentGreen,
  );

  @override
  Widget build(BuildContext context) {
    final outline = _outline;
    final piece = this.piece;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _fill,
          border: outline == null
              ? null
              : Border.all(color: outline, width: _outlineWidth),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (piece != null)
              Padding(
                padding: const EdgeInsets.all(AppDimens.spacingSmall / 2),
                child: piece,
              ),
            if (rankLabel case final label?)
              Positioned(
                top: AppDimens.spacingSmall / 2,
                left: AppDimens.spacingSmall / 2,
                child: Text(label, style: AppTypography.boardLabel),
              ),
            if (state == BoardSquareState.suggestedCapture)
              const Positioned(
                top: AppDimens.spacingSmall / 2,
                right: AppDimens.spacingSmall,
                child: Text('✕', style: _captureMarkStyle),
              ),
            if (fileLabel case final label?)
              Positioned(
                bottom: AppDimens.spacingSmall / 2,
                right: AppDimens.spacingSmall / 2,
                child: Text(label, style: AppTypography.boardLabel),
              ),
          ],
        ),
      ),
    );
  }
}
