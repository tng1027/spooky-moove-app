import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/legal/engine_license.dart';
import 'package:spookymoove/core/legal/open_source_info.dart';
import 'package:spookymoove/core/theme/app_dimens.dart';
import 'package:spookymoove/core/widgets/app_key.dart';
import 'package:spookymoove/features/settings/presentation/about_licenses_dialog.dart';
import 'package:spookymoove/features/settings/presentation/settings_dialog.dart';

void main() {
  Future<void> openSettings(
    WidgetTester tester, {
    Size size = const Size(392, 800),
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) =>
                  const SettingsDialog(entries: [AboutLicensesKey()]),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> openAbout(WidgetTester tester, {double textScale = 1.0}) async {
    await openSettings(
      tester,
      size: textScale > 1 ? const Size(360, 640) : const Size(392, 800),
      textScale: textScale,
    );
    await tester.tap(find.byKey(AboutLicensesKey.openKey));
    await tester.pumpAndSettle();
  }

  testWidgets('Settings lists ABOUT & LICENSES instead of the empty line', (
    tester,
  ) async {
    await openSettings(tester);

    expect(find.byKey(AboutLicensesKey.openKey), findsOneWidget);
    expect(find.byKey(SettingsDialog.emptyKey), findsNothing);
  });

  testWidgets('shows the GPLv3 engine, its tag and the source URL', (
    tester,
  ) async {
    await openAbout(tester);

    expect(find.byType(AboutLicensesDialog), findsOneWidget);
    expect(find.textContaining(OpenSourceInfo.engineName), findsWidgets);
    expect(find.textContaining(OpenSourceInfo.engineTag), findsOneWidget);
    expect(find.textContaining('GPLv3'), findsOneWidget);
    expect(find.text(OpenSourceInfo.appSourceUrl), findsOneWidget);
  });

  testWidgets('COPY SOURCE URL puts the URL on the clipboard', (tester) async {
    final copied = <String?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String?);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await openAbout(tester);

    await tester.tap(find.byKey(AboutLicensesDialog.copySourceKey));
    await tester.pumpAndSettle();

    expect(copied, [OpenSourceInfo.appSourceUrl]);
    expect(find.text('COPIED'), findsOneWidget);
  });

  testWidgets('VIEW LICENSES opens the license page', (tester) async {
    await openAbout(tester);

    await tester.tap(find.byKey(AboutLicensesDialog.licensesKey));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('CLOSE pops the dialog', (tester) async {
    await openAbout(tester);

    await tester.tap(find.byKey(AboutLicensesDialog.closeKey));
    await tester.pumpAndSettle();

    expect(find.byType(AboutLicensesDialog), findsNothing);
  });

  testWidgets('no overflow at 360x640, scale 2.0', (tester) async {
    await openAbout(tester, textScale: 2.0);

    expect(tester.takeException(), isNull);
    final dialog = find.byType(AboutLicensesDialog);
    for (final key in tester.widgetList<AppKey>(
      find.descendant(of: dialog, matching: find.byType(AppKey)),
    )) {
      expect(
        tester.getSize(find.byWidget(key)).height,
        greaterThanOrEqualTo(AppDimens.minKeyHeight),
      );
    }
  });

  test('registers the Fairy-Stockfish GPLv3 text and authors', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerEngineLicense();

    final entries = await LicenseRegistry.licenses
        .where((e) => e.packages.contains(OpenSourceInfo.engineName))
        .toList();

    expect(entries, hasLength(1));
    final text = entries.single.paragraphs.map((p) => p.text).join('\n');
    expect(text, contains('GNU GENERAL PUBLIC LICENSE'));
    expect(text, contains('Fabian Fichter'));
    expect(text, contains(OpenSourceInfo.engineCommit));
  });
}
