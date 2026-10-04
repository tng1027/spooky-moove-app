import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/game/player_side.dart';
import 'package:spookymoove/core/theme/app_colors.dart';
import 'package:spookymoove/features/xiangqi/presentation/widgets/xiangqi_grid_painter.dart';
import 'package:spookymoove/features/xiangqi/presentation/widgets/xiangqi_piece_disc.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  test('the grid repaints only when the cell size changes', () {
    const painter = XiangqiGridPainter(cell: 40);
    expect(painter.shouldRepaint(const XiangqiGridPainter(cell: 40)), isFalse);
    expect(painter.shouldRepaint(const XiangqiGridPainter(cell: 34.8)), isTrue);
  });

  test('both glyph colors reach 4.5:1 on the disc', () {
    for (final side in PlayerSide.values) {
      final ratio = contrast(
        XiangqiPieceDisc.glyphColor(side),
        AppColors.keyNormal,
      );
      expect(ratio, greaterThanOrEqualTo(4.5), reason: side.name);
    }
  });
}
