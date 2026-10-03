import '../../../core/game/player_side.dart';
import 'xiangqi_models.dart';

/// WXF notation for the expert line (OB-046 REQ-005), e.g. `C2.5`, `H2+3`,
/// `R9+6`, tandem `H++7`, multi-tandem soldiers `15.6`.
///
/// Ported from Fairy-Stockfish's `NOTATION_XIANGQI_WXF` (`apiutil.h`) so it
/// agrees with the engine's own formatter, except that a sideways move uses
/// `.` (the WXF standard) where Fairy-Stockfish writes `=`.
abstract final class XiangqiWxf {
  static const Map<XiangqiPieceKind, String> _letters = {
    XiangqiPieceKind.general: 'K',
    XiangqiPieceKind.advisor: 'A',
    XiangqiPieceKind.elephant: 'E',
    XiangqiPieceKind.horse: 'H',
    XiangqiPieceKind.chariot: 'R',
    XiangqiPieceKind.cannon: 'C',
    XiangqiPieceKind.soldier: 'P',
  };

  /// [pieces] is the position before [move], which must be a move of the
  /// piece on `move.from`.
  static String format(
    Map<XiangqiPoint, XiangqiPiece> pieces,
    XiangqiMove move,
  ) {
    final from = move.from;
    final to = move.to;
    final mover = pieces[from];
    if (mover == null) {
      throw ArgumentError.value(move, 'move', 'No piece on ${from.name}');
    }
    final side = mover.side;
    final same = [
      for (final MapEntry(:key, :value) in pieces.entries)
        if (value == mover) key,
    ];
    final onFile = [
      for (final point in same)
        if (point.file == from.file) point,
    ];
    final isMultiTandem = _isMultiTandem(same);
    final ahead = onFile.where((p) => _isAhead(p, from, side)).length;

    final piece = onFile.length >= (isMultiTandem ? 2 : 3)
        ? '${ahead + 1}'
        : _letters[mover.kind]!;

    final origin =
        _usesRankDisambiguation(mover, from, to, onFile, isMultiTandem)
        ? (ahead > 0 ? '-' : '+')
        : '${_fileNumber(from.file, side)}';

    final String operator;
    if (from.rank == to.rank) {
      operator = '.';
    } else {
      operator = _relativeRank(to, side) > _relativeRank(from, side)
          ? '+'
          : '-';
    }

    final target = from.file == to.file
        ? '${(to.rank - from.rank).abs()}'
        : '${_fileNumber(to.file, side)}';

    return '$piece$origin$operator$target';
  }

  /// Files are numbered 1–9 from the mover's right.
  static int _fileNumber(int file, PlayerSide side) =>
      side == PlayerSide.first ? XiangqiPoint.files - file : file + 1;

  static int _relativeRank(XiangqiPoint point, PlayerSide side) =>
      side == PlayerSide.first
      ? point.rank
      : XiangqiPoint.ranks - 1 - point.rank;

  /// [point] is further forward than [from] (same file) from [side]'s view.
  static bool _isAhead(
    XiangqiPoint point,
    XiangqiPoint from,
    PlayerSide side,
  ) => _relativeRank(point, side) > _relativeRank(from, side);

  /// More than one file holds two or more of these pieces.
  static bool _isMultiTandem(List<XiangqiPoint> same) {
    final perFile = <int, int>{};
    for (final point in same) {
      perFile.update(point.file, (n) => n + 1, ifAbsent: () => 1);
    }
    return perFile.values.where((n) => n >= 2).length >= 2;
  }

  /// Front/rear (`+`/`-`) instead of the file number, for exactly two of a
  /// kind on the file, when the other piece could make the same step.
  static bool _usesRankDisambiguation(
    XiangqiPiece mover,
    XiangqiPoint from,
    XiangqiPoint to,
    List<XiangqiPoint> onFile,
    bool isMultiTandem,
  ) {
    if (onFile.length != 2 || isMultiTandem) return false;
    final other = onFile.firstWhere((p) => p != from);
    final file = other.file + to.file - from.file;
    final rank = other.rank + to.rank - from.rank;
    if (file < 0 || file >= XiangqiPoint.files) return false;
    if (rank < 0 || rank >= XiangqiPoint.ranks) return false;
    return _isInRegion(mover, file, rank);
  }

  /// Where a piece of this kind may stand (Fairy-Stockfish mobility region).
  static bool _isInRegion(XiangqiPiece piece, int file, int rank) {
    final isRed = piece.side == PlayerSide.first;
    switch (piece.kind) {
      case XiangqiPieceKind.general || XiangqiPieceKind.advisor:
        final inPalaceRanks = isRed ? rank <= 2 : rank >= 7;
        return inPalaceRanks && file >= 3 && file <= 5;
      case XiangqiPieceKind.elephant:
        return isRed ? rank <= 4 : rank >= 5;
      case XiangqiPieceKind.horse ||
          XiangqiPieceKind.chariot ||
          XiangqiPieceKind.cannon ||
          XiangqiPieceKind.soldier:
        return true;
    }
  }
}
