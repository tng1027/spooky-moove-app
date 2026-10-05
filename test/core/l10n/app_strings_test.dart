import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/game/game_result.dart';
import 'package:spookymoove/core/game/player_side.dart';
import 'package:spookymoove/core/l10n/app_strings.dart';
import 'package:spookymoove/features/chess/domain/chess_game_status.dart';
import 'package:spookymoove/features/chess/domain/chess_models.dart';
import 'package:spookymoove/features/chess/domain/chess_result_format.dart';
import 'package:spookymoove/features/new_game/domain/game_kind.dart';
import 'package:spookymoove/features/settings/domain/app_language.dart';
import 'package:spookymoove/features/xiangqi/domain/xiangqi_game_status.dart';
import 'package:spookymoove/features/xiangqi/domain/xiangqi_result_format.dart';

/// Every source holding in-app copy (OB-053, OB-034 banned-terms audit).
const _copySources = [
  'lib/core/l10n/app_strings_en.dart',
  'lib/core/l10n/app_strings_vi.dart',
  'lib/features/persona/domain/persona_tier_copy.dart',
  'lib/features/fair_play/domain/fair_play_notice.dart',
];

/// OB-034 / marketing doc section 5, plus the Vietnamese equivalents.
const _bannedTerms = [
  'cheat',
  'hack',
  'stealth',
  'bot',
  'auto-move',
  'undetected',
  'god mode',
  'gian lận',
  'cờ độ',
  'cá cược',
];

void main() {
  test('every catalogue is tagged with its own language', () {
    for (final language in AppLanguage.values) {
      expect(AppStrings.forLanguage(language).language, language);
    }
  });

  test('no banned term in any in-app copy, in either language', () {
    for (final path in _copySources) {
      final source = File(path).readAsStringSync().toLowerCase();
      for (final term in _bannedTerms) {
        expect(
          RegExp('(?<![a-z])${RegExp.escape(term)}(?![a-z])').hasMatch(source),
          isFalse,
          reason: '"$term" in $path',
        );
      }
    }
  });

  test('no Vietnamese string is empty', () {
    final source = File('lib/core/l10n/app_strings_vi.dart').readAsStringSync();
    expect(source, isNot(contains(": ''")));
  });

  test('two-part results keep the separator the card splits on', () {
    for (final strings in [AppStrings.english, AppStrings.vietnamese]) {
      for (final text in [
        strings.stalemateDraw,
        strings.drawInsufficientMaterial,
        strings.drawFivefold,
        strings.drawSeventyFiveMoves,
        strings.hintThreefold,
        strings.hintFiftyMoves,
      ]) {
        expect(text.split(GameResultHeadline.separator), hasLength(2));
      }
    }
  });

  test('Vietnamese game and side names (REQ-010)', () {
    const vi = AppStrings.vietnamese;
    expect(vi.gameName(GameKind.chess), 'CỜ VUA');
    expect(vi.gameName(GameKind.xiangqi), 'CỜ TƯỚNG');
    expect(vi.sideName(GameKind.chess, PlayerSide.first), 'TRẮNG');
    expect(vi.sideName(GameKind.chess, PlayerSide.second), 'ĐEN');
    expect(vi.sideName(GameKind.xiangqi, PlayerSide.first), 'ĐỎ');
    expect(vi.sideName(GameKind.xiangqi, PlayerSide.second), 'ĐEN');
  });

  test('Vietnamese game results', () {
    const vi = AppStrings.vietnamese;
    expect(
      ChessResultFormat.headline(
        const ChessCheckmate(winner: PieceColor.white),
        PieceColor.white,
        vi,
      )!.lines,
      ['CHIẾU TƯỚNG', 'BẠN THẮNG'],
    );
    expect(
      ChessResultFormat.headline(
        const ChessDraw(reason: DrawReason.stalemate),
        PieceColor.white,
        vi,
      )!.lines.last,
      'HÒA',
    );
    expect(
      XiangqiResultFormat.headline(
        const XiangqiLoss(
          winner: PlayerSide.first,
          reason: XiangqiEndReason.noMoves,
        ),
        PlayerSide.second,
        vi,
      )!.lines,
      ['HẾT CỜ', 'BẠN THUA'],
    );
  });

  test('untranslated parts stay identical (REQ-008)', () {
    expect(AppStrings.vietnamese.aboutEngine, contains('Fairy-Stockfish'));
    expect(AppStrings.vietnamese.aboutFreeSoftware, contains('SpookyMoove'));
  });
}
