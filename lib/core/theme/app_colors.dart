import 'package:flutter/painting.dart';

/// Color tokens from `memory-bank/designSystem.md`.
///
/// Accents carry meaning (green = good, red = danger, amber = selected) and
/// must not be used decoratively.
abstract final class AppColors {
  static const Color bgDark = Color(0xFF0F1015);
  static const Color surfaceDark = Color(0xFF1E2029);
  static const Color keyNormal = Color(0xFF2C2D35);
  static const Color keyDisabled = Color(0xFF1A1B20);
  static const Color accentGreen = Color(0xFF00E676);
  static const Color accentRed = Color(0xFFFF5252);
  static const Color accentActive = Color(0xFFFFD600);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E92A4);

  static const Color boardLight = keyNormal;
  static const Color boardDark = surfaceDark;

  /// Board-only: Xiangqi Red side glyphs and rims. Not a "danger" accent.
  static const Color pieceRed = Color(0xFFFF8A80);
}
