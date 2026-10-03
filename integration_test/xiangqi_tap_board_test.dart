import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cataland/core/board/intersection_board.dart';
import 'package:cataland/core/game/player_side.dart';
import 'package:cataland/core/theme/app_theme.dart';
import 'package:cataland/features/advisor/presentation/advisor_screen.dart';
import 'package:cataland/features/xiangqi/data/dart_xiangqi_rules.dart';
import 'package:cataland/features/xiangqi/domain/xiangqi_models.dart';
import 'package:cataland/features/xiangqi/presentation/xiangqi_board_controller.dart';
import 'package:cataland/features/xiangqi/presentation/widgets/xiangqi_board.dart';

/// Xiangqi board on the simulator, started programmatically (the new-game
/// entry comes with OB-045). `SHOT:<name>` lines mark states that stay on
/// screen for [_hold] so an external script can capture them.
const _hold = Duration(seconds: 3);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Finder point(String name) {
    final p = XiangqiPoint.parse(name);
    return find.byKey(IntersectionBoard.pointKey(p.file, p.rank));
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(XiangqiBoardController.commitGuard),
    );
  }

  Future<void> tapPoint(WidgetTester tester, String name) async {
    await tester.tap(point(name));
    await settle(tester);
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    debugPrint('SHOT:$name');
    await tester.runAsync(() => Future<void>.delayed(_hold));
  }

  testWidgets('enter Xiangqi moves on the intersection board', (tester) async {
    final rules = DartXiangqiRules();
    final container = ProviderContainer(
      overrides: [xiangqiRulesProvider.overrideWithValue(rules)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => Center(
                  child: XiangqiBoard(
                    size: AdvisorScreen.boardSizeFor(
                      constraints.biggest,
                      files: XiangqiPoint.files,
                      ranks: XiangqiPoint.ranks,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final controller = container.read(xiangqiBoardControllerProvider.notifier)
      ..newGame(PlayerSide.first);
    await shot(tester, 'xiangqi_initial');

    await tapPoint(tester, 'h3');
    await shot(tester, 'xiangqi_h3_selected');
    await tapPoint(tester, 'e3');
    expect(rules.toEnginePosition().moves, ['h3e3']);

    // Only the A7 soldier reaches A6: it is offered, and a second tap picks it.
    await tapPoint(tester, 'a6');
    expect(rules.toEnginePosition().moves, ['h3e3']);
    await shot(tester, 'xiangqi_a6_single_source');
    await tapPoint(tester, 'a7');
    expect(rules.toEnginePosition().moves, ['h3e3', 'a7a6']);

    // Select the A1 chariot, then tap inside B2's cell near A2: snaps to A2.
    await tapPoint(tester, 'a1');
    await shot(tester, 'xiangqi_a1_selected');
    final b2 = tester.getRect(point('b2'));
    await tester.tapAt(Offset(b2.left + b2.width * 0.1, b2.center.dy));
    await settle(tester);
    expect(rules.toEnginePosition().moves, ['h3e3', 'a7a6', 'a1a2']);
    await shot(tester, 'xiangqi_after_snap');

    controller.undo();
    await settle(tester);
    expect(rules.toEnginePosition().moves, ['h3e3', 'a7a6']);
    expect(
      rules.pieceAt(XiangqiPoint.parse('a1'))?.kind,
      XiangqiPieceKind.chariot,
    );

    // The E3 cannon captures E7 over the E4 soldier.
    expect(controller.showSuggestion('e3e7'), isTrue);
    await shot(tester, 'xiangqi_suggestion');

    controller.newGame(PlayerSide.second);
    await shot(tester, 'xiangqi_black_bottom');
  });
}
