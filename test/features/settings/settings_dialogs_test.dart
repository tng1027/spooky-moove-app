import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/theme/app_dimens.dart';
import 'package:spookymoove/core/widgets/app_key.dart';
import 'package:spookymoove/features/settings/domain/app_language.dart';
import 'package:spookymoove/features/settings/presentation/language_dialog.dart';
import 'package:spookymoove/features/settings/presentation/settings_dialog.dart';

void main() {
  /// Opens [dialog] over a page; returns a getter for the popped result.
  Future<Object? Function()> openDialog(
    WidgetTester tester,
    Widget dialog, {
    Size size = const Size(392, 800),
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    Object? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<Object>(
                context: context,
                builder: (_) => dialog,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => result;
  }

  group('SettingsDialog', () {
    testWidgets('empty: header title, NO SETTINGS YET, CLOSE pops', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await openDialog(tester, const SettingsDialog());

      expect(
        tester.getSemantics(find.bySemanticsLabel('Settings')),
        matchesSemantics(label: 'Settings', isHeader: true),
      );
      expect(find.text(SettingsDialog.emptyLabel), findsOneWidget);
      semantics.dispose();

      await tester.tap(find.byKey(SettingsDialog.closeKey));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsDialog), findsNothing);
    });

    testWidgets('with an entry: no empty line', (tester) async {
      await openDialog(
        tester,
        const SettingsDialog(entries: [Text('HAPTICS')]),
      );

      expect(find.text('HAPTICS'), findsOneWidget);
      expect(find.byKey(SettingsDialog.emptyKey), findsNothing);
    });
  });

  group('LanguageDialog', () {
    Finder english() =>
        find.byKey(LanguageDialog.languageKey(AppLanguage.english));

    testWidgets('lists exactly ENGLISH, selected, announced "English"', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await openDialog(
        tester,
        const LanguageDialog(selected: AppLanguage.current),
      );

      expect(AppLanguage.values, [AppLanguage.english]);
      expect(find.text('ENGLISH'), findsOneWidget);
      expect(tester.widget<AppKey>(english()).isSelected, isTrue);
      expect(
        tester.getSemantics(english()),
        matchesSemantics(
          label: 'English',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Language')),
        matchesSemantics(label: 'Language', isHeader: true),
      );
      semantics.dispose();
    });

    testWidgets('tapping ENGLISH pops it', (tester) async {
      final result = await openDialog(
        tester,
        const LanguageDialog(selected: AppLanguage.current),
      );

      await tester.tap(english());
      await tester.pumpAndSettle();

      expect(find.byType(LanguageDialog), findsNothing);
      expect(result(), AppLanguage.english);
    });

    testWidgets('CLOSE pops without a language', (tester) async {
      final result = await openDialog(
        tester,
        const LanguageDialog(selected: AppLanguage.current),
      );

      await tester.tap(find.byKey(LanguageDialog.closeKey));
      await tester.pumpAndSettle();

      expect(find.byType(LanguageDialog), findsNothing);
      expect(result(), isNull);
    });
  });

  for (final dialog in const <Widget>[
    SettingsDialog(),
    LanguageDialog(selected: AppLanguage.current),
  ]) {
    testWidgets('${dialog.runtimeType}: no overflow at 360x640, scale 2.0', (
      tester,
    ) async {
      await openDialog(
        tester,
        dialog,
        size: const Size(360, 640),
        textScale: 2.0,
      );

      expect(tester.takeException(), isNull);
      for (final key in tester.widgetList<AppKey>(find.byType(AppKey))) {
        expect(
          tester.getSize(find.byWidget(key)).height,
          greaterThanOrEqualTo(AppDimens.minKeyHeight),
        );
      }
    });
  }
}
