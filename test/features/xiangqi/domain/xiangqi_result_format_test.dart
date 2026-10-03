import 'package:flutter_test/flutter_test.dart';
import 'package:cataland/core/game/game_result.dart';
import 'package:cataland/core/game/player_side.dart';
import 'package:cataland/features/xiangqi/domain/xiangqi_game_status.dart';
import 'package:cataland/features/xiangqi/domain/xiangqi_result_format.dart';

void main() {
  const redMates = XiangqiLoss(
    winner: PlayerSide.first,
    reason: XiangqiEndReason.checkmate,
  );
  const blackBlocks = XiangqiLoss(
    winner: PlayerSide.second,
    reason: XiangqiEndReason.noMoves,
  );

  test('in progress: no headline', () {
    for (final side in PlayerSide.values) {
      expect(
        XiangqiResultFormat.headline(const XiangqiInProgress(), side),
        isNull,
      );
    }
  });

  test('checkmate from each side', () {
    expect(
      XiangqiResultFormat.headline(redMates, PlayerSide.first),
      const GameResultHeadline('CHECKMATE — YOU WIN', ResultTone.win),
    );
    expect(
      XiangqiResultFormat.headline(redMates, PlayerSide.second),
      const GameResultHeadline('CHECKMATE — YOU LOSE', ResultTone.loss),
    );
  });

  test('no moves from each side, never a draw', () {
    expect(
      XiangqiResultFormat.headline(blackBlocks, PlayerSide.second),
      const GameResultHeadline('NO MOVES — YOU WIN', ResultTone.win),
    );
    final loss = XiangqiResultFormat.headline(blackBlocks, PlayerSide.first)!;
    expect(
      loss,
      const GameResultHeadline('NO MOVES — YOU LOSE', ResultTone.loss),
    );
    expect(loss.lines, ['NO MOVES', 'YOU LOSE']);
    expect(loss.text, isNot(contains('STALEMATE')));
  });
}
