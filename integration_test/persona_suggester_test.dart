import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spookymoove/core/engine/engine_models.dart';
import 'package:spookymoove/core/engine/fairy_stockfish/fairy_stockfish_engine.dart';
import 'package:spookymoove/core/engine/uci/uci_engine.dart';
import 'package:spookymoove/features/persona/application/persona_suggester.dart';
import 'package:spookymoove/features/persona/domain/persona_tier.dart';

/// Legal moves of the variant's start position according to the engine
/// itself (`go perft 1`).
Future<Set<String>> _legalMoves(String variant) async {
  final transport = FairyStockfishEngine();
  await transport.start();
  try {
    final ready = transport.lines.firstWhere((l) => l == 'readyok');
    transport
      ..send('setoption name UCI_Variant value $variant')
      ..send('isready');
    await ready;

    final legal = <String>{};
    final perftDone = transport.lines.firstWhere((line) {
      final match = RegExp(r'^(\S+): \d+$').firstMatch(line);
      if (match != null) legal.add(match.group(1)!);
      return line.startsWith('Nodes searched');
    });
    transport
      ..send('position startpos')
      ..send('go perft 1');
    await perftDone.timeout(const Duration(seconds: 5));
    return legal;
  } finally {
    await transport.dispose();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const start = EnginePosition.startPos();

  testWidgets('Chess: every tier suggests a legal move within budget', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final legal = await _legalMoves('chess');
      expect(legal, hasLength(20));

      final engine = UciEngine(transportFactory: FairyStockfishEngine.new);
      await engine.start();
      await engine.setVariant('chess');
      final suggester = PersonaSuggester(
        engine: engine,
        random: math.Random(1),
      );

      for (final tier in PersonaTier.values) {
        final stopwatch = Stopwatch()..start();
        final suggestion = await suggester.suggest(
          position: start,
          legalMoveCount: legal.length,
          tier: tier,
        );
        stopwatch.stop();
        debugPrint(
          '${tier.name}: ${suggestion!.move} WC '
          '${suggestion.winChance.toStringAsFixed(1)}% ${suggestion.score} '
          'depth ${suggestion.depth} in ${stopwatch.elapsedMilliseconds} ms',
        );
        expect(legal, contains(suggestion.move), reason: tier.name);
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(1000),
          reason: tier.name,
        );
      }
      await engine.dispose();
    });
  });

  testWidgets('Chess: the Baby search scores all 20 moves', (tester) async {
    await tester.runAsync(() async {
      final legal = await _legalMoves('chess');

      final engine = UciEngine(transportFactory: FairyStockfishEngine.new);
      await engine.start();
      await engine.setVariant('chess');
      final result = await engine
          .search(start, PersonaSuggester.limitsFor(PersonaTier.baby, 20))
          .result;
      debugPrint('Baby all-move depth ${result.depth}');

      expect(result.lines.map((l) => l.firstMove).toSet(), legal);
      await engine.dispose();
    });
  });

  testWidgets('Xiangqi: the Baby search scores all 44 moves', (tester) async {
    await tester.runAsync(() async {
      final legal = await _legalMoves('xiangqi');
      expect(legal, hasLength(44));

      final engine = UciEngine(transportFactory: FairyStockfishEngine.new);
      await engine.start();
      await engine.setVariant('xiangqi');
      final result = await engine
          .search(start, PersonaSuggester.limitsFor(PersonaTier.baby, 44))
          .result;
      debugPrint('Xiangqi Baby all-move depth ${result.depth}');

      expect(result.lines.map((l) => l.firstMove).toSet(), legal);
      await engine.dispose();
    });
  });

  testWidgets('Xiangqi: every tier suggests a legal move within budget', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final legal = await _legalMoves('xiangqi');
      expect(legal, hasLength(44));

      final engine = UciEngine(transportFactory: FairyStockfishEngine.new);
      await engine.start();
      await engine.setVariant('xiangqi');
      final suggester = PersonaSuggester(
        engine: engine,
        random: math.Random(1),
      );

      for (final tier in PersonaTier.values) {
        final stopwatch = Stopwatch()..start();
        final suggestion = await suggester.suggest(
          position: start,
          legalMoveCount: legal.length,
          tier: tier,
        );
        stopwatch.stop();
        debugPrint(
          'Xiangqi ${tier.name}: ${suggestion!.move} WC '
          '${suggestion.winChance.toStringAsFixed(1)}% depth '
          '${suggestion.depth} in ${stopwatch.elapsedMilliseconds} ms',
        );
        expect(legal, contains(suggestion.move), reason: tier.name);
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(1000),
          reason: tier.name,
        );
      }
      await engine.dispose();
    });
  });
}
