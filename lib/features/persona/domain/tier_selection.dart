import 'dart:math' as math;

import 'persona_config.dart';
import 'persona_tier.dart';

/// One legal move with the user's win chance after it.
class MoveCandidate {
  const MoveCandidate({
    required this.move,
    required this.winChance,
    this.userMatedIn,
  });

  /// Engine notation.
  final String move;

  /// User's win chance after [move], 0–100 %.
  final double winChance;

  /// Moves until the user is mated, when [move] allows a forced mate
  /// against the user.
  final int? userMatedIn;
}

/// Chooses the move to suggest for [tier] (OB-022 REQ-005 – REQ-011).
///
/// Ties on win chance keep [candidates] order, so pass them in engine rank
/// order. Throws [ArgumentError] if [candidates] is empty.
MoveCandidate selectMove(
  List<MoveCandidate> candidates,
  PersonaTier tier,
  math.Random random,
) {
  if (candidates.isEmpty) {
    throw ArgumentError.value(candidates, 'candidates', 'Must not be empty');
  }
  final best = candidates.reduce((a, b) => b.winChance > a.winChance ? b : a);
  if (candidates.length == 1) return best;

  double loss(MoveCandidate m) => best.winChance - m.winChance;

  return switch (tier) {
    PersonaTier.baby => _selectBaby(candidates, loss, random),
    PersonaTier.gentle => _selectInBand(
      candidates,
      PersonaConfig.gentleLoss,
      loss,
      loss,
      random,
    ),
    PersonaTier.soft => _selectInBand(
      candidates,
      PersonaConfig.softLoss,
      loss,
      loss,
      random,
    ),
    PersonaTier.even => _selectInBand(
      candidates,
      PersonaConfig.evenWinChance,
      (m) => m.winChance,
      loss,
      random,
    ),
    PersonaTier.solid || PersonaTier.master || PersonaTier.god => best,
  };
}

MoveCandidate _selectBaby(
  List<MoveCandidate> candidates,
  double Function(MoveCandidate) loss,
  math.Random random,
) {
  final maxLoss = candidates.map(loss).reduce(math.max);
  final qualifying = candidates
      .where((m) => loss(m) >= maxLoss - PersonaConfig.babyMarginPp)
      .toList();

  MoveCandidate? fastestMate;
  for (final m in qualifying) {
    final matedIn = m.userMatedIn;
    if (matedIn == null) continue;
    if (fastestMate == null || matedIn < fastestMate.userMatedIn!) {
      fastestMate = m;
    }
  }
  return fastestMate ?? qualifying[random.nextInt(qualifying.length)];
}

/// Random pick among moves whose [measure] is inside [band]; otherwise the
/// move closest to the band, ties broken by the smaller loss (REQ-009).
MoveCandidate _selectInBand(
  List<MoveCandidate> candidates,
  Band band,
  double Function(MoveCandidate) measure,
  double Function(MoveCandidate) loss,
  math.Random random,
) {
  final qualifying = candidates
      .where((m) => band.contains(measure(m)))
      .toList();
  if (qualifying.isNotEmpty) {
    return qualifying[random.nextInt(qualifying.length)];
  }
  return candidates.reduce((a, b) {
    final distanceA = band.distanceTo(measure(a));
    final distanceB = band.distanceTo(measure(b));
    if (distanceB != distanceA) return distanceB < distanceA ? b : a;
    return loss(b) < loss(a) ? b : a;
  });
}
