import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/game/player_side.dart';
import 'package:spookymoove/core/theme/app_colors.dart';
import 'package:spookymoove/features/new_game/domain/game_kind.dart';
import 'package:spookymoove/features/new_game/presentation/game_registry.dart';

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

  test('each game has its identity accent: Chess pink, Xiangqi blue', () {
    expect(GameKind.chess.accent, AppColors.accentChess);
    expect(GameKind.chess.accentSide, AppColors.accentChessSide);
    expect(GameKind.xiangqi.accent, AppColors.accentXiangqi);
    expect(GameKind.xiangqi.accentSide, AppColors.accentXiangqiSide);
    expect(AppColors.accentChess, const Color(0xFFED96D7));
    expect(AppColors.accentXiangqi, const Color(0xFF578EF5));
  });

  test('game accents never reuse a status colour', () {
    final status = {
      AppColors.accentGreen,
      AppColors.accentRed,
      AppColors.accentActive,
    };
    for (final game in GameKind.values) {
      expect(status, isNot(contains(game.accent)), reason: game.label);
    }
  });
}
