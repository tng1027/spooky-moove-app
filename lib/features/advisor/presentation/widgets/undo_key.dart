import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_key.dart';
import '../../../new_game/presentation/game_registry.dart';

/// "UNDO" key (OB-012): takes back the last entered move, one per tap.
/// Disabled until a move is entered, unless the promotion chooser is open.
class UndoKey extends ConsumerWidget {
  const UndoKey({super.key = regionKey});

  static const Key regionKey = Key('advisor.undo');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = ref.watch(
      ref.watch(activeGameStateSourceProvider).select((game) => game.canUndo),
    );
    final color = isEnabled ? AppColors.textPrimary : AppColors.textSecondary;
    return AppKey(
      onTap: isEnabled ? ref.read(activeGameControllerProvider).undo : null,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppDimens.spacingSmall,
          children: [
            Icon(
              Icons.undo,
              size: AppTypography.primary.fontSize,
              color: color,
            ),
            Text(
              AppStrings.of(context).undo,
              style: AppTypography.primary.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
