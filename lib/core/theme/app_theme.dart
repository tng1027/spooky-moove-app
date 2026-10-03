import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_typography.dart';

/// The only theme of the app: dark, flat, no shadows/gradients/blur.
abstract final class AppTheme {
  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.accentGreen,
      onPrimary: AppColors.bgDark,
      secondary: AppColors.accentActive,
      onSecondary: AppColors.bgDark,
      error: AppColors.accentRed,
      onError: AppColors.bgDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimary,
    );

    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgDark,
      fontFamily: AppTypography.fontFamily,
      textTheme: AppTypography.textTheme(base.textTheme),
      shadowColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      cardTheme: const CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppDimens.radius)),
        ),
      ),
    );
  }
}
