import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/legal/open_source_info.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_key.dart';

/// Settings entry that opens [AboutLicensesDialog].
class AboutLicensesKey extends StatelessWidget {
  const AboutLicensesKey({super.key});

  static const Key openKey = Key('settings.aboutLicenses');

  @override
  Widget build(BuildContext context) {
    return AppKey(
      key: openKey,
      label: 'ABOUT & LICENSES',
      semanticsLabel: 'About and licenses',
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => const AboutLicensesDialog(),
      ),
    );
  }
}

/// About & Licenses, opened from Settings (OB-033). Names the GPLv3 engine,
/// shows the source URL as copyable text (no external link, so no parental
/// gate and it works offline) and opens the offline license list.
class AboutLicensesDialog extends StatefulWidget {
  const AboutLicensesDialog({super.key});

  static const Key licensesKey = Key('about.licenses');
  static const Key copySourceKey = Key('about.copySource');
  static const Key closeKey = Key('about.close');

  @override
  State<AboutLicensesDialog> createState() => _AboutLicensesDialogState();
}

class _AboutLicensesDialogState extends State<AboutLicensesDialog> {
  bool _isSourceCopied = false;

  Future<void> _copySourceUrl() async {
    await Clipboard.setData(
      const ClipboardData(text: OpenSourceInfo.appSourceUrl),
    );
    if (mounted) setState(() => _isSourceCopied = true);
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'ABOUT & LICENSES',
      spokenTitle: 'About and licenses',
      children: [
        const Text(
          '${OpenSourceInfo.appName} is free software under '
          '${OpenSourceInfo.appLicense}.',
          style: AppTypography.secondary,
        ),
        const Text(
          'Chess & Xiangqi engine: ${OpenSourceInfo.engineName} '
          '${OpenSourceInfo.engineTag} (${OpenSourceInfo.engineLicense}), '
          'modified for ${OpenSourceInfo.appName}.',
          style: AppTypography.secondary,
        ),
        const Text('SOURCE CODE', style: AppTypography.primary),
        const SelectableText(
          OpenSourceInfo.appSourceUrl,
          style: AppTypography.secondary,
        ),
        const Text(
          'Each release is tagged v<version>. Engine commit '
          '${OpenSourceInfo.engineCommit}.',
          style: AppTypography.secondary,
        ),
        AppKey(
          key: AboutLicensesDialog.copySourceKey,
          label: _isSourceCopied ? 'COPIED' : 'COPY SOURCE URL',
          semanticsLabel: _isSourceCopied ? 'Copied' : 'Copy source URL',
          onTap: _copySourceUrl,
        ),
        AppKey(
          key: AboutLicensesDialog.licensesKey,
          label: 'VIEW LICENSES',
          semanticsLabel: 'View licenses',
          onTap: () => showLicensePage(
            context: context,
            applicationName: OpenSourceInfo.appName,
            applicationLegalese:
                '${OpenSourceInfo.appLicense}. '
                'Source: ${OpenSourceInfo.appSourceUrl}',
          ),
        ),
        AppKey(
          key: AboutLicensesDialog.closeKey,
          label: 'CLOSE',
          semanticsLabel: 'Close',
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
