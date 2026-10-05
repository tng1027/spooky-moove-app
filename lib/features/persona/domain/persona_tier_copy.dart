import '../../settings/domain/app_language.dart';
import 'persona_tier.dart';

/// User-facing text of one tier: [name] as shown (upper case), [spoken] for
/// screen readers, and the short [description] of what its suggestions do.
typedef TierCopy = ({String name, String spoken, String description});

/// Approved tier names and on-screen descriptions (OB-054 D3, D8). They must
/// stay true to the tier logic in `tier_selection.dart` (OB-054 BR-001);
/// change them only together with the ticket and the design spec.
abstract final class PersonaTierCopy {
  static const Map<PersonaTier, TierCopy> english = {
    PersonaTier.baby: (
      name: 'NOOB',
      spoken: 'Noob',
      description:
          'Suggests comically bad moves that gift pieces away. '
          'Perfect for letting kids win.',
    ),
    PersonaTier.gentle: (
      name: 'ROOKIE',
      spoken: 'Rookie',
      description:
          'Knows the rules, still learning. '
          'Suggests clearly weaker moves for easy games.',
    ),
    PersonaTier.soft: (
      name: 'CHILL GUY',
      spoken: 'Chill guy',
      description:
          'Solid, laid-back moves, a notch below its best. '
          'Grab a coffee and enjoy.',
    ),
    PersonaTier.even: (
      name: '50/50',
      spoken: 'Fifty-fifty',
      description:
          'Keeps it 50/50: eases up when you lead, '
          'brings its best when you fall behind.',
    ),
    PersonaTier.solid: (
      name: 'HUSTLER',
      spoken: 'Hustler',
      description:
          'Quick and crafty: the best move it sees on a short look ahead. '
          'Slip up and it pounces.',
    ),
    PersonaTier.master: (
      name: 'LOCAL BOSS',
      spoken: 'Local boss',
      description:
          'Thinks deeper, hits harder. '
          'Solid in attack and defence, hard to catch out.',
    ),
    PersonaTier.god: (
      name: 'BIG BRAIN',
      spoken: 'Big brain',
      description:
          'Full thinking time for the strongest move the app can find. '
          'Our toughest level.',
    ),
  };

  static const Map<PersonaTier, TierCopy> vietnamese = {
    PersonaTier.baby: (
      name: 'GÀ MỜ',
      spoken: 'Gà mờ',
      description:
          'Gợi ý toàn nước "tấu hài", thả quân biếu không. '
          'Nhường bé thắng là chuẩn bài!',
    ),
    PersonaTier.gentle: (
      name: 'TÂN BINH',
      spoken: 'Tân binh',
      description:
          'Biết luật nhưng còn non: gợi ý nước yếu thấy rõ. '
          'Chơi nhẹ nhàng với người mới.',
    ),
    PersonaTier.soft: (
      name: 'CHILL CHILL',
      spoken: 'Chill chill',
      description:
          'Gợi ý nước chắc, nhẹ tay một chút. '
          'Cà phê, cờ nhẹ, không cay cú.',
    ),
    PersonaTier.even: (
      name: 'HÊN XUI',
      spoken: 'Hên xui',
      description:
          'Giữ ván sát nút: bạn dẫn thì nương tay, '
          'bạn bị dẫn thì gợi ý nước tốt nhất.',
    ),
    PersonaTier.solid: (
      name: 'CÁO GIÀ',
      spoken: 'Cáo già',
      description:
          'Lanh lẹ, mắt tinh: gợi ý nước mạnh nhất trong tầm ngắn. '
          'Sơ hở là bị bắt bài.',
    ),
    PersonaTier.master: (
      name: 'ÔNG TRÙM',
      spoken: 'Ông trùm',
      description:
          'Tính sâu hơn, đánh lì hơn. '
          'Công thủ toàn diện, khó mà bắt lỗi.',
    ),
    PersonaTier.god: (
      name: 'CAO THỦ',
      spoken: 'Cao thủ',
      description:
          'Dùng trọn thời gian suy nghĩ, gợi ý nước mạnh nhất app tìm được. '
          'Cấp mạnh nhất!',
    ),
  };

  static Map<PersonaTier, TierCopy> forLanguage(AppLanguage language) =>
      switch (language) {
        AppLanguage.english => english,
        AppLanguage.vietnamese => vietnamese,
      };

  static TierCopy of(PersonaTier tier, AppLanguage language) =>
      forLanguage(language)[tier]!;

  /// Static LEVEL section heading on the new-game screen (OB-054 REQ-002).
  static String levelHeading(AppLanguage language) => switch (language) {
    AppLanguage.english => 'LEVEL',
    AppLanguage.vietnamese => 'CẤP ĐỘ',
  };

  /// Spoken heading, e.g. "Level, Fifty-fifty".
  static String spokenHeading(PersonaTier tier, AppLanguage language) =>
      switch (language) {
        AppLanguage.english => 'Level, ${of(tier, language).spoken}',
        AppLanguage.vietnamese => 'Cấp độ, ${of(tier, language).spoken}',
      };

  /// Spoken label of a level key, e.g. "Level 4 of 7, Fifty-fifty".
  static String keyLabel(PersonaTier tier, AppLanguage language) {
    final count = PersonaTier.values.length;
    final spoken = of(tier, language).spoken;
    return switch (language) {
      AppLanguage.english => 'Level ${tier.level} of $count, $spoken',
      AppLanguage.vietnamese => 'Cấp ${tier.level} trên $count, $spoken',
    };
  }
}
