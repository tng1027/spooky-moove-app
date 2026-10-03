import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_key.dart';
import '../game_session_controller.dart';
import '../new_game_screen.dart';

/// "NEW GAME" key on the advisor screen (OB-011 REQ-001, REQ-007).
///
/// Asks for confirmation, then opens the new-game screen over the advisor.
/// The current game and its tier are only discarded once a side is tapped,
/// so backing out leaves them unchanged.
class NewGameKey extends ConsumerWidget {
  const NewGameKey({super.key = regionKey});

  static const Key regionKey = Key('advisor.newGame');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppKey(
      onTap: () => _onTap(context, ref),
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text('NEW GAME', style: AppTypography.primary),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    final isConfirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const NewGameConfirmDialog(),
    );
    if (isConfirmed != true || !context.mounted) return;
    await openNewGameScreen(context, ref);
  }

  /// Opens the new-game screen without asking; BACK keeps the current game.
  static Future<void> openNewGameScreen(BuildContext context, WidgetRef ref) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => NewGameScreen(
          initialGame: ref.read(gameSessionProvider)?.game,
          onStart: (game, userSide, tier) {
            ref.read(gameSessionProvider.notifier).start(game, userSide, tier);
            Navigator.of(routeContext).pop();
          },
        ),
      ),
    );
  }
}

/// Pops `true` on confirm and `false` on cancel.
class NewGameConfirmDialog extends StatelessWidget {
  const NewGameConfirmDialog({super.key});

  static const Key confirmKey = Key('newGame.confirm');
  static const Key cancelKey = Key('newGame.cancel');

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppDimens.radius)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppDimens.spacingLarge,
          children: [
            const Text(
              'DISCARD THE CURRENT GAME?',
              style: AppTypography.primary,
            ),
            Row(
              spacing: AppDimens.spacing,
              children: [
                Expanded(
                  child: AppKey(
                    key: cancelKey,
                    label: 'CANCEL',
                    onTap: () => Navigator.of(context).maybePop(false),
                  ),
                ),
                Expanded(
                  child: AppKey(
                    key: confirmKey,
                    label: 'NEW GAME',
                    onTap: () => Navigator.of(context).maybePop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
