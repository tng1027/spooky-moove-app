import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_key.dart';
import '../../domain/game_kind.dart';
import '../game_session_controller.dart';
import '../home_screen.dart';

/// "NEW GAME" key on the advisor screen (OB-011 REQ-001, REQ-007).
///
/// Asks for confirmation; confirming discards the current game and opens the
/// new-game screen (OB-050). CANCEL leaves the game unchanged.
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
    openNewGameScreen(context, ref);
  }

  /// Discards the current game without asking (OB-050 D1) and opens the
  /// new-game screen for the same game, with Home as the root beneath it.
  ///
  /// The navigator and notifier are captured first: discarding swaps the
  /// root from the advisor to Home, which disposes [context] and [ref].
  static void openNewGameScreen(BuildContext context, WidgetRef ref) {
    final navigator = Navigator.of(context);
    final session = ref.read(gameSessionProvider.notifier);
    final game = ref.read(gameSessionProvider)?.game ?? GameKind.values.first;
    session.discard();
    HomeScreen.openNewGame(navigator, game: game, onStart: session.start);
  }
}

/// Pops `true` on confirm and `false` on cancel.
class NewGameConfirmDialog extends StatelessWidget {
  const NewGameConfirmDialog({super.key});

  static const Key confirmKey = Key('newGame.confirm');
  static const Key cancelKey = Key('newGame.cancel');

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'DISCARD THE CURRENT GAME?',
      spokenTitle: 'Discard the current game?',
      children: [
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
    );
  }
}
