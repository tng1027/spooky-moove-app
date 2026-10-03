import 'dart:math' as math;

import '../../../core/engine/engine_models.dart';
import 'persona_config.dart';

/// Win chance (0–100 %) for the side whose perspective [score] is from
/// (OB-022 REQ-003). A forced mate counts as a certain win or loss.
double winChance(EngineScore score) => switch (score) {
  CentipawnScore(:final centipawns) =>
    100 / (1 + math.exp(-PersonaConfig.winChanceSlope * centipawns)),
  MateScore(:final moves) => moves > 0 ? 100 : 0,
};
