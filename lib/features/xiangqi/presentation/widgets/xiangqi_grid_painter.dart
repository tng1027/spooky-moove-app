import 'package:flutter/rendering.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/xiangqi_models.dart';

/// Xiangqi lines through the point centres: the inner files break at the
/// river, the edge files run through, plus the palace diagonals. The pattern
/// is symmetric under a half turn, so flipping the board needs no repaint.
class XiangqiGridPainter extends CustomPainter {
  const XiangqiGridPainter({required this.cell});

  static const double lineWidth = 1;

  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.surfaceDark);
    final line = Paint()
      ..color = AppColors.textSecondary
      ..strokeWidth = lineWidth;
    Offset point(num column, num row) =>
        Offset((column + 0.5) * cell, (row + 0.5) * cell);

    const lastFile = XiangqiPoint.files - 1;
    const lastRank = XiangqiPoint.ranks - 1;
    const riverTop = XiangqiPoint.ranks ~/ 2 - 1;
    for (var row = 0; row <= lastRank; row++) {
      canvas.drawLine(point(0, row), point(lastFile, row), line);
    }
    for (var column = 0; column <= lastFile; column++) {
      if (column == 0 || column == lastFile) {
        canvas.drawLine(point(column, 0), point(column, lastRank), line);
      } else {
        canvas
          ..drawLine(point(column, 0), point(column, riverTop), line)
          ..drawLine(
            point(column, riverTop + 1),
            point(column, lastRank),
            line,
          );
      }
    }
    for (final top in const [0, lastRank - 2]) {
      canvas
        ..drawLine(point(3, top), point(5, top + 2), line)
        ..drawLine(point(5, top), point(3, top + 2), line);
    }
  }

  @override
  bool shouldRepaint(XiangqiGridPainter oldDelegate) =>
      oldDelegate.cell != cell;
}
