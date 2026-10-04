import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/game/player_side.dart';
import 'package:spookymoove/app.dart';
import 'package:spookymoove/core/board/tap_board.dart';
import 'package:spookymoove/core/theme/app_dimens.dart';
import 'package:spookymoove/core/widgets/app_key.dart';
import 'package:spookymoove/features/advisor/presentation/advisor_screen.dart';
import 'package:spookymoove/features/advisor/presentation/suggestion_controller.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/suggestion_card.dart';
import 'package:spookymoove/features/chess/domain/chess_models.dart';
import 'package:spookymoove/features/chess/presentation/chess_board_controller.dart';
import 'package:spookymoove/features/fair_play/domain/fair_play_notice.dart';
import 'package:spookymoove/features/fair_play/presentation/fair_play_controller.dart';
import 'package:spookymoove/features/fair_play/presentation/fair_play_screen.dart';
import 'package:spookymoove/features/new_game/domain/game_kind.dart';
import 'package:spookymoove/features/new_game/presentation/game_session_controller.dart';
import 'package:spookymoove/features/new_game/presentation/home_screen.dart';
import 'package:spookymoove/features/new_game/presentation/new_game_screen.dart';
import 'package:spookymoove/features/new_game/presentation/widgets/new_game_key.dart';
import 'package:spookymoove/features/persona/domain/persona_tier.dart';
import 'package:spookymoove/features/persona/presentation/persona_tier_controller.dart';
import 'package:spookymoove/features/persona/presentation/widgets/persona_row.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spookymoove/core/board/intersection_board.dart';
import 'package:spookymoove/core/engine/engine_models.dart';
import 'package:spookymoove/features/advisor/presentation/suggestion_providers.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/status_line.dart';
import 'package:spookymoove/features/new_game/presentation/game_registry.dart';
import 'package:spookymoove/features/xiangqi/domain/xiangqi_models.dart';
import 'package:spookymoove/features/xiangqi/presentation/widgets/xiangqi_board.dart';
import 'package:spookymoove/features/xiangqi/presentation/widgets/xiangqi_piece_disc.dart';
import 'package:spookymoove/features/xiangqi/presentation/xiangqi_board_controller.dart';

import '../persona/fake_game_engine.dart';

ChessSquare sq(String name) => ChessSquare.parse(name);

/// Pumps the app on the Home screen.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  Size size = const Size(392, 800),
  double textScale = 1.0,
  FakeGameEngine? engine,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  SharedPreferences.setMockInitialValues({
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
  return ProviderScope.containerOf(tester.element(find.byType(SpookyMooveApp)));
}

/// Taps [game] on the Home screen.
Future<void> pickGame(WidgetTester tester, GameKind game) async {
  final gameKey = find.byKey(HomeScreen.gameKey(game));
  await tester.ensureVisible(gameKey);
  await tester.tap(gameKey);
  await tester.pumpAndSettle();
}

/// Pumps the app and opens the new-game screen for [game] from Home.
Future<ProviderContainer> pumpNewGame(
  WidgetTester tester, {
  GameKind game = GameKind.chess,
  Size size = const Size(392, 800),
  double textScale = 1.0,
  FakeGameEngine? engine,
}) async {
  final container = await pumpApp(
    tester,
    size: size,
    textScale: textScale,
    engine: engine,
  );
  await pickGame(tester, game);
  return container;
}

Finder square(String name) {
  final s = sq(name);
  return find.byKey(TapBoard.squareKey(s.file, s.rank));
}

/// Selects [side] and taps START GAME.
Future<void> tapSide(WidgetTester tester, PlayerSide side) async {
  final sideKey = find.byKey(NewGameScreen.sideKey(side));
  await tester.ensureVisible(sideKey);
  await tester.tap(sideKey);
  await tester.pump();
  await tester.tap(find.byKey(NewGameScreen.startKey));
  await tester.pumpAndSettle();
}

/// Starts Chess as White, enters 1. e4 and picks the Soft tier.
Future<ProviderContainer> pumpGameInProgress(WidgetTester tester) async {
  final container = await pumpNewGame(tester);
  await tapSide(tester, PlayerSide.first);
  await tester.tap(square('e2'));
  await tester.pump();
  await tester.tap(square('e4'));
  await tester.pump();
  await tester.tap(find.byKey(PersonaRow.tierKey(PersonaTier.soft)));
  await tester.pump();
  return container;
}

void expectGameInProgress(ProviderContainer container) {
  final board = container.read(chessBoardControllerProvider);
  expect(
    board.pieces[sq('e4')],
    const ChessPiece(PieceColor.white, PieceKind.pawn),
  );
  expect(board.sideToMove, PieceColor.black);
  expect(container.read(personaTierProvider), PersonaTier.soft);
}

Future<void> openNewGameConfirm(WidgetTester tester) async {
  await tester.tap(find.byKey(NewGameKey.regionKey));
  await tester.pumpAndSettle();
  expect(find.byType(NewGameConfirmDialog), findsOneWidget);
}

Future<void> confirmNewGame(WidgetTester tester) async {
  await openNewGameConfirm(tester);
  await tester.tap(find.byKey(NewGameConfirmDialog.confirmKey));
  await tester.pumpAndSettle();
}

Future<void> tapBack(WidgetTester tester) async {
  await tester.tap(find.byKey(NewGameScreen.backKey));
  await tester.pumpAndSettle();
}

/// The game was discarded and Home is the only route, without a BACK key.
void expectDiscardedOnHome(WidgetTester tester, ProviderContainer container) {
  expect(container.read(gameSessionProvider), isNull);
  expect(find.byType(HomeScreen), findsOneWidget);
  expect(find.byType(NewGameScreen), findsNothing);
  expect(find.text('BACK'), findsNothing);
  expect(find.byKey(HomeScreen.settingsKey), findsOneWidget);
  expect(find.byKey(HomeScreen.languageKey), findsOneWidget);
  final navigator = tester.state<NavigatorState>(find.byType(Navigator));
  expect(navigator.canPop(), isFalse);
}

void main() {
  group('first use', () {
    testWidgets('header: BACK, the game name, FAIR PLAY; no bottom row', (
      tester,
    ) async {
      await pumpNewGame(tester);

      expect(find.byType(NewGameScreen), findsOneWidget);
      final back = tester.getRect(find.byKey(NewGameScreen.backKey));
      final name = tester.getRect(find.text('CHESS'));
      final fairPlay = tester.getRect(find.byKey(NewGameScreen.fairPlayKey));
      final start = tester.getRect(find.byKey(NewGameScreen.startKey));
      expect(back.right, lessThanOrEqualTo(name.left));
      expect(name.right, lessThanOrEqualTo(fairPlay.left));
      expect(back.center.dy, closeTo(fairPlay.center.dy, 0.5));
      expect(back.bottom, lessThan(start.top));
      expect(fairPlay.bottom, lessThan(start.top));
      expect(name.center.dx, closeTo(392 / 2, 0.5));
      expect(find.textContaining('NEW GAME'), findsNothing);
      expect(find.text('HOME'), findsNothing);
      expect(find.text('GAME'), findsNothing);
      expect(find.text('XIANGQI'), findsNothing);
    });

    testWidgets('defaults: Even and WHITE selected, nothing started yet', (
      tester,
    ) async {
      final container = await pumpNewGame(tester);

      expect(find.text('LEVEL · EVEN'), findsOneWidget);
      AppKey key(Key k) => tester.widget<AppKey>(find.byKey(k));
      expect(key(NewGameScreen.sideKey(PlayerSide.first)).isSelected, isTrue);
      expect(key(NewGameScreen.sideKey(PlayerSide.second)).isSelected, isFalse);
      expect(key(NewGameScreen.startKey).isPrimary, isTrue);
      expect(container.read(gameSessionProvider), isNull);
    });

    testWidgets('tapping a side selects it without starting', (tester) async {
      final container = await pumpNewGame(tester);

      await tester.tap(find.byKey(NewGameScreen.sideKey(PlayerSide.second)));
      await tester.pump();
      final black = tester.widget<AppKey>(
        find.byKey(NewGameScreen.sideKey(PlayerSide.second)),
      );
      expect(black.isSelected, isTrue);
      expect(find.byType(NewGameScreen), findsOneWidget);
      expect(container.read(gameSessionProvider), isNull);
    });

    testWidgets('START GAME with the defaults: White below, Even level', (
      tester,
    ) async {
      final container = await pumpNewGame(tester);
      await tester.tap(find.byKey(NewGameScreen.startKey));
      await tester.pumpAndSettle();

      expect(find.byType(AdvisorScreen), findsOneWidget);
      expect(find.byType(NewGameScreen), findsNothing);
      expect(find.byType(HomeScreen), findsNothing);
      expect(container.read(personaTierProvider), PersonaTier.even);
      expect(find.text(SuggestionCard.pickTierPrompt), findsNothing);
      final board = container.read(chessBoardControllerProvider);
      expect(board.pieces, hasLength(32));
      expect(board.sideToMove, PieceColor.white);
      expect(
        tester.getCenter(square('e1')).dy,
        greaterThan(tester.getCenter(square('e8')).dy),
      );
    });

    testWidgets('after START, system back does not return to Home', (
      tester,
    ) async {
      await pumpNewGame(tester);
      await tester.tap(find.byKey(NewGameScreen.startKey));
      await tester.pumpAndSettle();

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isFalse);
    });

    testWidgets('BLACK puts Black at the bottom; White moves first', (
      tester,
    ) async {
      final container = await pumpNewGame(tester);
      await tapSide(tester, PlayerSide.second);

      final board = container.read(chessBoardControllerProvider);
      expect(board.userSide, PieceColor.black);
      expect(board.sideToMove, PieceColor.white);
      expect(
        tester.getCenter(square('e8')).dy,
        greaterThan(tester.getCenter(square('e1')).dy),
      );
    });

    testWidgets('BACK returns to Home without starting a game', (tester) async {
      final container = await pumpNewGame(tester);
      await tapBack(tester);

      expect(find.byType(NewGameScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(container.read(gameSessionProvider), isNull);
    });

    testWidgets('system back returns to Home without starting a game', (
      tester,
    ) async {
      final container = await pumpNewGame(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(NewGameScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(container.read(gameSessionProvider), isNull);
    });

    testWidgets('FAIR PLAY opens the notice read-only and closes back', (
      tester,
    ) async {
      await pumpNewGame(tester);

      await tester.tap(find.byKey(NewGameScreen.fairPlayKey));
      await tester.pumpAndSettle();
      expect(find.byKey(FairPlayScreen.closeKey), findsOneWidget);
      expect(find.byKey(FairPlayScreen.acknowledgeKey), findsNothing);

      await tester.tap(find.byKey(FairPlayScreen.closeKey));
      await tester.pumpAndSettle();
      expect(find.byType(FairPlayScreen), findsNothing);
      expect(find.byType(NewGameScreen), findsOneWidget);
    });

    testWidgets('no overflow at text scale 2.0 on a small phone', (
      tester,
    ) async {
      await pumpNewGame(tester, size: const Size(360, 640), textScale: 2.0);
      expect(tester.takeException(), isNull);

      await tapSide(tester, PlayerSide.first);
      expect(tester.takeException(), isNull);
      expect(find.byType(AdvisorScreen), findsOneWidget);
    });
  });

  group('guard', () {
    final starts = <(GameKind, PlayerSide, PersonaTier?)>[];

    Future<void> pumpScreen(WidgetTester tester) async {
      starts.clear();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => NewGameScreen(
                    game: GameKind.chess,
                    onStart: (game, side, tier) =>
                        starts.add((game, side, tier)),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('a rapid double tap on START GAME starts one game', (
      tester,
    ) async {
      await pumpScreen(tester);

      final start = find.byKey(NewGameScreen.startKey);
      await tester.tap(start);
      await tester.tap(start);
      await tester.pump();

      expect(starts, [(GameKind.chess, PlayerSide.first, PersonaTier.even)]);
    });

    testWidgets('BACK then START: only BACK acts', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(NewGameScreen.backKey));
      await tester.tap(find.byKey(NewGameScreen.startKey));
      await tester.pumpAndSettle();

      expect(starts, isEmpty);
      expect(find.byType(NewGameScreen), findsNothing);
    });
  });

  group('LEVEL', () {
    Finder tierKey(PersonaTier tier) => find.byKey(NewGameScreen.tierKey(tier));

    testWidgets('shows the 7 tiers, Even selected, above SIDE', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpNewGame(tester);

      expect(find.text('LEVEL · EVEN'), findsOneWidget);
      for (final tier in PersonaTier.values) {
        expect(
          tester.getSemantics(tierKey(tier)),
          matchesSemantics(
            label: tier.label,
            isButton: true,
            hasSelectedState: true,
            isSelected: tier == PersonaTier.even,
            hasTapAction: true,
          ),
        );
      }
      semantics.dispose();
      expect(
        tester.getCenter(tierKey(PersonaTier.baby)).dy,
        lessThan(
          tester
              .getCenter(find.byKey(NewGameScreen.sideKey(PlayerSide.first)))
              .dy,
        ),
      );
    });

    testWidgets('the picked level is named and carried into the game', (
      tester,
    ) async {
      final container = await pumpNewGame(tester);

      await tester.tap(tierKey(PersonaTier.god));
      await tester.pump();
      await tester.tap(tierKey(PersonaTier.soft));
      await tester.pump();
      expect(find.text('LEVEL · SOFT'), findsOneWidget);
      expect(container.read(personaTierProvider), isNull);

      await tapSide(tester, PlayerSide.first);

      expect(find.byType(AdvisorScreen), findsOneWidget);
      expect(container.read(personaTierProvider), PersonaTier.soft);
      expect(find.text(SuggestionCard.pickTierPrompt), findsNothing);
    });

    testWidgets('keys are at least 44 x 48 dp on a 360 dp screen', (
      tester,
    ) async {
      await pumpNewGame(tester, size: const Size(360, 800));

      for (final tier in PersonaTier.values) {
        final rect = tester.getRect(tierKey(tier));
        expect(rect.width, greaterThanOrEqualTo(44), reason: tier.label);
        expect(
          rect.height,
          greaterThanOrEqualTo(AppDimens.minKeyHeight),
          reason: tier.label,
        );
      }
    });

    testWidgets('a level picked mid-game starts the new game with it', (
      tester,
    ) async {
      final container = await pumpGameInProgress(tester);
      await confirmNewGame(tester);

      await tester.tap(tierKey(PersonaTier.master));
      await tester.pump();
      await tapSide(tester, PlayerSide.second);

      expect(find.byType(AdvisorScreen), findsOneWidget);
      expect(container.read(personaTierProvider), PersonaTier.master);
      expect(container.read(gameSessionProvider)?.userSide, PlayerSide.second);
    });
  });

  group('NEW GAME during a game', () {
    testWidgets('cancel keeps the game, tier and side', (tester) async {
      final container = await pumpGameInProgress(tester);
      await openNewGameConfirm(tester);

      await tester.tap(find.byKey(NewGameConfirmDialog.cancelKey));
      await tester.pumpAndSettle();

      expect(find.byType(NewGameConfirmDialog), findsNothing);
      expect(find.byType(NewGameScreen), findsNothing);
      expectGameInProgress(container);
    });

    testWidgets('confirm discards the game and opens the same game', (
      tester,
    ) async {
      final container = await pumpGameInProgress(tester);
      await confirmNewGame(tester);

      expect(container.read(gameSessionProvider), isNull);
      expect(find.byType(AdvisorScreen), findsNothing);
      expect(find.byType(NewGameScreen), findsOneWidget);
      expect(find.text('CHESS'), findsOneWidget);
      expect(find.text('LEVEL · EVEN'), findsOneWidget);
    });

    testWidgets('confirm, BACK: Home with no BACK and no way back', (
      tester,
    ) async {
      final container = await pumpGameInProgress(tester);
      await confirmNewGame(tester);
      await tapBack(tester);

      expectDiscardedOnHome(tester, container);
    });

    testWidgets('confirm, system back: Home with no BACK', (tester) async {
      final container = await pumpGameInProgress(tester);
      await confirmNewGame(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expectDiscardedOnHome(tester, container);
    });

    testWidgets(
      'confirm then START discards the game; the default tier applies',
      (tester) async {
        final container = await pumpGameInProgress(tester);
        await confirmNewGame(tester);

        await tapSide(tester, PlayerSide.second);

        expect(find.byType(NewGameScreen), findsNothing);
        expect(find.byType(HomeScreen), findsNothing);
        expect(find.byType(AdvisorScreen), findsOneWidget);
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        expect(navigator.canPop(), isFalse);
        final board = container.read(chessBoardControllerProvider);
        expect(board.pieces[sq('e4')], isNull);
        expect(
          board.pieces[sq('e2')],
          const ChessPiece(PieceColor.white, PieceKind.pawn),
        );
        expect(board.sideToMove, PieceColor.white);
        expect(board.userSide, PieceColor.black);
        expect(container.read(personaTierProvider), PersonaTier.even);
        expect(
          container.read(gameSessionProvider)?.userSide,
          PlayerSide.second,
        );
      },
    );
  });

  group('XIANGQI', () {
    AppKey key(WidgetTester tester, Finder finder) =>
        tester.widget<AppKey>(finder);
    Finder sideKey(PlayerSide side) => find.byKey(NewGameScreen.sideKey(side));

    List<XiangqiPiece> sideDiscs(WidgetTester tester) => [
      for (final side in PlayerSide.values)
        tester
            .widget<XiangqiPieceDisc>(
              find.descendant(
                of: sideKey(side),
                matching: find.byType(XiangqiPieceDisc),
              ),
            )
            .piece,
    ];

    testWidgets('XIANGQI shows RED / BLACK with general discs, RED selected', (
      tester,
    ) async {
      await pumpNewGame(tester, game: GameKind.xiangqi);

      expect(find.text('XIANGQI'), findsOneWidget);
      expect(find.text('RED'), findsOneWidget);
      expect(find.text('BLACK'), findsOneWidget);
      expect(find.text('WHITE'), findsNothing);
      expect(sideDiscs(tester), const [
        XiangqiPiece(PlayerSide.first, XiangqiPieceKind.general),
        XiangqiPiece(PlayerSide.second, XiangqiPieceKind.general),
      ]);
      expect(key(tester, sideKey(PlayerSide.first)).isSelected, isTrue);
      expect(find.text('LEVEL · EVEN'), findsOneWidget);
    });

    testWidgets('picking a side clicks', (tester) async {
      final haptics = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String);
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
      await pumpNewGame(tester, game: GameKind.xiangqi);
      haptics.clear();

      await tester.tap(sideKey(PlayerSide.second));
      await tester.pump();
      expect(haptics, ['HapticFeedbackType.selectionClick']);

      await tester.tap(sideKey(PlayerSide.second));
      await tester.pump();
      expect(haptics, hasLength(1), reason: 'reselecting is a no-op');
    });

    testWidgets('START passes the game on', (tester) async {
      final starts = <(GameKind, PlayerSide, PersonaTier?)>[];
      await tester.pumpWidget(
        MaterialApp(
          home: NewGameScreen(
            game: GameKind.xiangqi,
            onStart: (game, side, tier) => starts.add((game, side, tier)),
          ),
        ),
      );

      await tester.tap(find.byKey(NewGameScreen.startKey));
      await tester.pump();

      expect(starts, [(GameKind.xiangqi, PlayerSide.first, PersonaTier.even)]);
    });

    testWidgets('title, header and side keys announce title-case names', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpNewGame(tester, game: GameKind.xiangqi);

      expect(
        tester.getSemantics(find.bySemanticsLabel('New game, Xiangqi')),
        matchesSemantics(label: 'New game, Xiangqi', isHeader: true),
      );
      for (final (key, label) in const [
        (NewGameScreen.backKey, 'Back'),
        (NewGameScreen.fairPlayKey, 'Fair play'),
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
      expect(
        tester.getSemantics(sideKey(PlayerSide.first)),
        matchesSemantics(
          label: 'Red',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(sideKey(PlayerSide.second)),
        matchesSemantics(
          label: 'Black',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('confirm during a search: the old result never shows', (
      tester,
    ) async {
      final engine = FakeGameEngine();
      final container = await pumpNewGame(
        tester,
        game: GameKind.xiangqi,
        engine: engine,
      );
      await tapSide(tester, PlayerSide.first);
      final search = engine.last;
      expect(search.isPending, isTrue);

      await confirmNewGame(tester);
      if (search.isPending) {
        search.complete([fakeLine(1, 'h3e3', const CentipawnScore(30))]);
      }
      await tester.pumpAndSettle();

      expect(container.read(gameSessionProvider), isNull);
      expect(
        container.read(suggestionControllerProvider),
        isNot(isA<SuggestionReady>()),
      );
      expect(
        container.read(xiangqiBoardControllerProvider).suggestedMove,
        isNull,
      );
      expect(find.text('XIANGQI'), findsOneWidget);
    });

    testWidgets('a Chess game: confirm, BACK, XIANGQI, START switches game', (
      tester,
    ) async {
      final container = await pumpGameInProgress(tester);
      await confirmNewGame(tester);
      await tapBack(tester);
      await pickGame(tester, GameKind.xiangqi);
      await tapSide(tester, PlayerSide.first);

      expect(container.read(gameSessionProvider)?.game, GameKind.xiangqi);
      expect(find.byType(XiangqiBoard), findsOneWidget);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isFalse);
    });

    testWidgets('a Xiangqi game opens XIANGQI on NEW GAME', (tester) async {
      await pumpNewGame(tester, game: GameKind.xiangqi);
      await tapSide(tester, PlayerSide.first);
      expect(find.byType(XiangqiBoard), findsOneWidget);

      await confirmNewGame(tester);

      expect(find.text('XIANGQI'), findsOneWidget);
      expect(find.text('RED'), findsOneWidget);
    });

    testWidgets('START as RED: Xiangqi advisor, xiangqi variant, suggestion', (
      tester,
    ) async {
      final engine = FakeGameEngine();
      final container = await pumpNewGame(
        tester,
        game: GameKind.xiangqi,
        engine: engine,
      );
      await tester.ensureVisible(
        find.byKey(NewGameScreen.tierKey(PersonaTier.god)),
      );
      await tester.tap(find.byKey(NewGameScreen.tierKey(PersonaTier.god)));
      await tester.pump();
      await tapSide(tester, PlayerSide.first);

      expect(find.byType(AdvisorScreen), findsOneWidget);
      final boardSize = tester.getSize(find.byType(XiangqiBoard));
      final available = tester.getSize(find.byType(SafeArea).first);
      expect(
        boardSize,
        AdvisorScreen.boardSizeFor(available, files: 9, ranks: 10),
      );
      expect(container.read(activeEngineVariantProvider), 'xiangqi');
      expect(engine.variants, ['xiangqi']);
      expect(engine.last.position.moves, isEmpty);

      engine.last.complete([fakeLine(1, 'h3e3', const CentipawnScore(30))]);
      await tester.pumpAndSettle();

      expect(find.text('H3 ➔ E3'), findsOneWidget);
      expect(find.text('WHITE'), findsNothing);
    });

    testWidgets('START as BLACK: Black at the bottom, waiting for Red', (
      tester,
    ) async {
      final container = await pumpNewGame(tester, game: GameKind.xiangqi);
      await tapSide(tester, PlayerSide.second);

      final board = container.read(xiangqiBoardControllerProvider);
      expect(board.userSide, PlayerSide.second);
      expect(board.sideToMove, PlayerSide.first);
      expect(
        tester.getCenter(find.byKey(IntersectionBoard.pointKey(4, 9))).dy,
        greaterThan(
          tester.getCenter(find.byKey(IntersectionBoard.pointKey(4, 0))).dy,
        ),
      );
      expect(find.text(StatusLine.waitingLabel), findsOneWidget);
      expect(find.text('WHITE'), findsNothing);
    });

    group('no overflow at text scale 2.0', () {
      for (final size in const [
        Size(360, 640),
        Size(392, 800),
        Size(360, 800),
        Size(360, 600),
      ]) {
        testWidgets('${size.width.toInt()}x${size.height.toInt()}', (
          tester,
        ) async {
          await pumpNewGame(
            tester,
            game: GameKind.xiangqi,
            size: size,
            textScale: 2.0,
          );
          expect(tester.takeException(), isNull);

          await tapSide(tester, PlayerSide.first);
          expect(tester.takeException(), isNull);
          expect(find.byType(XiangqiBoard), findsOneWidget);
        });
      }
    });
  });
}
