import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:cataland/features/persona/domain/persona_tier.dart';
import 'package:cataland/features/persona/domain/tier_selection.dart';

List<MoveCandidate> _candidates(Map<String, double> winChances) => [
  for (final MapEntry(:key, :value) in winChances.entries)
    MoveCandidate(move: key, winChance: value),
];

/// Moves chosen over many seeded RNGs.
Set<String> _picks(List<MoveCandidate> candidates, PersonaTier tier) => {
  for (var seed = 0; seed < 200; seed++)
    selectMove(candidates, tier, math.Random(seed)).move,
};

String _pick(List<MoveCandidate> candidates, PersonaTier tier) =>
    selectMove(candidates, tier, math.Random(0)).move;

void main() {
  test('the 7 tiers are ordered by level', () {
    expect(PersonaTier.values.map((t) => t.level), [1, 2, 3, 4, 5, 6, 7]);
    expect(PersonaTier.values.map((t) => t.emoji).join(), '🥚🐣🐥🥉🥈🥇👑');
  });

  test('an empty candidate list is rejected', () {
    expect(
      () => selectMove(const [], PersonaTier.god, math.Random(0)),
      throwsArgumentError,
    );
  });

  test('a single candidate is chosen by every tier', () {
    final only = _candidates({'A': 30});
    for (final tier in PersonaTier.values) {
      expect(_pick(only, tier), 'A', reason: tier.label);
    }
  });

  group('Baby', () {
    test('picks randomly among moves within 3 pp of the max loss', () {
      final candidates = _candidates({
        'A': 50,
        'B': 45,
        'C': 12,
        'D': 10,
        'E': 9,
      });
      expect(_picks(candidates, PersonaTier.baby), {'C', 'D', 'E'});
    });

    test('prefers the qualifying move allowing the fastest mate', () {
      const candidates = [
        MoveCandidate(move: 'A', winChance: 50),
        MoveCandidate(move: 'D', winChance: 0, userMatedIn: 3),
        MoveCandidate(move: 'E', winChance: 0, userMatedIn: 1),
      ];
      expect(_picks(candidates, PersonaTier.baby), {'E'});
    });
  });

  group('Gentle', () {
    test('picks randomly among losses of 9 to 22 pp', () {
      final candidates = _candidates({
        'A': 60,
        'B': 55,
        'C': 48,
        'D': 40,
        'E': 20,
      });
      expect(_picks(candidates, PersonaTier.gentle), {'C', 'D'});
    });

    test('falls back to the move closest to the band from below', () {
      expect(
        _pick(_candidates({'A': 60, 'B': 57, 'C': 54}), PersonaTier.gentle),
        'C',
      );
    });

    test('falls back to the move closest to the band from above', () {
      expect(_pick(_candidates({'A': 60, 'B': 30}), PersonaTier.gentle), 'B');
    });
  });

  group('Soft', () {
    test('picks randomly among losses of 3 to under 9 pp', () {
      final candidates = _candidates({
        'A': 60,
        'B': 58,
        'C': 55,
        'D': 52,
        'E': 40,
      });
      expect(_picks(candidates, PersonaTier.soft), {'C', 'D'});
    });

    test('falls back to the move closest to the band', () {
      expect(
        _pick(_candidates({'A': 60, 'B': 59, 'C': 45}), PersonaTier.soft),
        'B',
      );
    });

    test('a loss of exactly 9 pp belongs to Gentle, not Soft', () {
      final candidates = _candidates({'A': 60, 'B': 51, 'C': 55});
      expect(_picks(candidates, PersonaTier.gentle), {'B'});
      expect(_picks(candidates, PersonaTier.soft), {'C'});
    });
  });

  group('Even', () {
    test('picks randomly among resulting win chances of 47 to 53 %', () {
      final candidates = _candidates({
        'A': 80,
        'B': 65,
        'C': 52,
        'D': 49,
        'E': 30,
      });
      expect(_picks(candidates, PersonaTier.even), {'C', 'D'});
    });

    test('suggests the best move when the user is behind', () {
      expect(
        _pick(_candidates({'A': 40, 'B': 35, 'C': 20}), PersonaTier.even),
        'A',
      );
    });

    test('suggests the move closest to 53 % when far ahead', () {
      expect(
        _pick(_candidates({'A': 95, 'B': 85, 'C': 70}), PersonaTier.even),
        'C',
      );
    });

    test('breaks a distance tie by the smaller loss', () {
      expect(_pick(_candidates({'A': 61, 'B': 39}), PersonaTier.even), 'A');
      expect(_pick(_candidates({'B': 39, 'A': 61}), PersonaTier.even), 'A');
    });
  });

  test('Solid, Master and God suggest the best move', () {
    final candidates = _candidates({'B': 40, 'A': 70, 'C': 10});
    for (final tier in [
      PersonaTier.solid,
      PersonaTier.master,
      PersonaTier.god,
    ]) {
      expect(_picks(candidates, tier), {'A'}, reason: tier.label);
    }
  });
}
