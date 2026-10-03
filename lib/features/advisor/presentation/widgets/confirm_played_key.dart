import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_key.dart';
import '../../../new_game/presentation/game_registry.dart';
import '../suggestion_controller.dart';

/// "✓ I PLAYED IT" key (OB-041): commits the suggestion shown on the card,
/// so the user doesn't have to enter it on the board again. Green with dark
/// text when enabled (the screen's primary action).
class ConfirmPlayedKey extends ConsumerWidget {
  const ConfirmPlayedKey({required this.isEnabled, super.key = regionKey});

  static const Key regionKey = Key('advisor.confirmPlayed');
  static const String label = '✓ I PLAYED IT';
  static const String semanticsLabel = 'I played the suggested move';

  final bool isEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = isEnabled ? AppColors.bgDark : AppColors.textSecondary;
    return AppKey(
      onTap: isEnabled ? () => _commitSuggestion(ref) : null,
      isPrimary: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Semantics(
          label: semanticsLabel,
          excludeSemantics: true,
          child: Text(
            label,
            style: AppTypography.primary.copyWith(color: color),
          ),
        ),
      ),
    );
  }

  /// Commits the move held by the ready state, never a re-derived one, so a
  /// stale suggestion can't be played (REQ-006).
  static void _commitSuggestion(WidgetRef ref) {
    final suggestion = ref.read(suggestionControllerProvider);
    if (suggestion is! SuggestionReady) return;
    ref
        .read(activeGameControllerProvider)
        .commitEngineMove(suggestion.engineMove);
  }
}
