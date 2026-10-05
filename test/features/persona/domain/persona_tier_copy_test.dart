import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/features/persona/domain/persona_tier.dart';
import 'package:spookymoove/features/persona/domain/persona_tier_copy.dart';
import 'package:spookymoove/features/settings/domain/app_language.dart';

/// Approved strings, OB-054 D3 / D8.
const _approved = {
  PersonaTier.baby: (
    en: 'NOOB',
    vi: 'GÀ MỜ',
    enText: 'Suggests comically bad moves that gift pieces away. Perfect for letting kids win.',
    viText: 'Gợi ý toàn nước "tấu hài", thả quân biếu không. Nhường bé thắng là chuẩn bài!',
  ),
  PersonaTier.gentle: (
    en: 'ROOKIE',
    vi: 'TÂN BINH',
    enText: 'Knows the rules, still learning. Suggests clearly weaker moves for easy games.',
    viText: 'Biết luật nhưng còn non: gợi ý nước yếu thấy rõ. Chơi nhẹ nhàng với người mới.',
  ),
  PersonaTier.soft: (
    en: 'CHILL GUY',
    vi: 'CHILL CHILL',
    enText: 'Solid, laid-back moves, a notch below its best. Grab a coffee and enjoy.',
    viText: 'Gợi ý nước chắc, nhẹ tay một chút. Cà phê, cờ nhẹ, không cay cú.',
  ),
  PersonaTier.even: (
    en: '50/50',
    vi: 'HÊN XUI',
    enText: 'Keeps it 50/50: eases up when you lead, brings its best when you fall behind.',
    viText: 'Giữ ván sát nút: bạn dẫn thì nương tay, bạn bị dẫn thì gợi ý nước tốt nhất.',
  ),
  PersonaTier.solid: (
    en: 'HUSTLER',
    vi: 'CÁO GIÀ',
    enText: 'Quick and crafty: the best move it sees on a short look ahead. Slip up and it pounces.',
    viText: 'Lanh lẹ, mắt tinh: gợi ý nước mạnh nhất trong tầm ngắn. Sơ hở là bị bắt bài.',
  ),
  PersonaTier.master: (
    en: 'LOCAL BOSS',
    vi: 'ÔNG TRÙM',
    enText: 'Thinks deeper, hits harder. Solid in attack and defence, hard to catch out.',
    viText: 'Tính sâu hơn, đánh lì hơn. Công thủ toàn diện, khó mà bắt lỗi.',
  ),
  PersonaTier.god: (
    en: 'BIG BRAIN',
    vi: 'CAO THỦ',
    enText: 'Full thinking time for the strongest move the app can find. Our toughest level.',
    viText: 'Dùng trọn thời gian suy nghĩ, gợi ý nước mạnh nhất app tìm được. Cấp mạnh nhất!',
  ),
};

/// OB-054 BR-003 / BR-004 and the OB-034 banned terms.
const _bannedTerms = [
  'god',
  'flawless',
  'absolute',
  'zero mistakes',
  'unbeatable',
  'grandmaster',
  'toddler',
  'bot',
  'cheat',
  'plies',
  'depth',
  'cờ độ',
  'cá cược',
  'kèo',
  'gian lận',
  'bay màu',
];

const _oldNames = ['Baby', 'Gentle', 'Soft', 'Even', 'Solid', 'Master', 'God'];

void main() {
  final languages = {
    'EN': PersonaTierCopy.english,
    'VI': PersonaTierCopy.vietnamese,
  };

  test('every tier has the approved EN and VI name and description', () {
    for (final tier in PersonaTier.values) {
      final approved = _approved[tier]!;
      expect(PersonaTierCopy.english[tier]!.name, approved.en);
      expect(PersonaTierCopy.english[tier]!.description, approved.enText);
      expect(PersonaTierCopy.vietnamese[tier]!.name, approved.vi);
      expect(PersonaTierCopy.vietnamese[tier]!.description, approved.viText);
    }
  });

  test('names ≤ 12 and descriptions ≤ 90 characters, nothing empty', () {
    languages.forEach((language, copy) {
      expect(copy.keys, PersonaTier.values, reason: language);
      for (final MapEntry(key: tier, value: text) in copy.entries) {
        final reason = '$language ${tier.name}';
        expect(text.name, isNotEmpty, reason: reason);
        expect(text.spoken, isNotEmpty, reason: reason);
        expect(text.name.runes.length, lessThanOrEqualTo(12), reason: reason);
        expect(
          text.description.runes.length,
          lessThanOrEqualTo(90),
          reason: reason,
        );
      }
    });
  });

  test('descriptions use no banned or old-name wording', () {
    languages.forEach((language, copy) {
      for (final MapEntry(key: tier, value: text) in copy.entries) {
        final lower = text.description.toLowerCase();
        for (final term in _bannedTerms) {
          expect(
            RegExp(
              '\\b${RegExp.escape(term)}\\b',
              unicode: true,
            ).hasMatch(lower),
            isFalse,
            reason: '$language ${tier.name}: "$term"',
          );
        }
        for (final old in _oldNames) {
          expect(text.name.toLowerCase(), isNot(old.toLowerCase()));
          expect(
            text.spoken.contains(old),
            isFalse,
            reason: '$language ${tier.name}',
          );
        }
      }
    });
  });

  test('spoken forms: 50/50 is read as words; key label and heading', () {
    const en = AppLanguage.english;
    expect(PersonaTierCopy.of(PersonaTier.even, en).spoken, 'Fifty-fifty');
    expect(
      PersonaTierCopy.keyLabel(PersonaTier.even, en),
      'Level 4 of 7, Fifty-fifty',
    );
    expect(PersonaTierCopy.levelHeading(en), 'LEVEL');
    expect(
      PersonaTierCopy.spokenHeading(PersonaTier.god, en),
      'Level, Big brain',
    );
  });
}
