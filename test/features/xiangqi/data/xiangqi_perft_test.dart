import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/features/xiangqi/data/dart_xiangqi_rules.dart';

import 'xiangqi_perft_positions.dart';

void main() {
  for (final position in xiangqiPerftPositions) {
    group(position.name, () {
      for (var depth = 1; depth <= position.counts.length; depth++) {
        test('perft $depth = ${position.counts[depth - 1]}', () {
          final rules = DartXiangqiRules(fen: position.fen);
          expect(rules.perft(depth), position.counts[depth - 1]);
          expect(rules.fen, position.fen, reason: 'perft restores the board');
        });
      }
    });
  }
}
