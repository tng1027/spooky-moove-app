import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/engine/engine_models.dart';
import 'package:spookymoove/features/advisor/domain/eval_format.dart';
import 'package:spookymoove/core/l10n/app_strings.dart';

void main() {
  group('headline', () {
    test('win chance is a whole percent, green from 50 %', () {
      const score = CentipawnScore(0);
      expect(
        EvalFormat.headline(score, 61.6, AppStrings.english),
        const EvalHeadline(
          'WIN RATE',
          '62%',
          spoken: 'Win rate 62 percent',
          isFavorable: true,
        ),
      );
      expect(
        EvalFormat.headline(score, 38.2, AppStrings.english),
        const EvalHeadline(
          'WIN RATE',
          '38%',
          spoken: 'Win rate 38 percent',
          isFavorable: false,
        ),
      );
      expect(
        EvalFormat.headline(score, 49.5, AppStrings.english).isFavorable,
        isTrue,
      );
      expect(
        EvalFormat.headline(score, 49.4, AppStrings.english).isFavorable,
        isFalse,
      );
    });

    test('forced mates use plain words', () {
      expect(
        EvalFormat.headline(const MateScore(4), 100, AppStrings.english),
        const EvalHeadline(
          'YOU MATE IN',
          '4',
          spoken: 'You mate in 4',
          isFavorable: true,
        ),
      );
      expect(
        EvalFormat.headline(const MateScore(-4), 0, AppStrings.english),
        const EvalHeadline(
          'OPPONENT MATES IN',
          '4',
          spoken: 'Opponent mates in 4',
          isFavorable: false,
        ),
      );
    });

    test('is spoken as one plain label', () {
      expect(
        EvalFormat.headline(
          const CentipawnScore(0),
          62,
          AppStrings.english,
        ).spoken,
        'Win rate 62 percent',
      );
      expect(
        EvalFormat.headline(const MateScore(4), 100, AppStrings.english).spoken,
        'You mate in 4',
      );
    });

    test('Vietnamese captions keep the number format', () {
      final headline = EvalFormat.headline(
        const CentipawnScore(0),
        61.6,
        AppStrings.vietnamese,
      );
      expect(headline.caption, 'TỶ LỆ THẮNG');
      expect(headline.value, '62%');
      expect(headline.spoken, 'Tỷ lệ thắng 62 phần trăm');
      expect(
        EvalFormat.unknown(AppStrings.vietnamese).value,
        EvalFormat.unknownValue,
      );
    });
  });

  group('expertLine', () {
    test('pawns with sign, depth and abbreviated nps', () {
      expect(
        EvalFormat.expertLine(
          const CentipawnScore(140),
          depth: 16,
          nps: 850000,
        ),
        'EVAL +1.4 • DEPTH 16 • 850k nps',
      );
      expect(
        EvalFormat.expertLine(
          const CentipawnScore(-63),
          depth: 8,
          nps: 1234567,
        ),
        'EVAL -0.6 • DEPTH 8 • 1.2M nps',
      );
    });

    test('nps abbreviations at the boundaries', () {
      String nps(int value) =>
          EvalFormat.expertLine(const CentipawnScore(0), nps: value);
      expect(nps(850), 'EVAL +0.0 • 850 nps');
      expect(nps(1000), 'EVAL +0.0 • 1k nps');
      expect(nps(999499), 'EVAL +0.0 • 999k nps');
      expect(nps(999500), 'EVAL +0.0 • 1.0M nps');
    });

    test('tiny negative scores do not show -0.0', () {
      expect(EvalFormat.expertLine(const CentipawnScore(-4)), 'EVAL +0.0');
    });

    test('mates and missing parts', () {
      expect(EvalFormat.expertLine(const MateScore(3)), 'EVAL M3');
      expect(
        EvalFormat.expertLine(const MateScore(-2), depth: 20),
        'EVAL -M2 • DEPTH 20',
      );
    });
  });
}
