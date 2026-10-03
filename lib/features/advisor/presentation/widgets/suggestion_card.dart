import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/game/game_result.dart';
import '../../../../core/game/move_text.dart';
import '../../../../core/widgets/app_key.dart';
import '../../../new_game/domain/game_kind.dart';
import '../../../new_game/presentation/game_registry.dart';
import '../../domain/eval_format.dart';
import '../suggestion_controller.dart';

/// Suggestion card (OB-007): the persona's move in plain coordinates, any
/// extra physical action and the expert line. The win rate is in the top
/// bar (OB-041 revision 3).
class SuggestionCard extends ConsumerWidget {
  const SuggestionCard({super.key = regionKey});

  static const Key regionKey = Key('advisor.suggestionCard');
  static const Key retryKey = Key('suggestionCard.retry');
  static const String pickTierPrompt = 'PICK A LEVEL';
  static const String thinkingLabel = 'THINKING...';
  static const String errorLabel = 'ENGINE ERROR';
  static const String emptyLine = MoveText.emptyLine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(suggestionControllerProvider);
    final game = ref.watch(activeGameKindProvider);
    final hint = ref.watch(
      ref.watch(activeGameStateSourceProvider).select((g) => g.hint),
    );
    return Padding(
      padding: const EdgeInsets.all(AppDimens.spacing),
      child: Card(
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.spacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _content(state, game, ref),
                  ),
                ),
                if (hint != null)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(hint, style: AppTypography.secondary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(SuggestionState state, GameKind game, WidgetRef ref) {
    return switch (state) {
      SuggestionReady(:final engineMove, :final suggestion) => _Result(
        move: GameWidgets.suggestedMove(game, engineMove),
        expertLine: GameWidgets.expertLine(
          game,
          engineMove,
          EvalFormat.expertLine(
            suggestion.score,
            depth: suggestion.depth,
            nps: suggestion.nps,
          ),
        ),
      ),
      SuggestionThinking() => const _Empty(
        caption: thinkingLabel,
        isDimmed: true,
      ),
      SuggestionNoTier() => const _Empty(caption: pickTierPrompt),
      SuggestionFailed() => _Failed(
        onRetry: ref.read(suggestionControllerProvider.notifier).retry,
      ),
      SuggestionGameOver(:final headline) => _GameOver(headline: headline),
      SuggestionWaiting() => const _Empty(),
    };
  }
}

/// The result on two lines, e.g. `CHECKMATE` / `YOU WIN` (OB-024 BR-002).
class _GameOver extends StatelessWidget {
  const _GameOver({required this.headline});

  final GameResultHeadline headline;

  @override
  Widget build(BuildContext context) {
    final color = switch (headline.tone) {
      ResultTone.win => AppColors.accentGreen,
      ResultTone.loss => AppColors.accentRed,
      ResultTone.draw => AppColors.textPrimary,
    };
    final lines = headline.lines;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppDimens.spacingSmall,
      children: [
        Text(
          lines.first,
          style: AppTypography.suggestion.copyWith(color: color),
        ),
        for (final line in lines.skip(1))
          Text(line, style: AppTypography.primary.copyWith(color: color)),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({this.caption, this.isDimmed = false});

  final String? caption;
  final bool isDimmed;

  @override
  Widget build(BuildContext context) {
    final caption = this.caption;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          SuggestionCard.emptyLine,
          style: isDimmed
              ? AppTypography.suggestion.copyWith(
                  color: AppColors.textSecondary,
                )
              : AppTypography.suggestion,
        ),
        if (caption != null) ...[
          const SizedBox(height: AppDimens.spacingSmall),
          Text(caption, style: AppTypography.secondary),
        ],
      ],
    );
  }
}

/// The game's move area above the shared expert line.
class _Result extends StatelessWidget {
  const _Result({required this.move, required this.expertLine});

  final Widget move;
  final Widget expertLine;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppDimens.spacingSmall,
      children: [move, expertLine],
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppDimens.spacing,
      children: [
        Text(
          SuggestionCard.errorLabel,
          style: AppTypography.primary.copyWith(color: AppColors.accentRed),
        ),
        AppKey(key: SuggestionCard.retryKey, label: 'RETRY', onTap: onRetry),
      ],
    );
  }
}
