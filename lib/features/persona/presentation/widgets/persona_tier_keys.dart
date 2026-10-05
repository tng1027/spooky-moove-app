import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_block.dart';
import '../../domain/persona_tier.dart';

/// Equal-width keys for the 7 persona tiers, built from [PersonaTier.values]
/// (OB-023): a pictogram and the tier number (OB-052 DS-7). Fills the height
/// it is given.
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
      child: AppBlock(
        face: isSelected ? AppColors.accentActive : AppColors.keyNormal,
        side: isSelected ? AppColors.accentActiveSide : AppColors.keyNormalSide,
        hasHighlight: !isSelected,
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: _TierPictogram(tier: tier, color: _foreground),
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

/// One game-agnostic strength progression (OB-052 DS-7): a dot, then the
/// Cburnett pawn to king as one-colour silhouettes. Fixed size, so it never
/// clips at large text scales.
class _TierPictogram extends StatelessWidget {
  const _TierPictogram({required this.tier, required this.color});

  static const double _size = 24;
  static const double _dotSize = 8;

  final PersonaTier tier;
  final Color color;

  static String? _assetFor(PersonaTier tier) => switch (tier) {
    PersonaTier.baby => null,
    PersonaTier.gentle => 'assets/pieces/cburnett/bP.svg',
    PersonaTier.soft => 'assets/pieces/cburnett/bN.svg',
    PersonaTier.even => 'assets/pieces/cburnett/bB.svg',
    PersonaTier.solid => 'assets/pieces/cburnett/bR.svg',
    PersonaTier.master => 'assets/pieces/cburnett/bQ.svg',
    PersonaTier.god => 'assets/pieces/cburnett/bK.svg',
  };

  @override
  Widget build(BuildContext context) {
    final asset = _assetFor(tier);
    return SizedBox.square(
      dimension: _size,
      child: asset == null
          ? Center(
              child: Container(
                width: _dotSize,
                height: _dotSize,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            )
          : SvgPicture.asset(
              asset,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
    );
  }
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
