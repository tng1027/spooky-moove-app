import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';

/// Design-system key: flat block, small radius, ≥ 48 dp high, amber when
/// selected, green when it is the primary action, `keyDisabled` when [onTap]
/// is null (designSystem.md). Shows [label], or [child] when given.
class AppKey extends StatelessWidget {
  const AppKey({
    required this.onTap,
    this.label,
    this.child,
    this.isSelected = false,
    this.isPrimary = false,
    this.semanticsLabel,
    super.key,
  }) : assert((label == null) != (child == null), 'Pass label or child');

  /// Null disables the key.
  final VoidCallback? onTap;
  final String? label;

  /// What a screen reader says instead of [label].
  final String? semanticsLabel;
  final Widget? child;
  final bool isSelected;

  /// The screen's main action (OB-041): `accentGreen` with dark text.
  final bool isPrimary;

  bool get isEnabled => onTap != null;

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    final background = !isEnabled
        ? AppColors.keyDisabled
        : isSelected
        ? AppColors.accentActive
        : isPrimary
        ? AppColors.accentGreen
        : AppColors.keyNormal;
    final foreground = !isEnabled
        ? AppColors.textSecondary
        : isSelected || isPrimary
        ? AppColors.bgDark
        : AppColors.textPrimary;
    return Semantics(
      button: true,
      enabled: isEnabled,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppDimens.minKeyHeight),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(AppDimens.spacing),
          decoration: BoxDecoration(
            color: background,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppDimens.radius),
            ),
          ),
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
