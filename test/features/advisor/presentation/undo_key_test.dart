import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/theme/app_colors.dart';
import 'package:spookymoove/core/widgets/app_key.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/undo_key.dart';
import 'package:spookymoove/features/chess/data/chess_package_rules.dart';
import 'package:spookymoove/features/chess/domain/chess_models.dart';
import 'package:spookymoove/features/chess/presentation/chess_board_controller.dart';

void main() {
  late ProviderContainer container;
  var now = Duration.zero;

  Future<void> pumpUndoKey(WidgetTester tester) async {
    container = ProviderContainer(
      overrides: [
        chessRulesProvider.overrideWithValue(ChessPackageRules()),
        boardClockProvider.overrideWithValue(
          () => now += ChessBoardController.commitGuard,
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: Center(child: UndoKey())),
        ),
      ),
    );
  }

  AppKey appKey(WidgetTester tester) => tester.widget<AppKey>(
    find.descendant(
      of: find.byKey(UndoKey.regionKey),
      matching: find.byType(AppKey),
    ),
  );

  Color? labelColor(WidgetTester tester) =>
      tester.widget<Text>(find.text(UndoKey.label)).style?.color;

  void play(String from, String to) {
    container.read(chessBoardControllerProvider.notifier)
      ..tap(ChessSquare.parse(from))
      ..tap(ChessSquare.parse(to));
  }

  testWidgets('disabled before the first move', (tester) async {
    await pumpUndoKey(tester);

    expect(appKey(tester).onTap, isNull);
    expect(labelColor(tester), AppColors.textSecondary);
    expect(find.byIcon(Icons.undo), findsOneWidget);
  });

  testWidgets('enabled after a move; a tap undoes it', (tester) async {
    await pumpUndoKey(tester);
    play('e2', 'e4');
    await tester.pump();
    expect(appKey(tester).onTap, isNotNull);
    expect(labelColor(tester), AppColors.textPrimary);

    await tester.tap(find.byKey(UndoKey.regionKey));
    await tester.pump();
    final board = container.read(chessBoardControllerProvider);
    expect(board.pieces[ChessSquare.parse('e2')], isNotNull);
    expect(board.canUndo, isFalse);
    expect(appKey(tester).onTap, isNull);
  });
}
