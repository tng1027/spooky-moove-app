import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:cataland/core/engine/engine_models.dart';
import 'package:cataland/core/engine/engine_transport.dart';
import 'package:cataland/core/engine/uci/uci_engine.dart';

/// Answers the UCI handshake automatically and lets tests emit engine output.
class FakeTransport implements EngineTransport {
  final List<String> sent = [];
  final StreamController<String> _lines = StreamController.broadcast(
    sync: true,
  );
  bool isStarted = false;
  bool isDisposed = false;
  Set<String> rejectedOptions = {};

  @override
  Stream<String> get lines => _lines.stream;

  @override
  Future<void> start() async => isStarted = true;

  @override
  void send(String line) {
    sent.add(line);
    if (line == 'uci') {
      scheduleMicrotask(() => emit('uciok'));
    } else if (line == 'isready') {
      scheduleMicrotask(() => emit('readyok'));
    } else if (line.startsWith('setoption name ')) {
      final name = line.substring('setoption name '.length).split(' value ')[0];
      if (rejectedOptions.contains(name)) emit('No such option: $name');
    }
  }

  @override
  Future<void> dispose() async {
    isDisposed = true;
    await _lines.close();
  }

  void emit(String line) => _lines.add(line);

  void fail(Object error) => _lines.addError(error);

  /// Commands sent after the handshake, for asserting search sequences.
  List<String> sentSince(int index) => sent.sublist(index);
}

void main() {
  late List<FakeTransport> transports;
  late UciEngine engine;

  FakeTransport transport() => transports.last;

  SearchLimits limits({int? depth, int multiPv = 1}) => SearchLimits(
    moveTime: const Duration(milliseconds: 500),
    depth: depth,
    multiPv: multiPv,
  );

  setUp(() {
    transports = [];
    engine = UciEngine(
      transportFactory: () {
        final transport = FakeTransport();
        transports.add(transport);
        return transport;
      },
      commandTimeout: const Duration(milliseconds: 200),
    );
  });

  test('start applies thread and hash defaults', () async {
    await engine.start();

    expect(transport().sent, [
      'uci',
      'setoption name Threads value 2',
      'setoption name Hash value 16',
      'isready',
    ]);
    expect(engine.isRunning, isTrue);
  });

  test('start fails when the engine rejects an option', () async {
    engine = UciEngine(
      transportFactory: () {
        final transport = FakeTransport()..rejectedOptions = {'Hash'};
        transports.add(transport);
        return transport;
      },
    );

    await expectLater(engine.start(), throwsA(isA<EngineFailureException>()));
    expect(engine.isRunning, isFalse);
    expect(transport().isDisposed, isTrue);
  });

  test('config rejects out-of-budget resources', () {
    expect(() => EngineConfig(threads: 3), throwsRangeError);
    expect(() => EngineConfig(hashMb: 64), throwsRangeError);
    expect(() => EngineConfig(hashMb: 8), throwsRangeError);
  });

  test('limits reject move times above the 900 ms cap', () {
    expect(
      () => SearchLimits(moveTime: const Duration(milliseconds: 901)),
      throwsRangeError,
    );
  });

  test('setVariant sends the variant and resets the game', () async {
    await engine.start();
    final mark = transport().sent.length;

    await engine.setVariant('xiangqi');

    expect(transport().sentSince(mark), [
      'setoption name UCI_Variant value xiangqi',
      'ucinewgame',
      'isready',
    ]);
  });

  test('search sends position and go, and returns the best move', () async {
    await engine.start();
    final mark = transport().sent.length;

    final handle = engine.search(
      const EnginePosition.startPos(moves: ['e2e4', 'e7e5']),
      limits(depth: 12),
    );
    final updates = <SearchInfo>[];
    handle.updates.listen(updates.add);

    transport()
      ..emit('info string classical evaluation enabled')
      ..emit('info depth 1 score cp 20 nodes 30 nps 3000 pv g1f3')
      ..emit('info depth 2 score cp 35 nodes 90 nps 9000 pv g1f3 b8c6')
      ..emit('bestmove g1f3 ponder b8c6');
    final result = await handle.result;

    expect(transport().sentSince(mark), [
      'setoption name MultiPV value 1',
      'position startpos moves e2e4 e7e5',
      'go movetime 500 depth 12',
    ]);
    expect(result.bestMove, const EngineMove('g1f3', ponder: 'b8c6'));
    expect(result.depth, 2);
    expect(result.nps, 9000);
    expect(result.lines.single.score, const CentipawnScore(35));
    await pumpEventQueue();
    expect(updates.map((u) => u.depth), [1, 2]);
  });

  test('FEN positions and unchanged MultiPV are sent correctly', () async {
    await engine.start();
    engine.search(
      const EnginePosition.fen('8/8/8/8/8/8/8/K6k w - - 0 1'),
      limits(),
    );
    transport().emit('bestmove a1b1');
    final mark = transport().sent.length;

    engine.search(
      const EnginePosition.fen('8/8/8/8/8/8/8/K6k w - - 0 1', moves: ['a1b1']),
      limits(),
    );

    expect(transport().sentSince(mark), [
      'position fen 8/8/8/8/8/8/8/K6k w - - 0 1 moves a1b1',
      'go movetime 500',
    ]);
  });

  test('a new search cancels the old one and drops its output', () async {
    await engine.start();
    final first = engine.search(const EnginePosition.startPos(), limits());
    transport().emit('info depth 5 score cp 10 pv e2e4');

    final mark = transport().sent.length;
    final second = engine.search(
      const EnginePosition.startPos(moves: ['d2d4']),
      limits(),
    );
    expect(transport().sentSince(mark).first, 'stop');

    final secondUpdates = <SearchInfo>[];
    second.updates.listen(secondUpdates.add);
    transport()
      ..emit('info depth 6 score cp 15 pv e2e4')
      ..emit('bestmove e2e4')
      ..emit('info depth 3 score cp -5 pv g8f6')
      ..emit('bestmove g8f6');

    await expectLater(first.result, throwsA(isA<SearchCancelledException>()));
    final result = await second.result;
    expect(result.bestMove, const EngineMove('g8f6'));
    await pumpEventQueue();
    expect(secondUpdates.map((u) => u.depth), [3]);
  });

  test('rapid submissions deliver only the latest result', () async {
    await engine.start();
    final a = engine.search(const EnginePosition.startPos(), limits());
    final b = engine.search(
      const EnginePosition.startPos(moves: ['e2e4']),
      limits(),
    );
    final c = engine.search(
      const EnginePosition.startPos(moves: ['e2e4', 'e7e5']),
      limits(),
    );
    transport()
      ..emit('bestmove e2e4')
      ..emit('bestmove e7e5')
      ..emit('bestmove g1f3');

    await expectLater(a.result, throwsA(isA<SearchCancelledException>()));
    await expectLater(b.result, throwsA(isA<SearchCancelledException>()));
    expect((await c.result).bestMove, const EngineMove('g1f3'));
  });

  test(
    'multi-line result uses the deepest iteration complete for all lines',
    () async {
      await engine.start();
      final handle = engine.search(
        const EnginePosition.startPos(),
        limits(multiPv: 3),
      );
      transport()
        ..emit('info depth 7 multipv 1 score cp 30 pv e2e4')
        ..emit('info depth 7 multipv 2 score cp 25 pv d2d4')
        ..emit('info depth 7 multipv 3 score cp 10 pv g1f3')
        ..emit('info depth 8 multipv 1 score cp 32 lowerbound pv e2e4')
        ..emit('info depth 8 multipv 1 score cp 28 pv e2e4')
        ..emit('info depth 8 multipv 2 score cp 20 pv d2d4')
        ..emit('info depth 8 multipv 3 score cp 12 pv c2c4')
        // Stopped mid-iteration: only line 1 reached depth 9.
        ..emit('info depth 9 multipv 1 score cp 31 pv e2e4')
        ..emit('bestmove e2e4');

      final result = await handle.result;

      expect(transport().sent, contains('setoption name MultiPV value 3'));
      expect(result.depth, 8);
      expect(result.lines.map((l) => l.firstMove), ['e2e4', 'd2d4', 'c2c4']);
      expect(result.lines.first.score, const CentipawnScore(28));
      expect(result.lines.first.bound, ScoreBound.exact);
    },
  );

  test('no legal move is represented explicitly', () async {
    await engine.start();
    final handle = engine.search(const EnginePosition.startPos(), limits());
    transport()
      ..emit('info depth 0 score mate 0')
      ..emit('bestmove (none)');

    expect((await handle.result).bestMove, const NoLegalMove());
  });

  test('malformed output is ignored without crashing', () async {
    await engine.start();
    final handle = engine.search(const EnginePosition.startPos(), limits());
    transport()
      ..emit('info depth x score cp')
      ..emit('garbage line')
      ..emit('')
      ..emit('bestmove e2e4');

    expect((await handle.result).bestMove, const EngineMove('e2e4'));
  });

  test('stop delivers the current result', () async {
    await engine.start();
    final handle = engine.search(const EnginePosition.startPos(), limits());
    engine.stop();
    expect(transport().sent.last, 'stop');
    transport().emit('bestmove e2e4');

    expect((await handle.result).bestMove, const EngineMove('e2e4'));
  });

  test(
    'a transport error fails the running search and allows restart',
    () async {
      await engine.start();
      final handle = engine.search(const EnginePosition.startPos(), limits());

      transport().fail(Exception('native crash'));

      await expectLater(handle.result, throwsA(isA<EngineFailureException>()));
      expect(engine.isRunning, isFalse);

      await engine.start();
      expect(transports, hasLength(2));
      expect(engine.isRunning, isTrue);
    },
  );

  test('an unexpected engine exit fails the running search', () async {
    await engine.start();
    final handle = engine.search(const EnginePosition.startPos(), limits());

    await transport().dispose();

    await expectLater(handle.result, throwsA(isA<EngineFailureException>()));
    expect(engine.isRunning, isFalse);
  });

  test('dispose cancels the search and start works again', () async {
    await engine.start();
    final handle = engine.search(const EnginePosition.startPos(), limits());

    await engine.dispose();

    await expectLater(handle.result, throwsA(isA<SearchCancelledException>()));
    expect(transports.first.isDisposed, isTrue);

    await engine.start();
    final next = engine.search(const EnginePosition.startPos(), limits());
    transport().emit('bestmove d2d4');
    expect((await next.result).bestMove, const EngineMove('d2d4'));
  });

  test('search before start throws', () {
    expect(
      () => engine.search(const EnginePosition.startPos(), limits()),
      throwsStateError,
    );
  });
}
