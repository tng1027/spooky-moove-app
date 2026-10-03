import '../../../core/engine/engine_models.dart';

/// Evaluation text for the advisor screen (OB-007, OB-041). Scores are from
/// the user's side and describe the suggested move (OB-021 D12).
abstract final class EvalFormat {
  /// Shown while there is no suggestion to evaluate.
  static const String unknownWinRate = 'WIN RATE --';

  /// `WIN RATE 62%`, `YOU MATE IN 4` or `OPPONENT MATES IN 4`.
  /// [EvalHeadline.isFavorable] picks green (true) or red.
  static EvalHeadline headline(EngineScore score, double winChance) {
    return switch (score) {
      MateScore(:final moves) when moves > 0 => EvalHeadline(
        'YOU MATE IN $moves',
        isFavorable: true,
      ),
      MateScore(:final moves) => EvalHeadline(
        'OPPONENT MATES IN ${moves.abs()}',
        isFavorable: false,
      ),
      CentipawnScore() => EvalHeadline(
        'WIN RATE ${winChance.round()}%',
        isFavorable: winChance.round() >= 50,
      ),
    };
  }

  /// `EVAL +1.4 | DEPTH 16 | 850k nps`; missing parts are left out.
  static String expertLine(EngineScore score, {int? depth, int? nps}) {
    return [
      'EVAL ${_eval(score)}',
      if (depth != null) 'DEPTH $depth',
      if (nps != null) '${_abbreviate(nps)} nps',
    ].join(' | ');
  }

  static String _eval(EngineScore score) => switch (score) {
    MateScore(:final moves) => moves > 0 ? 'M$moves' : '-M${moves.abs()}',
    CentipawnScore(:final centipawns) => _pawns(centipawns),
  };

  static String _pawns(int centipawns) {
    final tenths = (centipawns / 10).round();
    final sign = tenths < 0 ? '-' : '+';
    return '$sign${(tenths.abs() / 10).toStringAsFixed(1)}';
  }

  static String _abbreviate(int value) {
    if (value >= 999500) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).round()}k';
    return '$value';
  }
}

final class EvalHeadline {
  const EvalHeadline(this.text, {required this.isFavorable});

  final String text;
  final bool isFavorable;

  @override
  bool operator ==(Object other) =>
      other is EvalHeadline &&
      other.text == text &&
      other.isFavorable == isFavorable;

  @override
  int get hashCode => Object.hash(text, isFavorable);

  @override
  String toString() => 'EvalHeadline($text, favorable: $isFavorable)';
}
