import 'package:flutter_test/flutter_test.dart';
import 'package:cataland/core/game/game_result.dart';
import 'package:cataland/features/chess/domain/chess_game_status.dart';
import 'package:cataland/features/chess/domain/chess_models.dart';
import 'package:cataland/features/chess/domain/chess_result_format.dart';

void main() {
  test('in progress: no headline', () {
    expect(
      ChessResultFormat.headline(const ChessInProgress(), PieceColor.white),
      isNull,
    );
  });

  test('checkmate reads from the user\'s side', () {
    const whiteWins = ChessCheckmate(winner: PieceColor.white);
    expect(
      ChessResultFormat.headline(whiteWins, PieceColor.white),
      const GameResultHeadline('CHECKMATE — YOU WIN', ResultTone.win),
    );
    expect(
      ChessResultFormat.headline(whiteWins, PieceColor.black),
      const GameResultHeadline('CHECKMATE — YOU LOSE', ResultTone.loss),
    );
  });

  test('every draw reason has plain text and the draw tone', () {
    const expected = {
      DrawReason.stalemate: 'STALEMATE — DRAW',
      DrawReason.insufficientMaterial: 'DRAW — NOT ENOUGH PIECES TO WIN',
      DrawReason.fivefoldRepetition: 'DRAW — SAME POSITION 5 TIMES',
      DrawReason.seventyFiveMoveRule:
          'DRAW — 75 MOVES WITHOUT CAPTURE OR PAWN MOVE',
    };
    for (final reason in DrawReason.values) {
      expect(
        ChessResultFormat.headline(ChessDraw(reason: reason), PieceColor.white),
        GameResultHeadline(expected[reason]!, ResultTone.draw),
      );
    }
  });

  test('lines split at the dash', () {
    expect(
      const GameResultHeadline('CHECKMATE — YOU WIN', ResultTone.win).lines,
      ['CHECKMATE', 'YOU WIN'],
    );
  });

  test('hints only for claimable draws', () {
    expect(
      ChessResultFormat.hint(
        const ChessInProgress(claimableDraw: ClaimableDraw.threefoldRepetition),
      ),
      'DRAW POSSIBLE — SAME POSITION 3 TIMES',
    );
    expect(
      ChessResultFormat.hint(
        const ChessInProgress(claimableDraw: ClaimableDraw.fiftyMoveRule),
      ),
      'DRAW POSSIBLE — 50 MOVES WITHOUT CAPTURE OR PAWN MOVE',
    );
    expect(ChessResultFormat.hint(const ChessInProgress()), isNull);
    expect(
      ChessResultFormat.hint(const ChessDraw(reason: DrawReason.stalemate)),
      isNull,
    );
  });
}
