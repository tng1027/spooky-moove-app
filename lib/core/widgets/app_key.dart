import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';
import 'app_block.dart';

/// Design-system key: an isometric [AppBlock] ≥ 48 dp high (side included)
/// that sinks while pressed. `keyNormal` by default, amber when selected,
/// green when it is the primary action, the game accent when [accentColor]
/// is given, and lowered `keyDisabled` when [onTap] is null
/// (designSystem.md). Shows [label], or [child] when given.
class AppKey extends StatelessWidget {
  const AppKey({
    required this.onTap,
    this.label,
    this.child,
    this.isSelected = false,
    this.isPrimary = false,
    this.accentColor,
    this.accentSideColor,
    this.semanticsLabel,
    super.key,
  }) : assert((label == null) != (child == null), 'Pass label or child'),
       assert(
         (accentColor == null) == (accentSideColor == null),
         'Pass both accent colors or neither',
       );

  /// Null disables the key.
  final VoidCallback? onTap;
  final String? label;

  /// What a screen reader says instead of [label].
  final String? semanticsLabel;
  final Widget? child;
  final bool isSelected;

  /// The screen's main action (OB-041): `accentGreen` with dark text.
  final bool isPrimary;

  /// A game identity face and its side (OB-052), with dark text. Selected
  /// still wins with amber.
  final Color? accentColor;
  final Color? accentSideColor;

  bool get isEnabled => onTap != null;

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    final accentColor = this.accentColor;
    final accentSideColor = this.accentSideColor;
    final (face, side) = !isEnabled
        ? (AppColors.keyDisabled, null)
        : isSelected
        ? (AppColors.accentActive, AppColors.accentActiveSide)
        : isPrimary
        ? (AppColors.accentGreen, AppColors.accentGreenSide)
        : accentColor != null && accentSideColor != null
        ? (accentColor, accentSideColor)
        : (AppColors.keyNormal, AppColors.keyNormalSide);
    final isNeutral = face == AppColors.keyNormal;
    final foreground = !isEnabled
        ? AppColors.textSecondary
        : isNeutral
        ? AppColors.textPrimary
        : AppColors.bgDark;
    return Semantics(
      button: true,
      enabled: isEnabled,
      selected: isSelected,
      child: AppBlock(
        face: face,
        side: side,
        hasHighlight: isNeutral,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppDimens.minKeyHeight - AppDimens.blockDepth,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(AppDimens.spacing),
          child: label == null
              ? child
              : Text(
                  label,
                  semanticsLabel: semanticsLabel,
                  style: AppTypography.primary.copyWith(color: foreground),
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }
}
