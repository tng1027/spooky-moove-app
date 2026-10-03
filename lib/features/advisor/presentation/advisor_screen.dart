import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_dimens.dart';
import '../../new_game/presentation/game_registry.dart';
import '../../persona/presentation/widgets/persona_row.dart';
import 'widgets/status_line.dart';
import 'widgets/suggestion_card.dart';
import 'widgets/top_bar.dart';

/// Portrait advisor layout (designSystem.md, revised 2026-10-03):
/// top bar / persona row / suggestion card / board / status line.
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
                Center(child: GameWidgets.board(game, boardSize)),
                const StatusLine(),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The board takes the full width unless that would squeeze the
  /// suggestion card below its minimum height on short screens
  /// (OB-042 REQ-006).
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
        AppDimens.minSuggestionCardHeight;
    final cell = math.max(
      0.0,
      math.min(available.width / files, maxBoardHeight / ranks),
    );
    return Size(cell * files, cell * ranks);
  }
}
