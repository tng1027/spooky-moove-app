import 'package:flutter/painting.dart';

/// Color tokens from `memory-bank/designSystem.md`.
///
/// Status accents carry meaning (green = good, red = danger, amber =
/// selected). Game accents (OB-052) only identify a game and never signal
/// status. `bgDark` is the text colour on every accent, amber and green face.
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

  static const Color accentChess = Color(0xFFED96D7);
  static const Color accentXiangqi = Color(0xFF578EF5);

  /// Isometric side faces, drawn under the face colour of the same name.
  static const Color accentChessSide = Color(0xFFA8508F);
  static const Color accentXiangqiSide = Color(0xFF2A56B3);
  static const Color keyNormalSide = Color(0xFF1D1E25);
  static const Color surfaceSide = Color(0xFF15161D);
  static const Color accentActiveSide = Color(0xFFA68B00);
  static const Color accentGreenSide = Color(0xFF00994F);

  /// 1 dp top edge on neutral faces (`keyNormal`, `surfaceDark`) only.
  static const Color edgeHighlight = Color(0xFF3A3B45);

  static const Color boardLight = keyNormal;
  static const Color boardDark = surfaceDark;

  /// Board-only: Xiangqi Red side glyphs and rims. Not a "danger" accent.
  static const Color pieceRed = Color(0xFFFF8A80);
}
