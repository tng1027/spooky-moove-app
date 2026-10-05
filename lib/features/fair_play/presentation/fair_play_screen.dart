import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_key.dart';
import '../domain/fair_play_notice.dart';

/// Full-screen first-launch fair-play gate (OB-008) with an acknowledge key.
/// The re-view from the new-game screen is `FairPlaySheet`.
class FairPlayScreen extends StatelessWidget {
  const FairPlayScreen({required this.onAcknowledge, super.key});

  static const Key acknowledgeKey = Key('fairPlay.acknowledge');

  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final text = FairPlayNoticeBody.textOf(context);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(child: FairPlayNoticeBody(text)),
              ),
              const SizedBox(height: AppDimens.spacingLarge),
              AppKey(
                key: acknowledgeKey,
                label: text.acknowledgeLabel,
                onTap: onAcknowledge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Title and paragraphs of the fair-play notice, in Vietnamese on a
/// Vietnamese device and English otherwise.
class FairPlayNoticeBody extends StatelessWidget {
  const FairPlayNoticeBody(this.text, {super.key});

  static FairPlayNoticeText textOf(BuildContext context) =>
      FairPlayNoticeText.forLanguage(
        View.of(context).platformDispatcher.locale.languageCode,
      );

  static const TextStyle _bodyStyle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  final FairPlayNoticeText text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppDimens.spacingLarge,
      children: [
        Semantics(
          header: true,
          child: Text(text.title, style: AppTypography.primary),
        ),
        for (final paragraph in text.paragraphs)
          Text(paragraph, style: _bodyStyle),
      ],
    );
  }
}
