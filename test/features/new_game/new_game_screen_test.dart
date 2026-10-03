import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cataland/core/game/player_side.dart';
import 'package:cataland/app.dart';
import 'package:cataland/core/board/tap_board.dart';
import 'package:cataland/core/theme/app_dimens.dart';
import 'package:cataland/core/widgets/app_key.dart';
import 'package:cataland/features/advisor/presentation/advisor_screen.dart';
import 'package:cataland/features/advisor/presentation/widgets/suggestion_card.dart';
import 'package:cataland/features/chess/domain/chess_models.dart';
import 'package:cataland/features/chess/presentation/chess_board_controller.dart';
import 'package:cataland/features/fair_play/domain/fair_play_notice.dart';
import 'package:cataland/features/fair_play/presentation/fair_play_controller.dart';
import 'package:cataland/features/fair_play/presentation/fair_play_screen.dart';
import 'package:cataland/features/new_game/domain/game_kind.dart';
import 'package:cataland/features/new_game/presentation/game_session_controller.dart';
import 'package:cataland/features/new_game/presentation/new_game_screen.dart';
import 'package:cataland/features/new_game/presentation/widgets/new_game_key.dart';
import 'package:cataland/features/persona/domain/persona_tier.dart';
import 'package:cataland/features/persona/presentation/persona_tier_controller.dart';
import 'package:cataland/features/persona/presentation/widgets/persona_row.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cataland/core/board/intersection_board.dart';
import 'package:cataland/core/engine/engine_models.dart';
import 'package:cataland/features/advisor/presentation/suggestion_providers.dart';
import 'package:cataland/features/advisor/presentation/widgets/status_line.dart';
import 'package:cataland/features/chess/presentation/widgets/chess_board.dart';
import 'package:cataland/features/new_game/presentation/game_registry.dart';
import 'package:cataland/features/xiangqi/domain/xiangqi_models.dart';
import 'package:cataland/features/xiangqi/presentation/widgets/xiangqi_board.dart';
import 'package:cataland/features/xiangqi/presentation/widgets/xiangqi_piece_disc.dart';
import 'package:cataland/features/xiangqi/presentation/xiangqi_board_controller.dart';

import '../persona/fake_game_engine.dart';

ChessSquare sq(String name) => ChessSquare.parse(name);

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
      child: const CatalandApp(),
    ),
  );
  return ProviderScope.containerOf(tester.element(find.byType(CatalandApp)));
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

/// Starts as White, enters 1. e4 and picks the Soft tier.
Future<ProviderContainer> pumpGameInProgress(WidgetTester tester) async {
  final container = await pumpApp(tester);
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

void main() {
  group('first use', () {
    testWidgets('lists CHESS then XIANGQI, CHESS preselected, no BACK key', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.byType(NewGameScreen), findsOneWidget);
      final chess = find.byKey(NewGameScreen.gameKey(GameKind.chess));
      final xiangqi = find.byKey(NewGameScreen.gameKey(GameKind.xiangqi));
      expect(find.text('CHESS'), findsOneWidget);
      expect(find.text('XIANGQI'), findsOneWidget);
      expect(
        tester.getCenter(xiangqi).dy,
        greaterThan(tester.getCenter(chess).dy),
      );
      expect(tester.widget<AppKey>(chess).isSelected, isTrue);
      expect(tester.widget<AppKey>(xiangqi).isSelected, isFalse);
      expect(find.byKey(NewGameScreen.backKey), findsNothing);
    });

    testWidgets('defaults: Even and WHITE selected, nothing started yet', (
      tester,
    ) async {
      final container = await pumpApp(tester);

      expect(find.text('LEVEL · EVEN'), findsOneWidget);
      AppKey key(Key k) => tester.widget<AppKey>(find.byKey(k));
      expect(key(NewGameScreen.sideKey(PlayerSide.first)).isSelected, isTrue);
      expect(key(NewGameScreen.sideKey(PlayerSide.second)).isSelected, isFalse);
      expect(key(NewGameScreen.startKey).isPrimary, isTrue);
      expect(container.read(gameSessionProvider), isNull);
    });

    testWidgets('tapping a side selects it without starting', (tester) async {
      final container = await pumpApp(tester);

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
      final container = await pumpApp(tester);
      await tester.tap(find.byKey(NewGameScreen.startKey));
      await tester.pumpAndSettle();

      expect(find.byType(AdvisorScreen), findsOneWidget);
      expect(find.byType(NewGameScreen), findsNothing);
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

    testWidgets('BLACK puts Black at the bottom; White moves first', (
      tester,
    ) async {
      final container = await pumpApp(tester);
      await tapSide(tester, PlayerSide.second);

      final board = container.read(chessBoardControllerProvider);
      expect(board.userSide, PieceColor.black);
      expect(board.sideToMove, PieceColor.white);
      expect(
        tester.getCenter(square('e8')).dy,
        greaterThan(tester.getCenter(square('e1')).dy),
      );
    });

    testWidgets('FAIR PLAY opens the notice read-only and closes back', (
      tester,
    ) async {
      await pumpApp(tester);

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
      await pumpApp(tester, size: const Size(360, 640), textScale: 2.0);
      expect(tester.takeException(), isNull);

      await tapSide(tester, PlayerSide.first);
      expect(tester.takeException(), isNull);
      expect(find.byType(AdvisorScreen), findsOneWidget);
    });
  });

  testWidgets('a rapid double tap on START GAME starts one game', (
    tester,
  ) async {
    final starts = <(GameKind, PlayerSide, PersonaTier?)>[];
    await tester.pumpWidget(
      MaterialApp(
        home: NewGameScreen(
          onStart: (game, side, tier) => starts.add((game, side, tier)),
        ),
      ),
    );

    final start = find.byKey(NewGameScreen.startKey);
    await tester.tap(start);
    await tester.tap(start);
    await tester.pump();

    expect(starts, [(GameKind.chess, PlayerSide.first, PersonaTier.even)]);
  });

  group('LEVEL', () {
    Finder tierKey(PersonaTier tier) => find.byKey(NewGameScreen.tierKey(tier));

    testWidgets('shows the 7 tiers, Even selected, between GAME and SIDE', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(tester);

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
      final levelY = tester.getCenter(tierKey(PersonaTier.baby)).dy;
      expect(
        levelY,
        greaterThan(
          tester
              .getCenter(find.byKey(NewGameScreen.gameKey(GameKind.chess)))
              .dy,
        ),
      );
      expect(
        levelY,
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
      final container = await pumpApp(tester);

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
      await pumpApp(tester, size: const Size(360, 800));

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

    testWidgets('picking a level then BACK keeps the game and its tier', (
      tester,
    ) async {
      final container = await pumpGameInProgress(tester);
      await openNewGameConfirm(tester);
      await tester.tap(find.byKey(NewGameConfirmDialog.confirmKey));
      await tester.pumpAndSettle();

      await tester.tap(tierKey(PersonaTier.god));
      await tester.pump();
      await tester.tap(find.byKey(NewGameScreen.backKey));
      await tester.pumpAndSettle();

      expectGameInProgress(container);
    });

    testWidgets('a level picked mid-game starts the new game with it', (
      tester,
    ) async {
      final container = await pumpGameInProgress(tester);
      await openNewGameConfirm(tester);
      await tester.tap(find.byKey(NewGameConfirmDialog.confirmKey));
      await tester.pumpAndSettle();

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

    testWidgets('confirm then BACK returns to the unchanged game', (
      tester,
    ) async {
      final container = await pumpGameInProgress(tester);
      await openNewGameConfirm(tester);

      await tester.tap(find.byKey(NewGameConfirmDialog.confirmKey));
      await tester.pumpAndSettle();
      expect(find.byType(NewGameScreen), findsOneWidget);
      expect(find.byKey(NewGameScreen.backKey), findsOneWidget);

      await tester.tap(find.byKey(NewGameScreen.backKey));
      await tester.pumpAndSettle();

      expect(find.byType(NewGameScreen), findsNothing);
      expect(find.byType(AdvisorScreen), findsOneWidget);
      expectGameInProgress(container);
    });

    testWidgets(
      'confirm then START discards the game; the default tier applies',
      (tester) async {
        final container = await pumpGameInProgress(tester);
        await openNewGameConfirm(tester);
        await tester.tap(find.byKey(NewGameConfirmDialog.confirmKey));
        await tester.pumpAndSettle();

        await tapSide(tester, PlayerSide.second);

        expect(find.byType(NewGameScreen), findsNothing);
        expect(find.byType(AdvisorScreen), findsOneWidget);
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
    Finder gameKey(GameKind game) => find.byKey(NewGameScreen.gameKey(game));
    AppKey key(WidgetTester tester, Finder finder) =>
        tester.widget<AppKey>(finder);
    Finder sideKey(PlayerSide side) => find.byKey(NewGameScreen.sideKey(side));

    Future<void> selectGame(WidgetTester tester, GameKind game) async {
      await tester.ensureVisible(gameKey(game));
      await tester.tap(gameKey(game));
      await tester.pump();
    }

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

    testWidgets(
      'XIANGQI relabels the sides RED / BLACK with general discs, keeps '
      'side and level, and clicks',
      (tester) async {
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
        await pumpApp(tester);
        await tester.tap(find.byKey(NewGameScreen.tierKey(PersonaTier.soft)));
        await tester.pump();
        haptics.clear();

        await selectGame(tester, GameKind.xiangqi);

        expect(haptics, ['HapticFeedbackType.selectionClick']);
        expect(key(tester, gameKey(GameKind.xiangqi)).isSelected, isTrue);
        expect(key(tester, gameKey(GameKind.chess)).isSelected, isFalse);
        expect(find.text('RED'), findsOneWidget);
        expect(find.text('BLACK'), findsOneWidget);
        expect(find.text('WHITE'), findsNothing);
        expect(sideDiscs(tester), const [
          XiangqiPiece(PlayerSide.first, XiangqiPieceKind.general),
          XiangqiPiece(PlayerSide.second, XiangqiPieceKind.general),
        ]);
        expect(key(tester, sideKey(PlayerSide.first)).isSelected, isTrue);
        expect(find.text('LEVEL · SOFT'), findsOneWidget);

        await selectGame(tester, GameKind.xiangqi);
        expect(haptics, hasLength(1), reason: 'reselecting is a no-op');
      },
    );

    testWidgets('XIANGQI + BLACK, then CHESS keeps BLACK selected', (
      tester,
    ) async {
      await pumpApp(tester);
      await selectGame(tester, GameKind.xiangqi);
      await tester.ensureVisible(sideKey(PlayerSide.second));
      await tester.tap(sideKey(PlayerSide.second));
      await tester.pump();

      await selectGame(tester, GameKind.chess);

      expect(find.text('WHITE'), findsOneWidget);
      expect(find.text('RED'), findsNothing);
      expect(find.byType(XiangqiPieceDisc), findsNothing);
      expect(key(tester, sideKey(PlayerSide.second)).isSelected, isTrue);
    });

    testWidgets('initialGame preselects XIANGQI; START passes it on', (
      tester,
    ) async {
      final starts = <(GameKind, PlayerSide, PersonaTier?)>[];
      await tester.pumpWidget(
        MaterialApp(
          home: NewGameScreen(
            initialGame: GameKind.xiangqi,
            onStart: (game, side, tier) => starts.add((game, side, tier)),
          ),
        ),
      );

      expect(key(tester, gameKey(GameKind.xiangqi)).isSelected, isTrue);
      expect(find.text('RED'), findsOneWidget);
      await tester.tap(find.byKey(NewGameScreen.startKey));
      await tester.pump();

      expect(starts, [(GameKind.xiangqi, PlayerSide.first, PersonaTier.even)]);
    });

    testWidgets('game and side keys announce title-case names', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(tester);
      await selectGame(tester, GameKind.xiangqi);

      expect(
        tester.getSemantics(gameKey(GameKind.xiangqi)),
        matchesSemantics(
          label: 'Xiangqi',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(gameKey(GameKind.chess)),
        matchesSemantics(
          label: 'Chess',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
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

    testWidgets('a Chess game: confirm, XIANGQI, BACK keeps the Chess game', (
      tester,
    ) async {
      final container = await pumpGameInProgress(tester);
      await openNewGameConfirm(tester);
      await tester.tap(find.byKey(NewGameConfirmDialog.confirmKey));
      await tester.pumpAndSettle();
      expect(key(tester, gameKey(GameKind.chess)).isSelected, isTrue);

      await selectGame(tester, GameKind.xiangqi);
      await tester.tap(find.byKey(NewGameScreen.backKey));
      await tester.pumpAndSettle();

      expect(container.read(gameSessionProvider)?.game, GameKind.chess);
      expect(find.byType(ChessBoard), findsOneWidget);
      expectGameInProgress(container);
    });

    testWidgets('a Xiangqi game preselects XIANGQI on NEW GAME', (
      tester,
    ) async {
      await pumpApp(tester);
      await selectGame(tester, GameKind.xiangqi);
      await tapSide(tester, PlayerSide.first);
      expect(find.byType(XiangqiBoard), findsOneWidget);

      await openNewGameConfirm(tester);
      await tester.tap(find.byKey(NewGameConfirmDialog.confirmKey));
      await tester.pumpAndSettle();

      expect(key(tester, gameKey(GameKind.xiangqi)).isSelected, isTrue);
      expect(find.text('RED'), findsOneWidget);
    });

    testWidgets('START as RED: Xiangqi advisor, xiangqi variant, suggestion', (
      tester,
    ) async {
      final engine = FakeGameEngine();
      final container = await pumpApp(tester, engine: engine);
      await selectGame(tester, GameKind.xiangqi);
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
      final container = await pumpApp(tester);
      await selectGame(tester, GameKind.xiangqi);
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
          await pumpApp(tester, size: size, textScale: 2.0);
          await selectGame(tester, GameKind.xiangqi);
          expect(tester.takeException(), isNull);

          await tapSide(tester, PlayerSide.first);
          expect(tester.takeException(), isNull);
          expect(find.byType(XiangqiBoard), findsOneWidget);
        });
      }
    });
  });
}
