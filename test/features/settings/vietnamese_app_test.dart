import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spookymoove/app.dart';
import 'package:spookymoove/core/engine/engine_models.dart';
import 'package:spookymoove/core/l10n/app_strings.dart';
import 'package:spookymoove/core/theme/app_dimens.dart';
import 'package:spookymoove/core/widgets/app_key.dart';
import 'package:spookymoove/features/advisor/presentation/advisor_screen.dart';
import 'package:spookymoove/features/advisor/presentation/suggestion_providers.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/top_bar.dart';
import 'package:spookymoove/features/chess/domain/chess_models.dart';
import 'package:spookymoove/features/chess/presentation/widgets/promotion_chooser.dart';
import 'package:spookymoove/features/fair_play/domain/fair_play_notice.dart';
import 'package:spookymoove/features/fair_play/presentation/fair_play_controller.dart';
import 'package:spookymoove/features/fair_play/presentation/fair_play_screen.dart';
import 'package:spookymoove/features/fair_play/presentation/fair_play_sheet.dart';
import 'package:spookymoove/features/new_game/domain/game_kind.dart';
import 'package:spookymoove/features/new_game/presentation/home_screen.dart';
import 'package:spookymoove/features/new_game/presentation/new_game_screen.dart';
import 'package:spookymoove/features/new_game/presentation/widgets/new_game_key.dart';
import 'package:spookymoove/features/persona/domain/persona_tier_copy.dart';
import 'package:spookymoove/features/settings/application/app_language_controller.dart';
import 'package:spookymoove/features/settings/domain/app_language.dart';
import 'package:spookymoove/features/settings/presentation/about_licenses_dialog.dart';
import 'package:spookymoove/features/settings/presentation/language_dialog.dart';
import 'package:spookymoove/features/settings/presentation/settings_dialog.dart';

import '../persona/fake_game_engine.dart';

const vi = AppStrings.vietnamese;
const en = AppStrings.english;

Future<SharedPreferences> pumpApp(
  WidgetTester tester, {
  String? savedLanguage,
  bool isAcknowledged = true,
  Size size = const Size(392, 800),
  double textScale = 1.0,
  FakeGameEngine? engine,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);

  SharedPreferences.setMockInitialValues({
    AppLanguageController.languageKey: ?savedLanguage,
    if (isAcknowledged)
      FairPlayController.acknowledgedVersionKey: fairPlayNoticeVersion,
  });
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        gameEngineProvider.overrideWithValue(engine ?? FakeGameEngine()),
      ],
      child: const SpookyMooveApp(),
    ),
  );
  await tester.pumpAndSettle();
  return preferences;
}

Future<void> tapKey(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

/// No overflow, and every visible key stays at least 48 dp tall.
void expectFits(WidgetTester tester, String reason) {
  expect(tester.takeException(), isNull, reason: reason);
  for (final element in find.byType(AppKey).hitTestable().evaluate()) {
    expect(
      element.size!.height,
      greaterThanOrEqualTo(AppDimens.minKeyHeight),
      reason: reason,
    );
  }
}

Finder inDialog(Type dialog, String text) =>
    find.descendant(of: find.byType(dialog), matching: find.text(text));

void main() {
  testWidgets('a Vietnamese device: notice, then Home, in Vietnamese', (
    tester,
  ) async {
    tester.platformDispatcher.localeTestValue = const Locale('vi', 'VN');
    await pumpApp(tester, isAcknowledged: false);

    expect(find.text(FairPlayNoticeText.vietnamese.title), findsOneWidget);
    await tapKey(tester, FairPlayScreen.acknowledgeKey);

    expect(find.text(vi.homeTitle), findsOneWidget);
    expect(find.text(vi.chessName), findsOneWidget);
    expect(find.text(vi.xiangqiName), findsOneWidget);
    expect(find.text(en.homeTitle), findsNothing);
  });

  testWidgets('a saved Vietnamese choice wins on an English device', (
    tester,
  ) async {
    await pumpApp(tester, savedLanguage: 'vi');

    expect(find.text(vi.homeTitle), findsOneWidget);
    expect(
      Localizations.localeOf(tester.element(find.byType(HomeScreen))),
      const Locale('vi'),
    );
  });

  testWidgets('a saved English choice wins on a Vietnamese device', (
    tester,
  ) async {
    tester.platformDispatcher.localeTestValue = const Locale('vi', 'VN');
    await pumpApp(tester, savedLanguage: 'en');

    expect(find.text(en.homeTitle), findsOneWidget);
    await tapKey(tester, HomeScreen.gameKey(GameKind.chess));
    await tapKey(tester, NewGameScreen.fairPlayKey);
    expect(
      find.descendant(
        of: find.byType(FairPlaySheet),
        matching: find.text(FairPlayNoticeText.english.title),
      ),
      findsOneWidget,
    );
  });

  testWidgets('picking TIẾNG VIỆT switches every screen at once and saves it; '
      'the fair-play re-view follows without a new acknowledgement', (
    tester,
  ) async {
    final preferences = await pumpApp(tester);
    expect(find.text(en.homeTitle), findsOneWidget);

    await tapKey(tester, HomeScreen.languageKey);
    await tapKey(tester, LanguageDialog.languageKey(AppLanguage.vietnamese));

    expect(find.byType(LanguageDialog), findsNothing);
    expect(find.text(vi.homeTitle), findsOneWidget);
    expect(find.text(en.homeTitle), findsNothing);
    expect(preferences.getString(AppLanguageController.languageKey), 'vi');

    await tapKey(tester, HomeScreen.gameKey(GameKind.xiangqi));
    expect(find.text(vi.xiangqiName), findsOneWidget);
    expect(find.text(vi.startGame), findsOneWidget);
    expect(
      find.text(PersonaTierCopy.levelHeading(AppLanguage.vietnamese)),
      findsOneWidget,
    );

    await tapKey(tester, NewGameScreen.fairPlayKey);
    expect(find.byType(FairPlaySheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FairPlaySheet),
        matching: find.text(FairPlayNoticeText.vietnamese.title),
      ),
      findsOneWidget,
    );
    expect(find.byType(FairPlayScreen), findsNothing);
    expect(
      preferences.getInt(FairPlayController.acknowledgedVersionKey),
      fairPlayNoticeVersion,
    );
  });

  testWidgets('Vietnamese screen readers hear Vietnamese labels', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, savedLanguage: 'vi');

    expect(find.bySemanticsLabel(vi.homeTitleSpoken), findsOneWidget);
    expect(find.bySemanticsLabel(vi.languageTitleSpoken), findsOneWidget);
    expect(
      find.bySemanticsLabel('${vi.chessNameSpoken}, ${vi.chessTaglineSpoken}'),
      findsOneWidget,
    );

    await tapKey(tester, HomeScreen.gameKey(GameKind.chess));
    expect(find.bySemanticsLabel(vi.startGameSpoken), findsOneWidget);
    await tapKey(tester, NewGameScreen.startKey);
    expect(find.bySemanticsLabel(vi.undoSpoken), findsOneWidget);
    expect(find.bySemanticsLabel(vi.newGameSpoken), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Vietnamese screen readers hear the promotion choices', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        supportedLocales: const [Locale('en'), Locale('vi')],
        localizationsDelegates: const [
          AppStrings.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: PromotionChooser(
          color: PieceColor.white,
          keySize: 48,
          onChosen: (_) {},
          onCancel: () {},
        ),
      ),
    );

    for (final label in [
      vi.queenSpoken,
      vi.rookSpoken,
      vi.bishopSpoken,
      vi.knightSpoken,
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    semantics.dispose();
  });

  group('Vietnamese at 360x640, text scale 2.0', () {
    const size = Size(360, 640);

    testWidgets('Home and its dialogs', (tester) async {
      await pumpApp(tester, savedLanguage: 'vi', size: size, textScale: 2.0);
      expectFits(tester, 'Home');

      await tapKey(tester, HomeScreen.settingsKey);
      expect(inDialog(SettingsDialog, vi.settingsTitle), findsOneWidget);
      expectFits(tester, 'Settings');

      await tapKey(tester, AboutLicensesKey.openKey);
      expect(inDialog(AboutLicensesDialog, vi.aboutTitle), findsOneWidget);
      expectFits(tester, 'About');
      await tapKey(tester, AboutLicensesDialog.closeKey);
      await tester.tap(find.text(vi.close));
      await tester.pumpAndSettle();

      await tapKey(tester, HomeScreen.languageKey);
      expect(find.text('TIẾNG VIỆT'), findsOneWidget);
      expectFits(tester, 'Language');
    });

    for (final game in GameKind.values) {
      testWidgets('${game.name}: new-game screen, advisor, discard dialog', (
        tester,
      ) async {
        final engine = FakeGameEngine();
        await pumpApp(
          tester,
          savedLanguage: 'vi',
          size: size,
          textScale: 2.0,
          engine: engine,
        );

        await tapKey(tester, HomeScreen.gameKey(game));
        expect(find.text(vi.gameName(game)), findsOneWidget);
        expectFits(tester, '${game.name} new game');

        await tapKey(tester, NewGameScreen.startKey);
        expect(find.byType(AdvisorScreen), findsOneWidget);
        expectFits(tester, '${game.name} advisor');

        expect(engine.searches, isNotEmpty);
        engine.last.complete([
          fakeLine(
            1,
            game == GameKind.chess ? 'e2e4' : 'h3e3',
            const CentipawnScore(30),
          ),
        ]);
        await tester.pumpAndSettle();
        expect(find.text(vi.suggestionCaption), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(TopBar.regionKey),
            matching: find.text(vi.winRate),
          ),
          findsOneWidget,
        );
        expectFits(tester, '${game.name} suggestion');

        await tapKey(tester, NewGameKey.regionKey);
        expect(find.text(vi.discardTitle), findsOneWidget);
        expectFits(tester, '${game.name} discard dialog');
      });
    }
  });
}
