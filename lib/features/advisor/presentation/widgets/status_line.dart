import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_key.dart';
import '../../../new_game/presentation/widgets/new_game_key.dart';
import '../status_line_content.dart';
import 'confirm_played_key.dart';

/// Status line at the bottom, within thumb reach: one full-width button that
/// is always there (OB-041, revised 2026-10-03). It guides the user while
/// they can't confirm, confirms the played suggestion on their turn, and
/// opens the new-game screen once the game is over.
class StatusLine extends ConsumerStatefulWidget {
  const StatusLine({super.key = regionKey});

  static const Key regionKey = Key('advisor.statusLine');
  static const Key newGameKey = Key('advisor.statusLine.newGame');

  /// Taps on NEW GAME are ignored this long after it appears, so a double
  /// tap on a mating "I PLAYED IT" can't also leave the game.
  static const Duration newGameTapGuard = Duration(milliseconds: 500);

  @override
  ConsumerState<StatusLine> createState() => _StatusLineState();
}

class _StatusLineState extends ConsumerState<StatusLine> {
  Timer? _tapGuard;

  @override
  void dispose() {
    _tapGuard?.cancel();
    super.dispose();
  }

  void _guardTaps() {
    _tapGuard?.cancel();
    setState(() {
      _tapGuard = Timer(StatusLine.newGameTapGuard, () {
        if (mounted) setState(() => _tapGuard = null);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(statusLineContentProvider, (_, next) {
      if (next == StatusLineContent.newGame) _guardTaps();
    });
    final content = ref.watch(statusLineContentProvider);
    return SizedBox(
      height: AppDimens.statusLineHeight,
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppDimens.spacingSmall,
          left: AppDimens.spacingSmall,
          right: AppDimens.spacingSmall,
        ),
        child: SizedBox.expand(
          child: AbsorbPointer(
            absorbing: _tapGuard != null,
            child: _buildButton(content),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(StatusLineContent content) => switch (content) {
    StatusLineContent.none => const SizedBox.shrink(),
    StatusLineContent.waitingForOpponent => _ActionKey(
      label: AppStrings.of(context).waitingForOpponent,
      spoken: AppStrings.of(context).waitingForOpponentSpoken,
    ),
    StatusLineContent.pickLevel => _ActionKey(
      label: AppStrings.of(context).pickLevelAbove,
      spoken: AppStrings.of(context).pickLevelAboveSpoken,
    ),
    StatusLineContent.confirmDisabled => const ConfirmPlayedKey(
      isEnabled: false,
    ),
    StatusLineContent.confirmEnabled => const ConfirmPlayedKey(isEnabled: true),
    StatusLineContent.newGame => _ActionKey(
      key: StatusLine.newGameKey,
      label: AppStrings.of(context).newGame,
      spoken: AppStrings.of(context).newGameSpoken,
      onTap: () => NewGameKey.openNewGameScreen(context, ref),
    ),
  };
}

/// A full-width key with a single label; disabled when [onTap] is null.
class _ActionKey extends StatelessWidget {
  const _ActionKey({
    required this.label,
    required this.spoken,
    this.onTap,
    super.key,
  });

  final String label;
  final String spoken;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = onTap == null
        ? AppColors.textSecondary
        : AppColors.textPrimary;
    return AppKey(
      onTap: onTap,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          semanticsLabel: spoken,
          style: AppTypography.primary.copyWith(color: color),
        ),
      ),
    );
  }
}
