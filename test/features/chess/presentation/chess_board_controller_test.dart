import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cataland/core/game/player_side.dart';
import 'package:cataland/features/chess/data/chess_package_rules.dart';
import 'package:cataland/features/chess/domain/chess_game_status.dart';
import 'package:cataland/features/chess/domain/chess_models.dart';
import 'package:cataland/features/chess/domain/move_entry.dart';
import 'package:cataland/features/chess/presentation/chess_board_controller.dart';

import '../fake_chess_rules.dart';

ChessSquare sq(String name) => ChessSquare.parse(name);

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

  final knightMoves = [
    ChessMove(from: sq('g1'), to: sq('f3')),
    ChessMove(from: sq('g1'), to: sq('h3')),
  ];

  (ProviderContainer, FakeChessRules) setUpController(List<ChessMove> moves) {
    final rules = FakeChessRules(
      pieces: {sq('g1'): const ChessPiece(PieceColor.white, PieceKind.knight)},
      legalMoves: moves,
    );
    final container = ProviderContainer(
      overrides: [
        chessRulesProvider.overrideWithValue(rules),
        boardClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    return (container, rules);
  }

  test('selecting plays selectionClick, committing applies the move', () {
    final (container, rules) = setUpController(knightMoves);
    final controller = container.read(chessBoardControllerProvider.notifier);

    controller.tap(sq('g1'));
    expect(
      container.read(chessBoardControllerProvider).entry,
      isA<SourceSelected>(),
    );
    expect(haptics, ['HapticFeedbackType.selectionClick']);

    controller.tap(sq('h3'));
    expect(rules.applied, [knightMoves[1]]);
    expect(
      container.read(chessBoardControllerProvider).entry,
      const EntryIdle(),
    );
    expect(haptics.last, 'HapticFeedbackType.lightImpact');
  });

  test('taps right after a commit are ignored', () {
    final single = [ChessMove(from: sq('g1'), to: sq('f3'))];
    final (container, rules) = setUpController(single);
    final controller = container.read(chessBoardControllerProvider.notifier);

    controller
      ..tap(sq('f3'))
      ..tap(sq('g1'));
    expect(rules.applied, hasLength(1));

    controller.tap(sq('f3'));
    expect(
      container.read(chessBoardControllerProvider).entry,
      const EntryIdle(),
    );

    now += ChessBoardController.commitGuard;
    controller
      ..tap(sq('f3'))
      ..tap(sq('g1'));
    expect(rules.applied, hasLength(2));
  });

  test('cancelEntry clears a selection without haptics', () {
    final (container, _) = setUpController(knightMoves);
    final controller = container.read(chessBoardControllerProvider.notifier);

    controller.tap(sq('g1'));
    haptics.clear();
    controller.cancelEntry();
    expect(
      container.read(chessBoardControllerProvider).entry,
      const EntryIdle(),
    );
    expect(haptics, isEmpty);
  });

  test('a commit keeps the user side and drops the suggestion', () {
    final (container, _) = setUpController(knightMoves);
    final controller = container.read(chessBoardControllerProvider.notifier);

    controller
      ..newGame(PlayerSide.second)
      ..showSuggestedMove(knightMoves[0]);
    expect(
      container.read(chessBoardControllerProvider).suggestedMove,
      knightMoves[0],
    );

    controller
      ..tap(sq('g1'))
      ..tap(sq('f3'));
    final state = container.read(chessBoardControllerProvider);
    expect(state.userSide, PieceColor.black);
    expect(state.suggestedMove, isNull);
  });

  test('newGame resets the rules, entry, suggestion and commit guard', () {
    final (container, rules) = setUpController(knightMoves);
    final controller = container.read(chessBoardControllerProvider.notifier);

    controller
      ..tap(sq('g1'))
      ..tap(sq('f3'))
      ..tap(sq('g1'))
      ..showSuggestedMove(knightMoves[1]);
    expect(rules.applied, hasLength(1));

    controller.newGame(PlayerSide.second);
    final state = container.read(chessBoardControllerProvider);
    expect(rules.applied, isEmpty);
    expect(state.entry, const EntryIdle());
    expect(state.suggestedMove, isNull);
    expect(state.userSide, PieceColor.black);

    controller.tap(sq('g1'));
    expect(
      container.read(chessBoardControllerProvider).entry,
      isA<SourceSelected>(),
    );
  });

  ProviderContainer realRules(String fen) {
    final container = ProviderContainer(
      overrides: [
        chessRulesProvider.overrideWithValue(ChessPackageRules(fen: fen)),
        boardClockProvider.overrideWithValue(
          () => now += ChessBoardController.commitGuard,
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('checkmate ends entry: every square dimmed, taps ignored', () {
    final container = realRules(
      'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq g3 0 2',
    );
    final controller = container.read(chessBoardControllerProvider.notifier);
    controller
      ..tap(sq('d8'))
      ..tap(sq('h4'));

    final state = container.read(chessBoardControllerProvider);
    expect(state.status, const ChessCheckmate(winner: PieceColor.black));
    expect(state.activeSquares, isEmpty);

    controller.tap(sq('e1'));
    expect(
      container.read(chessBoardControllerProvider).entry,
      isA<EntryIdle>(),
    );
  });

  test('an automatic draw with legal moves left still blocks entry', () {
    final container = realRules('8/8/8/4k3/8/8/8/4KN2 w - - 0 1');
    final controller = container.read(chessBoardControllerProvider.notifier);
    final state = container.read(chessBoardControllerProvider);
    expect(
      state.status,
      const ChessDraw(reason: DrawReason.insufficientMaterial),
    );
    expect(state.legalMoves, isNotEmpty);
    expect(state.activeSquares, isEmpty);

    controller
      ..tap(sq('f1'))
      ..tap(sq('g3'));
    final after = container.read(chessBoardControllerProvider);
    expect(after.entry, isA<EntryIdle>());
    expect(after.pieces[sq('f1')], isNotNull);
  });

  group('undo', () {
    const startFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

    void play(ProviderContainer container, String uci) {
      final controller = container.read(chessBoardControllerProvider.notifier);
      controller.tap(sq(uci.substring(0, 2)));
      if (container.read(chessBoardControllerProvider).entry is! EntryIdle) {
        controller.tap(sq(uci.substring(2, 4)));
      }
    }

    ChessBoardState stateOf(ProviderContainer c) =>
        c.read(chessBoardControllerProvider);

    test('unavailable before the first move, available after it', () {
      final c = realRules(startFen);
      expect(stateOf(c).canUndo, isFalse);
      c.read(chessBoardControllerProvider.notifier).undo();
      expect(haptics, isEmpty, reason: 'nothing to undo');

      play(c, 'e2e4');
      expect(stateOf(c).canUndo, isTrue);
    });

    test('restores pieces, side to move and availability', () {
      final c = realRules(startFen);
      play(c, 'e2e4');
      haptics.clear();

      c.read(chessBoardControllerProvider.notifier).undo();
      final state = stateOf(c);
      expect(state.pieces[sq('e2')], isNotNull);
      expect(state.pieces[sq('e4')], isNull);
      expect(state.sideToMove, PieceColor.white);
      expect(state.canUndo, isFalse);
      expect(haptics, ['HapticFeedbackType.selectionClick']);
    });

    test('one move per tap back to the start position', () {
      final c = realRules(startFen);
      final start = stateOf(c).pieces;
      for (final uci in ['e2e4', 'e7e5', 'g1f3']) {
        play(c, uci);
      }
      final controller = c.read(chessBoardControllerProvider.notifier);
      controller.undo();
      expect(stateOf(c).sideToMove, PieceColor.white);
      controller
        ..undo()
        ..undo();
      expect(stateOf(c).pieces, start);
      expect(stateOf(c).canUndo, isFalse);
    });

    test('clears a selection and undoes the move in one tap', () {
      final c = realRules(startFen);
      play(c, 'e2e4');
      final controller = c.read(chessBoardControllerProvider.notifier);
      controller.tap(sq('g8'));
      expect(stateOf(c).entry, isA<SourceSelected>());

      controller.undo();
      expect(stateOf(c).entry, const EntryIdle());
      expect(stateOf(c).pieces[sq('e2')], isNotNull);
    });

    test('an open promotion chooser is closed first; the next tap undoes', () {
      final c = realRules('7k/4P3/8/8/8/8/8/K7 b - - 0 1');
      play(c, 'h8g8');
      final controller = c.read(chessBoardControllerProvider.notifier);
      controller.tap(sq('e7'));
      if (stateOf(c).entry is! PromotionPending) controller.tap(sq('e8'));
      expect(stateOf(c).entry, isA<PromotionPending>());

      controller.undo();
      expect(stateOf(c).entry, const EntryIdle());
      expect(stateOf(c).pieces[sq('g8')], isNotNull, reason: 'position kept');

      controller.undo();
      expect(stateOf(c).pieces[sq('h8')], isNotNull);
      expect(stateOf(c).sideToMove, PieceColor.black);
    });

    test('from checkmate: the game resumes and taps work again', () {
      final c = realRules(
        'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq g3 0 2',
      );
      play(c, 'd8h4');
      expect(stateOf(c).status.isOver, isTrue);

      c.read(chessBoardControllerProvider.notifier).undo();
      expect(stateOf(c).status, const ChessInProgress());
      expect(stateOf(c).activeSquares, isNotEmpty);

      c.read(chessBoardControllerProvider.notifier).tap(sq('d8'));
      expect(stateOf(c).entry, isA<SourceSelected>());
    });
  });

  group('commit (OB-041)', () {
    ChessBoardState stateOf(ProviderContainer c) =>
        c.read(chessBoardControllerProvider);

    ChessMove legal(ProviderContainer c, String uci) =>
        stateOf(c).legalMoves.firstWhere((move) => move.uci == uci);

    void commit(ProviderContainer c, ChessMove move) =>
        c.read(chessBoardControllerProvider.notifier).commit(move);

    test('applies the move with the move-accepted haptic', () {
      final (container, rules) = setUpController(knightMoves);
      commit(container, knightMoves[0]);

      expect(rules.applied, [knightMoves[0]]);
      expect(haptics, ['HapticFeedbackType.lightImpact']);
    });

    test('clears a pending selection', () {
      final (container, rules) = setUpController(knightMoves);
      container.read(chessBoardControllerProvider.notifier).tap(sq('g1'));
      expect(stateOf(container).entry, isA<SourceSelected>());

      commit(container, knightMoves[1]);
      expect(rules.applied, [knightMoves[1]]);
      expect(stateOf(container).entry, const EntryIdle());
    });

    test('ignores an illegal move', () {
      final (container, rules) = setUpController(knightMoves);
      commit(container, ChessMove(from: sq('g1'), to: sq('e2')));

      expect(rules.applied, isEmpty);
      expect(haptics, isEmpty);
    });

    test('ignores a second commit within the double-tap guard', () {
      final (container, rules) = setUpController(knightMoves);
      commit(container, knightMoves[0]);
      commit(container, knightMoves[1]);
      expect(rules.applied, hasLength(1));

      now += ChessBoardController.commitGuard;
      commit(container, knightMoves[1]);
      expect(rules.applied, hasLength(2));
    });

    test('ignored once the game is over', () {
      final c = realRules('8/8/8/4k3/8/8/8/4KN2 w - - 0 1');
      commit(c, legal(c, 'f1g3'));
      expect(stateOf(c).pieces[sq('f1')], isNotNull);
    });

    test('castling also moves the rook', () {
      final c = realRules('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
      commit(c, legal(c, 'e1g1'));

      final pieces = stateOf(c).pieces;
      expect(
        pieces[sq('g1')],
        const ChessPiece(PieceColor.white, PieceKind.king),
      );
      expect(
        pieces[sq('f1')],
        const ChessPiece(PieceColor.white, PieceKind.rook),
      );
      expect(pieces[sq('h1')], isNull);
    });

    test('en passant removes the captured pawn', () {
      final c = realRules('k7/8/8/3pP3/8/8/8/K7 w - d6 0 1');
      commit(c, legal(c, 'e5d6'));

      final pieces = stateOf(c).pieces;
      expect(
        pieces[sq('d6')],
        const ChessPiece(PieceColor.white, PieceKind.pawn),
      );
      expect(pieces[sq('d5')], isNull);
    });

    test('a promotion places the chosen piece without opening the chooser', () {
      final c = realRules('7k/4P3/8/8/8/8/8/K7 w - - 0 1');
      commit(c, legal(c, 'e7e8q'));

      final state = stateOf(c);
      expect(state.entry, const EntryIdle());
      expect(
        state.pieces[sq('e8')],
        const ChessPiece(PieceColor.white, PieceKind.queen),
      );
    });
  });

  test('a promotion choice is ignored once the game is over', () {
    final container = realRules('8/8/8/4k3/8/8/8/4KN2 w - - 0 1');
    container
        .read(chessBoardControllerProvider.notifier)
        .choosePromotion(PieceKind.queen);
    expect(
      container.read(chessBoardControllerProvider).entry,
      isA<EntryIdle>(),
    );
  });
}
