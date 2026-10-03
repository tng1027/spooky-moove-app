import '../../../core/game/move_text.dart';
import 'chess_models.dart';

/// Plain-coordinate move text for users without chess knowledge (OB-007):
/// no SAN, piece letters, `O-O` or `e.p.`.
abstract final class ChessMoveFormat {
  static const String arrow = MoveText.arrow;
  static const String captureMark = '✕';

  /// Uppercase file + rank in White's frame, e.g. `E4`.
  static String squareLabel(ChessSquare square) => square.name.toUpperCase();

  /// `E2 ➔ E4`, with `✕` when a piece is captured (en passant included).
  /// A promotion piece is shown as a pictogram by the caller.
  static String moveLine(ChessMove move) {
    final line = '${squareLabel(move.from)} $arrow ${squareLabel(move.to)}';
    return move.isCapture ? '$line $captureMark' : line;
  }

  /// The extra physical action of castling (the rook also moves) or en
  /// passant (remove the captured pawn); null for other moves.
  static MoveInstruction? instructionFor(ChessMove move) {
    final rook = move.castlingRookMove;
    if (rook != null) {
      return MoveInstruction(
        pictogram: PieceKind.rook,
        text: '${squareLabel(rook.from)} $arrow ${squareLabel(rook.to)}',
      );
    }
    final captured = enPassantCapturedSquare(move);
    if (captured != null) {
      return MoveInstruction(text: '$captureMark ${squareLabel(captured)}');
    }
    return null;
  }

  /// The square of the pawn removed by an en passant capture.
  static ChessSquare? enPassantCapturedSquare(ChessMove move) =>
      move.isEnPassant ? ChessSquare(move.to.file, move.from.rank) : null;
}

/// Second card line: an optional piece pictogram followed by [text].
final class MoveInstruction {
  const MoveInstruction({required this.text, this.pictogram});

  final String text;
  final PieceKind? pictogram;

  @override
  bool operator ==(Object other) =>
      other is MoveInstruction &&
      other.text == text &&
      other.pictogram == pictogram;

  @override
  int get hashCode => Object.hash(text, pictogram);

  @override
  String toString() => 'MoveInstruction($pictogram, $text)';
}
