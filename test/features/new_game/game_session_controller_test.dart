import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/game/player_side.dart';
import 'package:spookymoove/features/chess/domain/chess_models.dart';
import 'package:spookymoove/features/chess/presentation/chess_board_controller.dart';
import 'package:spookymoove/features/new_game/domain/game_kind.dart';
import 'package:spookymoove/features/new_game/domain/game_session.dart';
import 'package:spookymoove/features/new_game/presentation/game_registry.dart';
import 'package:spookymoove/features/new_game/presentation/game_session_controller.dart';
import 'package:spookymoove/features/persona/domain/persona_tier.dart';
import 'package:spookymoove/features/persona/presentation/persona_tier_controller.dart';
import 'package:spookymoove/features/xiangqi/domain/xiangqi_models.dart';
import 'package:spookymoove/features/xiangqi/presentation/xiangqi_board_controller.dart';

import '../chess/fake_chess_rules.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final move = ChessMove(
    from: ChessSquare.parse('g1'),
    to: ChessSquare.parse('f3'),
  );

  (ProviderContainer, FakeChessRules) setUpContainer() {
    final rules = FakeChessRules(
      pieces: {
        ChessSquare.parse('g1'): const ChessPiece(
          PieceColor.white,
          PieceKind.knight,
        ),
      },
      legalMoves: [move],
    );
    final container = ProviderContainer(
      overrides: [chessRulesProvider.overrideWithValue(rules)],
    );
    addTearDown(container.dispose);
    return (container, rules);
  }

  test('there is no game until one is started', () {
    final (container, _) = setUpContainer();

    expect(container.read(gameSessionProvider), isNull);
  });

  test('start discards the game, sets the side and clears the tier', () {
    final (container, rules) = setUpContainer();
    container.read(chessBoardControllerProvider.notifier)
      ..tap(move.from)
      ..tap(move.to);
    container.read(personaTierProvider.notifier).select(PersonaTier.god);
    expect(rules.applied, [move]);

    container
        .read(gameSessionProvider.notifier)
        .start(GameKind.chess, PlayerSide.second);

    expect(
      container.read(gameSessionProvider),
      const GameSession(game: GameKind.chess, userSide: PlayerSide.second),
    );
    expect(rules.applied, isEmpty);
    expect(
      container.read(chessBoardControllerProvider).userSide,
      PieceColor.black,
    );
    expect(container.read(personaTierProvider), isNull);
  });

  test('start with a tier selects it for the new game', () {
    final (container, _) = setUpContainer();
    container.read(personaTierProvider.notifier).select(PersonaTier.god);

    container
        .read(gameSessionProvider.notifier)
        .start(GameKind.chess, PlayerSide.first, PersonaTier.soft);

    expect(container.read(personaTierProvider), PersonaTier.soft);
  });

  test('a Xiangqi session resets the Xiangqi board and becomes active', () {
    final (container, _) = setUpContainer();
    final xiangqi = container.read(xiangqiBoardControllerProvider.notifier);
    xiangqi
      ..tap(XiangqiPoint.parse('a2'))
      ..tap(XiangqiPoint.parse('a1'));
    expect(container.read(xiangqiBoardControllerProvider).canUndo, isTrue);

    container
        .read(gameSessionProvider.notifier)
        .start(GameKind.xiangqi, PlayerSide.second);

    final board = container.read(xiangqiBoardControllerProvider);
    expect(board.canUndo, isFalse);
    expect(board.userSide, PlayerSide.second);
    expect(container.read(activeGameKindProvider), GameKind.xiangqi);
    expect(container.read(activeGameControllerProvider), same(xiangqi));
    expect(container.read(activeEngineVariantProvider), 'xiangqi');
    final state = container.read(container.read(activeGameStateSourceProvider));
    expect(state.sideToMove, PlayerSide.first);
    expect(state.legalMoveCount, 44);
  });
}
