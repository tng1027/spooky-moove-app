import '../../../core/engine/engine_models.dart';

/// Evaluation text for the advisor screen (OB-007, OB-041). Scores are from
/// the user's side and describe the suggested move (OB-021 D12).
abstract final class EvalFormat {
  static const String winRateCaption = 'WIN RATE';

  /// The value shown under [winRateCaption] while there is no suggestion.
  static const String unknownValue = '--';

  /// `WIN RATE` / `62%`, `YOU MATE IN` / `4` or `OPPONENT MATES IN` / `4`
  /// (OB-052 DS-7: caption above value). [EvalHeadline.isFavorable] picks
  /// green (true) or red.
  static EvalHeadline headline(EngineScore score, double winChance) {
    return switch (score) {
      MateScore(:final moves) when moves > 0 => EvalHeadline(
        'YOU MATE IN',
        '$moves',
        isFavorable: true,
      ),
      MateScore(:final moves) => EvalHeadline(
        'OPPONENT MATES IN',
        '${moves.abs()}',
        isFavorable: false,
      ),
      CentipawnScore() => EvalHeadline(
        winRateCaption,
        '${winChance.round()}%',
        isFavorable: winChance.round() >= 50,
      ),
    };
  }

  static const String expertSeparator = ' • ';

  /// `EVAL +1.4 • DEPTH 16 • 850k nps`; missing parts are left out.
  static String expertLine(EngineScore score, {int? depth, int? nps}) {
    return [
      'EVAL ${_eval(score)}',
      if (depth != null) 'DEPTH $depth',
      if (nps != null) '${_abbreviate(nps)} nps',
    ].join(expertSeparator);
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
  const EvalHeadline(this.caption, this.value, {required this.isFavorable});

  final String caption;
  final String value;
  final bool isFavorable;

  /// One label for screen readers, e.g. `Win rate 62 percent`.
  String get spoken {
    final text = '$caption $value'.replaceAll('%', ' percent');
    return text[0] + text.substring(1).toLowerCase();
  }

  @override
  bool operator ==(Object other) =>
      other is EvalHeadline &&
      other.caption == caption &&
      other.value == value &&
      other.isFavorable == isFavorable;

  @override
  int get hashCode => Object.hash(caption, value, isFavorable);

  @override
  String toString() => 'EvalHeadline($caption $value, favorable: $isFavorable)';
}
