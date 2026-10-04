import 'package:integration_test/integration_test_driver.dart';

/// Driver for `flutter drive --profile` performance runs (OB-010). Writes
/// each report key (e.g. the `watchPerformance` frame summary) to
/// `build/<reportKey>.json`.
Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    for (final entry in data.entries) {
      await writeResponseData(
        {entry.key: entry.value},
        testOutputFilename: entry.key,
      );
    }
  },
);
