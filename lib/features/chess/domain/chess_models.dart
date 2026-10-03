/// Typed Chess model used by the UI, the session and the engine bridge.
/// Third-party rules types never leave the rules adapter.
library;

import '../../../core/board/smart_entry.dart';
import '../../../core/game/player_side.dart';

enum PieceColor {
  white,
  black;

  /// White moves first.
  factory PieceColor.of(PlayerSide side) =>
      side == PlayerSide.first ? white : black;

  PieceColor get opposite => this == white ? black : white;

  PlayerSide get side => this == white ? PlayerSide.first : PlayerSide.second;
}

enum PieceKind {
  pawn('p'),
  knight('n'),
  bishop('b'),
  rook('r'),
  queen('q'),
  king('k');

  const PieceKind(this.uciLetter);

  /// Lower-case letter used only in engine (UCI) notation, never in the UI.
  final String uciLetter;

  /// Promotion choices in chooser order (queen first).
  static const List<PieceKind> promotionChoices = [queen, rook, bishop, knight];
}

/// Board square; [file] 0..7 = a..h, [rank] 0..7 = 1..8.
final class ChessSquare {
  const ChessSquare(this.file, this.rank)
    : assert(file >= 0 && file < 8),
      assert(rank >= 0 && rank < 8);

  /// Parses `e4`; returns null for anything else.
  static ChessSquare? tryParse(String name) {
    if (name.length != 2) return null;
    final file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = name.codeUnitAt(1) - '1'.codeUnitAt(0);
    if (file < 0 || file > 7 || rank < 0 || rank > 7) return null;
    return ChessSquare(file, rank);
  }

  /// Parses `e4`; throws [FormatException] for anything else.
  factory ChessSquare.parse(String name) =>
      tryParse(name) ?? (throw FormatException('Invalid square', name));

  final int file;
  final int rank;

  /// Lower-case coordinate, e.g. `e4`.
  String get name =>
      '${String.fromCharCode('a'.codeUnitAt(0) + file)}${rank + 1}';

  @override
  bool operator ==(Object other) =>
      other is ChessSquare && other.file == file && other.rank == rank;

  @override
  int get hashCode => file * 8 + rank;

  @override
  String toString() => name;
}

final class ChessPiece {
  const ChessPiece(this.color, this.kind);

  final PieceColor color;
  final PieceKind kind;

  @override
  bool operator ==(Object other) =>
      other is ChessPiece && other.color == color && other.kind == kind;

  @override
  int get hashCode => Object.hash(color, kind);

  @override
  String toString() => 'ChessPiece(${color.name} ${kind.name})';
}

enum CastlingSide { kingside, queenside }

final class ChessMove implements EntryMove<ChessSquare> {
  const ChessMove({
    required this.from,
    required this.to,
    this.promotion,
    this.isCapture = false,
    this.castling,
    this.isEnPassant = false,
  });

  @override
  final ChessSquare from;
  @override
  final ChessSquare to;
  final PieceKind? promotion;

  /// True for every capture, including en passant.
  final bool isCapture;

  /// Non-null when this is a castling move (the king's move).
  final CastlingSide? castling;
  final bool isEnPassant;

  bool get isPromotion => promotion != null;
  bool get isCastling => castling != null;

  /// Engine notation, e.g. `e2e4`, `e7e8q`.
  String get uci => '${from.name}${to.name}${promotion?.uciLetter ?? ''}';

  /// The rook's move for a castling move, else null.
  ({ChessSquare from, ChessSquare to})? get castlingRookMove =>
      switch (castling) {
        null => null,
        CastlingSide.kingside => (
          from: ChessSquare(7, from.rank),
          to: ChessSquare(5, from.rank),
        ),
        CastlingSide.queenside => (
          from: ChessSquare(0, from.rank),
          to: ChessSquare(3, from.rank),
        ),
      };

  @override
  bool operator ==(Object other) =>
      other is ChessMove &&
      other.from == from &&
      other.to == to &&
      other.promotion == promotion &&
      other.isCapture == isCapture &&
      other.castling == castling &&
      other.isEnPassant == isEnPassant;

  @override
  int get hashCode =>
      Object.hash(from, to, promotion, isCapture, castling, isEnPassant);

  @override
  String toString() => 'ChessMove($uci)';
}
