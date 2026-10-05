import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spookymoove/core/l10n/app_strings.dart';
import 'package:spookymoove/features/fair_play/presentation/fair_play_controller.dart';
import 'package:spookymoove/features/settings/application/app_language_controller.dart';
import 'package:spookymoove/features/settings/domain/app_language.dart';

const _key = AppLanguageController.languageKey;

Future<(ProviderContainer, SharedPreferences)> _container({
  String? saved,
  String device = 'en',
}) async {
  SharedPreferences.setMockInitialValues({_key: ?saved});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      deviceLanguageCodeProvider.overrideWithValue(device),
    ],
  );
  addTearDown(container.dispose);
  return (container, preferences);
}

void main() {
  group('default language', () {
    for (final (device, expected) in const [
      ('vi', AppLanguage.vietnamese),
      ('en', AppLanguage.english),
      ('fr', AppLanguage.english),
    ]) {
      test('no saved choice, device "$device": ${expected.name}', () async {
        final (container, _) = await _container(device: device);
        expect(container.read(appLanguageProvider), expected);
      });
    }

    test('a saved choice wins over the device language', () async {
      final (english, _) = await _container(saved: 'en', device: 'vi');
      expect(english.read(appLanguageProvider), AppLanguage.english);

      final (vietnamese, _) = await _container(saved: 'vi', device: 'en');
      expect(vietnamese.read(appLanguageProvider), AppLanguage.vietnamese);
    });

    test('an unknown saved value falls back to the device language', () async {
      final (container, _) = await _container(saved: 'de', device: 'vi');
      expect(container.read(appLanguageProvider), AppLanguage.vietnamese);
    });
  });

  test('select applies at once and saves the language code', () async {
    final (container, preferences) = await _container();

    await container
        .read(appLanguageProvider.notifier)
        .select(AppLanguage.vietnamese);

    expect(container.read(appLanguageProvider), AppLanguage.vietnamese);
    expect(container.read(appStringsProvider), AppStrings.vietnamese);
    expect(preferences.getString(_key), 'vi');
  });

  test('selecting the current language saves nothing', () async {
    final (container, preferences) = await _container();

    await container
        .read(appLanguageProvider.notifier)
        .select(AppLanguage.english);

    expect(preferences.getString(_key), isNull);
  });

  test('device code mapping accepts any Vietnamese region only', () {
    expect(AppLanguage.fromDeviceCode('vi'), AppLanguage.vietnamese);
    expect(AppLanguage.fromDeviceCode('en'), AppLanguage.english);
    expect(AppLanguage.fromCode('vi'), AppLanguage.vietnamese);
    expect(AppLanguage.fromCode(null), isNull);
  });
}
