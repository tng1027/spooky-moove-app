import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spookymoove/core/engine/engine_models.dart';
import 'package:spookymoove/core/engine/fairy_stockfish/fairy_stockfish_engine.dart';
import 'package:spookymoove/core/engine/uci/uci_engine.dart';

final _maxLimits = SearchLimits(moveTime: SearchLimits.maxMoveTime);

/// Legal moves according to the engine itself (`go perft 1`), read through
/// a raw transport so the adapter under test is not involved.
Future<Set<String>> _legalMoves(String variant, List<String> moves) async {
  final transport = FairyStockfishEngine();
  await transport.start();
  try {
    final done = transport.lines.firstWhere((l) => l == 'readyok');
    transport
      ..send('setoption name UCI_Variant value $variant')
      ..send('isready');
    await done;

    final legal = <String>{};
    final perftDone = transport.lines.firstWhere((line) {
      final match = RegExp(r'^(\S+): \d+$').firstMatch(line);
      if (match != null) legal.add(match.group(1)!);
      return line.startsWith('Nodes searched');
    });
    transport
      ..send(
        moves.isEmpty
            ? 'position startpos'
            : 'position startpos moves ${moves.join(' ')}',
      )
      ..send('go perft 1');
    await perftDone.timeout(const Duration(seconds: 5));
    return legal;
  } finally {
    await transport.dispose();
  }
}

String _move(SearchResult result) => switch (result.bestMove) {
  EngineMove(:final move) => move,
  NoLegalMove() => fail('Expected a move, got none'),
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late UciEngine engine;

  Future<void> startEngine() async {
    engine = UciEngine(transportFactory: FairyStockfishEngine.new);
    await engine.start();
  }

  testWidgets('defaults are accepted and a Chess search fits the budget', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final legal = await _legalMoves('chess', const []);
      expect(legal, hasLength(20));

      await startEngine();
      await engine.setVariant('chess');
      final stopwatch = Stopwatch()..start();
      final result = await engine
          .search(const EnginePosition.startPos(), _maxLimits)
          .result;
      stopwatch.stop();
      debugPrint(
        'chess bestmove ${_move(result)} in ${stopwatch.elapsedMilliseconds} '
        'ms, depth ${result.depth}, ${result.nps} nps',
      );

      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(legal, contains(_move(result)));
      await engine.dispose();
    });
  });

  testWidgets('Xiangqi via UCI_Variant returns a legal move', (tester) async {
    await tester.runAsync(() async {
      final legal = await _legalMoves('xiangqi', const []);
      expect(legal, hasLength(44));

      await startEngine();
      await engine.setVariant('xiangqi');
      final result = await engine
          .search(const EnginePosition.startPos(), _maxLimits)
          .result;
      debugPrint('xiangqi bestmove ${_move(result)} depth ${result.depth}');

      expect(legal, contains(_move(result)));
      await engine.dispose();
    });
  });

  testWidgets('a newer position supersedes the running search', (tester) async {
    await tester.runAsync(() async {
      final legalAfterE4 = await _legalMoves('chess', const ['e2e4']);

      await startEngine();
      await engine.setVariant('chess');
      final first = engine.search(const EnginePosition.startPos(), _maxLimits);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final second = engine.search(
        const EnginePosition.startPos(moves: ['e2e4']),
        _maxLimits,
      );

      await expectLater(first.result, throwsA(isA<SearchCancelledException>()));
      expect(legalAfterE4, contains(_move(await second.result)));
      await engine.dispose();
    });
  });

  testWidgets('all-move search scores every legal move', (tester) async {
    await tester.runAsync(() async {
      final legal = await _legalMoves('chess', const []);

      await startEngine();
      await engine.setVariant('chess');
      final result = await engine
          .search(
            const EnginePosition.startPos(),
            SearchLimits(
              moveTime: SearchLimits.maxMoveTime,
              depth: 8,
              multiPv: 500,
            ),
          )
          .result;
      debugPrint(
        'all-move depth ${result.depth}, ${result.lines.length} lines',
      );

      expect(result.lines, hasLength(legal.length));
      expect(result.lines.map((l) => l.firstMove).toSet(), legal);
      expect(result.depth, lessThanOrEqualTo(8));
      await engine.dispose();
    });
  });

  testWidgets('depth cap is respected', (tester) async {
    await tester.runAsync(() async {
      await startEngine();
      await engine.setVariant('chess');
      final result = await engine
          .search(
            const EnginePosition.startPos(),
            SearchLimits(moveTime: SearchLimits.maxMoveTime, depth: 12),
          )
          .result;
      debugPrint('depth-capped search reached depth ${result.depth}');

      expect(result.depth, lessThanOrEqualTo(12));
      await engine.dispose();
    });
  });

  testWidgets('engine works again after dispose and start', (tester) async {
    await tester.runAsync(() async {
      await startEngine();
      await engine.dispose();
      expect(engine.isRunning, isFalse);

      await engine.start();
      await engine.setVariant('chess');
      final result = await engine
          .search(
            const EnginePosition.startPos(),
            SearchLimits(moveTime: const Duration(milliseconds: 300)),
          )
          .result;
      expect(result.bestMove, isA<EngineMove>());
      await engine.dispose();
    });
  });
}
