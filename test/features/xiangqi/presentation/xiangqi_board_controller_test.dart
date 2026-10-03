import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cataland/core/board/board_clock.dart';
import 'package:cataland/core/board/smart_entry.dart';
import 'package:cataland/core/game/game_result.dart';
import 'package:cataland/core/game/player_side.dart';
import 'package:cataland/features/xiangqi/data/dart_xiangqi_rules.dart';
import 'package:cataland/features/xiangqi/domain/xiangqi_game_status.dart';
import 'package:cataland/features/xiangqi/domain/xiangqi_models.dart';
import 'package:cataland/features/xiangqi/presentation/xiangqi_board_controller.dart';

XiangqiPoint pt(String name) => XiangqiPoint.parse(name);

const twoChariotsFen = '3k5/9/9/9/9/9/9/9/R7R/4K4 w - - 0 1';
const checkmateFen = '3k5/3R5/3R5/9/9/9/9/9/9/4K4 b - - 0 1';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> haptics;
  late Duration now;

  setUp(() {
    haptics = [];
    now = Duration.zero;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String);
        }
        return null;
      },
    );
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  (ProviderContainer, DartXiangqiRules) setUpController({String? fen}) {
    final rules = DartXiangqiRules(fen: fen);
    final container = ProviderContainer(
      overrides: [
        xiangqiRulesProvider.overrideWithValue(rules),
        boardClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    return (container, rules);
  }

  XiangqiBoardState read(ProviderContainer container) =>
      container.read(xiangqiBoardControllerProvider);

  XiangqiBoardController controllerOf(ProviderContainer container) =>
      container.read(xiangqiBoardControllerProvider.notifier);

  test('initial snapshot: Red to move, 32 pieces, idle targets = active', () {
    final (container, _) = setUpController();
    final state = read(container);
    expect(state.pieces, hasLength(32));
    expect(state.sideToMove, PlayerSide.first);
    expect(state.legalMoves, hasLength(44));
    expect(state.targets, same(state.activePoints));
    expect(state.activePoints, contains(pt('h3')));
    expect(state.activePoints, isNot(contains(pt('d10'))));
    expect(state.checkedGeneral, isNull);
    expect(state.canUndo, isFalse);
  });

  test('selecting the H3 cannon then E3 commits with lightImpact', () {
    final (container, rules) = setUpController();
    final controller = controllerOf(container);

    controller.tap(pt('h3'));
    final selected = read(container).entry;
    expect(selected, isA<SourceSelected<XiangqiPoint, XiangqiMove>>());
    final destinations =
        (selected as SourceSelected<XiangqiPoint, XiangqiMove>).destinations;
    expect(destinations, containsAll([pt('e3'), pt('h10'), pt('h4')]));
    expect(read(container).targets, {pt('h3'), ...destinations});
    expect(haptics, ['HapticFeedbackType.selectionClick']);

    controller.tap(pt('e3'));
    expect(rules.moveCount, 1);
    expect(read(container).pieces[pt('e3')]?.kind, XiangqiPieceKind.cannon);
    expect(read(container).entry, const XiangqiEntryIdle());
    expect(read(container).sideToMove, PlayerSide.second);
    expect(haptics.last, 'HapticFeedbackType.lightImpact');
  });

  test('a destination reachable by one piece still takes two taps', () {
    final (container, rules) = setUpController();
    final controller = controllerOf(container);
    // Only the A1 chariot reaches A2.
    controller.tap(pt('a2'));
    expect(rules.moveCount, 0);
    expect(read(container).targets, {pt('a2'), pt('a1')});

    controller.tap(pt('a1'));
    expect(rules.moveCount, 1);
    expect(read(container).pieces[pt('a2')]?.kind, XiangqiPieceKind.chariot);
  });

  test('two sources are both candidates and tapping one commits', () {
    final (container, rules) = setUpController(fen: twoChariotsFen);
    final controller = controllerOf(container);

    controller.tap(pt('e2'));
    final entry = read(container).entry;
    expect(entry, isA<DestinationSelected<XiangqiPoint, XiangqiMove>>());
    final sources =
        (entry as DestinationSelected<XiangqiPoint, XiangqiMove>).sources;
    expect(sources, containsAll([pt('a2'), pt('i2')]));
    expect(read(container).targets, {pt('e2'), ...sources});

    controller.tap(pt('a2'));
    expect(rules.moveCount, 1);
    expect(read(container).pieces[pt('e2')]?.kind, XiangqiPieceKind.chariot);
    expect(read(container).pieces[pt('a2')], isNull);
  });

  test('tapping the selected point again or cancelEntry clears it', () {
    final (container, _) = setUpController();
    final controller = controllerOf(container);

    controller.tap(pt('h3'));
    controller.tap(pt('h3'));
    expect(read(container).entry, const XiangqiEntryIdle());

    controller.tap(pt('h3'));
    controller.cancelEntry();
    expect(read(container).entry, const XiangqiEntryIdle());
    expect(read(container).targets, read(container).activePoints);
  });

  test('a dimmed point changes nothing and plays no haptic', () {
    final (container, _) = setUpController();
    final before = read(container);
    controllerOf(container).tap(pt('d4'));
    expect(read(container), same(before));
    expect(haptics, isEmpty);
  });

  test('taps within 250 ms after a commit are ignored', () {
    final (container, rules) = setUpController();
    final controller = controllerOf(container);

    controller
      ..tap(pt('a2'))
      ..tap(pt('a1'));
    now += const Duration(milliseconds: 249);
    controller.tap(pt('a9'));
    expect(read(container).entry, const XiangqiEntryIdle());
    expect(rules.moveCount, 1);

    now += const Duration(milliseconds: 1);
    controller
      ..tap(pt('a9'))
      ..tap(pt('a10'));
    expect(rules.moveCount, 2);
  });

  test(
    'undo restores the earlier snapshot and clears selection and suggestion',
    () {
      final (container, rules) = setUpController();
      final controller = controllerOf(container);
      final before = read(container);

      controller
        ..tap(pt('a2'))
        ..tap(pt('a1'));
      now += XiangqiBoardController.commitGuard;
      controller.showSuggestion('h10g8');
      controller.tap(pt('h8'));
      expect(read(container).entry, isNot(const XiangqiEntryIdle()));
      haptics.clear();

      controller.undo();
      final after = read(container);
      expect(rules.moveCount, 0);
      expect(after.pieces, before.pieces);
      expect(after.legalMoves, before.legalMoves);
      expect(after.entry, const XiangqiEntryIdle());
      expect(after.suggestedMove, isNull);
      expect(after.canUndo, isFalse);
      expect(haptics, ['HapticFeedbackType.selectionClick']);

      controller.undo();
      expect(haptics, hasLength(1));
    },
  );

  test('newGame resets the position and sets the orientation', () {
    final (container, rules) = setUpController();
    final controller = controllerOf(container)
      ..tap(pt('a2'))
      ..tap(pt('a1'));

    controller.newGame(PlayerSide.second);
    expect(rules.moveCount, 0);
    expect(read(container).userSide, PlayerSide.second);
    expect(read(container).pieces, hasLength(32));

    // The commit guard is reset: the first taps of the new game count.
    controller
      ..tap(pt('a2'))
      ..tap(pt('a1'));
    expect(rules.moveCount, 1);
    expect(read(container).userSide, PlayerSide.second);
  });

  test('showSuggestion highlights a legal move and rejects an illegal one', () {
    final (container, _) = setUpController();
    final controller = controllerOf(container);

    expect(controller.showSuggestion('h3e3'), isTrue);
    expect(read(container).suggestedMove?.uci, 'h3e3');

    expect(controller.showSuggestion('a1a5'), isFalse);
    expect(read(container).suggestedMove, isNull);

    controller.showSuggestion('h3e3');
    expect(controller.showSuggestion(null), isTrue);
    expect(read(container).suggestedMove, isNull);
  });

  test('commitEngineMove applies legal engine moves only', () {
    final (container, rules) = setUpController();
    final controller = controllerOf(container);

    controller.commitEngineMove('a1a5');
    expect(rules.moveCount, 0);

    controller.commitEngineMove('h3e3');
    expect(rules.moveCount, 1);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
    expect(controller.enginePosition().moves, ['h3e3']);
  });

  test('no legal moves: game over, nothing active, taps ignored', () {
    final (container, rules) = setUpController(fen: checkmateFen);
    final state = read(container);
    expect(state.isOver, isTrue);
    expect(state.activePoints, isEmpty);
    expect(state.targets, isEmpty);
    expect(state.checkedGeneral, pt('d10'));

    controllerOf(container).tap(pt('d10'));
    expect(read(container), same(state));
    expect(rules.moveCount, 0);
  });

  group('game end', () {
    const mateInOneFen = '4k4/1R7/9/9/9/9/9/9/9/R2K5 w - - 0 1';

    test('a mating move ends the game; undo resumes it', () {
      final (container, _) = setUpController(fen: mateInOneFen);
      final controller = controllerOf(container);
      final activeBefore = read(container).activePoints;

      controller.commitEngineMove('a1a10');
      final over = read(container);
      expect(
        over.status,
        const XiangqiLoss(
          winner: PlayerSide.first,
          reason: XiangqiEndReason.checkmate,
        ),
      );
      expect(over.activePoints, isEmpty);
      expect(
        xiangqiActiveGameState(over).headline,
        const GameResultHeadline('CHECKMATE — YOU WIN', ResultTone.win),
      );
      expect(xiangqiActiveGameState(over).hint, isNull);

      controller.undo();
      final resumed = read(container);
      expect(resumed.status, const XiangqiInProgress());
      expect(resumed.activePoints, activeBefore);
      expect(xiangqiActiveGameState(resumed).isOver, isFalse);
    });

    test('the headline follows the user side', () {
      final (container, _) = setUpController(fen: mateInOneFen);
      final controller = controllerOf(container)..newGame(PlayerSide.second);
      controller.commitEngineMove('a1a10');
      expect(
        xiangqiActiveGameState(read(container)).headline,
        const GameResultHeadline('CHECKMATE — YOU LOSE', ResultTone.loss),
      );
    });

    test('several undos back to the start', () {
      final (container, rules) = setUpController();
      final controller = controllerOf(container);
      for (final uci in ['h3e3', 'h10g8', 'h1g3']) {
        now += XiangqiBoardController.commitGuard;
        controller.commitEngineMove(uci);
      }
      expect(rules.moveCount, 3);
      controller
        ..undo()
        ..undo()
        ..undo();
      expect(read(container).status, const XiangqiInProgress());
      expect(read(container).activePoints, isNotEmpty);
      expect(read(container).canUndo, isFalse);
    });
  });

  group('xiangqiActiveGameState', () {
    test('maps the board for the advisor layer', () {
      final (container, _) = setUpController();
      final controller = controllerOf(container);
      var game = xiangqiActiveGameState(read(container));
      expect(game.sideToMove, PlayerSide.first);
      expect(game.legalMoveCount, 44);
      expect(game.isInCheck, isFalse);
      expect(game.canUndo, isFalse);
      expect(game.isEntryBlocked, isFalse);
      expect(game.headline, isNull);
      expect(game.isOver, isFalse);

      controller
        ..tap(pt('a2'))
        ..tap(pt('a1'));
      game = xiangqiActiveGameState(read(container));
      expect(game.sideToMove, PlayerSide.second);
      expect(game.canUndo, isTrue);
      expect(game.positionId, same(read(container).legalMoves));
    });

    test('a selection keeps the same position id', () {
      final (container, _) = setUpController();
      final before = xiangqiActiveGameState(read(container));
      controllerOf(container).tap(pt('h3'));
      expect(xiangqiActiveGameState(read(container)), before);
    });

    test('check is reported', () {
      final (container, _) = setUpController(fen: checkmateFen);
      expect(xiangqiActiveGameState(read(container)).isInCheck, isTrue);
    });
  });
}
