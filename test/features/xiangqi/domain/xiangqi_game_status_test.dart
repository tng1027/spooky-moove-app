import 'package:flutter_test/flutter_test.dart';
import 'package:cataland/core/game/player_side.dart';
import 'package:cataland/features/xiangqi/data/dart_xiangqi_rules.dart';
import 'package:cataland/features/xiangqi/domain/xiangqi_game_status.dart';

XiangqiGameStatus statusOf([String? fen]) =>
    XiangqiGameStatus.of(DartXiangqiRules(fen: fen));

void main() {
  test('the start position is in progress', () {
    expect(statusOf(), const XiangqiInProgress());
    expect(statusOf().isOver, isFalse);
  });

  test('generals only: the game goes on (no automatic draw)', () {
    expect(
      statusOf('4k4/9/9/9/9/9/9/9/9/3K5 w - - 0 1'),
      const XiangqiInProgress(),
    );
  });

  test('Black checkmated: Red wins', () {
    final status = statusOf('R3k4/1R7/9/9/9/9/9/9/9/3K5 b - - 0 1');
    expect(
      status,
      const XiangqiLoss(
        winner: PlayerSide.first,
        reason: XiangqiEndReason.checkmate,
      ),
    );
    expect(status.isOver, isTrue);
  });

  test('Red checkmated: Black wins', () {
    expect(
      statusOf('3k5/9/9/9/9/9/9/9/1r7/r3K4 w - - 0 1'),
      const XiangqiLoss(
        winner: PlayerSide.second,
        reason: XiangqiEndReason.checkmate,
      ),
    );
  });

  test('a mate that relies on the flying-general rule', () {
    expect(
      statusOf('3k5/9/9/9/9/3R5/9/9/9/4K4 b - - 0 1'),
      const XiangqiLoss(
        winner: PlayerSide.first,
        reason: XiangqiEndReason.checkmate,
      ),
    );
  });

  test('Black has no moves and is not in check: a loss', () {
    expect(
      statusOf('4k4/9/6N2/9/9/3R1R3/9/9/9/3K5 b - - 0 1'),
      const XiangqiLoss(
        winner: PlayerSide.first,
        reason: XiangqiEndReason.noMoves,
      ),
    );
  });

  test('Red has no moves and is not in check: a loss', () {
    expect(
      statusOf('3k5/9/9/9/3r1r3/9/9/6n2/9/4K4 w - - 0 1'),
      const XiangqiLoss(
        winner: PlayerSide.second,
        reason: XiangqiEndReason.noMoves,
      ),
    );
  });
}
