import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/game/game_result.dart';
import 'package:spookymoove/core/game/player_side.dart';
import 'package:spookymoove/features/chess/data/chess_package_rules.dart';
import 'package:spookymoove/features/chess/domain/chess_models.dart';
import 'package:spookymoove/features/chess/presentation/chess_board_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  (ProviderContainer, ChessBoardController) setUp(String? fen) {
    final container = ProviderContainer(
      overrides: [
        chessRulesProvider.overrideWithValue(ChessPackageRules(fen: fen)),
        boardClockProvider.overrideWithValue(() => const Duration(days: 1)),
      ],
    );
    addTearDown(container.dispose);
    return (container, container.read(chessBoardControllerProvider.notifier));
  }

  test('start position: White to move, 20 moves, nothing to undo', () {
    final (container, _) = setUp(null);
    final state = chessActiveGameState(
      container.read(chessBoardControllerProvider),
    );
    expect(state.sideToMove, PlayerSide.first);
    expect(state.legalMoveCount, 20);
    expect(state.isOver, isFalse);
    expect(state.canUndo, isFalse);
    expect(state.isEntryBlocked, isFalse);
    expect(state.isInCheck, isFalse);
  });

  test('an open promotion chooser blocks confirming and can be undone', () {
    final (container, controller) = setUp('k7/4P3/8/8/8/8/8/K7 w - - 0 1');
    controller
      ..tap(ChessSquare.parse('e8'))
      ..tap(ChessSquare.parse('e7'));
    final state = chessActiveGameState(
      container.read(chessBoardControllerProvider),
    );
    expect(state.isEntryBlocked, isTrue);
    expect(state.canUndo, isTrue);
  });

  test('newGame maps the second side to Black', () {
    final (container, controller) = setUp(null);
    controller.newGame(PlayerSide.second);
    expect(
      container.read(chessBoardControllerProvider).userSide,
      PieceColor.black,
    );
  });

  test('the user mated: a loss headline; a new position id per move', () {
    final (container, controller) = setUp(
      'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq g3 0 2',
    );
    final before = chessActiveGameState(
      container.read(chessBoardControllerProvider),
    );
    controller.commitEngineMove('d8h4');
    final after = chessActiveGameState(
      container.read(chessBoardControllerProvider),
    );
    expect(identical(after.positionId, before.positionId), isFalse);
    expect(after.isOver, isTrue);
    expect(
      after.headline,
      const GameResultHeadline('CHECKMATE — YOU LOSE', ResultTone.loss),
    );
  });

  test('showSuggestion rejects an illegal engine move and clears', () {
    final (container, controller) = setUp(null);
    expect(controller.showSuggestion('e2e4'), isTrue);
    expect(
      container.read(chessBoardControllerProvider).suggestedMove?.uci,
      'e2e4',
    );
    expect(controller.showSuggestion('e2e5'), isFalse);
    expect(container.read(chessBoardControllerProvider).suggestedMove, isNull);
  });
}
