import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';
import 'snap.dart';
import 'tap_board.dart';

/// Game-agnostic board whose square cells are centred on line intersections
/// (designSystem.md, "Xiangqi board"). One [background] painter draws the
/// lines; points and pieces sit on top.
///
/// Coordinates are board coordinates as in [TapBoard]. Taps snap to the only
/// target point within one cell (OB-044 XQ3): a miss calls [onMiss], a tie is
/// ignored.
class IntersectionBoard extends StatelessWidget {
  const IntersectionBoard({
    required this.files,
    required this.ranks,
    required this.background,
    required this.pointState,
    required this.isTarget,
    required this.onTap,
    required this.onMiss,
    required this.fileLabel,
    required this.rankLabel,
    this.pieceBuilder,
    this.flipped = false,
    super.key,
  });

  /// Share of the cell a piece occupies, leaving a gap to its neighbours.
  static const double pieceFraction = 0.86;
  static const double dotDiameter = 12;
  static const double ringWidth = 3;
  static const double dimmedOpacity = 0.4;

  final int files;
  final int ranks;
  final CustomPainter background;
  final BoardSquareState Function(int file, int rank) pointState;
  final bool Function(int file, int rank) isTarget;
  final void Function(int file, int rank) onTap;
  final VoidCallback onMiss;
  final String Function(int file) fileLabel;
  final String Function(int rank) rankLabel;
  final Widget? Function(int file, int rank)? pieceBuilder;
  final bool flipped;

  static Key pointKey(int file, int rank) => Key('board.point.$file.$rank');

  int _file(int column) => flipped ? files - 1 - column : column;
  int _rank(int row) => flipped ? row : ranks - 1 - row;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = constraints.maxWidth / files;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => _handleTap(details.localPosition, cell),
          child: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(child: CustomPaint(painter: background)),
              ),
              for (var row = 0; row < ranks; row++)
                for (var column = 0; column < files; column++)
                  Positioned(
                    left: column * cell,
                    top: row * cell,
                    width: cell,
                    height: cell,
                    child: _buildPoint(row, column),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPoint(int row, int column) {
    final file = _file(column);
    final rank = _rank(row);
    return _Point(
      key: pointKey(file, rank),
      state: pointState(file, rank),
      piece: pieceBuilder?.call(file, rank),
      rankLabel: column == 0 ? rankLabel(rank) : null,
      fileLabel: row == ranks - 1 ? fileLabel(file) : null,
    );
  }

  void _handleTap(Offset position, double cell) {
    final targets = <(int, int)>{
      for (var row = 0; row < ranks; row++)
        for (var column = 0; column < files; column++)
          if (isTarget(_file(column), _rank(row))) (column, row),
    };
    switch (snapTap(tap: position, cell: cell, targets: targets)) {
      case SnapToCell(:final column, :final row):
        onTap(_file(column), _rank(row));
      case SnapMissed():
        onMiss();
      case SnapIgnored():
        break;
    }
  }
}

class _Point extends StatelessWidget {
  const _Point({
    required this.state,
    required this.piece,
    required this.rankLabel,
    required this.fileLabel,
    super.key,
  });

  final BoardSquareState state;
  final Widget? piece;
  final String? rankLabel;
  final String? fileLabel;

  Color? get _fill => switch (state) {
    BoardSquareState.selected => AppColors.accentActive,
    BoardSquareState.check => AppColors.accentRed,
    _ => null,
  };

  Color? get _mark => switch (state) {
    BoardSquareState.candidate => AppColors.accentActive,
    BoardSquareState.suggested ||
    BoardSquareState.suggestedCapture => AppColors.accentGreen,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final fill = _fill;
    final mark = _mark;
    final piece = this.piece;
    return DecoratedBox(
      decoration: BoxDecoration(color: fill),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (piece != null)
            FractionallySizedBox(
              widthFactor: IntersectionBoard.pieceFraction,
              heightFactor: IntersectionBoard.pieceFraction,
              child: state == BoardSquareState.dimmed
                  ? Opacity(
                      opacity: IntersectionBoard.dimmedOpacity,
                      child: piece,
                    )
                  : piece,
            ),
          if (mark != null)
            piece == null
                ? Center(
                    child: SizedBox.square(
                      dimension: IntersectionBoard.dotDiameter,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: mark,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  )
                : FractionallySizedBox(
                    widthFactor: IntersectionBoard.pieceFraction,
                    heightFactor: IntersectionBoard.pieceFraction,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: mark,
                          width: IntersectionBoard.ringWidth,
                        ),
                      ),
                    ),
                  ),
          if (rankLabel case final label?)
            Positioned(
              top: AppDimens.spacingSmall / 4,
              left: AppDimens.spacingSmall / 4,
              child: Text(label, style: AppTypography.boardLabel),
            ),
          if (fileLabel case final label?)
            Positioned(
              bottom: AppDimens.spacingSmall / 4,
              right: AppDimens.spacingSmall / 4,
              child: Text(label, style: AppTypography.boardLabel),
            ),
        ],
      ),
    );
  }
}
