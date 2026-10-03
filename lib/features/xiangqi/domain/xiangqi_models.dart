/// Typed Xiangqi model used by the board, the session and the engine bridge
/// (OB-043 REQ-001). Red is [PlayerSide.first], Black [PlayerSide.second].
library;

import '../../../core/board/smart_entry.dart';
import '../../../core/game/player_side.dart';

enum XiangqiPieceKind {
  general('k'),
  advisor('a'),
  elephant('b'),
  horse('n'),
  chariot('r'),
  cannon('c'),
  soldier('p');

  const XiangqiPieceKind(this.fenLetter);

  /// Lower-case Fairy-Stockfish FEN letter, never shown in the UI.
  final String fenLetter;
}

/// Board point; [file] 0..8 = a..i from Red's left, [rank] 0..9 = 1..10 from
/// Red's side.
final class XiangqiPoint {
  const XiangqiPoint(this.file, this.rank)
    : assert(file >= 0 && file < files),
      assert(rank >= 0 && rank < ranks);

  static const int files = 9;
  static const int ranks = 10;

  /// Parses `e1` or `h10`; returns null for anything else.
  static XiangqiPoint? tryParse(String name) {
    if (name.length < 2 || name.length > 3) return null;
    final file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.tryParse(name.substring(1));
    if (rank == null || name[1] == '0' || name[1] == '+' || name[1] == '-') {
      return null;
    }
    if (file < 0 || file >= files || rank < 1 || rank > ranks) return null;
    return XiangqiPoint(file, rank - 1);
  }

  /// Parses `e1`; throws [FormatException] for anything else.
  factory XiangqiPoint.parse(String name) =>
      tryParse(name) ?? (throw FormatException('Invalid point', name));

  final int file;
  final int rank;

  /// Engine coordinate, e.g. `e1`, `h10`.
  String get name =>
      '${String.fromCharCode('a'.codeUnitAt(0) + file)}${rank + 1}';

  @override
  bool operator ==(Object other) =>
      other is XiangqiPoint && other.file == file && other.rank == rank;

  @override
  int get hashCode => rank * files + file;

  @override
  String toString() => name;
}

final class XiangqiPiece {
  const XiangqiPiece(this.side, this.kind);

  final PlayerSide side;
  final XiangqiPieceKind kind;

  @override
  bool operator ==(Object other) =>
      other is XiangqiPiece && other.side == side && other.kind == kind;

  @override
  int get hashCode => Object.hash(side, kind);

  @override
  String toString() => 'XiangqiPiece(${side.name} ${kind.name})';
}

final class XiangqiMove implements EntryMove<XiangqiPoint> {
  const XiangqiMove({required this.from, required this.to, this.captured});

  @override
  final XiangqiPoint from;
  @override
  final XiangqiPoint to;

  /// The piece standing on [to] before the move, if any.
  final XiangqiPiece? captured;

  bool get isCapture => captured != null;

  /// Engine notation, e.g. `h3e3`, `h10g8`.
  String get uci => '${from.name}${to.name}';

  @override
  bool operator ==(Object other) =>
      other is XiangqiMove &&
      other.from == from &&
      other.to == to &&
      other.captured == captured;

  @override
  int get hashCode => Object.hash(from, to, captured);

  @override
  String toString() => 'XiangqiMove($uci)';
}
