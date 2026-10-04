import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_key.dart';

/// Settings dialog opened from Home (OB-051). Shows [entries], or
/// `NO SETTINGS YET` until the PO decides the content (D1).
class SettingsDialog extends StatelessWidget {
  const SettingsDialog({this.entries = const [], super.key});

  static const Key emptyKey = Key('settings.empty');
  static const Key closeKey = Key('settings.close');
  static const String emptyLabel = 'NO SETTINGS YET';

  final List<Widget> entries;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'SETTINGS',
      spokenTitle: 'Settings',
      children: [
        if (entries.isEmpty)
          Semantics(
            label: 'No settings yet',
            excludeSemantics: true,
            child: const Text(
              emptyLabel,
              key: emptyKey,
              style: AppTypography.secondary,
            ),
          )
        else
          ...entries,
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
