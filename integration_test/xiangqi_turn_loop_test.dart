import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cataland/app.dart';
import 'package:cataland/core/board/intersection_board.dart';
import 'package:cataland/core/game/player_side.dart';
import 'package:cataland/features/advisor/presentation/suggestion_controller.dart';
import 'package:cataland/features/advisor/presentation/widgets/confirm_played_key.dart';
import 'package:cataland/features/advisor/presentation/widgets/status_line.dart';
import 'package:cataland/features/advisor/presentation/widgets/suggestion_card.dart';
import 'package:cataland/features/advisor/presentation/widgets/undo_key.dart';
import 'package:cataland/features/fair_play/domain/fair_play_notice.dart';
import 'package:cataland/features/fair_play/presentation/fair_play_controller.dart';
import 'package:cataland/features/new_game/domain/game_kind.dart';
import 'package:cataland/features/new_game/presentation/home_screen.dart';
import 'package:cataland/features/new_game/presentation/new_game_screen.dart';
import 'package:cataland/features/persona/domain/persona_tier.dart';
import 'package:cataland/features/persona/presentation/persona_tier_controller.dart';
import 'package:cataland/features/persona/presentation/widgets/persona_row.dart';
import 'package:cataland/features/xiangqi/domain/xiangqi_models.dart';
import 'package:cataland/features/xiangqi/presentation/widgets/xiangqi_expert_line.dart';
import 'package:cataland/features/xiangqi/presentation/widgets/xiangqi_piece_disc.dart';
import 'package:cataland/features/xiangqi/presentation/xiangqi_board_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Xiangqi turn loop on the real app and engine (OB-046). `SHOT:<name>`
/// lines mark states that stay on screen for [_hold] so an external script
/// can capture them.
const _hold = Duration(seconds: 3);

final _wxfExpertLine = RegExp(r'^[KAEHRCP1-5][1-9+\-][+\-.][1-9] · EVAL ');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  XiangqiBoardState board() => container.read(xiangqiBoardControllerProvider);
  SuggestionState suggestion() => container.read(suggestionControllerProvider);

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    debugPrint('SHOT:$name');
    await tester.runAsync(() => Future<void>.delayed(_hold));
  }

  Future<void> launch(WidgetTester tester, PlayerSide side) async {
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
    await tester.tap(find.byKey(HomeScreen.gameKey(GameKind.xiangqi)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NewGameScreen.sideKey(side)));
    await tester.pump();
    await tester.tap(find.byKey(NewGameScreen.startKey));
    await tester.pumpAndSettle();
    expect(container.read(personaTierProvider), PersonaTier.even);
  }

  Future<void> tapPoint(WidgetTester tester, XiangqiPoint point) async {
    await tester.runAsync(
      () => Future<void>.delayed(XiangqiBoardController.commitGuard),
    );
    await tester.tap(
      find.byKey(IntersectionBoard.pointKey(point.file, point.rank)),
    );
    await tester.pump();
  }

  /// Enters [move] on the board like a user.
  Future<void> play(WidgetTester tester, XiangqiMove move) async {
    await tapPoint(tester, move.from);
    await tapPoint(tester, move.to);
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

  void expectCard(WidgetTester tester, SuggestionReady ready) {
    final move = board().legalMoves.firstWhere(
      (m) => m.uci == ready.engineMove,
    );
    final disc = tester.widget<XiangqiPieceDisc>(
      find.descendant(
        of: find.byKey(SuggestionCard.regionKey),
        matching: find.byType(XiangqiPieceDisc),
      ),
    );
    expect(disc.piece, board().pieces[move.from]);
    final expertLine = tester.widget<Text>(
      find.descendant(
        of: find.byType(XiangqiExpertLine),
        matching: find.byType(Text),
      ),
    );
    debugPrint('Card: ${ready.engineMove} / ${expertLine.data}');
    expect(expertLine.data, matches(_wxfExpertLine));
  }

  bool isConfirmEnabled(WidgetTester tester) => tester
      .widget<ConfirmPlayedKey>(find.byKey(ConfirmPlayedKey.regionKey))
      .isEnabled;

  testWidgets('Red: confirm, reply, override, undo, tier change', (
    tester,
  ) async {
    await launch(tester, PlayerSide.first);
    final first = await awaitSuggestion(tester);
    expectCard(tester, first);
    await shot(tester, 'xq_loop_suggestion');

    await tester.tap(find.byKey(ConfirmPlayedKey.regionKey));
    await tester.pumpAndSettle();
    expect(
      container
          .read(xiangqiBoardControllerProvider.notifier)
          .enginePosition()
          .moves,
      [first.engineMove],
    );
    expect(board().sideToMove, PlayerSide.second);
    expect(find.text(StatusLine.waitingLabel), findsOneWidget);
    await shot(tester, 'xq_loop_confirmed');

    await play(tester, board().legalMoves.first);
    final second = await awaitSuggestion(tester);
    expectCard(tester, second);
    await shot(tester, 'xq_loop_second_suggestion');

    final override = board().legalMoves.firstWhere(
      (m) => m.uci != second.engineMove,
    );
    await play(tester, override);
    expect(
      container
          .read(xiangqiBoardControllerProvider.notifier)
          .enginePosition()
          .moves
          .last,
      override.uci,
    );
    expect(board().suggestedMove, isNull);
    expect(find.text(StatusLine.waitingLabel), findsOneWidget);
    await shot(tester, 'xq_loop_override');

    await tester.tap(find.byKey(UndoKey.regionKey));
    await tester.pump();
    final restored = suggestion();
    expect(restored, isA<SuggestionReady>(), reason: 'cached, no new search');
    expect((restored as SuggestionReady).engineMove, second.engineMove);
    await tester.pumpAndSettle();
    expect(isConfirmEnabled(tester), isTrue);
    await shot(tester, 'xq_loop_undo_restored');

    await tester.tap(find.byKey(PersonaRow.tierKey(PersonaTier.god)));
    await tester.pump();
    expect(suggestion(), isA<SuggestionThinking>());
    expect(find.byKey(ConfirmPlayedKey.regionKey), findsOneWidget);
    expect(isConfirmEnabled(tester), isFalse);
    await awaitSuggestion(tester);
    expect(isConfirmEnabled(tester), isTrue);
  });

  testWidgets('Black: no suggestion until Red moves', (tester) async {
    await launch(tester, PlayerSide.second);
    expect(suggestion(), isA<SuggestionWaiting>());
    expect(find.text(StatusLine.waitingLabel), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(SuggestionCard.regionKey),
        matching: find.byType(XiangqiPieceDisc),
      ),
      findsNothing,
    );
    await shot(tester, 'xq_loop_black_waiting');

    await play(tester, board().legalMoves.firstWhere((m) => m.uci == 'h3e3'));
    final ready = await awaitSuggestion(tester);
    expect(
      board()
          .pieces[board().legalMoves
              .firstWhere((m) => m.uci == ready.engineMove)
              .from]
          ?.side,
      PlayerSide.second,
    );
    expectCard(tester, ready);
    await shot(tester, 'xq_loop_black_suggestion');
  });
}
