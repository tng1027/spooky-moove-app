import '../../../core/engine/engine_models.dart';

/// Inclusive lower bound, upper bound inclusive unless [upperExclusive].
class Band {
  const Band(this.lower, this.upper, {this.upperExclusive = false});

  final double lower;
  final double upper;
  final bool upperExclusive;

  bool contains(double value) =>
      value >= lower && (upperExclusive ? value < upper : value <= upper);

  /// Distance to the nearest edge; 0 inside the band.
  double distanceTo(double value) {
    if (contains(value)) return 0;
    return value < lower ? lower - value : value - upper;
  }
}

/// Tunable persona constants (OB-022 REQ-015). Band edges change only with
/// PO approval; depths may be tuned to meet the latency budget (BR-005).
abstract final class PersonaConfig {
  /// Fairy-Stockfish centipawn-to-win-chance slope (Lichess model).
  static const double winChanceSlope = 0.00368208;

  /// Engine time cap for every tier.
  static const Duration searchCap = SearchLimits.maxMoveTime;

  /// Target depth of the all-move evaluation (tiers 1–4).
  static const int allMoveDepth = 8;

  /// Baby qualifies moves with `loss >= maxLoss - babyMarginPp`.
  static const double babyMarginPp = 3;

  /// Loss band (pp) of Gentle.
  static const Band gentleLoss = Band(9, 22);

  /// Loss band (pp) of Soft; 9 pp belongs to Gentle.
  static const Band softLoss = Band(3, 9, upperExclusive: true);

  /// Resulting win-chance band (%) of Even.
  static const Band evenWinChance = Band(47, 53);

  /// Depth caps of the single-line tiers; null = only the time cap.
  static const int solidDepth = 12;
  static const int masterDepth = 18;
}
