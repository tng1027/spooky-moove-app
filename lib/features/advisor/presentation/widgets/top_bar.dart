import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../new_game/presentation/game_registry.dart';
import '../../../new_game/presentation/widgets/new_game_key.dart';
import '../../domain/eval_format.dart';
import '../suggestion_controller.dart';
import '../turn_status.dart';
import 'undo_key.dart';

/// Top bar: UNDO (OB-012) in the top-left corner, the suggested move's win
/// rate (OB-041 revision 3) or GAME OVER (OB-024) in the center, NEW GAME
/// (OB-011) in the top-right corner.
class TopBar extends ConsumerWidget {
  const TopBar({super.key = regionKey});

  static const Key regionKey = Key('advisor.topBar');
  static const String gameOverLabel = 'GAME OVER';

  /// Each corner key may take at most this share of the bar, so the label
  /// keeps room at large text scales (the key labels scale down instead).
  static const double _maxKeyWidthFraction = 0.3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOver = ref.watch(
      ref.watch(activeGameStateSourceProvider).select((game) => game.isOver),
    );
    final hasGame = ref.watch(turnStatusProvider) != null;
    final label = isOver
        ? const _Label(gameOverLabel)
        : hasGame
        ? _winRateLabel(ref.watch(suggestionControllerProvider))
        : null;
    return SizedBox(
      height: AppDimens.topBarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingSmall),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxKeyWidth = constraints.maxWidth * _maxKeyWidthFraction;
            return NavigationToolbar(
              leading: _cornerKey(const UndoKey(), maxKeyWidth),
              middle: label,
              trailing: _cornerKey(const NewGameKey(), maxKeyWidth),
              middleSpacing: AppDimens.spacing,
            );
          },
        ),
      ),
    );
  }

  /// The suggested move's win rate (or mate distance), green when favorable;
  /// `WIN RATE --` while there is no suggestion to evaluate.
  static Widget _winRateLabel(SuggestionState suggestion) {
    if (suggestion is! SuggestionReady) {
      return const _Label(EvalFormat.unknownWinRate);
    }
    final headline = EvalFormat.headline(
      suggestion.suggestion.score,
      suggestion.suggestion.winChance,
    );
    return _Label(
      headline.text,
      color: headline.isFavorable ? AppColors.accentGreen : AppColors.accentRed,
    );
  }

  /// AppKey fills bounded widths, so the key is sized to its content, capped
  /// at [maxWidth].
  static Widget _cornerKey(Widget key, double maxWidth) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: IntrinsicWidth(child: key),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.color = AppColors.textSecondary});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, style: AppTypography.primary.copyWith(color: color)),
    );
  }
}
