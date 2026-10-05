import '../../../core/engine/engine_models.dart';
import '../../../core/l10n/app_strings.dart';

/// Evaluation text for the advisor screen (OB-007, OB-041). Scores are from
/// the user's side and describe the suggested move (OB-021 D12).
abstract final class EvalFormat {
  /// The value shown under the win-rate caption while there is no
  /// suggestion.
  static const String unknownValue = '--';

  /// `WIN RATE` / `--`, shown while there is no suggestion to evaluate.
  static EvalHeadline unknown(AppStrings strings) =>
      _headline(strings.winRate, unknownValue, strings, isFavorable: false);

  /// `WIN RATE` / `62%`, `YOU MATE IN` / `4` or `OPPONENT MATES IN` / `4`
  /// (OB-052 DS-7: caption above value). [EvalHeadline.isFavorable] picks
  /// green (true) or red.
  static EvalHeadline headline(
    EngineScore score,
    double winChance,
    AppStrings strings,
  ) {
    return switch (score) {
      MateScore(:final moves) when moves > 0 => _headline(
        strings.youMateIn,
        '$moves',
        strings,
        isFavorable: true,
      ),
      MateScore(:final moves) => _headline(
        strings.opponentMatesIn,
        '${moves.abs()}',
        strings,
        isFavorable: false,
      ),
      CentipawnScore() => _headline(
        strings.winRate,
        '${winChance.round()}%',
        strings,
        isFavorable: winChance.round() >= 50,
      ),
    };
  }

  /// One spoken label, e.g. `Win rate 62 percent`: upper-case captions
  /// would be spelled out by screen readers.
  static EvalHeadline _headline(
    String caption,
    String value,
    AppStrings strings, {
    required bool isFavorable,
  }) {
    final text = '$caption $value'.replaceAll('%', ' ${strings.percentSpoken}');
    return EvalHeadline(
      caption,
      value,
      spoken: text[0] + text.substring(1).toLowerCase(),
      isFavorable: isFavorable,
    );
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
  const EvalHeadline(
    this.caption,
    this.value, {
    required this.spoken,
    required this.isFavorable,
  });

  final String caption;
  final String value;

  /// One label for screen readers, e.g. `Win rate 62 percent`.
  final String spoken;
  final bool isFavorable;

  @override
  bool operator ==(Object other) =>
      other is EvalHeadline &&
      other.caption == caption &&
      other.value == value &&
      other.spoken == spoken &&
      other.isFavorable == isFavorable;

  @override
  int get hashCode => Object.hash(caption, value, spoken, isFavorable);

  @override
  String toString() => 'EvalHeadline($caption $value, favorable: $isFavorable)';
}
