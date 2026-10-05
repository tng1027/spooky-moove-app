import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/l10n/app_strings.dart';
import '../../fair_play/presentation/fair_play_controller.dart';
import '../domain/app_language.dart';

/// The device's first preferred language code, read at launch (OB-053 R1).
/// Overridden in tests.
final deviceLanguageCodeProvider = Provider<String>(
  (ref) => WidgetsBinding.instance.platformDispatcher.locale.languageCode,
);

/// The app language: saved choice, else device language, else English
/// (OB-053 REQ-002/REQ-004).
final appLanguageProvider =
    NotifierProvider<AppLanguageController, AppLanguage>(
      AppLanguageController.new,
    );

/// The catalogue for [appLanguageProvider], for code without a
/// `BuildContext`; widgets use `AppStrings.of(context)`.
final appStringsProvider = Provider<AppStrings>(
  (ref) => AppStrings.forLanguage(ref.watch(appLanguageProvider)),
);

class AppLanguageController extends Notifier<AppLanguage> {
  static const String languageKey = 'settings.app_language';

  static final Logger _log = Logger('AppLanguageController');

  @override
  AppLanguage build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(languageKey);
    return AppLanguage.fromCode(saved) ??
        AppLanguage.fromDeviceCode(ref.watch(deviceLanguageCodeProvider));
  }

  /// Applies [language] at once and saves it; re-picking the current
  /// language is a no-op (OB-053 REQ-003).
  Future<void> select(AppLanguage language) async {
    if (language == state) return;
    state = language;
    try {
      final saved = await ref
          .read(sharedPreferencesProvider)
          .setString(languageKey, language.code);
      if (!saved) _log.warning('App language was not persisted');
    } catch (error, stackTrace) {
      _log.severe('Failed to persist app language', error, stackTrace);
    }
  }
}
