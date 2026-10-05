import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_block.dart';
import '../../new_game/presentation/game_registry.dart';
import '../../persona/presentation/widgets/persona_row.dart';
import 'widgets/status_line.dart';
import 'widgets/suggestion_card.dart';
import 'widgets/top_bar.dart';

/// Portrait advisor layout (designSystem.md, revised by OB-052 DS-7):
/// top bar / persona row / suggestion card / board tray / status line.
class AdvisorScreen extends ConsumerWidget {
  const AdvisorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(activeGameKindProvider);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardSize = boardSizeFor(
              constraints.biggest,
              files: game.files,
              ranks: game.ranks,
            );
            return Column(
              children: [
                const TopBar(),
                const PersonaRow(),
                const Expanded(child: SuggestionCard()),
                Center(
                  child: _BoardTray(child: GameWidgets.board(game, boardSize)),
                ),
                const StatusLine(),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Width and height the board tray adds around the board.
  static const double trayWidthOverhead = 2 * AppDimens.boardTrayPadding;
  static const double trayHeightOverhead =
      2 * AppDimens.boardTrayPadding + AppDimens.blockDepth;

  /// The board takes the full width inside its tray unless that would
  /// squeeze the suggestion card below its minimum height on short screens
  /// (OB-042 REQ-006, OB-052 DS-7).
  static Size boardSizeFor(
    Size available, {
    required int files,
    required int ranks,
  }) {
    final maxBoardHeight =
        available.height -
        AppDimens.topBarHeight -
        AppDimens.personaRowHeight -
        AppDimens.statusLineHeight -
        AppDimens.minSuggestionCardHeight -
        trayHeightOverhead;
    final maxBoardWidth = available.width - trayWidthOverhead;
    final cell = math.max(
      0.0,
      math.min(maxBoardWidth / files, maxBoardHeight / ranks),
    );
    return Size(cell * files, cell * ranks);
  }
}

/// Raised, non-pressable surface block around the board (OB-052 DS-7).
/// Takes no taps and has no semantics.
class _BoardTray extends StatelessWidget {
  const _BoardTray({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppBlock(
      face: AppColors.surfaceDark,
      side: AppColors.surfaceSide,
      hasHighlight: true,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.boardTrayPadding),
        child: child,
      ),
    );
  }
}
