import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/game/player_side.dart';
import 'package:spookymoove/core/theme/app_colors.dart';
import 'package:spookymoove/core/theme/app_dimens.dart';
import 'package:spookymoove/core/widgets/app_block.dart';
import 'package:spookymoove/features/new_game/domain/game_kind.dart';
import 'package:spookymoove/features/new_game/presentation/game_registry.dart';
import 'package:spookymoove/features/new_game/presentation/home_screen.dart';
import 'package:spookymoove/features/new_game/presentation/new_game_screen.dart';
import 'package:spookymoove/features/persona/domain/persona_tier.dart';
import 'package:spookymoove/features/settings/domain/app_language.dart';
import 'package:spookymoove/features/settings/presentation/language_dialog.dart';
import 'package:spookymoove/features/settings/presentation/settings_dialog.dart';

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

  testWidgets('each row: neutral block, accent icon, name, tagline, chevron', (
    tester,
  ) async {
    await pumpHome(tester);

    for (final (game, tagline) in const [
      (GameKind.chess, 'CLASSIC STRATEGY'),
      (GameKind.xiangqi, 'CHINESE CHESS'),
    ]) {
      final blocks = tester
          .widgetList<AppBlock>(
            find.descendant(of: gameKey(game), matching: find.byType(AppBlock)),
          )
          .toList();
      expect(blocks, hasLength(2), reason: game.label);
      final (row, icon) = (blocks.first, blocks.last);
      expect(row.face, AppColors.surfaceDark);
      expect(row.side, AppColors.surfaceSide);
      expect(row.onTap, isNotNull);
      expect(icon.face, game.accent);
      expect(icon.side, game.accentSide);
      expect(icon.onTap, isNull);

      Finder inRow(Finder finder) =>
          find.descendant(of: gameKey(game), matching: finder);
      expect(tester.getSize(inRow(find.byWidget(icon))), const Size(48, 48));
      final pictogram = GameWidgets.sidePictogram(game, PlayerSide.first);
      expect(
        tester.getSize(inRow(find.byType(pictogram.runtimeType))),
        const Size.square(AppDimens.gameIconPictogramSize),
      );
      expect(
        tester.widget<Text>(inRow(find.text(game.label))).style?.color,
        AppColors.textPrimary,
      );
      expect(game.tagline, tagline);
      expect(
        tester.widget<Text>(inRow(find.text(tagline))).style?.color,
        AppColors.textSecondary,
      );
      expect(
        tester.widget<Icon>(inRow(find.byIcon(Icons.chevron_right))).color,
        AppColors.textSecondary,
      );
    }
    for (final key in [HomeScreen.settingsKey, HomeScreen.languageKey]) {
      final block = tester.widget<AppBlock>(
        find.descendant(of: find.byKey(key), matching: find.byType(AppBlock)),
      );
      expect(block.face, AppColors.keyNormal);
    }
    expect(find.textContaining('GAMES'), findsNothing);
  });

  testWidgets('rows are ≥ 72 dp, 8 dp apart and top-aligned', (tester) async {
    await pumpHome(tester, size: const Size(360, 640));

    final chess = tester.getRect(gameKey(GameKind.chess));
    final xiangqi = tester.getRect(gameKey(GameKind.xiangqi));
    final header = tester.getRect(find.byKey(HomeScreen.settingsKey));
    for (final row in [chess, xiangqi]) {
      expect(row.height, greaterThanOrEqualTo(AppDimens.gameRowMinHeight));
      expect(row.width, 360 - 2 * AppDimens.spacingLarge);
    }
    expect(xiangqi.top - chess.bottom, AppDimens.spacing);
    expect(chess.top - header.bottom, AppDimens.spacingLarge);
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

  testWidgets('rows announce name and tagline; the title is a header', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpHome(tester);

    for (final (game, label) in const [
      (GameKind.chess, 'Chess, classic strategy'),
      (GameKind.xiangqi, 'Xiangqi, Chinese chess'),
    ]) {
      expect(
        tester.getSemantics(gameKey(game)),
        matchesSemantics(
          label: label,
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
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
    for (final textScale in const [1.0, 2.0]) {
      testWidgets('no overflow at text scale $textScale on '
          '${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        await pumpHome(tester, size: size, textScale: textScale);

        expect(tester.takeException(), isNull);
        for (final key in [HomeScreen.settingsKey, HomeScreen.languageKey]) {
          expect(
            tester.getSize(find.byKey(key)).height,
            greaterThanOrEqualTo(AppDimens.minKeyHeight),
          );
        }
        for (final game in GameKind.values) {
          final row = tester.getRect(gameKey(game));
          expect(row.height, greaterThanOrEqualTo(AppDimens.gameRowMinHeight));
          expect(row.bottom, lessThanOrEqualTo(size.height));
          expect(
            tester.getSize(
              find.descendant(
                of: gameKey(game),
                matching: find.byIcon(Icons.chevron_right),
              ),
            ),
            const Size.square(24),
          );
        }
      });
    }
  }
}
