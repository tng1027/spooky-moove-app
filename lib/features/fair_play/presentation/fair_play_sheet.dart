import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_key.dart';
import 'fair_play_screen.dart';

/// Read-only re-view of the fair-play notice (OB-008) from the new-game
/// screen, as a modal bottom sheet with a close key.
class FairPlaySheet extends StatelessWidget {
  const FairPlaySheet({super.key});

  static const Key closeKey = Key('fairPlay.close');

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceDark,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusLarge),
        ),
      ),
      builder: (_) => const FairPlaySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = FairPlayNoticeBody.textOf(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.spacingLarge,
          0,
          AppDimens.spacingLarge,
          AppDimens.spacingLarge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(child: FairPlayNoticeBody(text)),
            ),
            const SizedBox(height: AppDimens.spacingLarge),
            AppKey(
              key: closeKey,
              label: text.closeLabel,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
