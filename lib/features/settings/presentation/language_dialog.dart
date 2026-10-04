import 'package:flutter/material.dart';

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
    return AppDialog(
      title: 'LANGUAGE',
      spokenTitle: 'Language',
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
          label: 'CLOSE',
          semanticsLabel: 'Close',
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
