import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/game/game_result.dart';
import 'package:spookymoove/core/game/player_side.dart';
import 'package:spookymoove/features/xiangqi/domain/xiangqi_game_status.dart';
import 'package:spookymoove/features/xiangqi/domain/xiangqi_result_format.dart';
import 'package:spookymoove/core/l10n/app_strings.dart';

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
        XiangqiResultFormat.headline(
          const XiangqiInProgress(),
          side,
          AppStrings.english,
        ),
        isNull,
      );
    }
  });

  test('checkmate from each side', () {
    expect(
      XiangqiResultFormat.headline(
        redMates,
        PlayerSide.first,
        AppStrings.english,
      ),
      const GameResultHeadline('CHECKMATE — YOU WIN', ResultTone.win),
    );
    expect(
      XiangqiResultFormat.headline(
        redMates,
        PlayerSide.second,
        AppStrings.english,
      ),
      const GameResultHeadline('CHECKMATE — YOU LOSE', ResultTone.loss),
    );
  });

  test('no moves from each side, never a draw', () {
    expect(
      XiangqiResultFormat.headline(
        blackBlocks,
        PlayerSide.second,
        AppStrings.english,
      ),
      const GameResultHeadline('NO MOVES — YOU WIN', ResultTone.win),
    );
    final loss = XiangqiResultFormat.headline(
      blackBlocks,
      PlayerSide.first,
      AppStrings.english,
    )!;
    expect(
      loss,
      const GameResultHeadline('NO MOVES — YOU LOSE', ResultTone.loss),
    );
    expect(loss.lines, ['NO MOVES', 'YOU LOSE']);
    expect(loss.text, isNot(contains('STALEMATE')));
  });
}
