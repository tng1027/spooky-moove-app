import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../persona/domain/persona_tier.dart';
import '../../../persona/domain/persona_tier_copy.dart';
import '../../../persona/presentation/widgets/persona_tier_icon.dart';

/// Recessed, non-pressable card under the new-game level keys (OB-054 design
/// §5): the selected [tier]'s icon, name, strength bar and short description.
/// Always as tall as the longest description in [copy], so the section below
/// never jumps. Excluded from semantics: the level keys already carry the
/// same label and hint.
class LevelCard extends StatelessWidget {
  const LevelCard({required this.tier, required this.copy, super.key});

  static const Key iconKey = Key('newGame.levelCard.icon');
  static const Key nameKey = Key('newGame.levelCard.name');
  static const Key barKey = Key('newGame.levelCard.bar');
  static const Key descriptionKey = Key('newGame.levelCard.description');

  /// Keeps stacked Vietnamese diacritics from clipping between lines.
  static const double _descriptionLineHeight = 1.4;

  final PersonaTier tier;
  final Map<PersonaTier, TierCopy> copy;

  @override
  Widget build(BuildContext context) {
    final description = AppTypography.secondary.copyWith(
      height: _descriptionLineHeight,
    );
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(AppDimens.spacing),
        decoration: const BoxDecoration(
          color: AppColors.bgDark,
          borderRadius: BorderRadius.all(Radius.circular(AppDimens.radius)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppDimens.spacingSmall,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppDimens.spacing,
              runSpacing: AppDimens.spacingSmall,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppDimens.spacing,
                  children: [
                    PersonaTierIcon(
                      key: iconKey,
                      tier: tier,
                      color: AppColors.textPrimary,
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          copy[tier]!.name,
                          key: nameKey,
                          maxLines: 1,
                          style: AppTypography.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                _StrengthBar(key: barKey, level: tier.level),
              ],
            ),
            Stack(
              children: [
                for (final other in PersonaTier.values)
                  if (other == tier)
                    Text(
                      copy[other]!.description,
                      key: descriptionKey,
                      style: description,
                    )
                  else
                    Visibility(
                      visible: false,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: Text(copy[other]!.description, style: description),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Seven fixed-size segments, filled up to [level].
class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.level, super.key});

  static const double segmentWidth = 10;
  static const double segmentHeight = 6;

  final int level;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppDimens.spacingSmall,
      children: [
        for (var segment = 1; segment <= PersonaTier.values.length; segment++)
          Container(
            width: segmentWidth,
            height: segmentHeight,
            color: segment <= level
                ? AppColors.textPrimary
                : AppColors.keyNormal,
          ),
      ],
    );
  }
}
