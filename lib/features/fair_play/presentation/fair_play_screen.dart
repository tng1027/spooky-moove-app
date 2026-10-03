import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_key.dart';
import '../domain/fair_play_notice.dart';

/// Full-screen fair-play notice (OB-008), in Vietnamese on a Vietnamese
/// device and English otherwise.
///
/// The default constructor is the first-launch gate with an acknowledge key;
/// [FairPlayScreen.readOnly] is the re-view from the new-game screen with a
/// close key instead.
class FairPlayScreen extends StatelessWidget {
  const FairPlayScreen({required VoidCallback this.onAcknowledge, super.key});

  const FairPlayScreen.readOnly({super.key}) : onAcknowledge = null;

  static const Key acknowledgeKey = Key('fairPlay.acknowledge');
  static const Key closeKey = Key('fairPlay.close');

  static const TextStyle _bodyStyle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  final VoidCallback? onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final languageCode = View.of(context)
        .platformDispatcher
        .locale
        .languageCode;
    final text = FairPlayNoticeText.forLanguage(languageCode);
    final acknowledge = onAcknowledge;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
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
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.spacingLarge),
              if (acknowledge != null)
                AppKey(
                  key: acknowledgeKey,
                  label: text.acknowledgeLabel,
                  onTap: acknowledge,
                )
              else
                AppKey(
                  key: closeKey,
                  label: text.closeLabel,
                  onTap: () => Navigator.of(context).pop(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
