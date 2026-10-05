import '../../settings/domain/app_language.dart';

/// Wording version of the fair-play notice (OB-008). Bump it whenever the
/// text changes so every user acknowledges the new wording.
const int fairPlayNoticeVersion = 4;

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
      'Spooky Moove is for training, casual study, handicap games and '
          'friendly offline play.',
      'Do NOT use it during rated, sanctioned or tournament games (FIDE, '
          'national chess or xiangqi federations, or any other organisation) '
          'unless the arbiter has allowed it.',
      'Using move suggestions in competitive play breaks fair-play rules and '
          'can get you disqualified. You are responsible for how you use this '
          'app.',
    ],
    acknowledgeLabel: 'I UNDERSTAND',
    closeLabel: 'CLOSE',
  );

  static const FairPlayNoticeText vietnamese = FairPlayNoticeText(
    title: 'CHƠI CỜ CÔNG BẰNG',
    paragraphs: [
      'Spooky Moove dành cho luyện tập, học cờ, chơi chấp quân và các ván '
          'giao hữu ngoài đời.',
      'KHÔNG sử dụng trong các ván đấu tính điểm, giải đấu chính thức hoặc thi '
          'đấu (FIDE, các liên đoàn cờ vua hoặc cờ tướng quốc gia, hay bất kỳ '
          'tổ chức nào khác) nếu chưa được trọng tài cho phép.',
      'Dùng gợi ý nước đi khi thi đấu là vi phạm luật chơi công bằng và có '
          'thể bị truất quyền thi đấu. Bạn chịu trách nhiệm về cách sử dụng '
          'ứng dụng này.',
    ],
    acknowledgeLabel: 'TÔI ĐÃ HIỂU',
    closeLabel: 'ĐÓNG',
  );

  static FairPlayNoticeText forLanguage(AppLanguage language) =>
      switch (language) {
        AppLanguage.english => english,
        AppLanguage.vietnamese => vietnamese,
      };
}
