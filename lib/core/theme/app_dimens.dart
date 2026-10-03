/// Size and shape tokens from `memory-bank/designSystem.md`.
abstract final class AppDimens {
  static const double radius = 4;
  static const double radiusLarge = 6;

  static const double minKeyHeight = 48;
  static const double minBoardSquare = 44;
  static const double personaRowHeight = 52;

  /// Includes [spacing] above the bottom button, separating it from the board.
  static const double statusLineHeight = minKeyHeight + spacing;
  static const double topBarHeight = 48;
  static const double minSuggestionCardHeight = 96;

  static const double spacingSmall = 4;
  static const double spacing = 8;
  static const double spacingLarge = 16;

  static const int boardFiles = 8;
  static const int boardRanks = 8;
}
