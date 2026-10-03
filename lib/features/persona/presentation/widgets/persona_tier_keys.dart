import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/persona_tier.dart';

/// Equal-width keys for the 7 persona tiers, built from [PersonaTier.values]
/// (OB-023). Fills the height it is given.
class PersonaTierKeys extends StatelessWidget {
  const PersonaTierKeys({
    required this.selected,
    required this.onSelected,
    required this.tierKey,
    this.spacing = AppDimens.spacingSmall,
    super.key,
  });

  final PersonaTier? selected;
  final ValueChanged<PersonaTier> onSelected;
  final Key Function(PersonaTier tier) tierKey;
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
  });

  final PersonaTier tier;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: tier.label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentActive : AppColors.keyNormal,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppDimens.radius),
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(tier.emoji, style: AppTypography.tierEmoji),
            ),
          ),
        ),
      ),
    );
  }
}
