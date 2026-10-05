import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'open_source_info.dart';

/// Registers the bundled engine's GPLv3 text and copyright holders so they
/// appear in [showLicensePage], offline.
void registerEngineLicense() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(
      OpenSourceInfo.engineLicenseAsset,
    );
    final authors = await rootBundle.loadString(
      OpenSourceInfo.engineAuthorsAsset,
    );
    yield LicenseEntryWithLineBreaks(const [
      OpenSourceInfo.engineName,
    ], '${OpenSourceInfo.engineName} ${OpenSourceInfo.engineTag} '
        '(commit ${OpenSourceInfo.engineCommit}), modified for '
        '${OpenSourceInfo.appName}.\n'
        'Source: ${OpenSourceInfo.engineSourceUrl}\n\n'
        '$authors\n\n$license');
  });
}
