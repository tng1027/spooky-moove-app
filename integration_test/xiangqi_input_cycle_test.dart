import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spookymoove/app.dart';
import 'package:spookymoove/core/board/intersection_board.dart';
import 'package:spookymoove/core/board/smart_entry.dart';
import 'package:spookymoove/core/game/player_side.dart';
import 'package:spookymoove/features/advisor/presentation/suggestion_controller.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/confirm_played_key.dart';
import 'package:spookymoove/features/fair_play/domain/fair_play_notice.dart';
import 'package:spookymoove/features/fair_play/presentation/fair_play_controller.dart';
import 'package:spookymoove/features/new_game/domain/game_kind.dart';
import 'package:spookymoove/features/new_game/presentation/home_screen.dart';
import 'package:spookymoove/features/new_game/presentation/new_game_screen.dart';
import 'package:spookymoove/features/xiangqi/domain/xiangqi_models.dart';
import 'package:spookymoove/features/xiangqi/presentation/xiangqi_board_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spookymoove/features/settings/application/app_language_controller.dart';

/// OB-010 Xiangqi pass: input cycle on the real app, playing BLACK at the
/// default level. Each cycle enters Red's move like a user (first tap on the
/// piece, second tap off the destination so it has to snap, OB-044 XQ3) and
/// ends when the suggestion is on screen; then I PLAYED IT. Frame timings
/// of the whole loop are summarised by `watchPerformance`.
///
/// ```
/// flutter test integration_test/xiangqi_input_cycle_test.dart -d <device>
/// flutter drive --profile --driver=test_driver/perf_driver.dart \
///   --target=integration_test/xiangqi_input_cycle_test.dart -d <device>
/// ```
///
/// Tap-to-tap time of a real user is not included (taps are instant here).
const _cycles = 10;
const _budgetMs = 1200;

/// Timers may fire slightly before the board's stopwatch reaches the guard.
const _guardMargin = Duration(milliseconds: 50);
const _orthogonal = [(1, 0), (-1, 0), (0, 1), (0, -1)];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  XiangqiBoardState board() => container.read(xiangqiBoardControllerProvider);
  SuggestionState suggestion() => container.read(suggestionControllerProvider);
  Finder point(XiangqiPoint p) =>
      find.byKey(IntersectionBoard.pointKey(p.file, p.rank));

  Future<void> wait(WidgetTester tester, Duration duration) =>
      tester.runAsync(() => Future<void>.delayed(duration));

  Future<void> launchAsBlack(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppLanguageController.languageKey: 'en',
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
    await tester.tap(find.byKey(HomeScreen.gameKey(GameKind.xiangqi)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NewGameScreen.sideKey(PlayerSide.second)));
    await tester.pump();
    await tester.tap(find.byKey(NewGameScreen.startKey));
    await tester.pumpAndSettle();
  }

  /// A board point next to [to] that is not a tap target, so a tap there
  /// only acts through snapping; null if every neighbour is a target.
  XiangqiPoint? offTargetNeighbour(XiangqiPoint to) {
    for (final (df, dr) in _orthogonal) {
      final file = to.file + df;
      final rank = to.rank + dr;
      if (file < 0 || file > 8 || rank < 0 || rank > 9) continue;
      final neighbour = XiangqiPoint(file, rank);
      if (!board().targets.contains(neighbour)) return neighbour;
    }
    return null;
  }

  Future<void> awaitSuggestion(WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < const Duration(seconds: 10)) {
      if (suggestion() is SuggestionReady) break;
      await wait(tester, const Duration(milliseconds: 5));
      await tester.pump();
    }
    expect(suggestion(), isA<SuggestionReady>());
  }

  testWidgets('Xiangqi input cycle with snapping', (tester) async {
    await launchAsBlack(tester);
    final times = <int>[];

    await binding.watchPerformance(() async {
      for (var cycle = 0; cycle < _cycles; cycle++) {
        if (board().isOver) break;
        final moves = board().legalMoves;
        final move = moves[(cycle * 7) % moves.length];
        await wait(tester, XiangqiBoardController.commitGuard + _guardMargin);

        final stopwatch = Stopwatch()..start();
        await tester.tap(point(move.from));
        await tester.pump();
        expect(
          board().entry,
          isA<SourceSelected<XiangqiPoint, XiangqiMove>>(),
          reason: 'first tap on ${move.uci}',
        );
        final neighbour = offTargetNeighbour(move.to);
        final snapped = neighbour != null;
        final at = snapped
            ? Offset.lerp(
                tester.getCenter(point(move.to)),
                tester.getCenter(point(neighbour)),
                0.6,
              )!
            : tester.getCenter(point(move.to));
        await tester.tapAt(at);
        await tester.pump();
        expect(
          board().sideToMove,
          PlayerSide.second,
          reason: 'second tap on ${move.uci}: ${board().entry}',
        );
        await awaitSuggestion(tester);
        stopwatch.stop();

        final ms = stopwatch.elapsedMilliseconds;
        times.add(ms);
        debugPrint(
          'CYCLE|$cycle|${move.uci}|snapped ${snapped ? 'yes' : 'no'}|$ms',
        );
        expect(board().sideToMove, PlayerSide.second, reason: move.uci);

        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ConfirmPlayedKey.regionKey));
        await tester.pumpAndSettle();
      }
    }, reportKey: 'xiangqi_frames');

    final sorted = [...times]..sort();
    int percentile(double p) => sorted[((sorted.length - 1) * p).round()];
    debugPrint(
      'SUMMARY|input cycle|n ${times.length}|median ${percentile(0.5)}'
      '|p95 ${percentile(0.95)}|max ${sorted.last}'
      '|over ${_budgetMs}ms ${times.where((t) => t > _budgetMs).length}',
    );
    final frames = binding.reportData?['xiangqi_frames'] as Map?;
    debugPrint(
      'FRAMES|${frames?.entries.where((e) => e.value is num).map((e) => '${e.key} ${e.value}').join('|')}',
    );
    expect(times, isNotEmpty);
  });
}
