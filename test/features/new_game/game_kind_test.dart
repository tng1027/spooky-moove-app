import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/game/player_side.dart';
import 'package:spookymoove/features/new_game/domain/game_kind.dart';

void main() {
  test('Chess labels its sides WHITE and BLACK, never RED', () {
    expect(GameKind.chess.sideLabel(PlayerSide.first), 'WHITE');
    expect(GameKind.chess.sideLabel(PlayerSide.second), 'BLACK');
    for (final side in PlayerSide.values) {
      expect(GameKind.chess.sideLabel(side), isNot(contains('RED')));
    }
  });

  test('Chess runs in the chess engine variant on an 8 x 8 grid', () {
    expect(GameKind.chess.engineVariant, 'chess');
    expect((GameKind.chess.files, GameKind.chess.ranks), (8, 8));
  });

  test('games are offered as CHESS then XIANGQI', () {
    expect(GameKind.values, [GameKind.chess, GameKind.xiangqi]);
    expect(GameKind.xiangqi.label, 'XIANGQI');
  });

  test('Xiangqi labels its sides RED and BLACK, never WHITE', () {
    expect(GameKind.xiangqi.sideLabel(PlayerSide.first), 'RED');
    expect(GameKind.xiangqi.sideLabel(PlayerSide.second), 'BLACK');
    for (final side in PlayerSide.values) {
      expect(GameKind.xiangqi.sideLabel(side), isNot(contains('WHITE')));
    }
  });

  test('Xiangqi runs in the xiangqi engine variant on a 9 x 10 grid', () {
    expect(GameKind.xiangqi.engineVariant, 'xiangqi');
    expect((GameKind.xiangqi.files, GameKind.xiangqi.ranks), (9, 10));
  });
}
