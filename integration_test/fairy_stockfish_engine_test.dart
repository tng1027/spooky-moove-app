import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cataland/core/engine/fairy_stockfish/fairy_stockfish_engine.dart';

final _bestMovePattern = RegExp(r'^bestmove [a-h][1-8][a-h][1-8][qrbn]?( |$)');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FairyStockfishEngine engine;

  Future<String> sendAndWaitFor(
    String command,
    bool Function(String line) matches, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final match = engine.lines.firstWhere(matches).timeout(timeout);
    engine.send(command);
    return match;
  }

  Future<void> handshake() async {
    await sendAndWaitFor('uci', (line) => line == 'uciok');
    await sendAndWaitFor('isready', (line) => line == 'readyok');
  }

  setUp(() async {
    engine = FairyStockfishEngine();
    await engine.start();
  });

  tearDown(() => engine.dispose());

  testWidgets('uci and isready handshake succeeds', (tester) async {
    await tester.runAsync(handshake);
  });

  testWidgets('go movetime 500 returns a valid bestmove', (tester) async {
    await tester.runAsync(() async {
      await handshake();
      engine.send('position startpos');
      final stopwatch = Stopwatch()..start();
      final bestMove = await sendAndWaitFor(
        'go movetime 500',
        (line) => line.startsWith('bestmove'),
        timeout: const Duration(milliseconds: 1500),
      );
      stopwatch.stop();
      debugPrint(
        'bestmove after ${stopwatch.elapsedMilliseconds} ms: $bestMove',
      );

      expect(bestMove, matches(_bestMovePattern));
    });
  });

  testWidgets('stop during a search returns bestmove and engine stays usable', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await handshake();
      engine
        ..send('position startpos')
        ..send('go infinite');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final bestMove = await sendAndWaitFor(
        'stop',
        (line) => line.startsWith('bestmove'),
        timeout: const Duration(milliseconds: 500),
      );
      expect(bestMove, matches(_bestMovePattern));

      await sendAndWaitFor('isready', (line) => line == 'readyok');
    });
  });

  testWidgets('a second start is rejected while the engine runs', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await expectLater(engine.start(), throwsStateError);

      final other = FairyStockfishEngine();
      await expectLater(other.start(), throwsStateError);
      await other.dispose();
    });
  });

  testWidgets('dispose during a search completes and the engine restarts', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await handshake();
      engine
        ..send('position startpos')
        ..send('go infinite');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await engine.dispose();
      expect(engine.isRunning, isFalse);

      engine = FairyStockfishEngine();
      await engine.start();
      await handshake();
    });
  });

  testWidgets('engine search does not drop UI frames', (tester) async {
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    );
    await tester.runAsync(handshake);

    await binding.watchPerformance(() async {
      await tester.runAsync(() async {
        engine.send('position startpos');
        final bestMove = await sendAndWaitFor(
          'go movetime 1000',
          (line) => line.startsWith('bestmove'),
        );
        expect(bestMove, matches(_bestMovePattern));
      });
    }, reportKey: 'engine_search_frames');

    final summary = binding.reportData!['engine_search_frames'] as Map;
    debugPrint('Frame summary during search: $summary');
    expect(summary['missed_frame_build_budget_count'], 0);
    expect(summary['missed_frame_rasterizer_budget_count'], 0);
  });
}
