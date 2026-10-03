import 'dart:ui';

/// Where a tap on a cell grid lands (OB-044 XQ3 snapping).
sealed class SnapResult {
  const SnapResult();
}

/// The tap acts on the target cell ([column], [row]).
final class SnapToCell extends SnapResult {
  const SnapToCell(this.column, this.row);

  final int column;
  final int row;

  @override
  bool operator ==(Object other) =>
      other is SnapToCell && other.column == column && other.row == row;

  @override
  int get hashCode => Object.hash(column, row);

  @override
  String toString() => 'SnapToCell($column, $row)';
}

/// Two or more targets are equally near: the tap does nothing.
final class SnapIgnored extends SnapResult {
  const SnapIgnored();
}

/// No target within one cell: the tap acts as a tap on nothing.
final class SnapMissed extends SnapResult {
  const SnapMissed();
}

const double _tieTolerance = 1e-6;

/// Resolves [tap] (board pixels, origin top-left) on a grid of square cells of
/// size [cell]. [targets] are the (column, row) cells that would act.
///
/// The tapped cell wins when it is a target; otherwise the nearest target
/// centre within one cell, unless that distance is tied.
SnapResult snapTap({
  required Offset tap,
  required double cell,
  required Set<(int column, int row)> targets,
}) {
  if (cell <= 0 || targets.isEmpty) return const SnapMissed();
  final tapped = ((tap.dx / cell).floor(), (tap.dy / cell).floor());
  if (targets.contains(tapped)) return SnapToCell(tapped.$1, tapped.$2);

  (int, int)? nearest;
  var nearestDistance = double.infinity;
  var isTied = false;
  for (final target in targets) {
    final centre = Offset((target.$1 + 0.5) * cell, (target.$2 + 0.5) * cell);
    final distance = (tap - centre).distance;
    if (distance > cell) continue;
    if ((distance - nearestDistance).abs() <= _tieTolerance) {
      isTied = true;
    } else if (distance < nearestDistance) {
      nearest = target;
      nearestDistance = distance;
      isTied = false;
    }
  }
  if (nearest == null) return const SnapMissed();
  if (isTied) return const SnapIgnored();
  return SnapToCell(nearest.$1, nearest.$2);
}
