import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cataland/app.dart';
import 'package:cataland/core/board/tap_board.dart';
import 'package:cataland/features/chess/data/chess_package_rules.dart';
import 'package:cataland/features/chess/domain/chess_models.dart';
import 'package:cataland/features/chess/presentation/chess_board_controller.dart';
import 'package:cataland/features/chess/presentation/widgets/promotion_chooser.dart';
import 'package:cataland/features/fair_play/domain/fair_play_notice.dart';
import 'package:cataland/features/fair_play/presentation/fair_play_controller.dart';
import 'package:cataland/features/new_game/presentation/new_game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Real app on the simulator. `SHOT:<name>` lines mark states that stay on
/// screen for [_hold] so an external script can capture them.
const _hold = Duration(seconds: 3);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Finder square(String name) {
    final s = ChessSquare.parse(name);
    return find.byKey(TapBoard.squareKey(s.file, s.rank));
  }

  Future<void> tapSquare(WidgetTester tester, String name) async {
    await tester.tap(square(name));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(ChessBoardController.commitGuard),
    );
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    debugPrint('SHOT:$name');
    await tester.runAsync(() => Future<void>.delayed(_hold));
  }

  Future<void> pumpApp(WidgetTester tester, ChessPackageRules rules) async {
    SharedPreferences.setMockInitialValues({
      FairPlayController.acknowledgedVersionKey: fairPlayNoticeVersion,
    });
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chessRulesProvider.overrideWithValue(rules),
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: const CatalandApp(),
      ),
    );
    await tester.tap(find.byKey(NewGameScreen.startKey));
    await tester.pumpAndSettle();
  }

  testWidgets('enter moves on the tap board', (tester) async {
    final rules = ChessPackageRules();
    await pumpApp(tester, rules);
    await shot(tester, 'initial');

    await tapSquare(tester, 'e4');
    expect(rules.toEnginePosition().moves, isEmpty);
    await shot(tester, 'white_e4_source');
    final stopwatch = Stopwatch()..start();
    await tapSquare(tester, 'e2');
    debugPrint(
      'E2 commit + frame: ${stopwatch.elapsedMilliseconds} ms '
      '(includes the ${ChessBoardController.commitGuard.inMilliseconds} '
      'ms guard wait)',
    );
    expect(rules.toEnginePosition().moves, ['e2e4']);

    await tapSquare(tester, 'f6');
    await shot(tester, 'black_f6_candidates');
    await tapSquare(tester, 'g8');
    expect(rules.toEnginePosition().moves, ['e2e4', 'g8f6']);

    await tapSquare(tester, 'g1');
    await shot(tester, 'white_g1_selected');
    await tapSquare(tester, 'f3');
    expect(rules.toEnginePosition().moves, ['e2e4', 'g8f6', 'g1f3']);
    await shot(tester, 'after_three_moves');
  });

  testWidgets('promotion chooser', (tester) async {
    final rules = ChessPackageRules(fen: '3r3k/2P1P3/8/8/8/8/8/K7 w - - 0 1');
    await pumpApp(tester, rules);
    await tapSquare(tester, 'd8');
    await shot(tester, 'promotion_sources');
    await tapSquare(tester, 'e7');
    expect(find.byType(PromotionChooser), findsOneWidget);
    await shot(tester, 'promotion_chooser');

    await tester.tap(find.byKey(PromotionChooser.choiceKey(PieceKind.knight)));
    await tester.pumpAndSettle();
    expect(
      rules.pieceAt(ChessSquare.parse('d8')),
      const ChessPiece(PieceColor.white, PieceKind.knight),
    );
    await shot(tester, 'promoted_knight');
  });
}
