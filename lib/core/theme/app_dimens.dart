import 'package:flutter/animation.dart';

/// Size and shape tokens from `memory-bank/designSystem.md`.
abstract final class AppDimens {
  static const double radius = 4;
  static const double radiusLarge = 6;

  /// Includes [blockDepth]: face ≥ 44 dp + 4 dp side.
  static const double minKeyHeight = 48;
  static const double minBoardSquare = 44;
  static const double personaRowHeight = 52;

  /// Includes [spacingSmall] above the bottom button, below the board tray.
  static const double statusLineHeight = minKeyHeight + spacingSmall;
  static const double topBarHeight = 48;
  static const double minSuggestionCardHeight = 88;

  /// Padding of the advisor's board tray on all four sides (OB-052 DS-7).
  static const double boardTrayPadding = spacingSmall;

  /// Home game row incl. [blockDepth] (OB-052 DS-9), grows with text scale.
  static const double gameRowMinHeight = 72;

  /// The row's accent icon block incl. [blockDepth], and its pictogram.
  static const double gameIconBlockSize = 48;
  static const double gameIconPictogramSize = 32;

  static const double spacingSmall = 4;
  static const double spacing = 8;
  static const double spacingLarge = 16;

  /// Isometric extrusion of raised blocks (OB-052), also the press-sink
  /// distance. Counted inside the block's height.
  static const double blockDepth = 4;

  static const Duration pressSinkDuration = Duration(milliseconds: 80);
  static const Curve pressSinkCurve = Curves.easeOut;

  static const int boardFiles = 8;
  static const int boardRanks = 8;
}
