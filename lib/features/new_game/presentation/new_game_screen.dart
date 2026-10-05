import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/game/player_side.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_block.dart';
import '../../../core/widgets/app_key.dart';
import '../../../core/widgets/screen_header.dart';
import '../../fair_play/presentation/fair_play_sheet.dart';
import '../../persona/domain/persona_tier.dart';
import '../../persona/presentation/widgets/persona_tier_keys.dart';
import '../domain/game_kind.dart';
import 'game_registry.dart';
import 'widgets/new_game_hero.dart';

/// [tier] is null when the user starts without picking a level.
typedef StartNewGame = void Function(
  GameKind game,
  PlayerSide userSide,
  PersonaTier? tier,
);

/// New-game screen (OB-011, OB-049): for the [game] picked on Home, pick the
/// persona level (Even by default) and the side (first mover by default),
/// then START GAME. Layout per OB-052 DS-8: header BACK / FAIR PLAY, an
/// optional hero, the game title, a panel with level and side, and START
/// GAME pinned at the bottom.
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

  static const String playingLabel = 'PLAYING';
  static const String startLabel = 'START GAME';
  static const String helperLabel = 'LEVEL CAN BE CHANGED DURING THE GAME';

  /// Hero size (OB-052 DS-8); visibility is [NewGameHero.isShown].
  static const double heroHeightFraction = 0.25;
  static const double heroMaxHeight = 200;

  static const double _pictogramSize = 32;

  /// Side card ≥ 60 dp incl. depth: 60 − 4 depth − 2 × 8 padding.
  static const double _sideCardContentMinHeight = 40;

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
        child: LayoutBuilder(
          builder: (context, constraints) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spacing,
              vertical: AppDimens.spacingLarge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppDimens.spacing),
                        if (NewGameHero.isShown(
                          context,
                          constraints.maxHeight,
                        )) ...[
                          NewGameHero(
                            game: widget.game,
                            height: math.min(
                              NewGameScreen.heroHeightFraction *
                                  constraints.maxHeight,
                              NewGameScreen.heroMaxHeight,
                            ),
                          ),
                          const SizedBox(height: AppDimens.spacing),
                        ],
                        _title(),
                        const SizedBox(height: AppDimens.spacingLarge),
                        _panel(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.spacingLarge),
                _startKey(),
                const SizedBox(height: AppDimens.spacingSmall),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    NewGameScreen.helperLabel,
                    style: AppTypography.secondary,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return ScreenHeader(
      leading: HeaderKey(
        key: NewGameScreen.backKey,
        label: '‹ BACK',
        semanticsLabel: 'Back',
        onTap: _goHome,
      ),
      trailing: HeaderKey(
        key: NewGameScreen.fairPlayKey,
        label: 'FAIR PLAY',
        semanticsLabel: 'Fair play',
        onTap: () => FairPlaySheet.show(context),
      ),
    );
  }

  Widget _title() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacing),
      child: Semantics(
        header: true,
        label: 'New game, ${NewGameScreen.spoken(widget.game.label)}',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                NewGameScreen.playingLabel,
                style: AppTypography.secondary.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                widget.game.label.toUpperCase(),
                style: AppTypography.display.copyWith(
                  color: widget.game.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel() {
    return AppBlock(
      face: AppColors.surfaceDark,
      side: AppColors.surfaceSide,
      hasHighlight: true,
      radius: AppDimens.radiusLarge,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(
              number: '01',
              title: _levelHeading,
              spoken: 'Level, ${_selectedTier.label}',
            ),
            const SizedBox(height: AppDimens.spacing),
            SizedBox(
              height: AppDimens.minKeyHeight,
              child: PersonaTierKeys(
                selected: _selectedTier,
                onSelected: _selectTier,
                tierKey: NewGameScreen.tierKey,
                spacing: AppDimens.spacingSmall / 2,
              ),
            ),
            const SizedBox(height: AppDimens.spacingLarge),
            const _SectionHeader(
              number: '02',
              title: 'YOUR SIDE',
              spoken: 'Your side',
            ),
            const SizedBox(height: AppDimens.spacing),
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
    );
  }

  Widget _startKey() {
    return AppKey(
      key: NewGameScreen.startKey,
      accentColor: widget.game.accent,
      accentSideColor: widget.game.accentSide,
      onTap: _start,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppDimens.spacing,
          children: [
            Text(
              NewGameScreen.startLabel,
              style: AppTypography.primary.copyWith(color: AppColors.bgDark),
            ),
            const ExcludeSemantics(child: _ArrowChip()),
          ],
        ),
      ),
    );
  }

  /// The pictogram keys have no visible text, so the heading names the pick.
  String get _levelHeading => 'LEVEL · ${_selectedTier.label.toUpperCase()}';

  Widget _sideKey(PlayerSide side) {
    final label = widget.game.sideLabel(side);
    final subLabel = switch (side) {
      PlayerSide.first => 'FIRST MOVE',
      PlayerSide.second => 'SECOND MOVE',
    };
    final isSelected = side == _selectedSide;
    final color = isSelected ? AppColors.bgDark : AppColors.textPrimary;
    return AppKey(
      key: NewGameScreen.sideKey(side),
      isSelected: isSelected,
      onTap: () => _selectSide(side),
      child: Semantics(
        label:
            '${NewGameScreen.spoken(label)}, '
            '${NewGameScreen.spoken(subLabel).toLowerCase()}',
        excludeSemantics: true,
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: NewGameScreen._sideCardContentMinHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: _RadioDot.size - _RadioDot.inset,
                  ),
                  child: Row(
                    spacing: AppDimens.spacing,
                    children: [
                      SizedBox.square(
                        dimension: NewGameScreen._pictogramSize,
                        child: GameWidgets.sidePictogram(widget.game, side),
                      ),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                label,
                                style: AppTypography.primary.copyWith(
                                  color: color,
                                ),
                              ),
                              Text(
                                subLabel,
                                style: AppTypography.secondary.copyWith(
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: _RadioDot.inset - AppDimens.spacing,
                right: _RadioDot.inset - AppDimens.spacing,
                child: _RadioDot(isSelected: isSelected),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `01  LEVEL · EVEN`: a muted number, then the section title.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.number,
    required this.title,
    required this.spoken,
  });

  final String number;
  final String title;
  final String spoken;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: spoken,
      excludeSemantics: true,
      child: Row(
        spacing: AppDimens.spacing,
        children: [
          Text(number, style: AppTypography.secondary),
          Flexible(child: Text(title, style: AppTypography.primary)),
        ],
      ),
    );
  }
}

/// Second selection cue on a side card, besides the amber fill.
class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.isSelected});

  static const double size = 12;

  /// Distance from the card face's top-right corner.
  static const double inset = 6;
  static const double _ringWidth = 1.5;
  static const double _dotSize = 6;

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.bgDark : AppColors.textSecondary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: _ringWidth),
      ),
      child: isSelected
          ? Container(
              width: _dotSize,
              height: _dotSize,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            )
          : null,
    );
  }
}

/// Dark chip with a chevron, built like I PLAYED IT's check chip.
class _ArrowChip extends StatelessWidget {
  const _ArrowChip();

  static const double _size = 24;
  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.all(Radius.circular(AppDimens.radius)),
      ),
      child: const Icon(
        Icons.chevron_right,
        size: _iconSize,
        color: AppColors.textPrimary,
      ),
    );
  }
}
