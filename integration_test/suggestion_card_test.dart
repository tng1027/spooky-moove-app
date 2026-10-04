import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cataland/app.dart';
import 'package:cataland/core/board/tap_board.dart';
import 'package:cataland/features/advisor/presentation/suggestion_controller.dart';
import 'package:cataland/features/chess/domain/chess_models.dart';
import 'package:cataland/features/chess/presentation/chess_board_controller.dart';
import 'package:cataland/features/fair_play/domain/fair_play_notice.dart';
import 'package:cataland/features/fair_play/presentation/fair_play_controller.dart';
import 'package:cataland/features/new_game/domain/game_kind.dart';
import 'package:cataland/features/new_game/presentation/home_screen.dart';
import 'package:cataland/features/new_game/presentation/new_game_screen.dart';
import 'package:cataland/features/persona/domain/persona_tier.dart';
import 'package:cataland/features/persona/presentation/widgets/persona_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Real app and engine on the simulator. `SHOT:<name>` lines mark states
/// that stay on screen for [_hold] so an external script can capture them.
const _hold = Duration(seconds: 3);

/// OB-021 D14 / OB-007 BR-002.
const _budget = Duration(milliseconds: 1000);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    debugPrint('SHOT:$name');
    await tester.runAsync(() => Future<void>.delayed(_hold));
  }

  /// Waits out the commit guard first, so the tap that commits is the last
  /// thing that happens.
  Future<void> tapSquare(WidgetTester tester, ChessSquare square) async {
    await tester.runAsync(
      () => Future<void>.delayed(ChessBoardController.commitGuard),
    );
    await tester.tap(find.byKey(TapBoard.squareKey(square.file, square.rank)));
    await tester.pump();
  }

  /// Enters [uci] like a user: source, then destination.
  /// The returned stopwatch starts just before the committing tap.
  Future<Stopwatch> play(WidgetTester tester, String uci) async {
    await tapSquare(tester, ChessSquare.parse(uci.substring(0, 2)));
    final stopwatch = Stopwatch()..start();
    await tapSquare(tester, ChessSquare.parse(uci.substring(2, 4)));
    return stopwatch;
  }

  /// Waits in real time for a ready suggestion; returns it with the latency.
  Future<(SuggestionReady, Duration)> awaitSuggestion(
    WidgetTester tester, [
    Stopwatch? started,
  ]) async {
    final stopwatch = started ?? (Stopwatch()..start());
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

  testWidgets('tier-based suggestions on the user\'s turn', (tester) async {
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
        child: const CatalandApp(),
      ),
    );
    await tester.tap(find.byKey(HomeScreen.gameKey(GameKind.chess)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NewGameScreen.tierKey(PersonaTier.solid)));
    await tester.pump();
    final sinceSolid = Stopwatch()..start();
    await tester.tap(find.byKey(NewGameScreen.startKey));
    await tester.pump();
    final (first, firstLatency) = await awaitSuggestion(tester, sinceSolid);
    debugPrint(
      'First suggestion (incl. engine start): ${first.engineMove} '
      'in ${firstLatency.inMilliseconds} ms',
    );
    expect(
      container.read(chessBoardControllerProvider).suggestedMove?.uci,
      first.engineMove,
    );
    await shot(tester, 'suggestion_first');

    await play(tester, first.engineMove);
    expect(
      container.read(suggestionControllerProvider),
      isA<SuggestionWaiting>(),
    );
    final sinceReply = await play(tester, 'e7e5');
    final (reply, replyLatency) = await awaitSuggestion(tester, sinceReply);
    debugPrint(
      'Suggestion after the reply: ${reply.engineMove} '
      'in ${replyLatency.inMilliseconds} ms',
    );
    expect(replyLatency, lessThan(_budget));
    await shot(tester, 'suggestion_after_reply');

    final sinceBaby = Stopwatch()..start();
    await tester.tap(find.byKey(PersonaRow.tierKey(PersonaTier.baby)));
    await tester.pump();
    final (baby, babyLatency) = await awaitSuggestion(tester, sinceBaby);
    debugPrint(
      'Baby suggestion: ${baby.engineMove} in ${babyLatency.inMilliseconds} ms',
    );
    expect(babyLatency, lessThan(_budget));
    await shot(tester, 'suggestion_baby');
  });
}
