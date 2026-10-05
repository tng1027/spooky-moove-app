import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_key.dart';
import '../domain/app_language.dart';

/// Language dialog opened from Home (OB-051): one key per [AppLanguage],
/// [selected] highlighted. Picking a language pops it as the result.
class LanguageDialog extends StatelessWidget {
  const LanguageDialog({required this.selected, super.key});

  static const Key closeKey = Key('language.close');

  static Key languageKey(AppLanguage language) =>
      Key('language.${language.name}');

  final AppLanguage selected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AppDialog(
      title: strings.languageTitle,
      spokenTitle: strings.languageTitleSpoken,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppDimens.spacing,
          children: [
            for (final language in AppLanguage.values)
              AppKey(
                key: languageKey(language),
                label: language.label,
                semanticsLabel: language.spoken,
                isSelected: language == selected,
                onTap: () => Navigator.of(context).maybePop(language),
              ),
          ],
        ),
        AppKey(
          key: closeKey,
          label: strings.close,
          semanticsLabel: strings.closeSpoken,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
