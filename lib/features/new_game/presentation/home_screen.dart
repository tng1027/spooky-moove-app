import 'package:flutter/material.dart';

import '../../../core/game/player_side.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_block.dart';
import '../../../core/widgets/screen_header.dart';
import '../../settings/domain/app_language.dart';
import '../../settings/presentation/about_licenses_dialog.dart';
import '../../settings/presentation/language_dialog.dart';
import '../../settings/presentation/settings_dialog.dart';
import '../domain/game_kind.dart';
import 'game_registry.dart';
import 'new_game_screen.dart';

/// Home screen (OB-049): one row per [GameKind]; tapping one opens the
/// new-game screen for that game. Header (OB-051): SETTINGS, the title,
/// LANGUAGE. Layout per OB-052 DS-9: the rows, top-aligned and scrolling. Always the root: no game is ever beneath it
/// (OB-050 D1).
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.onStart,
    required this.onLanguageSelected,
    super.key,
  });

  static const Key settingsKey = Key('home.settings');
  static const Key languageKey = Key('home.language');

  static Key gameKey(GameKind game) => Key('home.game.${game.name}');

  final StartNewGame onStart;

  /// Called with the language picked in the Language dialog (OB-053).
  final ValueChanged<AppLanguage> onLanguageSelected;

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
  /// Game row face padding and gaps (DS-9).
  static const double _rowPaddingH = 12;
  static const double _rowPaddingV = 10;
  static const double _nameTaglineGap = 2;
  static const double _chevronSize = 24;

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
              const SizedBox(height: AppDimens.spacingLarge),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (index, game) in GameKind.values.indexed) ...[
                        if (index > 0)
                          const SizedBox(height: AppDimens.spacing),
                        _gameRow(game),
                      ],
                    ],
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
    final strings = AppStrings.of(context);
    return ScreenHeader(
      leading: HeaderKey(
        key: HomeScreen.settingsKey,
        label: strings.settingsTitle,
        semanticsLabel: strings.settingsTitleSpoken,
        onTap: () => _guarded(
          () => showDialog<void>(
            context: context,
            builder: (_) => const SettingsDialog(entries: [AboutLicensesKey()]),
          ),
        ),
      ),
      middle: Semantics(
        header: true,
        label: strings.homeTitleSpoken,
        excludeSemantics: true,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(strings.homeTitle, style: AppTypography.primary),
        ),
      ),
      trailing: HeaderKey(
        key: HomeScreen.languageKey,
        label: strings.languageTitle,
        semanticsLabel: strings.languageTitleSpoken,
        onTap: () => _guarded(() => _pickLanguage(strings.language)),
      ),
    );
  }

  Future<void> _pickLanguage(AppLanguage current) async {
    final picked = await showDialog<AppLanguage>(
      context: context,
      builder: (_) => LanguageDialog(selected: current),
    );
    if (picked != null && picked != current) widget.onLanguageSelected(picked);
  }

  /// A neutral row (OB-052 DS-9): `surfaceDark` keeps the tagline legible;
  /// only the icon block carries the game accent.
  Widget _gameRow(GameKind game) {
    final strings = AppStrings.of(context);
    return Semantics(
      key: HomeScreen.gameKey(game),
      button: true,
      enabled: true,
      label:
          '${strings.gameNameSpoken(game)}, ${strings.gameTaglineSpoken(game)}',
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppDimens.gameRowMinHeight,
        ),
        child: AppBlock(
          face: AppColors.surfaceDark,
          side: AppColors.surfaceSide,
          hasHighlight: true,
          onTap: () => _open(game),
          child: ExcludeSemantics(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AppDimens.gameRowMinHeight - AppDimens.blockDepth,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: _rowPaddingH,
                vertical: _rowPaddingV,
              ),
              child: Row(
                children: [
                  _GameIconBlock(game: game),
                  const SizedBox(width: _rowPaddingH),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      spacing: _nameTaglineGap,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            strings.gameName(game),
                            style: AppTypography.primary,
                          ),
                        ),
                        Text(
                          strings.gameTagline(game),
                          style: AppTypography.secondary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimens.spacing),
                  const Icon(
                    Icons.chevron_right,
                    size: _chevronSize,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The row's fixed-size accent block holding the game's first-side piece.
class _GameIconBlock extends StatelessWidget {
  const _GameIconBlock({required this.game});

  final GameKind game;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AppDimens.gameIconBlockSize,
      child: AppBlock(
        face: game.accent,
        side: game.accentSide,
        child: Center(
          child: SizedBox.square(
            dimension: AppDimens.gameIconPictogramSize,
            child: GameWidgets.sidePictogram(game, PlayerSide.first),
          ),
        ),
      ),
    );
  }
}
