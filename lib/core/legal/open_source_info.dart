/// Licensing facts shown in About & Licenses and registered with
/// [LicenseRegistry]. Must match `NOTICE.md` and the
/// `third_party/fairy-stockfish` submodule commit.
abstract final class OpenSourceInfo {
  static const String appName = 'SpookyMoove';
  static const String appLicense = 'GPL-3.0-or-later';

  /// Every release is tagged `v<version>` in this repository.
  static const String appSourceUrl =
      'https://github.com/tng1027/spooky-moove-app';

  static const String engineName = 'Fairy-Stockfish';
  static const String engineLicense = 'GPLv3';
  static const String engineTag = 'fairy_sf_14_0_1_xq';
  static const String engineCommit = '433d4115a31ebcf0d9c0e4238b12915b70a0b7c1';
  static const String engineSourceUrl =
      'https://github.com/tng1027/Fairy-Stockfish/tree/$engineCommit';

  static const String engineLicenseAsset =
      'assets/licenses/fairy_stockfish_copying.txt';
  static const String engineAuthorsAsset =
      'assets/licenses/fairy_stockfish_authors.txt';
}
