import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/features/xiangqi/data/dart_xiangqi_rules.dart';
import 'package:spookymoove/features/xiangqi/domain/xiangqi_models.dart';
import 'package:spookymoove/features/xiangqi/domain/xiangqi_wxf.dart';

String wxf(String fen, String uci) {
  final rules = DartXiangqiRules(fen: fen);
  final move = rules.moveFromUci(uci);
  expect(move, isNotNull, reason: '$uci is not legal in $fen');
  final pieces = <XiangqiPoint, XiangqiPiece>{
    for (var rank = 0; rank < XiangqiPoint.ranks; rank++)
      for (var file = 0; file < XiangqiPoint.files; file++)
        XiangqiPoint(file, rank): ?rules.pieceAt(XiangqiPoint(file, rank)),
  };
  return XiangqiWxf.format(pieces, move!);
}

const start = DartXiangqiRules.startFen;
const startBlack =
    'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR b - - 0 1';

void main() {
  group('Fairy-Stockfish test.py cases (= written as .)', () {
    for (final (fen, uci, expected) in const [
      (start, 'h1g3', 'H2+3'),
      (start, 'c1e3', 'E7+5'),
      (start, 'h3h10', 'C2+7'),
      ('4k4/4a3R/9/9/9/9/9/9/4K4/9 w - - 0 1', 'i9e9', 'R1.5'),
      ('4k4/4a3R/9/9/9/9/9/9/4K4/9 w - - 0 1', 'i9i10', 'R1+1'),
      (
        'rnbakabnr/9/1c5c1/p1p1p1p1p/4P4/1NB6/P1P1P3P/1C1A3C1/9/RNBAK4 w - - 0 1',
        'c5e3',
        'E7-5',
      ),
      (
        'rnbakabnr/9/1c5c1/p1p1p1p1p/4P4/1NB6/P1P1P3P/1C1A3C1/9/RNBAK4 w - - 0 1',
        'd1e2',
        'A6+5',
      ),
      (
        'rnbakabnr/9/1c5c1/p1p1p1p1p/4P4/1NB6/P1P1P3P/1C1A3C1/9/RNBAK4 w - - 0 1',
        'b5c7',
        'H++7',
      ),
      (
        'rnbakabnr/9/1c5c1/p1p1p1p1p/4P4/1NB6/P1P1P3P/1C1A3C1/9/RNBAK4 w - - 0 1',
        'e6e7',
        'P++1',
      ),
      (
        'rnbakabnr/9/1c5c1/p1p1p1p1p/4P4/1NB6/P1P1P3P/1C1A3C1/9/RNBAK4 w - - 0 1',
        'e4e5',
        'P-+1',
      ),
      (
        'rnbakabnr/9/1c5c1/p1p1P1p1p/4P4/9/P3P3P/1C5C1/9/RNBAKABNR w - - 0 1',
        'e7d7',
        '15.6',
      ),
      (
        'rnbakabnr/9/1c5c1/p1p1P1p1p/4P4/9/P3P3P/1C5C1/9/RNBAKABNR w - - 0 1',
        'e6d6',
        '25.6',
      ),
      (
        'rnbakabnr/9/1c5c1/p1p1P1p1p/4P4/9/P3P3P/1C5C1/9/RNBAKABNR w - - 0 1',
        'e4e5',
        '35+1',
      ),
      ('5k3/9/3P5/3P1P1P1/5P3/9/9/9/9/4K4 w - - 0 1', 'd7e7', '26.5'),
      ('5k3/9/3P5/3P1P1P1/5P3/9/9/9/9/4K4 w - - 0 1', 'f6e6', '24.5'),
    ]) {
      test('$uci -> $expected', () => expect(wxf(fen, uci), expected));
    }
  });

  group('ticket cases', () {
    test(
      'Red cannon H3 to E3 is C2.5',
      () => expect(wxf(start, 'h3e3'), 'C2.5'),
    );
    test('Black cannon B8 to E8 is C2.5 (Black counts from its right)', () {
      expect(wxf(startBlack, 'b8e8'), 'C2.5');
    });
  });

  group('every piece kind, both sides', () {
    for (final (fen, uci, expected) in const [
      (start, 'a1a2', 'R9+1'),
      (start, 'e1e2', 'K5+1'),
      (start, 'f1e2', 'A4+5'),
      (start, 'c4c5', 'P7+1'),
      (startBlack, 'b10c8', 'H2+3'),
      (startBlack, 'c10e8', 'E3+5'),
      (startBlack, 'd10e9', 'A4+5'),
      (startBlack, 'e10e9', 'K5+1'),
      (startBlack, 'a7a6', 'P1+1'),
      (startBlack, 'a10a8', 'R1+2'),
      // Red retreats and sideways moves.
      ('3k5/9/9/9/9/R3N4/9/9/9/4K4 w - - 0 1', 'a5a2', 'R9-3'),
      ('3k5/9/9/9/9/R3N4/9/9/9/4K4 w - - 0 1', 'a5d5', 'R9.6'),
      ('3k5/9/9/9/9/R3N4/9/9/9/4K4 w - - 0 1', 'e5d3', 'H5-6'),
      ('3k5/9/9/9/9/R3N4/9/9/9/4K4 w - - 0 1', 'e5f7', 'H5+4'),
      ('5k3/9/9/9/9/9/9/9/9/4K4 w - - 0 1', 'e1d1', 'K5.6'),
      // Black retreats, advances and sideways moves (Black's forward is down).
      ('3k5/9/9/9/r8/9/9/9/9/4K4 b - - 0 1', 'a6a9', 'R1-3'),
      ('3k5/9/9/9/r8/9/9/9/9/4K4 b - - 0 1', 'a6a3', 'R1+3'),
      ('3k5/9/9/9/r8/9/9/9/9/4K4 b - - 0 1', 'a6c6', 'R1.3'),
    ]) {
      test('$uci -> $expected', () => expect(wxf(fen, uci), expected));
    }
  });

  group('tandems', () {
    const chariots = '3k5/9/9/9/R8/9/9/R8/9/4K4 w - - 0 1';
    const cannons = '3k5/9/9/9/C8/9/9/C8/9/4K4 w - - 0 1';

    test('front chariot', () => expect(wxf(chariots, 'a6a8'), 'R++2'));
    test('rear chariot', () => expect(wxf(chariots, 'a3b3'), 'R-.8'));
    test('front cannon', () => expect(wxf(cannons, 'a6a7'), 'C++1'));
    test('rear cannon', () => expect(wxf(cannons, 'a3a2'), 'C--1'));
  });
}
