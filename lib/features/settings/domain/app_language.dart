/// App languages offered in the Language dialog, in display order (OB-051
/// BR-001). Each name is written in its own language (BR-002).
enum AppLanguage {
  english('ENGLISH', spoken: 'English', code: 'en'),
  vietnamese('TIẾNG VIỆT', spoken: 'Tiếng Việt', code: 'vi');

  const AppLanguage(this.label, {required this.spoken, required this.code});

  final String label;

  /// What a screen reader says; upper-case labels would be spelled out.
  final String spoken;

  /// ISO 639-1 language code, used for the app locale and persistence.
  final String code;

  /// Vietnamese for any `vi` region, English otherwise (OB-053 REQ-002).
  static AppLanguage fromDeviceCode(String languageCode) =>
      languageCode == vietnamese.code ? vietnamese : english;

  static AppLanguage? fromCode(String? code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return null;
  }
}
