import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/game/player_side.dart';
import 'package:spookymoove/features/advisor/presentation/turn_status.dart';
import 'package:spookymoove/features/chess/data/chess_package_rules.dart';
import 'package:spookymoove/features/chess/domain/chess_models.dart';
import 'package:spookymoove/features/chess/presentation/chess_board_controller.dart';
import 'package:spookymoove/features/new_game/domain/game_kind.dart';
import 'package:spookymoove/features/new_game/presentation/game_session_controller.dart';
import 'package:spookymoove/core/l10n/app_strings.dart';
import 'package:spookymoove/features/settings/application/app_language_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer container({String? fen}) {
    var now = Duration.zero;
    final c = ProviderContainer(
      overrides: [
        appStringsProvider.overrideWithValue(AppStrings.english),
        chessRulesProvider.overrideWithValue(ChessPackageRules(fen: fen)),
        boardClockProvider.overrideWithValue(
          () => now += ChessBoardController.commitGuard,
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  void start(ProviderContainer c, PlayerSide side) =>
      c.read(gameSessionProvider.notifier).start(GameKind.chess, side);

  void play(ProviderContainer c, String uci) {
    final board = c.read(chessBoardControllerProvider.notifier);
    board.tap(ChessSquare.parse(uci.substring(0, 2)));
    board.tap(ChessSquare.parse(uci.substring(2, 4)));
  }

  test('no game: no status', () {
    expect(container().read(turnStatusProvider), isNull);
  });

  test('playing White: your move, then the opponent\'s after it', () {
    final c = container();
    start(c, PlayerSide.first);
    expect(c.read(turnStatusProvider), TurnStatus.yourMove);

    play(c, 'e2e4');
    expect(c.read(turnStatusProvider), TurnStatus.opponentToMove);

    play(c, 'e7e5');
    expect(c.read(turnStatusProvider), TurnStatus.yourMove);
  });

  test('playing Black: the opponent moves first', () {
    final c = container();
    start(c, PlayerSide.second);
    expect(c.read(turnStatusProvider), TurnStatus.opponentToMove);
  });

  test('checkmate: no status', () {
    final c = container(
      fen: 'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq g3 0 2',
    );
    start(c, PlayerSide.first);
    expect(c.read(turnStatusProvider), TurnStatus.opponentToMove);

    play(c, 'd8h4');
    expect(c.read(turnStatusProvider), isNull);
  });

  test('an automatic draw with legal moves left: no status', () {
    final c = container(fen: '8/8/8/4k3/8/8/8/4KN2 w - - 0 1');
    start(c, PlayerSide.first);
    expect(c.read(chessBoardControllerProvider).legalMoves, isNotEmpty);
    expect(c.read(turnStatusProvider), isNull);
  });
}
