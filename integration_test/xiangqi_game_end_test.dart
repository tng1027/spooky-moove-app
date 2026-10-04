import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spookymoove/app.dart';
import 'package:spookymoove/core/board/intersection_board.dart';
import 'package:spookymoove/core/game/player_side.dart';
import 'package:spookymoove/features/advisor/presentation/suggestion_controller.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/confirm_played_key.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/status_line.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/top_bar.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/undo_key.dart';
import 'package:spookymoove/features/fair_play/domain/fair_play_notice.dart';
import 'package:spookymoove/features/fair_play/presentation/fair_play_controller.dart';
import 'package:spookymoove/features/new_game/domain/game_kind.dart';
import 'package:spookymoove/features/new_game/presentation/home_screen.dart';
import 'package:spookymoove/features/new_game/presentation/new_game_screen.dart';
import 'package:spookymoove/features/persona/domain/persona_tier.dart';
import 'package:spookymoove/features/persona/presentation/widgets/persona_row.dart';
import 'package:spookymoove/features/xiangqi/data/dart_xiangqi_rules.dart';
import 'package:spookymoove/features/xiangqi/domain/xiangqi_models.dart';
import 'package:spookymoove/features/xiangqi/presentation/xiangqi_board_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Xiangqi game end on the real app and engine (OB-047), started from
/// mate-in-1 positions. `SHOT:<name>` lines mark states that stay on screen
/// for [_hold] so an external script can capture them.
const _hold = Duration(seconds: 3);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  SuggestionState suggestion() => container.read(suggestionControllerProvider);

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    debugPrint('SHOT:$name');
    await tester.runAsync(() => Future<void>.delayed(_hold));
  }

  Future<void> launch(
    WidgetTester tester,
    String fen, {
    PersonaTier tier = PersonaTier.even,
  }) async {
    SharedPreferences.setMockInitialValues({
      FairPlayController.acknowledgedVersionKey: fairPlayNoticeVersion,
    });
    final preferences = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        xiangqiRulesProvider.overrideWithValue(DartXiangqiRules(fen: fen)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SpookyMooveApp(),
      ),
    );
    await tester.tap(find.byKey(HomeScreen.gameKey(GameKind.xiangqi)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NewGameScreen.tierKey(tier)));
    await tester.pump();
    await tester.tap(find.byKey(NewGameScreen.startKey));
    await tester.pumpAndSettle();
  }

  Future<SuggestionReady> awaitSuggestion(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < const Duration(seconds: 10)) {
      final state = suggestion();
      if (state is SuggestionReady || state is SuggestionFailed) break;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(suggestion(), isA<SuggestionReady>());
    return suggestion() as SuggestionReady;
  }

  Future<void> tapPoint(WidgetTester tester, String name) async {
    await tester.runAsync(
      () => Future<void>.delayed(XiangqiBoardController.commitGuard),
    );
    final point = XiangqiPoint.parse(name);
    await tester.tap(
      find.byKey(IntersectionBoard.pointKey(point.file, point.rank)),
    );
    await tester.pumpAndSettle();
  }

  void expectGameOver(String reason, String outcome) {
    expect(find.text(reason), findsOneWidget);
    expect(find.text(outcome), findsOneWidget);
    expect(find.text(TopBar.gameOverLabel), findsOneWidget);
    expect(find.byKey(StatusLine.newGameKey), findsOneWidget);
    expect(
      container.read(xiangqiBoardControllerProvider).activePoints,
      isEmpty,
    );
  }

  testWidgets('the user confirms a mate: YOU WIN; undo resumes', (
    tester,
  ) async {
    await launch(
      tester,
      '4k4/1R7/9/9/9/9/9/9/9/R2K5 w - - 0 1',
      tier: PersonaTier.god,
    );
    final mate = await awaitSuggestion(tester);
    debugPrint('God mate suggestion: ${mate.engineMove}');
    await shot(tester, 'xq_end_mate_suggested');

    await tester.tap(find.byKey(ConfirmPlayedKey.regionKey));
    await tester.pumpAndSettle();
    expectGameOver('CHECKMATE', 'YOU WIN');
    await shot(tester, 'xq_end_you_win');

    await tester.tap(find.byKey(UndoKey.regionKey));
    await tester.pump();
    expect((suggestion() as SuggestionReady).engineMove, mate.engineMove);
    await tester.pumpAndSettle();
    expect(find.byKey(ConfirmPlayedKey.regionKey), findsOneWidget);
  });

  testWidgets('the opponent mates the user: YOU LOSE, no search', (
    tester,
  ) async {
    await launch(tester, 'r2k5/9/9/9/9/9/9/9/1r7/4K4 b - - 0 1');
    expect(
      container.read(xiangqiBoardControllerProvider).userSide,
      PlayerSide.first,
    );
    expect(suggestion(), isA<SuggestionWaiting>());

    await tapPoint(tester, 'a10');
    await tapPoint(tester, 'a1');
    expectGameOver('CHECKMATE', 'YOU LOSE');

    await tester.tap(find.byKey(PersonaRow.tierKey(PersonaTier.god)));
    await tester.pumpAndSettle();
    expect(suggestion(), isA<SuggestionGameOver>());
    await shot(tester, 'xq_end_you_lose');
  });
}
