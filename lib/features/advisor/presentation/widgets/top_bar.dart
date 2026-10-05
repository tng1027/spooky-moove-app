import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../new_game/presentation/game_registry.dart';
import '../../../new_game/presentation/widgets/new_game_key.dart';
import '../../domain/eval_format.dart';
import '../suggestion_controller.dart';
import '../turn_status.dart';
import 'undo_key.dart';

/// Top bar: NEW GAME (OB-011) in the top-left corner, the suggested move's
/// win rate (OB-041 revision 3) as caption over value (OB-052 DS-7) or
/// GAME OVER (OB-024) in the center, UNDO (OB-012) in the top-right corner
/// (OB-050).
class TopBar extends ConsumerWidget {
  const TopBar({super.key = regionKey});

  static const Key regionKey = Key('advisor.topBar');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOver = ref.watch(
      ref.watch(activeGameStateSourceProvider).select((game) => game.isOver),
    );
    final hasGame = ref.watch(turnStatusProvider) != null;
    final strings = AppStrings.of(context);
    final label = isOver
        ? _Label(strings.gameOver)
        : hasGame
        ? _winRateLabel(ref.watch(suggestionControllerProvider), strings)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingSmall),
      child: ScreenHeader(
        leading: const NewGameKey(),
        middle: label,
        trailing: const UndoKey(),
      ),
    );
  }

  /// The suggested move's win rate (or mate distance), green when favorable;
  /// `WIN RATE` / `--` while there is no suggestion to evaluate.
  static Widget _winRateLabel(SuggestionState suggestion, AppStrings strings) {
    if (suggestion is! SuggestionReady) {
      return _Headline(
        EvalFormat.unknown(strings),
        color: AppColors.textSecondary,
      );
    }
    final headline = EvalFormat.headline(
      suggestion.suggestion.score,
      suggestion.suggestion.winChance,
      strings,
    );
    return _Headline(
      headline,
      color: headline.isFavorable ? AppColors.accentGreen : AppColors.accentRed,
    );
  }
}

/// Caption over value, scaled down as one block at large text scales.
class _Headline extends StatelessWidget {
  const _Headline(this.headline, {required this.color});

  final EvalHeadline headline;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: headline.spoken,
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(headline.caption, style: AppTypography.secondary),
            Text(
              headline.value,
              style: AppTypography.winRate.copyWith(color: color, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: AppTypography.primary.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
