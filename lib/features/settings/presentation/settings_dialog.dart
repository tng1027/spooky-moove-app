import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_key.dart';

/// Settings dialog opened from Home (OB-051). Shows [entries], or
/// `NO SETTINGS YET` until the PO decides the content (D1).
class SettingsDialog extends StatelessWidget {
  const SettingsDialog({this.entries = const [], super.key});

  static const Key emptyKey = Key('settings.empty');
  static const Key closeKey = Key('settings.close');

  final List<Widget> entries;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AppDialog(
      title: strings.settingsTitle,
      spokenTitle: strings.settingsTitleSpoken,
      children: [
        if (entries.isEmpty)
          Semantics(
            label: strings.settingsEmptySpoken,
            excludeSemantics: true,
            child: Text(
              strings.settingsEmpty,
              key: emptyKey,
              style: AppTypography.secondary,
            ),
          )
        else
          ...entries,
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
