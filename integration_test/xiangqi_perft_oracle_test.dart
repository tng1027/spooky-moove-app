import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cataland/core/engine/fairy_stockfish/fairy_stockfish_engine.dart';
import 'package:cataland/features/xiangqi/data/dart_xiangqi_rules.dart';

import '../test/features/xiangqi/data/xiangqi_perft_positions.dart';

/// Validates the hand-written Xiangqi rules against the bundled
/// Fairy-Stockfish (OB-043): `go perft n` must equal `DartXiangqiRules.perft`
/// for every reference position. Also times legal-move generation on the
/// device (REQ-007: < 2 ms).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FairyStockfishEngine engine;

  Future<String> sendAndWaitFor(
    String command,
    bool Function(String line) matches, {
    Duration timeout = const Duration(seconds: 30),
  }) {
    final match = engine.lines.firstWhere(matches).timeout(timeout);
    engine.send(command);
    return match;
  }

  setUp(() async {
    engine = FairyStockfishEngine();
    await engine.start();
  });

  tearDown(() => engine.dispose());

  testWidgets('Fairy-Stockfish perft equals the Dart module', (tester) async {
    await tester.runAsync(() async {
      await sendAndWaitFor('uci', (line) => line == 'uciok');
      engine.send('setoption name UCI_Variant value xiangqi');
      await sendAndWaitFor('isready', (line) => line == 'readyok');

      for (final position in xiangqiPerftPositions) {
        for (var depth = 1; depth <= position.counts.length; depth++) {
          engine.send('position fen ${position.fen}');
          final line = await sendAndWaitFor(
            'go perft $depth',
            (line) => line.startsWith('Nodes searched'),
          );
          final engineCount = int.parse(line.split(':').last.trim());
          final dartCount = DartXiangqiRules(fen: position.fen).perft(depth);
          debugPrint(
            '${position.name} perft $depth: engine $engineCount, '
            'dart $dartCount',
          );
          expect(dartCount, engineCount, reason: '${position.name} d$depth');
          expect(dartCount, position.counts[depth - 1]);
        }
      }
    });
  });

  testWidgets('legal-move generation takes well under a frame', (tester) async {
    const iterations = 200;
    for (final position in xiangqiPerftPositions) {
      final rules = DartXiangqiRules(fen: position.fen);
      final move = rules.legalMoves.first;
      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        rules
          ..apply(move)
          ..undo();
      }
      stopwatch.stop();
      final perPosition =
          stopwatch.elapsedMicroseconds / (2 * iterations) / 1000;
      debugPrint(
        '${position.name}: ${perPosition.toStringAsFixed(3)} ms per position',
      );
      expect(perPosition, lessThan(2));
    }
  });
}
