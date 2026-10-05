import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spookymoove/core/game/player_side.dart';
import 'package:spookymoove/app.dart';
import 'package:spookymoove/core/board/tap_board.dart';
import 'package:spookymoove/features/advisor/presentation/advisor_screen.dart';
import 'package:spookymoove/features/chess/domain/chess_models.dart';
import 'package:spookymoove/features/chess/presentation/chess_board_controller.dart';
import 'package:spookymoove/features/fair_play/domain/fair_play_notice.dart';
import 'package:spookymoove/features/fair_play/presentation/fair_play_controller.dart';
import 'package:spookymoove/features/new_game/presentation/new_game_screen.dart';
import 'package:spookymoove/features/new_game/presentation/widgets/new_game_key.dart';
import 'package:spookymoove/features/persona/domain/persona_tier.dart';
import 'package:spookymoove/features/settings/presentation/language_dialog.dart';
import 'package:spookymoove/features/settings/presentation/settings_dialog.dart';
import 'package:spookymoove/features/persona/presentation/persona_tier_controller.dart';
import 'package:spookymoove/features/persona/presentation/widgets/persona_row.dart';
import 'package:spookymoove/features/new_game/presentation/game_session_controller.dart';
import 'package:spookymoove/features/new_game/presentation/home_screen.dart';
import 'package:spookymoove/features/advisor/presentation/suggestion_controller.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/status_line.dart';
import 'package:spookymoove/features/new_game/domain/game_kind.dart';
import 'package:spookymoove/features/xiangqi/presentation/widgets/xiangqi_board.dart';
import 'package:spookymoove/features/xiangqi/presentation/xiangqi_board_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Real app on the simulator. `SHOT:<name>` lines mark states that stay on
/// screen for [_hold] so an external script can capture them.
const _hold = Duration(seconds: 3);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  Future<void> tapSquare(WidgetTester tester, String name) async {
    final s = ChessSquare.parse(name);
    await tap(tester, TapBoard.squareKey(s.file, s.rank));
    await tester.runAsync(
      () => Future<void>.delayed(ChessBoardController.commitGuard),
    );
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    debugPrint('SHOT:$name');
    await tester.runAsync(() => Future<void>.delayed(_hold));
  }

  testWidgets('start, cancel, back out and restart a game', (tester) async {
    SharedPreferences.setMockInitialValues({
      FairPlayController.acknowledgedVersionKey: fairPlayNoticeVersion,
    });
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SpookyMooveApp(),
      ),
    );
    expect(find.byType(HomeScreen), findsOneWidget);
    await shot(tester, 'home_root');

    await tap(tester, HomeScreen.settingsKey);
    expect(find.text(SettingsDialog.emptyLabel), findsOneWidget);
    await shot(tester, 'settings_dialog');
    await tap(tester, SettingsDialog.closeKey);

    await tap(tester, HomeScreen.languageKey);
    expect(find.text('ENGLISH'), findsOneWidget);
    await shot(tester, 'language_dialog');
    await tap(tester, LanguageDialog.closeKey);
    expect(find.byType(LanguageDialog), findsNothing);

    await tap(tester, HomeScreen.gameKey(GameKind.chess));
    expect(find.text('CHESS'), findsOneWidget);
    await shot(tester, 'new_game_chess');
    await tap(tester, NewGameScreen.backKey);
    expect(find.byType(NewGameScreen), findsNothing);

    await tap(tester, HomeScreen.gameKey(GameKind.chess));
    await tap(tester, NewGameScreen.startKey);
    expect(find.byType(AdvisorScreen), findsOneWidget);
    expect(container.read(personaTierProvider), PersonaTier.even);
    await shot(tester, 'advisor_white_even');

    await tapSquare(tester, 'e2');
    await tapSquare(tester, 'e4');
    await tap(tester, PersonaRow.tierKey(PersonaTier.soft));
    await shot(tester, 'game_in_progress');

    await tap(tester, NewGameKey.regionKey);
    await shot(tester, 'confirm_dialog');
    await tap(tester, NewGameConfirmDialog.cancelKey);
    expect(container.read(personaTierProvider), PersonaTier.soft);

    await tap(tester, NewGameKey.regionKey);
    await tap(tester, NewGameConfirmDialog.confirmKey);
    expect(
      container.read(gameSessionProvider),
      isNull,
      reason: 'confirming discards the game',
    );
    await shot(tester, 'new_game_after_discard');
    await tap(tester, NewGameScreen.backKey);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('‹ BACK'), findsNothing);
    await shot(tester, 'home_after_discard');

    await tap(tester, HomeScreen.gameKey(GameKind.chess));
    await tap(tester, NewGameScreen.sideKey(PlayerSide.second));
    await tap(tester, NewGameScreen.startKey);
    final board = container.read(chessBoardControllerProvider);
    expect(board.userSide, PieceColor.black);
    expect(board.sideToMove, PieceColor.white);
    expect(board.pieces[ChessSquare.parse('e4')], isNull);
    expect(container.read(personaTierProvider), PersonaTier.even);
    await shot(tester, 'advisor_black_even');
  });

  testWidgets('pick XIANGQI, get a real suggestion, restart as BLACK', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      FairPlayController.acknowledgedVersionKey: fairPlayNoticeVersion,
    });
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SpookyMooveApp(),
      ),
    );

    await tap(tester, HomeScreen.gameKey(GameKind.xiangqi));
    expect(find.text('RED'), findsOneWidget);
    await shot(tester, 'new_game_xiangqi');

    await tap(tester, NewGameScreen.startKey);
    expect(find.byType(XiangqiBoard), findsOneWidget);
    expect(container.read(personaTierProvider), PersonaTier.even);
    final suggestion = await _waitFor(
      tester,
      () => container.read(suggestionControllerProvider) is SuggestionReady,
    );
    expect(suggestion, isTrue, reason: 'Fairy-Stockfish suggests for Red');
    final move = (container.read(
      suggestionControllerProvider,
    ) as SuggestionReady).engineMove;
    debugPrint('Xiangqi suggestion for Red: $move');
    expect(
      container.read(xiangqiBoardControllerProvider).suggestedMove?.uci,
      move,
    );
    expect(find.text('WHITE'), findsNothing);
    await shot(tester, 'advisor_xiangqi_red');

    await tap(tester, NewGameKey.regionKey);
    await tap(tester, NewGameConfirmDialog.confirmKey);
    expect(find.text('XIANGQI'), findsOneWidget);

    await tap(tester, NewGameScreen.sideKey(PlayerSide.second));
    await shot(tester, 'new_game_xiangqi_black');
    await tap(tester, NewGameScreen.startKey);
    final board = container.read(xiangqiBoardControllerProvider);
    expect(board.userSide, PlayerSide.second);
    expect(board.sideToMove, PlayerSide.first);
    expect(find.text(StatusLine.waitingLabel), findsOneWidget);
    expect(find.text('WHITE'), findsNothing);
    await shot(tester, 'advisor_xiangqi_black');
  });
}

/// Pumps real frames until [condition] holds or [timeout] passes.
Future<bool> _waitFor(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final stopwatch = Stopwatch()..start();
  while (!condition()) {
    if (stopwatch.elapsed > timeout) return false;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
  return true;
}
