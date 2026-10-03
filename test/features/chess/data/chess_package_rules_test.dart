import 'package:flutter_test/flutter_test.dart';
import 'package:cataland/features/chess/data/chess_package_rules.dart';
import 'package:cataland/features/chess/domain/chess_models.dart';
import 'package:cataland/features/chess/domain/chess_rules.dart';

int perft(ChessRules rules, int depth) {
  if (depth == 0) return 1;
  final moves = rules.legalMoves;
  if (depth == 1) return moves.length;
  var nodes = 0;
  for (final move in moves) {
    rules.apply(move);
    nodes += perft(rules, depth - 1);
    rules.undo();
  }
  return nodes;
}

ChessSquare sq(String name) => ChessSquare.parse(name);

ChessMove uci(ChessRules rules, String move) {
  final found = rules.moveFromUci(move);
  expect(found, isNotNull, reason: '$move should be legal');
  return found!;
}

void play(ChessRules rules, List<String> moves) {
  for (final move in moves) {
    rules.apply(uci(rules, move));
  }
}

void main() {
  group('perft through the adapter', () {
    final cases = <(String, String?, List<int>)>[
      ('initial position', null, [20, 400, 8902]),
      (
        'kiwipete (castling, en passant, promotion)',
        'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
        [48, 2039],
      ),
      (
        'position 3 (en passant, checks)',
        '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1',
        [14, 191, 2812],
      ),
      (
        'position 4 (promotions)',
        'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1',
        [6, 264, 9467],
      ),
    ];
    for (final (name, fen, counts) in cases) {
      test(name, () {
        final rules = ChessPackageRules(fen: fen);
        for (var depth = 1; depth <= counts.length; depth++) {
          expect(
            perft(rules, depth),
            counts[depth - 1],
            reason: 'depth $depth',
          );
        }
      });
    }
  });

  test('initial position', () {
    final rules = ChessPackageRules();
    expect(rules.sideToMove, PieceColor.white);
    expect(
      rules.pieceAt(sq('e1')),
      const ChessPiece(PieceColor.white, PieceKind.king),
    );
    expect(
      rules.pieceAt(sq('d8')),
      const ChessPiece(PieceColor.black, PieceKind.queen),
    );
    expect(rules.pieceAt(sq('e4')), isNull);
    expect(rules.isCheck, isFalse);
    expect(rules.moveCount, 0);
  });

  test('rejects an illegal move and an invalid FEN', () {
    final rules = ChessPackageRules();
    expect(
      () => rules.apply(ChessMove(from: sq('e2'), to: sq('e5'))),
      throwsArgumentError,
    );
    expect(() => ChessPackageRules(fen: 'not a fen'), throwsArgumentError);
  });

  group('castling', () {
    const fen = 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1';

    test('kingside moves the rook to F1 and undo restores the FEN', () {
      final rules = ChessPackageRules(fen: fen);
      final before = rules.fen;
      final move = uci(rules, 'e1g1');
      expect(move.castling, CastlingSide.kingside);
      expect(move.castlingRookMove, (from: sq('h1'), to: sq('f1')));

      rules.apply(move);
      expect(rules.pieceAt(sq('f1'))?.kind, PieceKind.rook);
      expect(rules.pieceAt(sq('h1')), isNull);
      expect(rules.pieceAt(sq('g1'))?.kind, PieceKind.king);

      expect(rules.undo(), move);
      expect(rules.fen, before);
    });

    test('queenside moves the rook to D8 for Black', () {
      final rules = ChessPackageRules(
        fen: 'r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 0 1',
      );
      final before = rules.fen;
      final move = uci(rules, 'e8c8');
      expect(move.castling, CastlingSide.queenside);

      rules.apply(move);
      expect(rules.pieceAt(sq('d8'))?.kind, PieceKind.rook);
      expect(rules.pieceAt(sq('a8')), isNull);

      rules.undo();
      expect(rules.fen, before);
    });
  });

  test('en passant removes the captured pawn and undo restores it', () {
    final rules = ChessPackageRules();
    play(rules, ['e2e4', 'a7a6', 'e4e5', 'd7d5']);
    final before = rules.fen;
    final move = uci(rules, 'e5d6');
    expect(move.isEnPassant, isTrue);
    expect(move.isCapture, isTrue);

    rules.apply(move);
    expect(rules.pieceAt(sq('d5')), isNull);
    expect(rules.pieceAt(sq('d6'))?.kind, PieceKind.pawn);

    rules.undo();
    expect(rules.fen, before);
    expect(rules.pieceAt(sq('d5'))?.color, PieceColor.black);
  });

  test('every promotion piece is offered, applied and undone', () {
    const fen = '8/P6k/8/8/8/8/8/K7 w - - 0 1';
    final rules = ChessPackageRules(fen: fen);
    final promotions = rules.legalMoves.where((m) => m.isPromotion).toList();
    expect(
      promotions.map((m) => m.promotion),
      unorderedEquals(PieceKind.promotionChoices),
    );

    for (final kind in PieceKind.promotionChoices) {
      final move = uci(rules, 'a7a8${kind.uciLetter}');
      rules.apply(move);
      expect(rules.pieceAt(sq('a8')), ChessPiece(PieceColor.white, kind));
      rules.undo();
      expect(rules.fen, ChessPackageRules(fen: fen).fen);
    }
  });

  test('in check only check-resolving moves are legal', () {
    // Black rook gives check on the e-file; White can block or step aside.
    final rules = ChessPackageRules(fen: '4r2k/8/8/8/R7/8/3P1P2/4K3 w - - 0 1');
    expect(rules.isCheck, isTrue);
    final moves = rules.legalMoves.map((m) => m.uci).toSet();
    expect(moves, {'e1d1', 'e1f1', 'a4e4'});
  });

  test('checkmate and stalemate', () {
    final mate = ChessPackageRules();
    play(mate, ['f2f3', 'e7e5', 'g2g4', 'd8h4']);
    expect(mate.isCheckmate, isTrue);
    expect(mate.isStalemate, isFalse);

    final stalemate = ChessPackageRules(fen: '7k/5Q2/6K1/8/8/8/8/8 b - - 0 1');
    expect(stalemate.isStalemate, isTrue);
    expect(stalemate.isCheckmate, isFalse);
  });

  test('insufficient material and halfmove clock', () {
    expect(
      ChessPackageRules(fen: '8/8/8/4k3/8/8/8/4KN2 w - - 0 1')
          .hasInsufficientMaterial,
      isTrue,
    );
    expect(ChessPackageRules().hasInsufficientMaterial, isFalse);

    final rules = ChessPackageRules();
    play(rules, ['g1f3', 'g8f6']);
    expect(rules.halfmoveClock, 2);
    play(rules, ['e2e4']);
    expect(rules.halfmoveClock, 0);
  });

  test('repetition count follows apply and undo', () {
    final rules = ChessPackageRules();
    expect(rules.repetitionCount, 1);
    play(rules, ['g1f3', 'g8f6', 'f3g1', 'f6g8']);
    expect(rules.repetitionCount, 2);
    play(rules, ['g1f3', 'g8f6', 'f3g1', 'f6g8']);
    expect(rules.repetitionCount, 3);
    rules.undo();
    expect(rules.repetitionCount, 2, reason: 'position after f3g1 seen twice');
  });

  test(
    'a double push without a possible en passant does not break repetition',
    () {
      final rules = ChessPackageRules();
      play(rules, [
        'e2e4',
        'g8f6',
        'g1f3',
        'f6g8',
        'f3g1',
        'g8f6',
        'g1f3',
        'f6g8',
        'f3g1',
      ]);
      // After e2e4 the package records `e3`; the same placement later has `-`.
      expect(rules.repetitionCount, 3);
    },
  );

  test('engine position and UCI round trip', () {
    final rules = ChessPackageRules();
    play(rules, ['e2e4', 'e7e5']);
    final position = rules.toEnginePosition();
    expect(position.fen, isNull);
    expect(position.moves, ['e2e4', 'e7e5']);
    expect(rules.moveFromUci('g1f3')?.uci, 'g1f3');
    expect(rules.moveFromUci('e1e3'), isNull);

    const fen = '8/P6k/8/8/8/8/8/K7 w - - 0 1';
    final fromFen = ChessPackageRules(fen: fen);
    fromFen.apply(uci(fromFen, 'a7a8n'));
    expect(fromFen.toEnginePosition().fen, fen);
    expect(fromFen.toEnginePosition().moves, ['a7a8n']);
  });

  test('reset clears the history', () {
    final rules = ChessPackageRules();
    play(rules, ['e2e4']);
    rules.reset();
    expect(rules.moveCount, 0);
    expect(rules.undo(), isNull);
    expect(rules.fen, ChessPackageRules().fen);
  });
}
