import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/engine/engine_models.dart';
import 'package:spookymoove/features/persona/application/persona_suggester.dart';
import 'package:spookymoove/features/persona/domain/persona_config.dart';
import 'package:spookymoove/features/persona/domain/persona_tier.dart';

import '../fake_game_engine.dart';

SearchLine _line(int rank, String move, EngineScore score, {int depth = 8}) =>
    fakeLine(rank, move, score, depth: depth);

const _start = EnginePosition.startPos();
const _afterE4 = EnginePosition.startPos(moves: ['e2e4']);

void main() {
  late FakeGameEngine engine;
  late PersonaSuggester suggester;

  setUp(() {
    engine = FakeGameEngine();
    suggester = PersonaSuggester(engine: engine, random: math.Random(0));
  });

  group('limitsFor', () {
    test('tiers 1–4 score every legal move up to depth 8', () {
      for (final tier in [
        PersonaTier.baby,
        PersonaTier.gentle,
        PersonaTier.soft,
        PersonaTier.even,
      ]) {
        final limits = PersonaSuggester.limitsFor(tier, 20);
        expect(limits.multiPv, 20, reason: tier.label);
        expect(limits.depth, PersonaConfig.allMoveDepth, reason: tier.label);
        expect(limits.moveTime, SearchLimits.maxMoveTime, reason: tier.label);
      }
    });

    test('tiers 5–7 search one line with depth 12 / 18 / uncapped', () {
      final expected = {
        PersonaTier.solid: 12,
        PersonaTier.master: 18,
        PersonaTier.god: null,
      };
      for (final MapEntry(key: tier, value: depth) in expected.entries) {
        final limits = PersonaSuggester.limitsFor(tier, 20);
        expect(limits.multiPv, 1, reason: tier.label);
        expect(limits.depth, depth, reason: tier.label);
        expect(limits.moveTime, SearchLimits.maxMoveTime, reason: tier.label);
      }
    });
  });

  test('no legal moves gives no suggestion and no search', () async {
    final result = await suggester.suggest(
      position: _start,
      legalMoveCount: 0,
      tier: PersonaTier.god,
    );
    expect(result, isNull);
    expect(engine.searches, isEmpty);
  });

  test('maps the chosen line to a user-side suggestion', () async {
    final future = suggester.suggest(
      position: _start,
      legalMoveCount: 1,
      tier: PersonaTier.god,
    );
    expect(engine.last.limits.depth, isNull);
    engine.last.complete([_line(1, 'e2e4', const CentipawnScore(100))]);

    final suggestion = (await future)!;
    expect(suggestion.move, 'e2e4');
    expect(suggestion.score, const CentipawnScore(100));
    expect(suggestion.winChance, closeTo(59.1, 0.05));
    expect(suggestion.depth, 8);
    expect(suggestion.nps, 500000);
  });

  test('Baby suggests the move allowing the fastest mate', () async {
    final future = suggester.suggest(
      position: _start,
      legalMoveCount: 3,
      tier: PersonaTier.baby,
    );
    engine.last.complete([
      _line(1, 'e2e4', const CentipawnScore(30)),
      _line(2, 'f2f3', const MateScore(-3)),
      _line(3, 'g2g4', const MateScore(-1)),
    ]);

    final suggestion = (await future)!;
    expect(suggestion.move, 'g2g4');
    expect(suggestion.score, const MateScore(-1));
    expect(suggestion.winChance, 0);
  });

  test('the same position and tier returns the cached suggestion', () async {
    final first = suggester.suggest(
      position: _start,
      legalMoveCount: 3,
      tier: PersonaTier.baby,
    );
    engine.last.complete([
      _line(1, 'e2e4', const CentipawnScore(30)),
      _line(2, 'f2f3', const CentipawnScore(-200)),
      _line(3, 'g2g4', const CentipawnScore(-210)),
    ]);
    final firstMove = (await first)!.move;

    for (var i = 0; i < 5; i++) {
      final again = await suggester.suggest(
        position: _start,
        legalMoveCount: 3,
        tier: PersonaTier.baby,
      );
      expect(again!.move, firstMove);
    }
    expect(engine.searches, hasLength(1));
    expect(engine.stopCount, 0);
  });

  test('clearCache forces a new search', () async {
    final first = suggester.suggest(
      position: _start,
      legalMoveCount: 1,
      tier: PersonaTier.god,
    );
    engine.last.complete([_line(1, 'e2e4', const CentipawnScore(30))]);
    await first;

    suggester.clearCache();
    unawaited(
      suggester.suggest(
        position: _start,
        legalMoveCount: 1,
        tier: PersonaTier.god,
      ),
    );
    expect(engine.searches, hasLength(2));
  });

  test('a tier change during a search returns only the new result', () async {
    final god = suggester.suggest(
      position: _start,
      legalMoveCount: 2,
      tier: PersonaTier.god,
    );
    final baby = suggester.suggest(
      position: _start,
      legalMoveCount: 2,
      tier: PersonaTier.baby,
    );
    engine.last.complete([
      _line(1, 'e2e4', const CentipawnScore(30)),
      _line(2, 'f2f3', const CentipawnScore(-100)),
    ]);

    await expectLater(god, throwsA(isA<SearchCancelledException>()));
    expect((await baby)!.move, 'f2f3');
  });

  test(
    'a cached request stops the running search and drops its result',
    () async {
      final godStart = suggester.suggest(
        position: _start,
        legalMoveCount: 1,
        tier: PersonaTier.god,
      );
      engine.last.complete([_line(1, 'e2e4', const CentipawnScore(30))]);
      await godStart;

      final godAfterE4 = suggester.suggest(
        position: _afterE4,
        legalMoveCount: 1,
        tier: PersonaTier.god,
      );
      final cached = await suggester.suggest(
        position: _start,
        legalMoveCount: 1,
        tier: PersonaTier.god,
      );
      expect(cached!.move, 'e2e4');
      expect(engine.stopCount, 1);

      // The stopped search still delivers a (shallow) result.
      engine.last.complete([
        _line(1, 'e7e5', const CentipawnScore(0), depth: 3),
      ], depth: 3);
      await expectLater(godAfterE4, throwsA(isA<SearchCancelledException>()));

      unawaited(
        suggester.suggest(
          position: _afterE4,
          legalMoveCount: 1,
          tier: PersonaTier.god,
        ),
      );
      expect(
        engine.searches,
        hasLength(3),
        reason: 'truncated result not cached',
      );
    },
  );

  test('cancel stops the search and drops its result', () async {
    final future = suggester.suggest(
      position: _start,
      legalMoveCount: 1,
      tier: PersonaTier.god,
    );
    suggester.cancel();
    expect(engine.stopCount, 1);

    engine.last.complete([_line(1, 'e2e4', const CentipawnScore(30))]);
    await expectLater(future, throwsA(isA<SearchCancelledException>()));

    unawaited(
      suggester.suggest(
        position: _start,
        legalMoveCount: 1,
        tier: PersonaTier.god,
      ),
    );
    expect(
      engine.searches,
      hasLength(2),
      reason: 'cancelled result not cached',
    );
  });

  test('cancel without a running search does not stop the engine', () {
    suggester.cancel();
    expect(engine.stopCount, 0);
  });

  test('no scored line is an engine failure', () async {
    final future = suggester.suggest(
      position: _start,
      legalMoveCount: 1,
      tier: PersonaTier.god,
    );
    engine.last.complete(const []);
    await expectLater(future, throwsA(isA<EngineFailureException>()));
  });

  test('engine failures propagate', () async {
    final future = suggester.suggest(
      position: _start,
      legalMoveCount: 1,
      tier: PersonaTier.god,
    );
    engine.last.fail(const EngineFailureException('crashed'));
    await expectLater(future, throwsA(isA<EngineFailureException>()));
  });
}
