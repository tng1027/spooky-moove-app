import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
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
class NewGameKey extends ConsumerStatefulWidget {
  const NewGameKey({super.key = regionKey});

  static const Key regionKey = Key('advisor.newGame');

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

  @override
  ConsumerState<NewGameKey> createState() => _NewGameKeyState();
}

class _NewGameKeyState extends ConsumerState<NewGameKey> {
  /// A rapid double tap opens only one confirmation dialog.
  bool _isDialogOpen = false;

  @override
  Widget build(BuildContext context) {
    return AppKey(
      onTap: _onTap,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          AppStrings.of(context).newGame,
          semanticsLabel: AppStrings.of(context).newGameSpoken,
          style: AppTypography.primary,
        ),
      ),
    );
  }

  Future<void> _onTap() async {
    if (_isDialogOpen) return;
    _isDialogOpen = true;
    final isConfirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const NewGameConfirmDialog(),
    );
    if (!mounted) return;
    _isDialogOpen = false;
    if (isConfirmed != true) return;
    NewGameKey.openNewGameScreen(context, ref);
  }
}

/// Pops `true` on confirm and `false` on cancel.
class NewGameConfirmDialog extends StatelessWidget {
  const NewGameConfirmDialog({super.key});

  static const Key confirmKey = Key('newGame.confirm');
  static const Key cancelKey = Key('newGame.cancel');

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AppDialog(
      title: strings.discardTitle,
      spokenTitle: strings.discardTitleSpoken,
      children: [
        Row(
          spacing: AppDimens.spacing,
          children: [
            Expanded(
              child: AppKey(
                key: cancelKey,
                label: strings.cancel,
                onTap: () => Navigator.of(context).maybePop(false),
              ),
            ),
            Expanded(
              child: AppKey(
                key: confirmKey,
                label: strings.newGame,
                semanticsLabel: strings.newGameSpoken,
                onTap: () => Navigator.of(context).maybePop(true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
