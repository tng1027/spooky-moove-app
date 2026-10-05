import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/game/player_side.dart';
import 'package:spookymoove/core/board/tap_board.dart';
import 'package:spookymoove/core/theme/app_colors.dart';
import 'package:spookymoove/features/chess/data/chess_package_rules.dart';
import 'package:spookymoove/features/chess/domain/chess_models.dart';
import 'package:spookymoove/features/chess/presentation/chess_board_controller.dart';
import 'package:spookymoove/features/chess/presentation/widgets/chess_board.dart';
import 'package:spookymoove/features/chess/presentation/widgets/promotion_chooser.dart';
import 'package:spookymoove/core/l10n/app_strings.dart';
import 'package:spookymoove/features/settings/application/app_language_controller.dart';

const double boardSize = 360;

ChessSquare sq(String name) => ChessSquare.parse(name);

class BoardHarness {
  BoardHarness(this.tester, this.rules, this.container);

  final WidgetTester tester;
  final ChessPackageRules rules;
  final ProviderContainer container;

  ChessBoardController get controller =>
      container.read(chessBoardControllerProvider.notifier);

  Finder square(String name) {
    final s = sq(name);
    return find.byKey(TapBoard.squareKey(s.file, s.rank));
  }

  BoxDecoration decoration(String name) {
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(of: square(name), matching: find.byType(DecoratedBox))
          .first,
    );
    return box.decoration as BoxDecoration;
  }

  Color? fill(String name) => decoration(name).color;

  Color? outline(String name) =>
      (decoration(name).border as Border?)?.top.color;

  /// Taps a square and lets the commit guard pass.
  Future<void> tap(String name) async {
    await tester.tap(square(name));
    await tester.pump();
    clock += ChessBoardController.commitGuard;
  }

  Duration clock = Duration.zero;
}

Future<BoardHarness> pumpBoard(
  WidgetTester tester, {
  String? fen,
  List<String>? haptics,
}) async {
  tester.view.physicalSize = const Size(boardSize, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  if (haptics != null) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String);
        }
        return null;
      },
    );
  }

  final rules = ChessPackageRules(fen: fen);
  late BoardHarness harness;
  final container = ProviderContainer(
    overrides: [
      appStringsProvider.overrideWithValue(AppStrings.english),
      chessRulesProvider.overrideWithValue(rules),
      boardClockProvider.overrideWithValue(() => harness.clock),
    ],
  );
  addTearDown(container.dispose);
  harness = BoardHarness(tester, rules, container);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: ChessBoard(size: boardSize),
          ),
        ),
      ),
    ),
  );
  return harness;
}

void main() {
  testWidgets('initial position: inactive squares are dimmed and ignore taps', (
    tester,
  ) async {
    final haptics = <String>[];
    final board = await pumpBoard(tester, haptics: haptics);

    for (final name in ['e5', 'e8', 'd1', 'e1']) {
      expect(board.fill(name), AppColors.keyDisabled, reason: name);
    }
    expect(board.fill('e4'), isNot(AppColors.keyDisabled));
    expect(board.fill('e2'), isNot(AppColors.keyDisabled));

    await board.tap('e8');
    await board.tap('d1');
    expect(board.rules.moveCount, 0);
    expect(haptics, isEmpty);
  });

  testWidgets('E4 highlights only E2; tapping E2 commits with the '
      'move-accepted haptic', (tester) async {
    final haptics = <String>[];
    final board = await pumpBoard(tester, haptics: haptics);

    await board.tap('e4');
    expect(board.rules.moveCount, 0);
    expect(board.fill('e4'), AppColors.accentActive);
    expect(board.outline('e2'), AppColors.accentActive);
    expect(haptics, ['HapticFeedbackType.selectionClick']);

    await board.tap('e2');
    expect(board.rules.toEnginePosition().moves, ['e2e4']);
    expect(haptics.last, 'HapticFeedbackType.lightImpact');
  });

  testWidgets('a piece with one legal move still takes two taps', (
    tester,
  ) async {
    final board = await pumpBoard(tester, fen: 'k7/8/8/8/8/P7/8/K7 w - - 0 1');

    await board.tap('a3');
    expect(board.rules.moveCount, 0);
    expect(board.outline('a4'), AppColors.accentActive);

    await board.tap('a4');
    expect(board.rules.toEnginePosition().moves, ['a3a4']);
  });

  testWidgets('F3 highlights G1 and F2; tapping G1 commits G1-F3', (
    tester,
  ) async {
    final haptics = <String>[];
    final board = await pumpBoard(tester, haptics: haptics);

    await board.tap('f3');
    expect(board.fill('f3'), AppColors.accentActive);
    expect(board.outline('g1'), AppColors.accentActive);
    expect(board.outline('f2'), AppColors.accentActive);
    expect(board.outline('e2'), isNull);
    expect(haptics, ['HapticFeedbackType.selectionClick']);

    await board.tap('g1');
    expect(board.rules.toEnginePosition().moves, ['g1f3']);
    expect(board.outline('g1'), isNull);
  });

  testWidgets('tapping the selected square again clears the selection', (
    tester,
  ) async {
    final board = await pumpBoard(tester);
    final fenBefore = board.rules.fen;

    await board.tap('g1');
    expect(board.fill('g1'), AppColors.accentActive);
    await board.tap('g1');
    expect(board.fill('g1'), isNot(AppColors.accentActive));
    expect(board.rules.fen, fenBefore);
  });

  testWidgets('a rapid double tap commits only one move', (tester) async {
    final board = await pumpBoard(tester);

    for (final name in ['e4', 'e2', 'e5', 'e7']) {
      await tester.tap(board.square(name));
    }
    await tester.pump();

    expect(board.rules.toEnginePosition().moves, ['e2e4']);
  });

  testWidgets('the king in check is red', (tester) async {
    final board = await pumpBoard(
      tester,
      fen: '4r2k/8/8/8/R7/8/3P1P2/4K3 w - - 0 1',
    );
    expect(board.fill('e1'), AppColors.accentRed);
  });

  testWidgets('the suggestion and its castling rook squares are green', (
    tester,
  ) async {
    final board = await pumpBoard(
      tester,
      fen: 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
    );
    board.controller.showSuggestedMove(board.rules.moveFromUci('e1g1'));
    await tester.pump();

    for (final name in ['e1', 'g1', 'h1', 'f1']) {
      expect(board.outline(name), AppColors.accentGreen, reason: name);
    }
  });

  testWidgets('an en passant suggestion marks the pawn to remove', (
    tester,
  ) async {
    final board = await pumpBoard(
      tester,
      fen: 'rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3',
    );
    board.controller.showSuggestedMove(board.rules.moveFromUci('e5d6'));
    await tester.pump();

    for (final name in ['e5', 'd6', 'd5']) {
      expect(board.outline(name), AppColors.accentGreen, reason: name);
    }
    expect(
      find.descendant(of: board.square('d5'), matching: find.text('✕')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: board.square('d6'), matching: find.text('✕')),
      findsNothing,
    );
  });

  testWidgets('Black at the bottom: labels read H-A and 8-1', (tester) async {
    final board = await pumpBoard(tester);
    board.controller.newGame(PlayerSide.second);
    await tester.pump();

    final h = tester.getCenter(find.text('H'));
    final a = tester.getCenter(find.text('A'));
    final eight = tester.getCenter(find.text('8'));
    final one = tester.getCenter(find.text('1'));
    expect(h.dx, lessThan(a.dx));
    expect(eight.dy, greaterThan(one.dy));

    final e8 = tester.getCenter(board.square('e8'));
    final e1 = tester.getCenter(board.square('e1'));
    expect(e8.dy, greaterThan(e1.dy), reason: 'Black pieces at the bottom');
  });

  group('promotion', () {
    const fen = 'k7/4P3/8/8/8/8/8/K7 w - - 0 1';

    testWidgets('shows 4 pictograms, queen first, and commits a knight', (
      tester,
    ) async {
      final board = await pumpBoard(tester, fen: fen);
      await board.tap('e8');
      expect(find.byType(PromotionChooser), findsNothing);
      await board.tap('e7');

      final xs = [
        for (final kind in PieceKind.promotionChoices)
          tester.getCenter(find.byKey(PromotionChooser.choiceKey(kind))).dx,
      ];
      expect(xs, orderedEquals([...xs]..sort()));
      for (final kind in PieceKind.promotionChoices) {
        final key = tester.getSize(
          find.byKey(PromotionChooser.choiceKey(kind)),
        );
        expect(key.width, greaterThanOrEqualTo(48));
      }
      expect(
        find.descendant(
          of: find.byType(PromotionChooser),
          matching: find.byType(Text),
        ),
        findsNothing,
        reason: 'the chooser shows pictograms only',
      );
      final edgeLabels = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'};
      final allTexts = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .toSet();
      expect(
        allTexts.difference(edgeLabels).every((t) => int.tryParse(t!) != null),
        isTrue,
        reason: 'only edge labels A-H and 1-8 appear',
      );

      await tester.tap(
        find.byKey(PromotionChooser.choiceKey(PieceKind.knight)),
      );
      await tester.pump();

      expect(
        board.rules.pieceAt(sq('e8')),
        const ChessPiece(PieceColor.white, PieceKind.knight),
      );
      expect(find.byType(PromotionChooser), findsNothing);
    });

    testWidgets('tapping outside cancels and leaves the position unchanged', (
      tester,
    ) async {
      final board = await pumpBoard(tester, fen: fen);
      final fenBefore = board.rules.fen;
      await board.tap('e7');
      expect(find.byType(PromotionChooser), findsNothing);
      await board.tap('e8');
      expect(find.byType(PromotionChooser), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pump();

      expect(find.byType(PromotionChooser), findsNothing);
      expect(board.rules.fen, fenBefore);
    });

    testWidgets('the suggested piece is pre-highlighted', (tester) async {
      final board = await pumpBoard(tester, fen: fen);
      board.controller.showSuggestedMove(board.rules.moveFromUci('e7e8r'));
      await board.tap('e8');
      await board.tap('e7');

      final rookKey = tester.widget<Container>(
        find
            .descendant(
              of: find.byKey(PromotionChooser.choiceKey(PieceKind.rook)),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(
        (rookKey.decoration as BoxDecoration?)?.color,
        AppColors.accentActive,
      );
    });
  });
}
