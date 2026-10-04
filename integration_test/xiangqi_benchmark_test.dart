import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cataland/core/engine/engine_models.dart';
import 'package:cataland/core/engine/fairy_stockfish/fairy_stockfish_engine.dart';
import 'package:cataland/core/engine/uci/uci_engine.dart';
import 'package:cataland/features/persona/application/persona_suggester.dart';
import 'package:cataland/features/persona/domain/persona_config.dart';
import 'package:cataland/features/persona/domain/persona_tier.dart';
import 'package:cataland/features/persona/domain/win_chance.dart';
import 'package:cataland/features/xiangqi/data/dart_xiangqi_rules.dart';

import 'benchmark/xiangqi_bench_positions.dart';

/// OB-010 Xiangqi pass: per-tier suggestion latency and the win-chance band
/// check on a fixed position set. A measurement, not a gate: only legality
/// is asserted. On a device run in profile mode; the iOS simulator only
/// supports debug (the engine itself is always built optimized):
///
/// ```
/// flutter test integration_test/xiangqi_benchmark_test.dart --profile -d <device>
/// ```
///
/// Every run starts from a cleared engine (`setVariant` resets the hash) and
/// a fresh [PersonaSuggester] (no cache), so times are cold worst cases.
const _runsPerPosition = 3;
const _budgetMs = 1000;

int _percentile(List<int> sorted, double p) {
  final index = ((sorted.length - 1) * p).round();
  return sorted[index];
}

String _summary(String label, List<int> times, List<int> depths) {
  final sorted = [...times]..sort();
  final over = times.where((t) => t > _budgetMs).length;
  return 'SUMMARY|$label|n ${times.length}|median ${_percentile(sorted, 0.5)}'
      '|p95 ${_percentile(sorted, 0.95)}|max ${sorted.last}'
      '|min depth ${depths.reduce(math.min)}|over ${_budgetMs}ms $over';
}

String _score(EngineScore score) => switch (score) {
  CentipawnScore(:final centipawns) => 'cp $centipawns',
  MateScore(:final moves) => 'mate $moves',
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Xiangqi: per-tier latency on the benchmark positions', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final engine = UciEngine(transportFactory: FairyStockfishEngine.new);
      await engine.start();
      final timesByTier = {for (final t in PersonaTier.values) t: <int>[]};
      final depthsByTier = {for (final t in PersonaTier.values) t: <int>[]};

      for (final position in xiangqiBenchPositions) {
        final rules = DartXiangqiRules(fen: position.fen);
        final legal = rules.legalMoves.map((m) => m.uci).toSet();
        for (final tier in PersonaTier.values) {
          for (var run = 0; run < _runsPerPosition; run++) {
            await engine.setVariant('xiangqi');
            final suggester = PersonaSuggester(
              engine: engine,
              random: math.Random(run),
            );
            final stopwatch = Stopwatch()..start();
            final suggestion = await suggester.suggest(
              position: EnginePosition.fen(position.fen),
              legalMoveCount: legal.length,
              tier: tier,
            );
            stopwatch.stop();
            final ms = stopwatch.elapsedMilliseconds;
            timesByTier[tier]!.add(ms);
            depthsByTier[tier]!.add(suggestion!.depth ?? 0);
            debugPrint(
              'BENCH|${tier.label}|${position.name}|$ms'
              '|depth ${suggestion.depth}|nps ${suggestion.nps}'
              '|legal ${legal.length}|${_score(suggestion.score)}'
              '|wc ${suggestion.winChance.toStringAsFixed(1)}',
            );
            expect(
              legal,
              contains(suggestion.move),
              reason: '${tier.label} ${position.name}',
            );
          }
        }
      }

      for (final tier in PersonaTier.values) {
        debugPrint(
          _summary(tier.label, timesByTier[tier]!, depthsByTier[tier]!),
        );
      }
      await engine.dispose();
    });
  });

  testWidgets('Xiangqi: win-chance spread vs. the tier bands', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final engine = UciEngine(transportFactory: FairyStockfishEngine.new);
      await engine.start();
      var gentleHits = 0;
      var softHits = 0;
      var evenHits = 0;
      var counted = 0;

      for (final position in xiangqiBenchPositions) {
        final legalCount = DartXiangqiRules(
          fen: position.fen,
        ).legalMoves.length;
        await engine.setVariant('xiangqi');
        final result = await engine
            .search(
              EnginePosition.fen(position.fen),
              PersonaSuggester.limitsFor(PersonaTier.even, legalCount),
            )
            .result;
        final chances =
            result.lines.map((l) => winChance(l.score)).toList()
              ..sort((a, b) => b.compareTo(a));
        final best = chances.first;
        final losses = chances.map((c) => best - c).toList();
        final hasGentle = losses.any(PersonaConfig.gentleLoss.contains);
        final hasSoft = losses.any(PersonaConfig.softLoss.contains);
        final hasEven = chances.any(PersonaConfig.evenWinChance.contains);
        final scores = result.lines.map((l) => _score(l.score));
        debugPrint(
          'SPREAD|${position.name}|lines ${result.lines.length}/$legalCount'
          '|depth ${result.depth}|best wc ${best.toStringAsFixed(1)}'
          '|worst wc ${chances.last.toStringAsFixed(1)}'
          '|gentle ${hasGentle ? 'yes' : 'no'}|soft ${hasSoft ? 'yes' : 'no'}'
          '|even ${hasEven ? 'yes' : 'no'}'
          '|top ${scores.take(3).join(', ')}',
        );
        expect(result.lines, hasLength(legalCount), reason: position.name);

        // A forced mate leaves no meaningful spread; skip it in the rates.
        if (result.lines.first.score is MateScore) continue;
        counted++;
        if (hasGentle) gentleHits++;
        if (hasSoft) softHits++;
        if (hasEven) evenHits++;
      }

      debugPrint(
        'BANDS|positions $counted|gentle $gentleHits|soft $softHits'
        '|even $evenHits|slope ${PersonaConfig.winChanceSlope}',
      );
      await engine.dispose();
    });
  });
}
