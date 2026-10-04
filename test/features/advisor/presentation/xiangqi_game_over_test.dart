import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/app.dart';
import 'package:spookymoove/core/engine/engine_models.dart';
import 'package:spookymoove/core/game/game_result.dart';
import 'package:spookymoove/core/game/player_side.dart';
import 'package:spookymoove/core/theme/app_colors.dart';
import 'package:spookymoove/features/advisor/presentation/suggestion_controller.dart';
import 'package:spookymoove/features/advisor/presentation/suggestion_providers.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/confirm_played_key.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/status_line.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/top_bar.dart';
import 'package:spookymoove/features/chess/presentation/chess_board_controller.dart';
import 'package:spookymoove/features/fair_play/domain/fair_play_notice.dart';
import 'package:spookymoove/features/fair_play/presentation/fair_play_controller.dart';
import 'package:spookymoove/features/new_game/domain/game_kind.dart';
import 'package:spookymoove/features/new_game/presentation/game_registry.dart';
import 'package:spookymoove/features/new_game/presentation/game_session_controller.dart';
import 'package:spookymoove/features/new_game/presentation/home_screen.dart';
import 'package:spookymoove/features/new_game/presentation/new_game_screen.dart';
import 'package:spookymoove/features/persona/domain/persona_tier.dart';
import 'package:spookymoove/features/persona/presentation/persona_tier_controller.dart';
import 'package:spookymoove/features/xiangqi/data/dart_xiangqi_rules.dart';
import 'package:spookymoove/features/xiangqi/presentation/xiangqi_board_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../persona/fake_game_engine.dart';

/// Red to move; `a1a10` mates.
const _redMatesInOne = '4k4/1R7/9/9/9/9/9/9/9/R2K5 w - - 0 1';

/// Black to move; `a10a1` mates.
const _blackMatesInOne = 'r2k5/9/9/9/9/9/9/9/1r7/4K4 b - - 0 1';

/// Red to move; `h6g8` leaves Black no move, not in check.
const _redBlocksBlack = '4k4/9/9/9/7N1/3R1R3/9/9/9/3K5 w - - 0 1';

/// Black to move; `h5g3` leaves Red no move, not in check.
const _blackBlocksRed = '3k5/9/9/9/3r1r3/7n1/9/9/9/4K4 b - - 0 1';

class Harness {
  Harness(String fen) {
    container = ProviderContainer(
      overrides: [
        gameEngineProvider.overrideWithValue(engine),
        boardClockProvider.overrideWithValue(() => now),
        xiangqiRulesProvider.overrideWithValue(DartXiangqiRules(fen: fen)),
      ],
    );
    container.read(suggestionControllerProvider);
  }

  final FakeGameEngine engine = FakeGameEngine();
  late final ProviderContainer container;
  Duration now = Duration.zero;

  SuggestionState get state => container.read(suggestionControllerProvider);

  void start(PlayerSide side, [PersonaTier? tier]) => container
      .read(gameSessionProvider.notifier)
      .start(GameKind.xiangqi, side, tier);

  void play(String uci) {
    now += XiangqiBoardController.commitGuard;
    container.read(activeGameControllerProvider).commitEngineMove(uci);
  }

  void selectTier(PersonaTier tier) =>
      container.read(personaTierProvider.notifier).select(tier);

  GameResultHeadline? get headline => (state as SuggestionGameOver).headline;
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Harness harness(String fen) {
    final h = Harness(fen);
    addTearDown(h.container.dispose);
    return h;
  }

  group('through the seam', () {
    test('the opponent mates the user: result, no search, also after a '
        'tier change', () async {
      final h = harness(_blackMatesInOne)
        ..start(PlayerSide.first, PersonaTier.god);
      await settle();
      expect(h.state, isA<SuggestionWaiting>());

      h.play('a10a1');
      await settle();
      expect(
        h.headline,
        const GameResultHeadline('CHECKMATE — YOU LOSE', ResultTone.loss),
      );

      h.selectTier(PersonaTier.baby);
      await settle();
      expect(h.state, isA<SuggestionGameOver>());
      expect(h.engine.searches, isEmpty);
    });

    test('game over shows without a tier', () async {
      final h = harness(_blackMatesInOne)..start(PlayerSide.first);
      await settle();
      h.play('a10a1');
      await settle();
      expect(h.state, isA<SuggestionGameOver>());
      expect(h.engine.searches, isEmpty);
    });

    test("the user's confirmed mate wins; undo brings back the same "
        'suggestion without a new search', () async {
      final h = harness(_redMatesInOne)
        ..start(PlayerSide.first, PersonaTier.god);
      await settle();
      h.engine.last.complete([fakeLine(1, 'a1a10', const MateScore(1))]);
      await settle();
      expect((h.state as SuggestionReady).engineMove, 'a1a10');

      h.play('a1a10');
      await settle();
      expect(
        h.headline,
        const GameResultHeadline('CHECKMATE — YOU WIN', ResultTone.win),
      );

      h.container.read(activeGameControllerProvider).undo();
      await settle();
      expect((h.state as SuggestionReady).engineMove, 'a1a10');
      expect(h.engine.searches, hasLength(1));
    });

    test('no moves for the opponent: NO MOVES / YOU WIN', () async {
      final h = harness(_redBlocksBlack)..start(PlayerSide.first);
      await settle();
      h.play('h6g8');
      await settle();
      expect(
        h.headline,
        const GameResultHeadline('NO MOVES — YOU WIN', ResultTone.win),
      );
    });

    test('no moves for the user: NO MOVES / YOU LOSE', () async {
      final h = harness(_blackBlocksRed)..start(PlayerSide.first);
      await settle();
      h.play('h5g3');
      await settle();
      expect(
        h.headline,
        const GameResultHeadline('NO MOVES — YOU LOSE', ResultTone.loss),
      );
    });

    test('repetitions and generals only: the game goes on', () async {
      final h = harness('4k4/9/9/9/9/9/9/9/9/3K5 w - - 0 1')
        ..start(PlayerSide.first, PersonaTier.god);
      await settle();
      for (var i = 0; i < 4; i++) {
        for (final uci in ['d1d2', 'e10e9', 'd2d1', 'e9e10']) {
          h.play(uci);
        }
      }
      await settle();
      expect(h.container.read(xiangqiBoardControllerProvider).isOver, isFalse);
      expect(h.state, isA<SuggestionThinking>());
    });
  });

  group('on screen', () {
    late FakeGameEngine engine;

    Future<void> pumpXiangqi(WidgetTester tester, String fen) async {
      tester.view.physicalSize = const Size(392, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({
        FairPlayController.acknowledgedVersionKey: fairPlayNoticeVersion,
      });
      final preferences = await SharedPreferences.getInstance();
      engine = FakeGameEngine();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            gameEngineProvider.overrideWithValue(engine),
            xiangqiRulesProvider.overrideWithValue(DartXiangqiRules(fen: fen)),
          ],
          child: const SpookyMooveApp(),
        ),
      );
      await tester.tap(find.byKey(HomeScreen.gameKey(GameKind.xiangqi)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(NewGameScreen.startKey));
      await tester.pumpAndSettle();
    }

    Color? colorOf(WidgetTester tester, String text) =>
        tester.widget<Text>(find.text(text)).style?.color;

    testWidgets('a confirmed mate: green result, GAME OVER, NEW GAME', (
      tester,
    ) async {
      await pumpXiangqi(tester, _redMatesInOne);
      engine.last.complete([fakeLine(1, 'a1a10', const MateScore(1))]);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ConfirmPlayedKey.regionKey));
      await tester.pumpAndSettle();
      expect(colorOf(tester, 'CHECKMATE'), AppColors.accentGreen);
      expect(colorOf(tester, 'YOU WIN'), AppColors.accentGreen);
      expect(find.text(TopBar.gameOverLabel), findsOneWidget);
      expect(find.byKey(StatusLine.newGameKey), findsOneWidget);
      expect(find.byKey(ConfirmPlayedKey.regionKey), findsNothing);
    });

    testWidgets('game-over NEW GAME discards the game, opens XIANGQI', (
      tester,
    ) async {
      await pumpXiangqi(tester, _redMatesInOne);
      engine.last.complete([fakeLine(1, 'a1a10', const MateScore(1))]);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ConfirmPlayedKey.regionKey));
      await tester.pumpAndSettle();
      await tester.pump(StatusLine.newGameTapGuard);

      await tester.tap(find.byKey(StatusLine.newGameKey));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SpookyMooveApp)),
      );
      expect(container.read(gameSessionProvider), isNull);
      final screen = tester.widget<NewGameScreen>(find.byType(NewGameScreen));
      expect(screen.game, GameKind.xiangqi);

      await tester.tap(find.byKey(NewGameScreen.backKey));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('BACK'), findsNothing);
    });

    testWidgets('no moves for the user: red NO MOVES / YOU LOSE', (
      tester,
    ) async {
      await pumpXiangqi(tester, '3k5/9/9/9/3r1r3/9/9/6n2/9/4K4 w - - 0 1');
      expect(colorOf(tester, 'NO MOVES'), AppColors.accentRed);
      expect(colorOf(tester, 'YOU LOSE'), AppColors.accentRed);
      expect(find.textContaining('STALEMATE'), findsNothing);
      expect(find.textContaining('DRAW'), findsNothing);
      expect(engine.searches, isEmpty);
    });
  });
}
