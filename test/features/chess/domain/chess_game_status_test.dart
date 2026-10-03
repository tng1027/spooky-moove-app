import 'package:flutter_test/flutter_test.dart';
import 'package:cataland/features/chess/data/chess_package_rules.dart';
import 'package:cataland/features/chess/domain/chess_game_status.dart';
import 'package:cataland/features/chess/domain/chess_models.dart';

ChessPackageRules play(ChessPackageRules rules, List<String> moves) {
  for (final uci in moves) {
    rules.apply(rules.moveFromUci(uci)!);
  }
  return rules;
}

ChessGameStatus statusOf(String fen, [List<String> moves = const []]) =>
    ChessGameStatus.of(play(ChessPackageRules(fen: fen), moves));

/// One knight round trip for each side: the start position recurs once.
const knightCycle = ['g1f3', 'g8f6', 'f3g1', 'f6g8'];

void main() {
  test('the start position is in progress without a hint', () {
    expect(ChessGameStatus.of(ChessPackageRules()), const ChessInProgress());
  });

  test('checkmate names the winner', () {
    final white = play(ChessPackageRules(), [
      'e2e4',
      'e7e5',
      'f1c4',
      'b8c6',
      'd1h5',
      'g8f6',
      'h5f7',
    ]);
    expect(
      ChessGameStatus.of(white),
      const ChessCheckmate(winner: PieceColor.white),
    );

    final black = play(ChessPackageRules(), ['f2f3', 'e7e5', 'g2g4', 'd8h4']);
    expect(
      ChessGameStatus.of(black),
      const ChessCheckmate(winner: PieceColor.black),
    );
  });

  test('stalemate is a draw', () {
    expect(
      statusOf('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1'),
      const ChessDraw(reason: DrawReason.stalemate),
    );
  });

  for (final (name, fen) in [
    ('K v K', '8/8/8/4k3/8/8/8/4K3 w - - 0 1'),
    ('K+B v K', '8/8/8/4k3/8/8/8/4KB2 w - - 0 1'),
    ('K+N v K', '8/8/8/4k3/8/8/8/4KN2 w - - 0 1'),
  ]) {
    test('$name is a draw by insufficient material', () {
      expect(
        statusOf(fen),
        const ChessDraw(reason: DrawReason.insufficientMaterial),
      );
    });
  }

  test('threefold repetition is only a hint; play continues', () {
    final rules = play(ChessPackageRules(), [...knightCycle, ...knightCycle]);
    final status = ChessGameStatus.of(rules);
    expect(
      status,
      const ChessInProgress(claimableDraw: ClaimableDraw.threefoldRepetition),
    );
    expect(status.isOver, isFalse);
  });

  test('fivefold repetition ends the game; undo resumes it', () {
    final rules = play(ChessPackageRules(), [
      for (var i = 0; i < 4; i++) ...knightCycle,
    ]);
    expect(rules.repetitionCount, 5);
    expect(
      ChessGameStatus.of(rules),
      const ChessDraw(reason: DrawReason.fivefoldRepetition),
    );

    rules.undo();
    final status = ChessGameStatus.of(rules);
    expect(status.isOver, isFalse);
    expect(rules.repetitionCount, 4);
  });

  test('100 half-moves without capture or pawn move is only a hint', () {
    const fen = 'r3k3/8/8/8/8/8/8/R3K3 w - - 99 80';
    expect(statusOf(fen), const ChessInProgress());
    expect(
      statusOf(fen, ['a1a2']),
      const ChessInProgress(claimableDraw: ClaimableDraw.fiftyMoveRule),
    );
  });

  test('150 half-moves without capture or pawn move ends the game', () {
    expect(
      statusOf('r3k3/8/8/8/8/8/8/R3K3 w - - 149 100', ['a1a2']),
      const ChessDraw(reason: DrawReason.seventyFiveMoveRule),
    );
  });

  test('checkmate on the 150th half-move is checkmate, not a draw', () {
    expect(
      statusOf('k7/8/1K6/8/8/8/8/7R w - - 149 100', ['h1h8']),
      const ChessCheckmate(winner: PieceColor.white),
    );
  });
}
