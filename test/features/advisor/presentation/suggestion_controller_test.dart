import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/engine/engine_models.dart';
import 'package:spookymoove/features/advisor/presentation/suggestion_controller.dart';
import 'package:spookymoove/features/advisor/presentation/suggestion_providers.dart';
import 'package:spookymoove/features/chess/data/chess_package_rules.dart';
import 'package:spookymoove/features/chess/domain/chess_game_status.dart';
import 'package:spookymoove/features/chess/domain/chess_models.dart';
import 'package:spookymoove/features/chess/domain/chess_result_format.dart';
import 'package:spookymoove/features/chess/domain/move_entry.dart';
import 'package:spookymoove/features/chess/presentation/chess_board_controller.dart';
import 'package:spookymoove/features/new_game/domain/game_kind.dart';
import 'package:spookymoove/features/new_game/presentation/game_session_controller.dart';
import 'package:spookymoove/features/persona/domain/persona_tier.dart';
import 'package:spookymoove/features/persona/presentation/persona_tier_controller.dart';
import 'package:spookymoove/core/l10n/app_strings.dart';
import 'package:spookymoove/features/settings/application/app_language_controller.dart';

import '../../persona/fake_game_engine.dart';

ChessSquare sq(String name) => ChessSquare.parse(name);

class Harness {
  Harness({String? fen}) {
    container = ProviderContainer(
      overrides: [
        appStringsProvider.overrideWithValue(AppStrings.english),
        gameEngineProvider.overrideWithValue(engine),
        chessRulesProvider.overrideWithValue(ChessPackageRules(fen: fen)),
        boardClockProvider.overrideWithValue(() => now),
      ],
    );
    container.read(suggestionControllerProvider);
  }

  final FakeGameEngine engine = FakeGameEngine();
  late final ProviderContainer container;
  Duration now = Duration.zero;

  SuggestionState get state => container.read(suggestionControllerProvider);
  ChessBoardState get board => container.read(chessBoardControllerProvider);

  void start(PieceColor side) => container
      .read(gameSessionProvider.notifier)
      .start(GameKind.chess, side.side);

  void selectTier(PersonaTier tier) =>
      container.read(personaTierProvider.notifier).select(tier);

  /// Enters [uci] on the board as the user would (source, then destination).
  void play(String uci) {
    final controller = container.read(chessBoardControllerProvider.notifier);
    now += ChessBoardController.commitGuard;
    controller.tap(sq(uci.substring(0, 2)));
    if (board.entry is! EntryIdle) controller.tap(sq(uci.substring(2, 4)));
  }

  void undo() => container.read(chessBoardControllerProvider.notifier).undo();

  void dispose() => container.dispose();
}

/// Lets listeners, microtasks and fake engine futures run.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late List<String> haptics;

  setUp(() {
    haptics = [];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String);
        }
        return null;
      },
    );
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  Harness harness({String? fen}) {
    final h = Harness(fen: fen);
    addTearDown(h.dispose);
    return h;
  }

  const medium = 'HapticFeedbackType.mediumImpact';
  const heavy = 'HapticFeedbackType.heavyImpact';

  test('no game: waiting, no search', () async {
    final h = harness();
    await settle();

    expect(h.state, isA<SuggestionWaiting>());
    expect(h.engine.searches, isEmpty);
  });

  test("user's turn without a tier: prompt, no search", () async {
    final h = harness()..start(PieceColor.white);
    await settle();

    expect(h.state, isA<SuggestionNoTier>());
    expect(h.engine.searches, isEmpty);
    expect(h.engine.startCount, 0);
  });

  test(
    'a tier on the user\'s turn thinks, then shows and highlights',
    () async {
      final h = harness()..start(PieceColor.white);
      h.selectTier(PersonaTier.god);
      expect(h.state, isA<SuggestionThinking>());
      await settle();

      expect(h.engine.startCount, 1);
      expect(h.engine.variants, ['chess']);
      expect(h.engine.last.position.moves, isEmpty);

      h.engine.last.complete([fakeLine(1, 'e2e4', const CentipawnScore(40))]);
      await settle();

      final state = h.state as SuggestionReady;
      expect(state.engineMove, 'e2e4');
      expect(state.suggestion.score, const CentipawnScore(40));
      expect(h.board.suggestedMove, ChessMove(from: sq('e2'), to: sq('e4')));
      expect(haptics.where((h) => h == medium), hasLength(1));
    },
  );

  test('playing Black without a tier still prompts for one', () async {
    final h = harness()..start(PieceColor.black);
    await settle();

    expect(h.state, isA<SuggestionNoTier>());
    expect(h.engine.searches, isEmpty);
  });

  test("opponent's turn: waiting until the opponent's move", () async {
    final h = harness()..start(PieceColor.black);
    h.selectTier(PersonaTier.god);
    await settle();
    expect(h.state, isA<SuggestionWaiting>());
    expect(h.engine.searches, isEmpty);

    h.play('e2e4');
    await settle();
    expect(h.state, isA<SuggestionThinking>());
    expect(h.engine.last.position.moves, ['e2e4']);
  });

  test(
    "the user's own move cancels the search; its result is dropped",
    () async {
      final h = harness()..start(PieceColor.white);
      h.selectTier(PersonaTier.god);
      await settle();
      final search = h.engine.last;

      h.play('d2d4');
      await settle();
      expect(h.state, isA<SuggestionWaiting>());
      expect(h.engine.stopCount, 1);

      search.complete([fakeLine(1, 'e2e4', const CentipawnScore(40))]);
      await settle();
      expect(h.state, isA<SuggestionWaiting>());
      expect(h.board.suggestedMove, isNull);
      expect(haptics, isNot(contains(medium)));
    },
  );

  test(
    'entering the suggested move clears it from the card and board',
    () async {
      final h = harness()..start(PieceColor.white);
      h.selectTier(PersonaTier.god);
      await settle();
      h.engine.last.complete([fakeLine(1, 'e2e4', const CentipawnScore(40))]);
      await settle();

      h.play('e2e4');
      await settle();
      expect(h.state, isA<SuggestionWaiting>());
      expect(h.board.suggestedMove, isNull);
    },
  );

  test(
    'a move other than the suggestion is applied; no new search starts',
    () async {
      final h = harness()..start(PieceColor.white);
      h.selectTier(PersonaTier.god);
      await settle();
      h.engine.last.complete([fakeLine(1, 'e2e4', const CentipawnScore(40))]);
      await settle();

      h.play('d2d4');
      await settle();
      expect(h.board.sideToMove, PieceColor.black);
      expect(h.board.pieces[sq('d4')], isNotNull);
      expect(h.state, isA<SuggestionWaiting>());
      expect(h.board.suggestedMove, isNull);
      expect(h.engine.searches, hasLength(1));
    },
  );

  test(
    'without a tier both sides can move; a tier then searches the position',
    () async {
      final h = harness()..start(PieceColor.white);
      h.play('e2e4');
      h.play('e7e5');
      await settle();
      expect(h.board.sideToMove, PieceColor.white);
      expect(h.state, isA<SuggestionNoTier>());
      expect(h.engine.searches, isEmpty);

      h.selectTier(PersonaTier.god);
      await settle();
      expect(h.engine.last.position.moves, ['e2e4', 'e7e5']);
    },
  );

  test(
    "a tier change on the opponent's turn applies to the next suggestion",
    () async {
      final h = harness()..start(PieceColor.black);
      h.selectTier(PersonaTier.god);
      h.selectTier(PersonaTier.baby);
      await settle();
      expect(h.state, isA<SuggestionWaiting>());
      expect(h.engine.searches, isEmpty);

      h.play('e2e4');
      await settle();
      expect(h.engine.searches, hasLength(1));
      expect(h.engine.last.limits.multiPv, 20, reason: 'Baby scores all moves');
    },
  );

  test(
    'switching tiers recomputes; switching back shows the same move',
    () async {
      final h = harness()..start(PieceColor.white);
      h.selectTier(PersonaTier.god);
      await settle();
      h.engine.last.complete([fakeLine(1, 'e2e4', const CentipawnScore(40))]);
      await settle();

      h.selectTier(PersonaTier.baby);
      await settle();
      expect(h.engine.searches, hasLength(2));
      expect(h.engine.last.position.moves, isEmpty);
      h.engine.last.complete([fakeLine(1, 'g1h3', const CentipawnScore(-30))]);
      await settle();
      expect((h.state as SuggestionReady).engineMove, 'g1h3');

      h.selectTier(PersonaTier.god);
      await settle();
      expect(h.engine.searches, hasLength(2));
      expect((h.state as SuggestionReady).engineMove, 'e2e4');
    },
  );

  test('the opponent checkmating the user ends the loop: no search, even on '
      'a tier change', () async {
    final h = harness(
      fen: 'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq g3 0 2',
    )..start(PieceColor.white);
    h.selectTier(PersonaTier.god);
    await settle();
    expect(h.engine.searches, isEmpty);

    h.play('d8h4');
    await settle();
    expect(h.board.legalMoves, isEmpty);
    expect(
      (h.state as SuggestionGameOver).headline,
      ChessResultFormat.headline(
        const ChessCheckmate(winner: PieceColor.black),
        h.board.userSide,
        AppStrings.english,
      ),
    );
    expect(h.engine.searches, isEmpty);

    h.selectTier(PersonaTier.baby);
    await settle();
    expect(h.state, isA<SuggestionGameOver>());
    expect(h.engine.searches, isEmpty);
  });

  test(
    'the user delivering mate cancels the search and shows the result',
    () async {
      final h = harness(
        fen: 'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq g3 0 2',
      )..start(PieceColor.black);
      h.selectTier(PersonaTier.god);
      await settle();
      expect(h.engine.searches, hasLength(1));

      h.play('d8h4');
      await settle();
      expect(
        (h.state as SuggestionGameOver).headline,
        ChessResultFormat.headline(
          const ChessCheckmate(winner: PieceColor.black),
          h.board.userSide,
          AppStrings.english,
        ),
      );
      expect(h.engine.stopCount, 1);
      expect(h.engine.searches, hasLength(1));
    },
  );

  test('the result shows even without a tier', () async {
    final h = harness(
      fen: 'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq g3 0 2',
    )..start(PieceColor.white);
    h.play('d8h4');
    await settle();
    expect(h.state, isA<SuggestionGameOver>());
  });

  test('an automatic draw on the user\'s turn starts no search', () async {
    final h = harness(fen: '8/8/8/4k3/8/8/8/4KN2 w - - 0 1')
      ..start(PieceColor.white);
    h.selectTier(PersonaTier.god);
    await settle();
    expect(
      (h.state as SuggestionGameOver).headline,
      ChessResultFormat.headline(
        const ChessDraw(reason: DrawReason.insufficientMaterial),
        h.board.userSide,
        AppStrings.english,
      ),
    );
    expect(h.engine.searches, isEmpty);
  });

  group('undo', () {
    test(
      "undoing the opponent's move: waiting again, search cancelled",
      () async {
        final h = harness()..start(PieceColor.black);
        h.selectTier(PersonaTier.god);
        h.play('e2e4');
        await settle();
        final search = h.engine.last;
        expect(h.state, isA<SuggestionThinking>());

        h.undo();
        await settle();
        expect(h.state, isA<SuggestionWaiting>());
        expect(h.engine.stopCount, 1);

        search.complete([fakeLine(1, 'e7e5', const CentipawnScore(0))]);
        await settle();
        expect(h.state, isA<SuggestionWaiting>());
        expect(h.board.suggestedMove, isNull);
      },
    );

    test(
      'a different move, then undo: the same suggestion, no new search',
      () async {
        final h = harness()..start(PieceColor.white);
        h.selectTier(PersonaTier.baby);
        await settle();
        h.engine.last.complete([
          fakeLine(1, 'e2e4', const CentipawnScore(30)),
          fakeLine(2, 'g1h3', const CentipawnScore(-400)),
        ]);
        await settle();
        final shown = (h.state as SuggestionReady).engineMove;

        h.play('d2d4');
        await settle();
        h.undo();
        await settle();
        expect((h.state as SuggestionReady).engineMove, shown);
        expect(h.board.suggestedMove?.uci, shown);
        expect(h.engine.searches, hasLength(1));
      },
    );

    test(
      'a confirmed suggestion, then undo: the same suggestion, no new search',
      () async {
        final h = harness()..start(PieceColor.white);
        h.selectTier(PersonaTier.god);
        await settle();
        h.engine.last.complete([fakeLine(1, 'e2e4', const CentipawnScore(40))]);
        await settle();
        final shown = (h.state as SuggestionReady).engineMove;

        h.container
            .read(chessBoardControllerProvider.notifier)
            .commitEngineMove(shown);
        await settle();
        expect(h.board.pieces[sq('e4')], isNotNull);
        expect(h.state, isA<SuggestionWaiting>());

        h.undo();
        await settle();
        expect((h.state as SuggestionReady).engineMove, shown);
        expect(h.engine.searches, hasLength(1));
      },
    );

    test('a tier change after undo searches the restored position', () async {
      final h = harness()..start(PieceColor.white);
      h.selectTier(PersonaTier.god);
      await settle();
      h.engine.last.complete([fakeLine(1, 'e2e4', const CentipawnScore(40))]);
      await settle();
      h.play('e2e4');
      h.play('e7e5');
      await settle();
      h.undo();
      h.undo();
      await settle();

      h.selectTier(PersonaTier.solid);
      await settle();
      expect(h.engine.last.position.moves, isEmpty);
      expect(h.engine.last.limits.depth, 12);
    });

    test('from checkmate: the result goes, play resumes', () async {
      final h = harness(
        fen: 'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq g3 0 2',
      )..start(PieceColor.white);
      h.selectTier(PersonaTier.god);
      h.play('d8h4');
      await settle();
      expect(h.state, isA<SuggestionGameOver>());

      h.undo();
      await settle();
      expect(h.state, isA<SuggestionWaiting>(), reason: "opponent's turn");
      expect(h.engine.searches, isEmpty);
    });
  });

  test('a tier change while thinking shows only the new tier', () async {
    final h = harness()..start(PieceColor.white);
    h.selectTier(PersonaTier.god);
    await settle();
    h.selectTier(PersonaTier.solid);
    await settle();
    expect(h.engine.searches, hasLength(2));

    h.engine.last.complete([fakeLine(1, 'g1f3', const CentipawnScore(20))]);
    await settle();
    expect((h.state as SuggestionReady).engineMove, 'g1f3');
  });

  test(
    'engine failure shows the error; retry restarts and re-requests',
    () async {
      final h = harness()..start(PieceColor.white);
      h.selectTier(PersonaTier.god);
      await settle();

      h.engine.last.fail(const EngineFailureException('crashed'));
      await settle();
      expect(h.state, isA<SuggestionFailed>());

      h.container.read(suggestionControllerProvider.notifier).retry();
      expect(h.state, isA<SuggestionThinking>());
      await settle();
      expect(h.engine.disposeCount, 1);
      expect(h.engine.startCount, 2);
      expect(h.engine.searches, hasLength(2));

      h.engine.last.complete([fakeLine(1, 'e2e4', const CentipawnScore(40))]);
      await settle();
      expect(h.state, isA<SuggestionReady>());
    },
  );

  test('an engine that fails to start shows the error', () async {
    final h = harness()..start(PieceColor.white);
    h.engine.startError = const EngineFailureException('no engine');
    h.selectTier(PersonaTier.god);
    await settle();

    expect(h.state, isA<SuggestionFailed>());
    expect(h.engine.searches, isEmpty);
  });

  test('an illegal engine move shows the error', () async {
    final h = harness()..start(PieceColor.white);
    h.selectTier(PersonaTier.god);
    await settle();

    h.engine.last.complete([fakeLine(1, 'e2e5', const CentipawnScore(40))]);
    await settle();
    expect(h.state, isA<SuggestionFailed>());
  });

  testWidgets('a search slower than the timeout shows the error', (
    tester,
  ) async {
    final h = harness()..start(PieceColor.white);
    h.selectTier(PersonaTier.god);
    await tester.pump();
    expect(h.state, isA<SuggestionThinking>());
    expect(h.engine.searches, hasLength(1));

    await tester.pump(SuggestionController.timeout);
    expect(h.state, isA<SuggestionFailed>());
    expect(h.engine.stopCount, 1);
  });

  test('a new game clears the cached suggestions', () async {
    final h = harness()..start(PieceColor.white);
    h.selectTier(PersonaTier.god);
    await settle();
    h.engine.last.complete([fakeLine(1, 'e2e4', const CentipawnScore(40))]);
    await settle();

    h.start(PieceColor.white);
    await settle();
    expect(h.state, isA<SuggestionNoTier>());
    expect(h.board.suggestedMove, isNull);

    h.selectTier(PersonaTier.god);
    await settle();
    expect(h.engine.searches, hasLength(2));
    expect(h.engine.startCount, 1, reason: 'engine stays started');
  });

  test('the opponent putting the user in check plays heavyImpact', () async {
    final h = harness(
      fen: 'rnbqkbnr/pppp1ppp/8/4p3/3P4/8/PPP1PPPP/RNBQKBNR b KQkq - 0 2',
    )..start(PieceColor.white);
    await settle();

    h.play('f8b4');
    await settle();
    expect(h.board.checkedKing, sq('e1'));
    expect(haptics, contains(heavy));
  });
}
