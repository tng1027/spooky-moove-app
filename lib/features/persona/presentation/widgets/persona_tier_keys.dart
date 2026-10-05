import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_block.dart';
import '../../domain/persona_tier.dart';
import '../../domain/persona_tier_copy.dart';
import 'persona_tier_icon.dart';

/// Equal-width keys for the 7 persona tiers, built from [PersonaTier.values]
/// (OB-023): the tier's icon (OB-054 D9) and number (OB-052 DS-7). Fills the
/// height it is given. [hintOf] adds a spoken hint per key; the advisor passes
/// none, so descriptions are only read on the new-game screen (OB-054 D5).
class PersonaTierKeys extends StatelessWidget {
  const PersonaTierKeys({
    required this.selected,
    required this.onSelected,
    required this.tierKey,
    this.hintOf,
    this.spacing = AppDimens.spacingSmall,
    super.key,
  });

  final PersonaTier? selected;
  final ValueChanged<PersonaTier> onSelected;
  final Key Function(PersonaTier tier) tierKey;
  final String Function(PersonaTier tier)? hintOf;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: spacing,
      children: [
        for (final tier in PersonaTier.values)
          Expanded(
            child: _TierKey(
              key: tierKey(tier),
              tier: tier,
              isSelected: tier == selected,
              hint: hintOf?.call(tier),
              onTap: () => onSelected(tier),
            ),
          ),
      ],
    );
  }
}

class _TierKey extends StatelessWidget {
  const _TierKey({
    super.key,
    required this.tier,
    required this.isSelected,
    required this.onTap,
    this.hint,
  });

  final PersonaTier tier;
  final bool isSelected;
  final VoidCallback onTap;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: PersonaTierCopy.keyLabel(tier, AppStrings.of(context).language),
      hint: hint,
      onTap: onTap,
      excludeSemantics: true,
      child: AppBlock(
        face: isSelected ? AppColors.accentActive : AppColors.keyNormal,
        side: isSelected ? AppColors.accentActiveSide : AppColors.keyNormalSide,
        hasHighlight: !isSelected,
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: PersonaTierIcon(tier: tier, color: _foreground),
            ),
            Positioned(
              right: _badgeInset,
              bottom: _badgeInset,
              child: _LevelBadge(level: tier.level),
            ),
          ],
        ),
      ),
    );
  }

  Color get _foreground =>
      isSelected ? AppColors.bgDark : AppColors.textPrimary;

  static const double _badgeInset = 2;
}

/// The tier number 1–7 in a small dark circle; does not scale with text.
class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  static const double _size = 14;

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$level',
        textScaler: TextScaler.noScaling,
        style: AppTypography.boardLabel.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1,
        ),
      ),
    );
  }
}
