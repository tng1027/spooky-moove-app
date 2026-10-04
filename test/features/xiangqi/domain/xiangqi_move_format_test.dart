import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/features/xiangqi/data/dart_xiangqi_rules.dart';
import 'package:spookymoove/features/xiangqi/domain/xiangqi_move_format.dart';

void main() {
  final wxfLike = RegExp(r'[KAEHRCP1-5][1-9+\-][+\-.][1-9]');

  String line(String uci, {String? fen}) =>
      XiangqiMoveFormat.moveLine(DartXiangqiRules(fen: fen).moveFromUci(uci)!);

  test('a quiet move in absolute coordinates', () {
    expect(line('h3e3'), 'H3 ➔ E3');
  });

  test('a capture ends with the capture mark', () {
    expect(line('h3h10'), 'H3 ➔ H10 ✕');
  });

  test('Black moves stay in Red\'s frame', () {
    const black =
        'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR b - - 0 1';
    expect(line('b8e8', fen: black), 'B8 ➔ E8');
    expect(line('b10c8', fen: black), 'B10 ➔ C8');
  });

  test('never contains WXF notation', () {
    final rules = DartXiangqiRules();
    for (final move in rules.legalMoves) {
      expect(
        XiangqiMoveFormat.moveLine(move),
        isNot(contains(wxfLike)),
        reason: move.uci,
      );
    }
  });
}
