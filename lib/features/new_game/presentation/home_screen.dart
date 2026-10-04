import 'package:flutter/material.dart';

import '../../../core/game/player_side.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_key.dart';
import '../../../core/widgets/screen_header.dart';
import '../../settings/domain/app_language.dart';
import '../../settings/presentation/language_dialog.dart';
import '../../settings/presentation/settings_dialog.dart';
import '../domain/game_kind.dart';
import 'game_registry.dart';
import 'new_game_screen.dart';

/// Home screen (OB-049): one big key per [GameKind]; tapping one opens the
/// new-game screen for that game. Header (OB-051): SETTINGS, the title,
/// LANGUAGE. Always the root: no game is ever beneath it (OB-050 D1).
class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.onStart, super.key});

  static const Key settingsKey = Key('home.settings');
  static const Key languageKey = Key('home.language');

  static Key gameKey(GameKind game) => Key('home.game.${game.name}');

  final StartNewGame onStart;

  /// Pushes the new-game screen for [game]. START leaves only the root route,
  /// so no Home or new-game screen stays beneath the advisor (REQ-006).
  static Future<void> openNewGame(
    NavigatorState navigator, {
    required GameKind game,
    required StartNewGame onStart,
  }) {
    return navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => NewGameScreen(
          game: game,
          onStart: (game, userSide, tier) {
            onStart(game, userSide, tier);
            navigator.popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// A rapid double tap on any Home key must open only one screen or dialog.
  bool _isNavigating = false;

  Future<void> _guarded(Future<void> Function() action) async {
    if (_isNavigating) return;
    _isNavigating = true;
    await action();
    if (mounted) _isNavigating = false;
  }

  Future<void> _open(GameKind game) => _guarded(
    () => HomeScreen.openNewGame(
      Navigator.of(context),
      game: game,
      onStart: widget.onStart,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: AppDimens.spacingLarge,
                        children: [
                          const SizedBox(height: AppDimens.spacingLarge),
                          for (final game in GameKind.values) _gameKey(game),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return ScreenHeader(
      leading: HeaderKey(
        key: HomeScreen.settingsKey,
        label: 'SETTINGS',
        semanticsLabel: 'Settings',
        onTap: () => _guarded(
          () => showDialog<void>(
            context: context,
            builder: (_) => const SettingsDialog(),
          ),
        ),
      ),
      middle: Semantics(
        header: true,
        label: 'Pick a game',
        excludeSemantics: true,
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('PICK A GAME', style: AppTypography.primary),
        ),
      ),
      trailing: HeaderKey(
        key: HomeScreen.languageKey,
        label: 'LANGUAGE',
        semanticsLabel: 'Language',
        onTap: () => _guarded(
          () => showDialog<AppLanguage>(
            context: context,
            builder: (_) => const LanguageDialog(selected: AppLanguage.current),
          ),
        ),
      ),
    );
  }

  Widget _gameKey(GameKind game) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppDimens.gameKeyMinHeight),
      child: AppKey(
        key: HomeScreen.gameKey(game),
        onTap: () => _open(game),
        child: Semantics(
          label: NewGameScreen.spoken(game.label),
          excludeSemantics: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AppDimens.spacing,
            children: [
              SizedBox.square(
                dimension: AppDimens.gamePictogramSize,
                child: GameWidgets.sidePictogram(game, PlayerSide.first),
              ),
              Text(
                game.label,
                style: AppTypography.primary,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
