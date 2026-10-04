import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/engine/engine_models.dart';
import 'package:spookymoove/core/game/player_side.dart';
import 'package:spookymoove/features/xiangqi/data/dart_xiangqi_rules.dart';
import 'package:spookymoove/features/xiangqi/domain/xiangqi_models.dart';

import 'xiangqi_perft_positions.dart';

XiangqiPoint pt(String name) => XiangqiPoint.parse(name);

/// Destinations of the legal moves starting on [from].
Set<String> destinations(DartXiangqiRules rules, String from) => {
  for (final move in rules.legalMoves)
    if (move.from == pt(from)) move.to.name,
};

void main() {
  group('horse', () {
    test('an occupied leg removes the two destinations over it', () {
      final rules = DartXiangqiRules(
        fen: '4k4/9/9/9/9/9/9/4P4/4N4/3K5 w - - 0 1',
      );
      final targets = destinations(rules, 'e2');
      expect(targets, isNot(contains('d4')));
      expect(targets, isNot(contains('f4')));
      expect(targets, containsAll(['c3', 'c1', 'g3', 'g1']));
    });

    test('a free leg allows both destinations', () {
      final rules = DartXiangqiRules(
        fen: '4k4/9/9/9/9/9/9/9/4N4/3K5 w - - 0 1',
      );
      expect(destinations(rules, 'e2'), containsAll(['d4', 'f4']));
    });
  });

  group('elephant', () {
    test('an occupied eye blocks that destination', () {
      final rules = DartXiangqiRules(
        fen: '4k4/9/9/9/9/9/9/9/3P5/2BK5 w - - 0 1',
      );
      expect(destinations(rules, 'c1'), {'a3'});
    });

    test('cannot cross the river', () {
      final rules = DartXiangqiRules(
        fen: '4k4/9/9/9/9/2B6/9/9/9/3K5 w - - 0 1',
      );
      expect(destinations(rules, 'c5'), {'a3', 'e3'});
    });
  });

  group('cannon', () {
    test('captures over exactly one screen, never the screen itself', () {
      final rules = DartXiangqiRules(
        fen: '4k4/9/9/9/r8/9/9/p8/9/C2K5 w - - 0 1',
      );
      final targets = destinations(rules, 'a1');
      expect(targets, contains('a6'));
      expect(targets, isNot(contains('a3')));
      expect(targets, containsAll(['a2', 'b1', 'c1']));
    });

    test('no screen: no capture', () {
      final rules = DartXiangqiRules(
        fen: '4k4/9/9/9/r8/9/9/9/9/C2K5 w - - 0 1',
      );
      final targets = destinations(rules, 'a1');
      expect(targets, isNot(contains('a6')));
      expect(targets, containsAll(['a2', 'a3', 'a4', 'a5']));
    });

    test('two screens: no capture', () {
      final rules = DartXiangqiRules(
        fen: '4k4/9/9/9/r8/9/9/p8/P8/C2K5 w - - 0 1',
      );
      expect(destinations(rules, 'a1'), isNot(contains('a6')));
    });
  });

  group('soldier', () {
    test('before the river: forward only', () {
      final rules = DartXiangqiRules(
        fen: '3k5/9/9/9/9/9/4P4/9/9/5K3 w - - 0 1',
      );
      expect(destinations(rules, 'e4'), {'e5'});
    });

    test('after the river: forward and sideways, never backwards', () {
      final rules = DartXiangqiRules(
        fen: '3k5/9/9/9/4P4/9/9/9/9/5K3 w - - 0 1',
      );
      expect(destinations(rules, 'e6'), {'e7', 'd6', 'f6'});
    });

    test('on the last rank: sideways only', () {
      final rules = DartXiangqiRules(fen: 'P2k5/9/9/9/9/9/9/9/9/5K3 w - - 0 1');
      expect(destinations(rules, 'a10'), {'b10'});
    });

    test('a Black soldier moves down the board', () {
      final rules = DartXiangqiRules(
        fen: '3k5/9/9/4p4/9/9/9/9/9/5K3 b - - 0 1',
      );
      expect(destinations(rules, 'e7'), {'e6'});
    });
  });

  group('flying general', () {
    test('a general may not step onto the open file of the other', () {
      final rules = DartXiangqiRules(fen: '4k4/9/9/9/9/9/9/9/9/3K5 w - - 0 1');
      expect(destinations(rules, 'd1'), {'d2'});
    });

    test('a general capture that would face the other general is illegal', () {
      final rules = DartXiangqiRules(fen: '4k4/9/9/9/9/9/9/9/9/3Kr4 w - - 0 1');
      expect(rules.isCheck, isTrue);
      expect(destinations(rules, 'd1'), {'d2'});
    });

    test('a piece between the generals may only move along the file', () {
      final rules = DartXiangqiRules(
        fen: '3k5/4a4/9/9/9/3R5/9/9/4N4/3K5 w - - 0 1',
      );
      final targets = destinations(rules, 'd5');
      expect(targets, isNotEmpty);
      expect(targets.every((name) => name.startsWith('d')), isTrue);
    });
  });

  test("a cannon's second screen is pinned", () {
    final rules = DartXiangqiRules(
      fen: '4k4/9/4n4/9/9/4N4/9/4C4/9/3K5 b - - 0 1',
    );
    expect(rules.isCheck, isFalse);
    expect(destinations(rules, 'e8'), isEmpty);
  });

  group('no legal moves', () {
    test('checkmate: in check and no legal move', () {
      final rules = DartXiangqiRules(
        fen: 'R3k4/1R7/9/9/9/9/9/9/9/3K5 b - - 0 1',
      );
      expect(rules.isCheck, isTrue);
      expect(rules.hasNoLegalMoves, isTrue);
    });

    test('stalemate: no legal move without check', () {
      final rules = DartXiangqiRules(
        fen: '4k4/9/6N2/9/9/3R1R3/9/9/9/3K5 b - - 0 1',
      );
      expect(rules.isCheck, isFalse);
      expect(rules.hasNoLegalMoves, isTrue);
    });
  });

  group('apply / undo / reset', () {
    const moves = [
      'h3e3', 'h10g8', 'h1g3', 'i10h10', 'i1h1', 'b8b4', //
      'b1c3', 'h8h4', 'c4c5', 'g7g6', 'e3e7', 'g8e7',
    ];

    test('every undo restores the previous FEN, captures included', () {
      final rules = DartXiangqiRules();
      final fens = <String>[];
      for (final uci in moves) {
        fens.add(rules.fen);
        rules.apply(rules.moveFromUci(uci)!);
      }
      expect(rules.moveCount, moves.length);
      for (final uci in moves.reversed) {
        expect(rules.undo()?.uci, uci);
        expect(rules.fen, fens.removeLast());
      }
      expect(rules.moveCount, 0);
      expect(rules.undo(), isNull);
    });

    test('a capture records the captured piece and undo puts it back', () {
      final rules = DartXiangqiRules();
      for (final uci in moves.take(10)) {
        rules.apply(rules.moveFromUci(uci)!);
      }
      final capture = rules.moveFromUci('e3e7')!;
      expect(
        capture.captured,
        const XiangqiPiece(PlayerSide.second, XiangqiPieceKind.soldier),
      );
      rules
        ..apply(capture)
        ..undo();
      expect(
        rules.pieceAt(pt('e7')),
        const XiangqiPiece(PlayerSide.second, XiangqiPieceKind.soldier),
      );
    });

    test('reset returns to the start with an empty history', () {
      final rules = DartXiangqiRules();
      rules.apply(rules.moveFromUci('h3e3')!);
      rules.reset();
      expect(rules.fen, DartXiangqiRules.startFen);
      expect(rules.moveCount, 0);
      expect(rules.sideToMove, PlayerSide.first);
    });

    test('an illegal move throws ArgumentError', () {
      final rules = DartXiangqiRules();
      expect(
        () => rules.apply(XiangqiMove(from: pt('a1'), to: pt('a9'))),
        throwsArgumentError,
      );
    });

    test('the side to move alternates', () {
      final rules = DartXiangqiRules();
      rules.apply(rules.moveFromUci('h3e3')!);
      expect(rules.sideToMove, PlayerSide.second);
    });
  });

  group('engine notation', () {
    test('every legal move round-trips through moveFromUci', () {
      for (final position in xiangqiPerftPositions) {
        final rules = DartXiangqiRules(fen: position.fen);
        for (final move in rules.legalMoves) {
          expect(rules.moveFromUci(move.uci), move, reason: move.uci);
        }
      }
    });

    test('a1a9 is not legal at the start', () {
      expect(DartXiangqiRules().moveFromUci('a1a9'), isNull);
    });

    test('rank 10 moves parse (a10a9, i10i9)', () {
      final rules = DartXiangqiRules(
        fen: DartXiangqiRules.startFen.replaceFirst(' w ', ' b '),
      );
      expect(rules.moveFromUci('a10a9')?.from, const XiangqiPoint(0, 9));
      expect(rules.moveFromUci('i10i9')?.to, const XiangqiPoint(8, 8));
    });

    test('points parse ranks 1 to 10 only', () {
      expect(XiangqiPoint.tryParse('a1'), const XiangqiPoint(0, 0));
      expect(XiangqiPoint.tryParse('i10'), const XiangqiPoint(8, 9));
      for (final bad in ['a0', 'a11', 'j1', 'a01', 'a', 'a+1', '']) {
        expect(XiangqiPoint.tryParse(bad), isNull, reason: bad);
      }
    });

    test('the engine position is the start plus the moves played', () {
      final rules = DartXiangqiRules();
      rules
        ..apply(rules.moveFromUci('h3e3')!)
        ..apply(rules.moveFromUci('h10g8')!);
      final position = rules.toEnginePosition();
      expect(position.fen, isNull);
      expect(position.moves, ['h3e3', 'h10g8']);
    });

    test('a FEN-built position sends its FEN', () {
      const fen = '4k4/9/9/9/9/9/9/9/9/3K5 w - - 0 1';
      final EnginePosition position = DartXiangqiRules(fen: fen)
          .toEnginePosition();
      expect(position.fen, fen);
    });
  });

  test('legal moves are computed once per position', () {
    final rules = DartXiangqiRules();
    expect(identical(rules.legalMoves, rules.legalMoves), isTrue);
    expect(rules.legalMoves, hasLength(44));
  });
}
