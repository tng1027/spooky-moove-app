import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/game/player_side.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_key.dart';
import '../../../core/widgets/screen_header.dart';
import '../../fair_play/presentation/fair_play_screen.dart';
import '../../persona/domain/persona_tier.dart';
import '../../persona/presentation/widgets/persona_tier_keys.dart';
import '../domain/game_kind.dart';
import 'game_registry.dart';

/// [tier] is null when the user starts without picking a level.
typedef StartNewGame = void Function(
  GameKind game,
  PlayerSide userSide,
  PersonaTier? tier,
);

/// New-game screen (OB-011, OB-049): for the [game] picked on Home, pick the
/// persona level (Even by default) and the side (first mover by default),
/// then START GAME. Header (OB-050): BACK to Home, the game name, FAIR PLAY.
class NewGameScreen extends StatefulWidget {
  const NewGameScreen({required this.game, required this.onStart, super.key});

  static const Key backKey = Key('newGame.back');
  static const Key fairPlayKey = Key('newGame.fairPlay');
  static const Key startKey = Key('newGame.start');

  /// The middle of the seven levels (PO 2026-10-03).
  static const PersonaTier defaultTier = PersonaTier.even;
  static const PlayerSide defaultSide = PlayerSide.first;

  static Key tierKey(PersonaTier tier) => Key('newGame.tier.${tier.name}');

  static Key sideKey(PlayerSide side) => Key('newGame.side.${side.name}');

  /// Upper-case key labels would be spelled out by screen readers.
  static String spoken(String label) =>
      label.isEmpty ? label : label[0] + label.substring(1).toLowerCase();

  static const double _pictogramSize = 40;

  final GameKind game;
  final StartNewGame onStart;

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  PersonaTier _selectedTier = NewGameScreen.defaultTier;
  PlayerSide _selectedSide = NewGameScreen.defaultSide;

  /// BACK and START GAME share this guard: the first tap wins, so a rapid
  /// double tap starts only one game or navigates only once.
  bool _isLeaving = false;

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
    if (_isLeaving) return;
    _isLeaving = true;
    widget.onStart(widget.game, _selectedSide, _selectedTier);
  }

  Future<void> _goHome() async {
    if (_isLeaving) return;
    _isLeaving = true;
    final didPop = await Navigator.of(context).maybePop();
    if (!didPop) _isLeaving = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(
                leading: HeaderKey(
                  key: NewGameScreen.backKey,
                  label: 'BACK',
                  semanticsLabel: 'Back',
                  onTap: _goHome,
                ),
                middle: Semantics(
                  header: true,
                  label: 'New game, ${NewGameScreen.spoken(widget.game.label)}',
                  excludeSemantics: true,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.game.label,
                      style: AppTypography.primary,
                    ),
                  ),
                ),
                trailing: HeaderKey(
                  key: NewGameScreen.fairPlayKey,
                  label: 'FAIR PLAY',
                  semanticsLabel: 'Fair play',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const FairPlayScreen.readOnly(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.spacingLarge),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppDimens.spacing,
                    children: [
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

  Widget _sideKey(PlayerSide side) {
    final label = widget.game.sideLabel(side);
    final isSelected = side == _selectedSide;
    return AppKey(
      key: NewGameScreen.sideKey(side),
      isSelected: isSelected,
      onTap: () => _selectSide(side),
      child: Semantics(
        label: NewGameScreen.spoken(label),
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppDimens.spacingSmall,
          children: [
            SizedBox.square(
              dimension: NewGameScreen._pictogramSize,
              child: GameWidgets.sidePictogram(widget.game, side),
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
