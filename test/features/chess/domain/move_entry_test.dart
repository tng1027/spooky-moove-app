import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/features/chess/data/chess_package_rules.dart';
import 'package:spookymoove/features/chess/domain/chess_models.dart';
import 'package:spookymoove/features/chess/domain/move_entry.dart';

ChessSquare sq(String name) => ChessSquare.parse(name);

List<ChessMove> movesOf(String? fen) => ChessPackageRules(fen: fen).legalMoves;

/// Taps [squares] in order from idle and returns the last outcome.
EntryOutcome tapAll(List<ChessMove> moves, List<String> squares) {
  EntryState state = const EntryIdle();
  late EntryOutcome outcome;
  for (final name in squares) {
    outcome = MoveEntry.tap(state, sq(name), moves);
    state = outcome.state;
  }
  return outcome;
}

void main() {
  final initial = movesOf(null);

  test('E4 offers only E2; tapping E2 commits E2-E4', () {
    final first = tapAll(initial, ['e4']);
    expect(first.committed, isNull);
    expect((first.state as DestinationSelected).sources, {sq('e2')});

    final outcome = tapAll(initial, ['e4', 'e2']);
    expect(outcome.committed?.uci, 'e2e4');
    expect(outcome.state, const EntryIdle());
  });

  test('F3 offers G1 and F2 as sources; tapping G1 commits G1-F3', () {
    final first = tapAll(initial, ['f3']);
    expect(first.committed, isNull);
    final state = first.state as DestinationSelected;
    expect(state.destination, sq('f3'));
    expect(state.sources, {sq('g1'), sq('f2')});

    expect(tapAll(initial, ['f3', 'g1']).committed?.uci, 'g1f3');
  });

  test('the G1 knight offers exactly F3 and H3; tapping H3 commits', () {
    final state = tapAll(initial, ['g1']).state as SourceSelected;
    expect(state.source, sq('g1'));
    expect(state.destinations, {sq('f3'), sq('h3')});

    expect(tapAll(initial, ['g1', 'h3']).committed?.uci, 'g1h3');
  });

  test('a piece with a single destination still takes two taps', () {
    // A pawn on a3 can only advance to a4.
    final moves = movesOf('k7/8/8/8/8/P7/8/K7 w - - 0 1');
    final first = tapAll(moves, ['a3']);
    expect(first.committed, isNull);
    expect((first.state as SourceSelected).destinations, {sq('a4')});
    expect(tapAll(moves, ['a3', 'a4']).committed?.uci, 'a3a4');
  });

  test('inactive squares are ignored, with or without a selection', () {
    expect(tapAll(initial, ['e5']).state, const EntryIdle());
    expect(tapAll(initial, ['e8']).state, const EntryIdle());

    final selected = tapAll(initial, ['g1']).state;
    final outcome = MoveEntry.tap(selected, sq('e8'), initial);
    expect(outcome.state, same(selected));
    expect(outcome.committed, isNull);
  });

  test('a pinned piece with no legal move cannot be selected', () {
    // The e2 knight is pinned by the e8 rook.
    final moves = movesOf('4r2k/8/8/8/8/8/4N3/4K3 w - - 0 1');
    final outcome = tapAll(moves, ['e2']);
    expect(outcome.state, const EntryIdle());
    expect(outcome.committed, isNull);
    expect(MoveEntry.activeSquares(moves).contains(sq('e2')), isFalse);
  });

  test('in check only check-resolving squares are active', () {
    final moves = movesOf('4r2k/8/8/8/R7/8/3P1P2/4K3 w - - 0 1');
    expect(MoveEntry.activeSquares(moves), {
      sq('e1'),
      sq('d1'),
      sq('f1'),
      sq('a4'),
      sq('e4'),
    });
  });

  test('tapping the selected square again cancels', () {
    final outcome = tapAll(initial, ['g1', 'g1']);
    expect(outcome.state, const EntryIdle());
    expect(outcome.committed, isNull);
  });

  test('tapping an active, non-highlighted square cancels', () {
    expect(tapAll(initial, ['g1', 'e4']).state, const EntryIdle());
    expect(tapAll(initial, ['f3', 'e2']).state, const EntryIdle());
  });

  group('castling', () {
    const fen = 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1';

    test('G1 then the king commits kingside castling', () {
      // The H1 rook can also reach G1, so G1 alone is ambiguous.
      final state = tapAll(movesOf(fen), ['g1']).state as DestinationSelected;
      expect(state.sources, {sq('e1'), sq('h1')});

      final committed = tapAll(movesOf(fen), ['g1', 'e1']).committed;
      expect(committed?.uci, 'e1g1');
      expect(committed?.castling, CastlingSide.kingside);
    });
    test('king then G1 commits kingside castling', () {
      expect(tapAll(movesOf(fen), ['e1', 'g1']).committed?.uci, 'e1g1');
    });
  });

  test('en passant destination offers the capturing pawn, then commits', () {
    // White pawn e5, black just played d7-d5; d6 is reachable only by e5.
    final moves = movesOf('k7/8/8/3pP3/8/8/8/K7 w - d6 0 1');
    expect((tapAll(moves, ['d6']).state as DestinationSelected).sources, {
      sq('e5'),
    });
    final committed = tapAll(moves, ['d6', 'e5']).committed;
    expect(committed?.uci, 'e5d6');
    expect(committed?.isEnPassant, isTrue);
  });

  group('promotion', () {
    const fen = 'k7/4P3/8/8/8/8/8/K7 w - - 0 1';

    test('destination then pawn opens the chooser, queen first', () {
      final first = tapAll(movesOf(fen), ['e8']).state;
      expect((first as DestinationSelected).sources, {sq('e7')});
      final state =
          tapAll(movesOf(fen), ['e8', 'e7']).state as PromotionPending;
      expect(state.from, sq('e7'));
      expect(state.to, sq('e8'));
      expect(state.options.map((m) => m.promotion), PieceKind.promotionChoices);
    });

    test('pawn then destination opens the chooser and a knight can be '
        'picked', () {
      expect(tapAll(movesOf(fen), ['e7']).state, isA<SourceSelected>());
      final pending = tapAll(movesOf(fen), ['e7', 'e8']).state;
      expect(pending, isA<PromotionPending>());
      final outcome = MoveEntry.choosePromotion(pending, PieceKind.knight);
      expect(outcome.committed?.uci, 'e7e8n');
      expect(outcome.state, const EntryIdle());
    });

    test('a board tap while pending cancels', () {
      final pending = tapAll(movesOf(fen), ['e8', 'e7']).state;
      expect(pending, isA<PromotionPending>());
      final outcome = MoveEntry.tap(pending, sq('e7'), movesOf(fen));
      expect(outcome.state, const EntryIdle());
      expect(outcome.committed, isNull);
    });

    test('two pawns capturing onto the same square ask for the source', () {
      // Pawns on c7 and e7 can both capture the d8 rook.
      final moves = movesOf('3r3k/2P1P3/8/8/8/8/8/K7 w - - 0 1');
      final first = tapAll(moves, ['d8']).state as DestinationSelected;
      expect(first.sources, {sq('c7'), sq('e7')});

      final pending = tapAll(moves, ['d8', 'e7']).state as PromotionPending;
      expect(pending.from, sq('e7'));
      expect(pending.options, hasLength(4));
      expect(pending.options.every((m) => m.isCapture), isTrue);
    });

    test('choosePromotion is ignored when nothing is pending', () {
      const idle = EntryIdle();
      expect(MoveEntry.choosePromotion(idle, PieceKind.queen).state, idle);
    });
  });

  test('two rooks reaching the same square ask for the source', () {
    final moves = movesOf('3k4/8/8/8/7K/8/8/R6R w - - 0 1');
    final state = tapAll(moves, ['f1']).state as DestinationSelected;
    expect(state.sources, {sq('h1'), sq('a1')});
    expect(tapAll(moves, ['f1', 'a1']).committed?.uci, 'a1f1');
  });
}
