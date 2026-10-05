import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/legal/open_source_info.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_key.dart';

/// Settings entry that opens [AboutLicensesDialog].
class AboutLicensesKey extends StatelessWidget {
  const AboutLicensesKey({super.key});

  static const Key openKey = Key('settings.aboutLicenses');

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AppKey(
      key: openKey,
      label: strings.aboutTitle,
      semanticsLabel: strings.aboutTitleSpoken,
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
    final strings = AppStrings.of(context);
    return AppDialog(
      title: strings.aboutTitle,
      spokenTitle: strings.aboutTitleSpoken,
      children: [
        Text(strings.aboutFreeSoftware, style: AppTypography.secondary),
        Text(strings.aboutEngine, style: AppTypography.secondary),
        Text(strings.aboutSourceHeading, style: AppTypography.primary),
        const SelectableText(
          OpenSourceInfo.appSourceUrl,
          style: AppTypography.secondary,
        ),
        Text(strings.aboutReleaseTags, style: AppTypography.secondary),
        AppKey(
          key: AboutLicensesDialog.copySourceKey,
          label: _isSourceCopied
              ? strings.aboutCopied
              : strings.aboutCopySource,
          semanticsLabel: _isSourceCopied
              ? strings.aboutCopiedSpoken
              : strings.aboutCopySourceSpoken,
          onTap: _copySourceUrl,
        ),
        AppKey(
          key: AboutLicensesDialog.licensesKey,
          label: strings.aboutViewLicenses,
          semanticsLabel: strings.aboutViewLicensesSpoken,
          onTap: () => showLicensePage(
            context: context,
            applicationName: OpenSourceInfo.appName,
            applicationLegalese: strings.aboutLegalese,
          ),
        ),
        AppKey(
          key: AboutLicensesDialog.closeKey,
          label: strings.close,
          semanticsLabel: strings.closeSpoken,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
