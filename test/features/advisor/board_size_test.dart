import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/features/advisor/presentation/advisor_screen.dart';

void main() {
  Size sizeFor(double width, double height, int files, int ranks) =>
      AdvisorScreen.boardSizeFor(
        Size(width, height),
        files: files,
        ranks: ranks,
      );

  group('8 x 8 keeps the Phase 1 square sizes', () {
    for (final (width, height, side) in [
      (360.0, 800.0, 360.0),
      (392.0, 800.0, 392.0),
      (360.0, 600.0, 348.0),
    ]) {
      test('${width}x$height -> $side', () {
        expect(sizeFor(width, height, 8, 8), Size(side, side));
      });
    }
  });

  group('9 x 10 is sized by the narrower cell', () {
    for (final (width, height, cell) in [
      (392.0, 800.0, 392 / 9),
      (360.0, 800.0, 40.0),
      (360.0, 600.0, 34.8),
    ]) {
      test('${width}x$height -> ${cell.toStringAsFixed(1)} dp cells', () {
        final size = sizeFor(width, height, 9, 10);
        expect(size.width, closeTo(cell * 9, 1e-9));
        expect(size.height, closeTo(cell * 10, 1e-9));
      });
    }
  });

  test('never negative on a tiny screen', () {
    expect(sizeFor(320, 200, 8, 8), Size.zero);
  });
}
