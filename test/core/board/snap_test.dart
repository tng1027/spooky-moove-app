import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/board/snap.dart';

void main() {
  const cell = 40.0;
  Offset centre(int column, int row) =>
      Offset((column + 0.5) * cell, (row + 0.5) * cell);

  SnapResult snap(Offset tap, Set<(int, int)> targets) =>
      snapTap(tap: tap, cell: cell, targets: targets);

  test('the tapped cell wins when it is a target', () {
    // Corner of cell (2, 2): (1, 1) is nearer as a centre, but the cell rules.
    expect(
      snap(const Offset(81, 81), {(2, 2), (1, 1)}),
      const SnapToCell(2, 2),
    );
  });

  test('a non-target cell snaps to the nearest target within one cell', () {
    expect(snap(centre(4, 4), {(5, 4)}), const SnapToCell(5, 4));
    expect(
      snap(centre(4, 4) + const Offset(10, 0), {(5, 4), (3, 4)}),
      const SnapToCell(5, 4),
    );
  });

  test('a diagonal neighbour is beyond one cell', () {
    expect(snap(centre(4, 4), {(5, 5)}), const SnapMissed());
  });

  test('equally near targets are ignored', () {
    expect(snap(centre(4, 4), {(3, 4), (5, 4)}), const SnapIgnored());
    expect(snap(centre(4, 4), {(4, 3), (4, 5), (3, 4)}), const SnapIgnored());
  });

  test('a strictly nearer target overrides an earlier tie', () {
    // (3, 3) and (3, 4) are tied at ≈ 29.7, (4, 3) is nearer at ≈ 26.9.
    expect(
      snap(const Offset(162, 160), {(3, 3), (3, 4), (4, 3)}),
      const SnapToCell(4, 3),
    );
  });

  test('no target within one cell is a miss', () {
    expect(snap(centre(0, 0), {(8, 9)}), const SnapMissed());
    expect(snap(centre(0, 0), const {}), const SnapMissed());
  });

  test('taps outside the outer points snap inward or miss', () {
    expect(snap(const Offset(-10, 20), {(0, 0)}), const SnapToCell(0, 0));
    expect(snap(const Offset(-30, 20), {(0, 0)}), const SnapMissed());
    expect(
      snap(const Offset(9 * cell + 5, 9.5 * cell), {(8, 9)}),
      const SnapToCell(8, 9),
    );
  });

  test('a zero cell never snaps', () {
    expect(
      snapTap(tap: Offset.zero, cell: 0, targets: {(0, 0)}),
      const SnapMissed(),
    );
  });
}
