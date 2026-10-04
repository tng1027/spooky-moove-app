import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/board/board_clock.dart';
import 'package:spookymoove/core/board/intersection_board.dart';
import 'package:spookymoove/core/game/player_side.dart';
import 'package:spookymoove/core/theme/app_colors.dart';
import 'package:spookymoove/features/advisor/presentation/advisor_screen.dart';
import 'package:spookymoove/features/xiangqi/data/dart_xiangqi_rules.dart';
import 'package:spookymoove/features/xiangqi/domain/xiangqi_models.dart';
import 'package:spookymoove/features/xiangqi/presentation/xiangqi_board_controller.dart';
import 'package:spookymoove/features/xiangqi/presentation/widgets/xiangqi_board.dart';
import 'package:spookymoove/features/xiangqi/presentation/widgets/xiangqi_grid_painter.dart';
import 'package:spookymoove/features/xiangqi/presentation/widgets/xiangqi_piece_disc.dart';

const double cell = 40;
const Size boardSize = Size(9 * cell, 10 * cell);
const checkmateFen = '3k5/3R5/3R5/9/9/9/9/9/9/4K4 b - - 0 1';

class BoardHarness {
  BoardHarness(this.tester, this.rules, this.container);

  final WidgetTester tester;
  final DartXiangqiRules rules;
  final ProviderContainer container;
  Duration clock = Duration.zero;

  XiangqiBoardController get controller =>
      container.read(xiangqiBoardControllerProvider.notifier);

  Finder point(String name) {
    final p = XiangqiPoint.parse(name);
    return find.byKey(IntersectionBoard.pointKey(p.file, p.rank));
  }

  Iterable<BoxDecoration> _decorations(String name) => tester
      .widgetList<DecoratedBox>(
        find.descendant(of: point(name), matching: find.byType(DecoratedBox)),
      )
      .map((box) => box.decoration as BoxDecoration);

  Color? fill(String name) => _decorations(name).first.color;

  bool hasDot(String name, Color color) => _decorations(name).any(
    (d) => d.shape == BoxShape.circle && d.color == color && d.border == null,
  );

  bool hasRing(String name, Color color) => _decorations(name).any(
    (d) =>
        d.shape == BoxShape.circle &&
        d.color == null &&
        (d.border as Border?)?.top.color == color,
  );

  double? opacity(String name) {
    final finder = find.descendant(
      of: point(name),
      matching: find.byType(Opacity),
    );
    return finder.evaluate().isEmpty
        ? null
        : tester.widget<Opacity>(finder).opacity;
  }

  /// Taps a point's centre and lets the commit guard pass.
  Future<void> tap(String name) => tapAt(tester.getCenter(point(name)));

  Future<void> tapAt(Offset position) async {
    await tester.tapAt(position);
    await tester.pump();
    clock += XiangqiBoardController.commitGuard;
  }

  Offset get origin => tester.getTopLeft(find.byType(XiangqiBoard));
}

Future<BoardHarness> pumpBoard(
  WidgetTester tester, {
  String? fen,
  List<String>? haptics,
  Size viewSize = const Size(360, 800),
  Size size = boardSize,
  double textScale = 1,
}) async {
  tester.view.physicalSize = viewSize;
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
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }

  final rules = DartXiangqiRules(fen: fen);
  late BoardHarness harness;
  final container = ProviderContainer(
    overrides: [
      xiangqiRulesProvider.overrideWithValue(rules),
      boardClockProvider.overrideWithValue(() => harness.clock),
    ],
  );
  addTearDown(container.dispose);
  harness = BoardHarness(tester, rules, container);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: viewSize,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: XiangqiBoard(size: size),
            ),
          ),
        ),
      ),
    ),
  );
  return harness;
}

void main() {
  testWidgets('initial render: 90 points, grid, 32 discs, Red at the bottom', (
    tester,
  ) async {
    final board = await pumpBoard(tester);

    for (var file = 0; file < XiangqiPoint.files; file++) {
      for (var rank = 0; rank < XiangqiPoint.ranks; rank++) {
        expect(find.byKey(IntersectionBoard.pointKey(file, rank)), findsOne);
      }
    }
    expect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is XiangqiGridPainter,
      ),
      findsOne,
    );
    expect(find.byType(XiangqiPieceDisc), findsNWidgets(32));
    final redGeneral = tester.widget<XiangqiPieceDisc>(
      find.descendant(
        of: board.point('e1'),
        matching: find.byType(XiangqiPieceDisc),
      ),
    );
    expect(redGeneral.piece.side, PlayerSide.first);
    expect(
      tester.getCenter(board.point('e1')).dy,
      greaterThan(tester.getCenter(board.point('e10')).dy),
    );
    expect(tester.getSize(board.point('e1')), const Size(cell, cell));
    expect(
      tester.getTopLeft(find.text('A')).dx,
      lessThan(tester.getTopLeft(find.text('I')).dx),
    );
    expect(
      tester.getTopLeft(find.text('1')).dy,
      greaterThan(tester.getTopLeft(find.text('10')).dy),
    );
  });

  testWidgets('H3 selection: amber fill, dots incl. E3, capture ring on H10', (
    tester,
  ) async {
    final haptics = <String>[];
    final board = await pumpBoard(tester, haptics: haptics);

    await board.tap('h3');

    expect(board.fill('h3'), AppColors.accentActive);
    for (final name in ['e3', 'h4', 'h7', 'g3', 'i3']) {
      expect(board.hasDot(name, AppColors.accentActive), isTrue, reason: name);
    }
    expect(board.hasRing('h10', AppColors.accentActive), isTrue);
    expect(board.hasDot('h10', AppColors.accentActive), isFalse);
    expect(board.hasDot('e4', AppColors.accentActive), isFalse);
    expect(haptics, ['HapticFeedbackType.selectionClick']);
  });

  testWidgets('H3 then E3 commits once and clears the selection', (
    tester,
  ) async {
    final haptics = <String>[];
    final board = await pumpBoard(tester, haptics: haptics);

    await board.tap('h3');
    await board.tap('e3');

    expect(board.rules.toEnginePosition().moves, ['h3e3']);
    expect(haptics.last, 'HapticFeedbackType.lightImpact');
    expect(board.fill('h3'), isNull);
    expect(board.hasDot('e3', AppColors.accentActive), isFalse);
  });

  testWidgets('a tap between points snaps to the only target within a cell', (
    tester,
  ) async {
    final board = await pumpBoard(tester);
    await board.tap('a1');
    expect(board.fill('a1'), AppColors.accentActive);

    // Inside B2's cell (not a target), 25 px from A2's centre.
    await board.tapAt(board.origin + const Offset(cell + 5, 8.5 * cell));

    expect(board.rules.toEnginePosition().moves, ['a1a2']);
  });

  testWidgets('a tap equally near two targets changes nothing', (tester) async {
    final haptics = <String>[];
    final board = await pumpBoard(tester, haptics: haptics);
    await board.tap('a1');
    haptics.clear();

    // Inside B2's cell, on the line halfway between A2 and A3.
    await board.tapAt(board.origin + const Offset(cell + 5, 8 * cell));

    expect(board.rules.moveCount, 0);
    expect(board.fill('a1'), AppColors.accentActive);
    expect(haptics, isEmpty);
  });

  testWidgets('a tap far from every target cancels the selection', (
    tester,
  ) async {
    final board = await pumpBoard(tester);
    await board.tap('a1');

    await board.tap('e6');

    expect(board.fill('a1'), isNull);
    expect(board.rules.moveCount, 0);
  });

  testWidgets('the checked general cell is red', (tester) async {
    final board = await pumpBoard(tester, fen: checkmateFen);
    expect(board.fill('d10'), AppColors.accentRed);
    expect(board.fill('e1'), isNull);
  });

  testWidgets('Black at the bottom with labels I-A and 10-1', (tester) async {
    final board = await pumpBoard(tester);
    board.controller.newGame(PlayerSide.second);
    await tester.pump();

    expect(
      tester.getCenter(board.point('e10')).dy,
      greaterThan(tester.getCenter(board.point('e1')).dy),
    );
    expect(
      tester.getCenter(board.point('i1')).dx,
      lessThan(tester.getCenter(board.point('a1')).dx),
    );
    expect(
      tester.getTopLeft(find.text('I')).dx,
      lessThan(tester.getTopLeft(find.text('A')).dx),
    );
    expect(
      tester.getTopLeft(find.text('10')).dy,
      greaterThan(tester.getTopLeft(find.text('1')).dy),
    );
  });

  testWidgets('points outside every legal move are dimmed to 40 %', (
    tester,
  ) async {
    final board = await pumpBoard(tester);
    expect(board.opacity('d10'), IntersectionBoard.dimmedOpacity);
    expect(board.opacity('a10'), IntersectionBoard.dimmedOpacity);
    expect(board.opacity('h3'), isNull);
    expect(board.fill('d10'), isNull);
  });

  testWidgets(
    'suggestion: green ring on the piece, dot or ring on the target',
    (tester) async {
      final board = await pumpBoard(tester);

      board.controller.showSuggestion('h3e3');
      await tester.pump();
      expect(board.hasRing('h3', AppColors.accentGreen), isTrue);
      expect(board.hasDot('e3', AppColors.accentGreen), isTrue);

      board.controller.showSuggestion('h3h10');
      await tester.pump();
      expect(board.hasRing('h10', AppColors.accentGreen), isTrue);
      expect(board.hasDot('e3', AppColors.accentGreen), isFalse);
    },
  );

  group('no overflow at text scale 2.0', () {
    for (final view in const [Size(392, 800), Size(360, 800), Size(360, 600)]) {
      testWidgets('${view.width.toInt()}x${view.height.toInt()}', (
        tester,
      ) async {
        final size = AdvisorScreen.boardSizeFor(
          view,
          files: XiangqiPoint.files,
          ranks: XiangqiPoint.ranks,
        );
        final board = await pumpBoard(
          tester,
          viewSize: view,
          size: size,
          textScale: 2,
        );

        expect(tester.takeException(), isNull);
        final boardRect = board.origin & size;
        for (final name in ['a1', 'i1', 'a10', 'i10']) {
          final rect = tester.getRect(board.point(name));
          expect(
            boardRect.inflate(1e-6).contains(rect.topLeft) &&
                boardRect.inflate(1e-6).contains(rect.bottomRight),
            isTrue,
            reason: name,
          );
        }
      });
    }
  });
}
