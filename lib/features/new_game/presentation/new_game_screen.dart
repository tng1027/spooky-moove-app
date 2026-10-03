import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/game/player_side.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_key.dart';
import '../../fair_play/presentation/fair_play_screen.dart';
import '../../persona/domain/persona_tier.dart';
import '../../persona/presentation/widgets/persona_tier_keys.dart';
import '../domain/game_kind.dart';
import 'game_registry.dart';

/// New-game screen (OB-011): pick the game, the persona level (Even by
/// default) and the side (first mover by default), then START GAME. Shows a
/// BACK key only when there is a game to return to.
class NewGameScreen extends StatefulWidget {
  const NewGameScreen({required this.onStart, this.initialGame, super.key});

  static const Key backKey = Key('newGame.back');
  static const Key fairPlayKey = Key('newGame.fairPlay');
  static const Key startKey = Key('newGame.start');

  /// The middle of the seven levels (PO 2026-10-03).
  static const PersonaTier defaultTier = PersonaTier.even;
  static const PlayerSide defaultSide = PlayerSide.first;

  static Key gameKey(GameKind game) => Key('newGame.game.${game.name}');

  static Key tierKey(PersonaTier tier) => Key('newGame.tier.${tier.name}');

  static Key sideKey(PlayerSide side) => Key('newGame.side.${side.name}');

  static const double _pictogramSize = 40;

  /// [tier] is null when the user starts without picking a level.
  final void Function(GameKind game, PlayerSide userSide, PersonaTier? tier)
  onStart;

  /// Preselected game: the current session's game, else the first (XQ8).
  final GameKind? initialGame;

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  late GameKind _selectedGame = widget.initialGame ?? GameKind.values.first;
  PersonaTier _selectedTier = NewGameScreen.defaultTier;
  PlayerSide _selectedSide = NewGameScreen.defaultSide;

  /// A rapid double tap on START GAME must start only one game.
  bool _hasStarted = false;

  /// Switching games keeps the side position and the level.
  void _selectGame(GameKind game) {
    if (game == _selectedGame) return;
    setState(() => _selectedGame = game);
    HapticFeedback.selectionClick();
  }

  void _selectTier(PersonaTier tier) {
    if (tier == _selectedTier) return;
    setState(() => _selectedTier = tier);
    HapticFeedback.selectionClick();
  }

  void _selectSide(PlayerSide side) {
    if (side == _selectedSide) return;
    setState(() => _selectedSide = side);
    HapticFeedback.selectionClick();
  }

  void _start() {
    if (_hasStarted) return;
    _hasStarted = true;
    widget.onStart(_selectedGame, _selectedSide, _selectedTier);
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppDimens.spacing,
                    children: [
                      Semantics(
                        header: true,
                        child: const Text(
                          'NEW GAME',
                          style: AppTypography.primary,
                        ),
                      ),
                      const SizedBox(height: AppDimens.spacing),
                      const Text('GAME', style: AppTypography.secondary),
                      for (final game in GameKind.values)
                        AppKey(
                          key: NewGameScreen.gameKey(game),
                          label: game.label,
                          semanticsLabel: _spoken(game.label),
                          isSelected: game == _selectedGame,
                          onTap: () => _selectGame(game),
                        ),
                      const SizedBox(height: AppDimens.spacing),
                      Text(_levelHeading, style: AppTypography.secondary),
                      SizedBox(
                        height: AppDimens.minKeyHeight,
                        child: PersonaTierKeys(
                          selected: _selectedTier,
                          onSelected: _selectTier,
                          tierKey: NewGameScreen.tierKey,
                          spacing: AppDimens.spacingSmall / 2,
                        ),
                      ),
                      const SizedBox(height: AppDimens.spacing),
                      const Text('YOUR SIDE', style: AppTypography.secondary),
                      Row(
                        spacing: AppDimens.spacing,
                        children: [
                          for (final side in PlayerSide.values)
                            Expanded(child: _sideKey(side)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.spacingLarge),
              Row(
                spacing: AppDimens.spacing,
                children: [
                  if (canGoBack)
                    Expanded(
                      child: AppKey(
                        key: NewGameScreen.backKey,
                        label: 'BACK',
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  Expanded(
                    child: AppKey(
                      key: NewGameScreen.fairPlayKey,
                      label: 'FAIR PLAY',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const FairPlayScreen.readOnly(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.spacing),
              AppKey(
                key: NewGameScreen.startKey,
                isPrimary: true,
                onTap: _start,
                label: 'START GAME',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The emoji keys have no visible text, so the heading names the pick.
  String get _levelHeading => 'LEVEL · ${_selectedTier.label.toUpperCase()}';

  /// Upper-case key labels would be spelled out by screen readers.
  static String _spoken(String label) =>
      label.isEmpty ? label : label[0] + label.substring(1).toLowerCase();

  Widget _sideKey(PlayerSide side) {
    final label = _selectedGame.sideLabel(side);
    final isSelected = side == _selectedSide;
    return AppKey(
      key: NewGameScreen.sideKey(side),
      isSelected: isSelected,
      onTap: () => _selectSide(side),
      child: Semantics(
        label: _spoken(label),
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppDimens.spacingSmall,
          children: [
            SizedBox.square(
              dimension: NewGameScreen._pictogramSize,
              child: GameWidgets.sidePictogram(_selectedGame, side),
            ),
            Text(
              label,
              style: AppTypography.primary.copyWith(
                color: isSelected ? AppColors.bgDark : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
