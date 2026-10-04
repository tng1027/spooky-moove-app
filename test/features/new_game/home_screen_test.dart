import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cataland/core/game/player_side.dart';
import 'package:cataland/core/theme/app_dimens.dart';
import 'package:cataland/features/new_game/domain/game_kind.dart';
import 'package:cataland/features/new_game/presentation/home_screen.dart';
import 'package:cataland/features/new_game/presentation/new_game_screen.dart';
import 'package:cataland/features/persona/domain/persona_tier.dart';
import 'package:cataland/features/settings/domain/app_language.dart';
import 'package:cataland/features/settings/presentation/language_dialog.dart';
import 'package:cataland/features/settings/presentation/settings_dialog.dart';

void main() {
  final starts = <(GameKind, PlayerSide, PersonaTier?)>[];

  Finder gameKey(GameKind game) => find.byKey(HomeScreen.gameKey(game));

  Future<void> pumpHome(
    WidgetTester tester, {
    Size size = const Size(392, 800),
    double textScale = 1.0,
  }) async {
    starts.clear();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          onStart: (game, side, tier) => starts.add((game, side, tier)),
        ),
      ),
    );
  }

  testWidgets('shows CHESS then XIANGQI, the title, and no BACK key', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.text('PICK A GAME'), findsOneWidget);
    expect(find.text('CHESS'), findsOneWidget);
    expect(find.text('XIANGQI'), findsOneWidget);
    expect(
      tester.getCenter(gameKey(GameKind.xiangqi)).dy,
      greaterThan(tester.getCenter(gameKey(GameKind.chess)).dy),
    );
    expect(find.text('BACK'), findsNothing);
    expect(find.byType(NewGameScreen), findsNothing);
  });

  testWidgets('game keys are big', (tester) async {
    await pumpHome(tester);

    for (final game in GameKind.values) {
      expect(
        tester.getSize(gameKey(game)).height,
        greaterThanOrEqualTo(AppDimens.gameKeyMinHeight),
      );
    }
  });

  for (final game in GameKind.values) {
    testWidgets('${game.label} opens the new-game screen for it', (
      tester,
    ) async {
      await pumpHome(tester);
      await tester.tap(gameKey(game));
      await tester.pumpAndSettle();

      final screen = tester.widget<NewGameScreen>(find.byType(NewGameScreen));
      expect(screen.game, game);
      expect(find.text(game.label), findsOneWidget);
    });
  }

  testWidgets('a rapid double tap opens one new-game screen', (tester) async {
    await pumpHome(tester);

    await tester.tap(gameKey(GameKind.chess));
    await tester.tap(gameKey(GameKind.chess));
    await tester.pumpAndSettle();
    expect(find.byType(NewGameScreen), findsOneWidget);

    await tester.tap(find.byKey(NewGameScreen.backKey));
    await tester.pumpAndSettle();
    expect(find.byType(NewGameScreen), findsNothing);
  });

  testWidgets('BACK allows picking again', (tester) async {
    await pumpHome(tester);
    await tester.tap(gameKey(GameKind.chess));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NewGameScreen.backKey));
    await tester.pumpAndSettle();

    await tester.tap(gameKey(GameKind.xiangqi));
    await tester.pumpAndSettle();

    expect(
      tester.widget<NewGameScreen>(find.byType(NewGameScreen)).game,
      GameKind.xiangqi,
    );
  });

  testWidgets('START passes the picked game and pops back to the root', (
    tester,
  ) async {
    await pumpHome(tester);
    await tester.tap(gameKey(GameKind.xiangqi));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(NewGameScreen.startKey));
    await tester.pumpAndSettle();

    expect(starts, [(GameKind.xiangqi, PlayerSide.first, PersonaTier.even)]);
    expect(find.byType(NewGameScreen), findsNothing);
  });

  testWidgets('no BACK key even with a route beneath Home', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => HomeScreen(onStart: (_, _, _) {}),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('BACK'), findsNothing);
  });

  testWidgets('keys announce title-case names; the title is a header', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpHome(tester);

    for (final (game, label) in const [
      (GameKind.chess, 'Chess'),
      (GameKind.xiangqi, 'Xiangqi'),
    ]) {
      expect(
        tester.getSemantics(gameKey(game)),
        matchesSemantics(
          label: label,
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
    }
    expect(
      tester.getSemantics(find.bySemanticsLabel('Pick a game')),
      matchesSemantics(label: 'Pick a game', isHeader: true),
    );
    semantics.dispose();
  });

  group('header', () {
    testWidgets('SETTINGS left, PICK A GAME centred, LANGUAGE right', (
      tester,
    ) async {
      await pumpHome(tester);

      final settings = tester.getRect(find.byKey(HomeScreen.settingsKey));
      final title = tester.getRect(find.text('PICK A GAME'));
      final language = tester.getRect(find.byKey(HomeScreen.languageKey));
      expect(settings.right, lessThanOrEqualTo(title.left));
      expect(title.right, lessThanOrEqualTo(language.left));
      expect(title.center.dx, closeTo(392 / 2, 0.5));
      expect(settings.center.dy, closeTo(language.center.dy, 0.5));
      expect(
        settings.bottom,
        lessThan(tester.getRect(gameKey(GameKind.chess)).top),
      );
      expect(settings.height, greaterThanOrEqualTo(AppDimens.minKeyHeight));
      expect(language.height, greaterThanOrEqualTo(AppDimens.minKeyHeight));
    });

    testWidgets('keys announce "Settings" and "Language" as buttons', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpHome(tester);

      for (final (key, label) in const [
        (HomeScreen.settingsKey, 'Settings'),
        (HomeScreen.languageKey, 'Language'),
      ]) {
        expect(
          tester.getSemantics(find.byKey(key)),
          matchesSemantics(
            label: label,
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasSelectedState: true,
            hasTapAction: true,
          ),
        );
      }
      semantics.dispose();
    });

    for (final (name, key, dialogType, closeKey) in [
      (
        'SETTINGS',
        HomeScreen.settingsKey,
        SettingsDialog,
        SettingsDialog.closeKey,
      ),
      (
        'LANGUAGE',
        HomeScreen.languageKey,
        LanguageDialog,
        LanguageDialog.closeKey,
      ),
    ]) {
      Future<void> open(WidgetTester tester) async {
        await tester.tap(find.byKey(key));
        await tester.pumpAndSettle();
        expect(find.byType(dialogType), findsOneWidget);
      }

      void expectHomeUnchanged() {
        expect(find.byType(dialogType), findsNothing);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(NewGameScreen), findsNothing);
        expect(starts, isEmpty);
      }

      testWidgets('$name opens its dialog; CLOSE closes it', (tester) async {
        await pumpHome(tester);
        await open(tester);

        await tester.tap(find.byKey(closeKey));
        await tester.pumpAndSettle();
        expectHomeUnchanged();
      });

      testWidgets('$name dialog: a barrier tap closes it', (tester) async {
        await pumpHome(tester);
        await open(tester);

        await tester.tapAt(const Offset(4, 4));
        await tester.pumpAndSettle();
        expectHomeUnchanged();
      });

      testWidgets('$name dialog: system back closes it', (tester) async {
        await pumpHome(tester);
        await open(tester);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expectHomeUnchanged();
      });

      testWidgets('$name: a rapid double tap opens one dialog', (tester) async {
        await pumpHome(tester);

        await tester.tap(find.byKey(key));
        await tester.tap(find.byKey(key), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.byType(dialogType), findsOneWidget);

        await tester.tap(find.byKey(closeKey));
        await tester.pumpAndSettle();
        expectHomeUnchanged();

        await open(tester);
      });
    }

    testWidgets('LANGUAGE: picking ENGLISH closes it, text stays English', (
      tester,
    ) async {
      await pumpHome(tester);
      await tester.tap(find.byKey(HomeScreen.languageKey));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(LanguageDialog.languageKey(AppLanguage.english)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LanguageDialog), findsNothing);
      expect(find.text('PICK A GAME'), findsOneWidget);
    });
  });

  for (final size in const [Size(360, 640), Size(360, 600)]) {
    testWidgets('no overflow at text scale 2.0 on '
        '${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      await pumpHome(tester, size: size, textScale: 2.0);

      expect(tester.takeException(), isNull);
      for (final key in [HomeScreen.settingsKey, HomeScreen.languageKey]) {
        expect(
          tester.getSize(find.byKey(key)).height,
          greaterThanOrEqualTo(AppDimens.minKeyHeight),
        );
      }
      for (final game in GameKind.values) {
        expect(
          tester.getSize(gameKey(game)).height,
          greaterThanOrEqualTo(AppDimens.gameKeyMinHeight),
        );
      }
    });
  }
}
