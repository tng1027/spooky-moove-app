/// App languages offered in the Language dialog, in display order (OB-051
/// BR-001). Each name is written in its own language (BR-002).
enum AppLanguage {
  english('ENGLISH', spoken: 'English');

  const AppLanguage(this.label, {required this.spoken});

  /// English is the only language until localization ships (OB-051 REQ-005).
  static const AppLanguage current = english;

  final String label;

  /// What a screen reader says; upper-case labels would be spelled out.
  final String spoken;
}
