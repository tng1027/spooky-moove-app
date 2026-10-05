import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/theme/app_dimens.dart';
import 'package:spookymoove/features/advisor/presentation/advisor_screen.dart';

void main() {
  Size sizeFor(double width, double height, int files, int ranks) =>
      AdvisorScreen.boardSizeFor(
        Size(width, height),
        files: files,
        ranks: ranks,
      );

  test('the fixed parts take 252 dp, the tray 8 dp of width', () {
    expect(
      AppDimens.topBarHeight +
          AppDimens.personaRowHeight +
          AppDimens.minSuggestionCardHeight +
          AdvisorScreen.trayHeightOverhead +
          AppDimens.statusLineHeight,
      252,
    );
    expect(AdvisorScreen.trayWidthOverhead, 8);
  });

  group('8 x 8 fits the board tray (OB-052 DS-7)', () {
    for (final (width, height, side) in [
      (360.0, 640.0, 352.0),
      (360.0, 800.0, 352.0),
      (392.0, 800.0, 384.0),
      (360.0, 600.0, 348.0),
    ]) {
      test('${width}x$height -> $side', () {
        expect(sizeFor(width, height, 8, 8), Size(side, side));
      });
    }

    test('squares stay >= 44 dp at 360 dp and >= 48 dp at 392 dp', () {
      expect(sizeFor(360, 640, 8, 8).width / 8, greaterThanOrEqualTo(44));
      expect(sizeFor(392, 800, 8, 8).width / 8, greaterThanOrEqualTo(48));
    });
  });

  group('9 x 10 is sized by the narrower cell', () {
    for (final (width, height, cell) in [
      (392.0, 800.0, 384 / 9),
      (360.0, 800.0, 352 / 9),
      (360.0, 640.0, 38.8),
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
