import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/legal/engine_license.dart';
import 'features/fair_play/presentation/fair_play_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicense();
  _registerPieceLicense();
  registerEngineLicense();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const SpookyMooveApp(),
    ),
  );
}

void _registerFontLicense() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['JetBrains Mono'], license);
  });
}

void _registerPieceLicense() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(
      'assets/pieces/cburnett/LICENSE',
    );
    yield LicenseEntryWithLineBreaks(const ['Cburnett chess pieces'], license);
  });
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(
      'assets/pieces/xiangqi/OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(const [
      'Noto Serif TC (Xiangqi glyphs)',
    ], license);
  });
}
