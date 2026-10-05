import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spookymoove/core/game/player_side.dart';
import 'package:spookymoove/app.dart';
import 'package:spookymoove/core/board/tap_board.dart';
import 'package:spookymoove/features/advisor/domain/eval_format.dart';
import 'package:spookymoove/features/advisor/presentation/suggestion_controller.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/confirm_played_key.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/status_line.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/suggestion_card.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/top_bar.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/undo_key.dart';
import 'package:spookymoove/features/chess/domain/chess_models.dart';
import 'package:spookymoove/features/chess/presentation/chess_board_controller.dart';
import 'package:spookymoove/features/fair_play/domain/fair_play_notice.dart';
import 'package:spookymoove/features/fair_play/presentation/fair_play_controller.dart';
import 'package:spookymoove/features/new_game/domain/game_kind.dart';
import 'package:spookymoove/features/new_game/presentation/home_screen.dart';
import 'package:spookymoove/features/new_game/presentation/new_game_screen.dart';
import 'package:spookymoove/features/persona/domain/persona_tier.dart';
import 'package:spookymoove/features/persona/presentation/persona_tier_controller.dart';
import 'package:spookymoove/features/persona/presentation/widgets/persona_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Real app and engine on the simulator (OB-025). `SHOT:<name>` lines mark
/// states that stay on screen for [_hold] so an external script can capture
/// them.
const _hold = Duration(seconds: 3);

/// OB-021 D14.
const _budget = Duration(milliseconds: 1000);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    debugPrint('SHOT:$name');
    await tester.runAsync(() => Future<void>.delayed(_hold));
  }

  Future<void> openChess(WidgetTester tester) async {
    await tester.tap(find.byKey(HomeScreen.gameKey(GameKind.chess)));
    await tester.pumpAndSettle();
  }

  Future<void> tapSquare(WidgetTester tester, ChessSquare square) async {
    await tester.runAsync(
      () => Future<void>.delayed(ChessBoardController.commitGuard),
    );
    await tester.tap(find.byKey(TapBoard.squareKey(square.file, square.rank)));
    await tester.pump();
  }

  /// Enters [uci] like a user; the stopwatch starts before the committing tap.
  Future<Stopwatch> play(WidgetTester tester, String uci) async {
    await tapSquare(tester, ChessSquare.parse(uci.substring(0, 2)));
    final stopwatch = Stopwatch()..start();
    await tapSquare(tester, ChessSquare.parse(uci.substring(2, 4)));
    return stopwatch;
  }

  Future<(SuggestionReady, Duration)> awaitSuggestion(
    WidgetTester tester,
    Stopwatch stopwatch,
  ) async {
    final state = await tester.runAsync(() async {
      while (stopwatch.elapsed < const Duration(seconds: 5)) {
        final state = container.read(suggestionControllerProvider);
        if (state is SuggestionReady || state is SuggestionFailed) {
          return state;
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      return container.read(suggestionControllerProvider);
    });
    stopwatch.stop();
    await tester.pumpAndSettle();
    expect(state, isA<SuggestionReady>());
    return (state! as SuggestionReady, stopwatch.elapsed);
  }

  testWidgets('playing Black: opponent move, suggestion, own move', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      FairPlayController.acknowledgedVersionKey: fairPlayNoticeVersion,
    });
    final preferences = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SpookyMooveApp(),
      ),
    );
    await openChess(tester);
    await tester.tap(find.byKey(NewGameScreen.sideKey(PlayerSide.second)));
    await tester.pump();
    await tester.tap(find.byKey(NewGameScreen.startKey));
    await tester.pumpAndSettle();
    expect(container.read(personaTierProvider), PersonaTier.even);
    expect(find.text(StatusLine.waitingLabel), findsOneWidget);
    expect(find.text(SuggestionCard.emptyLine), findsOneWidget);
    expect(
      container.read(suggestionControllerProvider),
      isA<SuggestionWaiting>(),
    );
    await shot(tester, 'turn_opponent_first');

    final sinceOpponent = await play(tester, 'e2e4');
    final (suggestion, latency) = await awaitSuggestion(tester, sinceOpponent);
    debugPrint(
      'Even suggestion for Black: ${suggestion.engineMove} '
      'in ${latency.inMilliseconds} ms (incl. engine start)',
    );
    expect(find.byKey(ConfirmPlayedKey.regionKey), findsOneWidget);
    expect(
      ChessSquare.parse(suggestion.engineMove.substring(0, 2)).rank,
      greaterThanOrEqualTo(6),
    );
    await shot(tester, 'turn_your_move');

    // Override: a move other than the suggestion is entered on the board.
    final ownMove = suggestion.engineMove == 'd7d5' ? 'e7e5' : 'd7d5';
    await play(tester, ownMove);
    await tester.pumpAndSettle();
    expect(find.text(StatusLine.waitingLabel), findsOneWidget);
    expect(find.text(SuggestionCard.emptyLine), findsOneWidget);
    expect(container.read(chessBoardControllerProvider).suggestedMove, isNull);
    await shot(tester, 'turn_after_own_move');

    final sinceSecond = await play(tester, 'g1f3');
    final (_, secondLatency) = await awaitSuggestion(tester, sinceSecond);
    debugPrint('Second suggestion in ${secondLatency.inMilliseconds} ms');
    expect(secondLatency, lessThan(_budget));
    expect(find.byKey(ConfirmPlayedKey.regionKey), findsOneWidget);
  });

  testWidgets('I PLAYED IT commits the suggestion; undo brings it back', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      FairPlayController.acknowledgedVersionKey: fairPlayNoticeVersion,
    });
    final preferences = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SpookyMooveApp(),
      ),
    );
    await openChess(tester);
    final sinceStart = Stopwatch()..start();
    await tester.tap(find.byKey(NewGameScreen.startKey));
    await tester.pump();
    final (suggestion, _) = await awaitSuggestion(tester, sinceStart);
    await shot(tester, 'confirm_key_ready');

    await tester.tap(find.byKey(ConfirmPlayedKey.regionKey));
    await tester.pumpAndSettle();
    final board = container.read(chessBoardControllerProvider);
    expect(
      board
          .pieces[ChessSquare.parse(suggestion.engineMove.substring(2, 4))]
          ?.color,
      PieceColor.white,
    );
    expect(
      board.pieces[ChessSquare.parse(suggestion.engineMove.substring(0, 2))],
      isNull,
    );
    expect(board.sideToMove, PieceColor.black);
    expect(find.text(StatusLine.waitingLabel), findsOneWidget);
    expect(find.byKey(ConfirmPlayedKey.regionKey), findsNothing);
    await shot(tester, 'confirm_committed');

    await tester.tap(find.byKey(UndoKey.regionKey));
    await tester.pumpAndSettle();
    final restored = container.read(suggestionControllerProvider);
    expect((restored as SuggestionReady).engineMove, suggestion.engineMove);
    expect(find.byKey(ConfirmPlayedKey.regionKey), findsOneWidget);
  });

  testWidgets(
    'the opponent checkmates the user: result, board off, no search',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        FairPlayController.acknowledgedVersionKey: fairPlayNoticeVersion,
      });
      final preferences = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SpookyMooveApp(),
        ),
      );
      await openChess(tester);
      await tester.tap(find.byKey(NewGameScreen.startKey));
      await tester.pumpAndSettle();

      // The user ignores the Even suggestions and enters fool's mate.
      for (final uci in ['f2f3', 'e7e5', 'g2g4', 'd8h4']) {
        await play(tester, uci);
      }
      await tester.pumpAndSettle();

      final board = container.read(chessBoardControllerProvider);
      expect(board.activeSquares, isEmpty);
      expect(find.text('CHECKMATE'), findsOneWidget);
      expect(find.text('YOU LOSE'), findsOneWidget);
      expect(find.text(EvalFormat.unknownValue), findsNothing);
      expect(find.text(StatusLine.waitingLabel), findsNothing);
      expect(find.text(TopBar.gameOverLabel), findsOneWidget);
      expect(find.byKey(StatusLine.newGameKey), findsOneWidget);

      await tester.tap(find.byKey(PersonaRow.tierKey(PersonaTier.god)));
      await tester.pumpAndSettle();
      expect(
        container.read(suggestionControllerProvider),
        isA<SuggestionGameOver>(),
      );
      await shot(tester, 'game_over_checkmate');

      await tester.tap(find.byKey(UndoKey.regionKey));
      await tester.pumpAndSettle();
      expect(find.text('CHECKMATE'), findsNothing);
      expect(find.text(StatusLine.waitingLabel), findsOneWidget);
      expect(
        container.read(chessBoardControllerProvider).activeSquares,
        isNotEmpty,
      );
    },
  );

  testWidgets('undo brings back the same Baby suggestion', (tester) async {
    SharedPreferences.setMockInitialValues({
      FairPlayController.acknowledgedVersionKey: fairPlayNoticeVersion,
    });
    final preferences = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SpookyMooveApp(),
      ),
    );
    await openChess(tester);
    await tester.tap(find.byKey(NewGameScreen.tierKey(PersonaTier.baby)));
    await tester.pump();
    final sinceBaby = Stopwatch()..start();
    await tester.tap(find.byKey(NewGameScreen.startKey));
    await tester.pump();
    final (baby, _) = await awaitSuggestion(tester, sinceBaby);

    final other = baby.engineMove == 'e2e4' ? 'd2d4' : 'e2e4';
    await play(tester, other);
    await tester.pumpAndSettle();
    expect(find.text(StatusLine.waitingLabel), findsOneWidget);

    await tester.tap(find.byKey(UndoKey.regionKey));
    await tester.pumpAndSettle();
    final restored = container.read(suggestionControllerProvider);
    expect(restored, isA<SuggestionReady>());
    expect((restored as SuggestionReady).engineMove, baby.engineMove);
    expect(find.byKey(ConfirmPlayedKey.regionKey), findsOneWidget);
    await shot(tester, 'undo_restored_suggestion');
  });
}
