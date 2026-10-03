import 'package:flutter/material.dart';

import 'app_colors.dart';

/// JetBrains Mono, bundled as an asset font so no network fetch is needed.
/// Every style uses tabular figures so updating numbers never shift layout.
abstract final class AppTypography {
  static const String fontFamily = 'JetBrainsMono';

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static const TextStyle suggestion = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.accentGreen,
    fontFeatures: _tabular,
  );

  static const TextStyle primary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFeatures: _tabular,
  );

  static const TextStyle secondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    fontFeatures: _tabular,
  );

  /// Persona tier emoji (OB-023 BR-004: 20–22 sp).
  static const TextStyle tierEmoji = TextStyle(fontSize: 21, height: 1);

  static const TextStyle boardLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    fontFeatures: _tabular,
  );

  /// Material text theme where every slot uses the app font with tabular
  /// figures, so widgets that fall back to theme styles stay consistent.
  static TextTheme textTheme(TextTheme base) {
    TextStyle? withAppFont(TextStyle? style) => style?.copyWith(
      fontFamily: fontFamily,
      fontFeatures: _tabular,
      color: AppColors.textPrimary,
    );

    return TextTheme(
      displayLarge: withAppFont(base.displayLarge),
      displayMedium: withAppFont(base.displayMedium),
      displaySmall: withAppFont(base.displaySmall),
      headlineLarge: withAppFont(base.headlineLarge),
      headlineMedium: withAppFont(base.headlineMedium),
      headlineSmall: withAppFont(base.headlineSmall),
      titleLarge: withAppFont(base.titleLarge),
      titleMedium: withAppFont(base.titleMedium),
      titleSmall: withAppFont(base.titleSmall),
      bodyLarge: withAppFont(base.bodyLarge),
      bodyMedium: withAppFont(base.bodyMedium),
      bodySmall: withAppFont(base.bodySmall),
      labelLarge: withAppFont(base.labelLarge),
      labelMedium: withAppFont(base.labelMedium),
      labelSmall: withAppFont(base.labelSmall),
    );
  }
}
