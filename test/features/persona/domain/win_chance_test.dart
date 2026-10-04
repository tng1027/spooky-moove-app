import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/engine/engine_models.dart';
import 'package:spookymoove/features/persona/domain/win_chance.dart';

void main() {
  test('converts centipawns with the Lichess slope', () {
    expect(winChance(const CentipawnScore(0)), closeTo(50.0, 0.05));
    expect(winChance(const CentipawnScore(100)), closeTo(59.1, 0.05));
    expect(winChance(const CentipawnScore(-250)), closeTo(28.5, 0.05));
  });

  test('a mate for the user is 100 %, being mated is 0 %', () {
    expect(winChance(const MateScore(3)), 100);
    expect(winChance(const MateScore(-1)), 0);
  });
}
