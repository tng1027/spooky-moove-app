import 'package:flutter_test/flutter_test.dart';
import 'package:cataland/features/chess/data/chess_package_rules.dart';
import 'package:cataland/features/chess/domain/chess_models.dart';
import 'package:cataland/features/chess/domain/chess_move_format.dart';

/// Real moves (with rules-module flags) for [uci] in [fen].
ChessMove moveIn(String fen, String uci) {
  final rules = ChessPackageRules(fen: fen);
  final move = rules.moveFromUci(uci);
  if (move == null) throw ArgumentError('$uci is not legal in $fen');
  return move;
}

const startFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
const castlingFen = 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1';
const blackCastlingFen = 'r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 0 1';

void main() {
  test('normal move: coordinates only, no instruction', () {
    final move = moveIn(startFen, 'e2e4');
    expect(ChessMoveFormat.moveLine(move), 'E2 ➔ E4');
    expect(ChessMoveFormat.instructionFor(move), isNull);
  });

  test('capture adds the capture mark', () {
    final move = moveIn(
      'rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 2',
      'e4d5',
    );
    expect(ChessMoveFormat.moveLine(move), 'E4 ➔ D5 ✕');
    expect(ChessMoveFormat.instructionFor(move), isNull);
  });

  test('castling shows the king move and the rook instruction', () {
    final cases = {
      (castlingFen, 'e1g1'): ('E1 ➔ G1', 'H1 ➔ F1'),
      (castlingFen, 'e1c1'): ('E1 ➔ C1', 'A1 ➔ D1'),
      (blackCastlingFen, 'e8g8'): ('E8 ➔ G8', 'H8 ➔ F8'),
      (blackCastlingFen, 'e8c8'): ('E8 ➔ C8', 'A8 ➔ D8'),
    };
    for (final MapEntry(key: (fen, uci), value: (main, rook))
        in cases.entries) {
      final move = moveIn(fen, uci);
      expect(ChessMoveFormat.moveLine(move), main, reason: uci);
      expect(
        ChessMoveFormat.instructionFor(move),
        MoveInstruction(pictogram: PieceKind.rook, text: rook),
        reason: uci,
      );
    }
  });

  test('en passant marks the capture and names the removed pawn', () {
    final move = moveIn(
      'rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3',
      'e5d6',
    );
    expect(ChessMoveFormat.moveLine(move), 'E5 ➔ D6 ✕');
    expect(
      ChessMoveFormat.instructionFor(move),
      const MoveInstruction(text: '✕ D5'),
    );
    expect(
      ChessMoveFormat.enPassantCapturedSquare(move),
      ChessSquare.parse('d5'),
    );
  });

  test('promotion has no piece letter; the piece comes from the move', () {
    const fen = '3r3k/4P3/8/8/8/8/8/K7 w - - 0 1';
    final push = moveIn(fen, 'e7e8q');
    expect(ChessMoveFormat.moveLine(push), 'E7 ➔ E8');
    expect(push.promotion, PieceKind.queen);

    final capture = moveIn(fen, 'e7d8n');
    expect(ChessMoveFormat.moveLine(capture), 'E7 ➔ D8 ✕');
    expect(capture.promotion, PieceKind.knight);
    expect(ChessMoveFormat.instructionFor(capture), isNull);
  });

  test('no notation letters ever appear', () {
    final moves = [
      moveIn(castlingFen, 'e1g1'),
      moveIn('3r3k/4P3/8/8/8/8/8/K7 w - - 0 1', 'e7d8q'),
    ];
    for (final move in moves) {
      final text = [
        ChessMoveFormat.moveLine(move),
        ChessMoveFormat.instructionFor(move)?.text ?? '',
      ].join(' ');
      expect(text, isNot(matches(RegExp(r'O-O|e\.p\.|[KQRBN](?![0-9])'))));
    }
  });
}
