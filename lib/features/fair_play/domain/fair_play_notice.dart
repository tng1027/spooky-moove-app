/// Wording version of the fair-play notice (OB-008). Bump it whenever the
/// text changes so every user acknowledges the new wording.
const int fairPlayNoticeVersion = 1;

/// Bundled fair-play notice text for one language.
class FairPlayNoticeText {
  const FairPlayNoticeText({
    required this.title,
    required this.paragraphs,
    required this.acknowledgeLabel,
    required this.closeLabel,
  });

  final String title;
  final List<String> paragraphs;
  final String acknowledgeLabel;
  final String closeLabel;

  static const FairPlayNoticeText english = FairPlayNoticeText(
    title: 'FAIR PLAY',
    paragraphs: [
      'OmniChess Advisor is for training, casual study, handicap games and '
          'friendly offline play.',
      'Do NOT use it during rated, sanctioned or tournament games (FIDE, EGF, '
          'Nihon Ki-in or any other organisation) unless the arbiter has '
          'allowed it.',
      'Using move suggestions in competitive play is cheating and can get you '
          'disqualified. You are responsible for how you use this app.',
    ],
    acknowledgeLabel: 'I UNDERSTAND',
    closeLabel: 'CLOSE',
  );

  static const FairPlayNoticeText vietnamese = FairPlayNoticeText(
    title: 'CHƠI CỜ CÔNG BẰNG',
    paragraphs: [
      'OmniChess Advisor dành cho luyện tập, học cờ, chơi chấp quân và các ván '
          'giao hữu ngoài đời.',
      'KHÔNG sử dụng trong các ván đấu tính điểm, giải đấu chính thức hoặc thi '
          'đấu (FIDE, EGF, Nihon Ki-in hay bất kỳ tổ chức nào khác) nếu chưa '
          'được trọng tài cho phép.',
      'Dùng gợi ý nước đi khi thi đấu là gian lận và có thể bị truất quyền thi '
          'đấu. Bạn chịu trách nhiệm về cách sử dụng ứng dụng này.',
    ],
    acknowledgeLabel: 'TÔI ĐÃ HIỂU',
    closeLabel: 'ĐÓNG',
  );

  /// Vietnamese for a Vietnamese device, English otherwise.
  static FairPlayNoticeText forLanguage(String languageCode) =>
      languageCode == 'vi' ? vietnamese : english;
}
