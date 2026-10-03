import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cataland/core/engine/engine_models.dart';
import 'package:cataland/core/theme/app_colors.dart';
import 'package:cataland/features/advisor/presentation/suggestion_controller.dart';
import 'package:cataland/features/advisor/presentation/widgets/suggestion_card.dart';
import 'package:cataland/features/chess/data/chess_package_rules.dart';
import 'package:cataland/features/chess/domain/chess_game_status.dart';
import 'package:cataland/features/chess/domain/chess_models.dart';
import 'package:cataland/features/chess/domain/chess_result_format.dart';
import 'package:cataland/features/chess/presentation/chess_board_controller.dart';
import 'package:cataland/features/chess/presentation/widgets/chess_piece_pictogram.dart';
import 'package:cataland/features/persona/application/persona_suggester.dart';

class FixedSuggestionController extends SuggestionController {
  FixedSuggestionController(this._state);

  final SuggestionState _state;
  int retries = 0;

  @override
  SuggestionState build() => _state;

  @override
  void retry() => retries++;
}

ChessMove moveIn(String fen, String uci) =>
    ChessPackageRules(fen: fen).moveFromUci(uci)!;

SuggestionReady ready(
  ChessMove move, {
  EngineScore score = const CentipawnScore(140),
  double winChance = 62,
}) => SuggestionReady(
  suggestion: PersonaSuggestion(
    move: move.uci,
    score: score,
    winChance: winChance,
    depth: 16,
    nps: 850000,
  ),
);

Future<FixedSuggestionController> pumpCard(
  WidgetTester tester,
  SuggestionState state, {
  double textScale = 1.0,
  String? fen,
}) async {
  tester.view.physicalSize = const Size(360, 240);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final controller = FixedSuggestionController(state);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        suggestionControllerProvider.overrideWith(() => controller),
        chessRulesProvider.overrideWithValue(ChessPackageRules(fen: fen)),
      ],
      child: const MaterialApp(home: Scaffold(body: SuggestionCard())),
    ),
  );
  return controller;
}

Color? colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

List<ChessPiece> pictograms(WidgetTester tester) => tester
    .widgetList<ChessPiecePictogram>(find.byType(ChessPiecePictogram))
    .map((p) => p.piece)
    .toList();

const _startFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

void main() {
  testWidgets('a normal move: coordinates and expert line, no win rate', (
    tester,
  ) async {
    await pumpCard(tester, ready(moveIn(_startFen, 'e2e4')));

    expect(find.text('E2 ➔ E4'), findsOneWidget);
    expect(colorOf(tester, 'E2 ➔ E4'), AppColors.accentGreen);
    expect(find.text('WIN RATE 62%'), findsNothing, reason: 'in the top bar');
    expect(find.text('EVAL +1.4 | DEPTH 16 | 850k nps'), findsOneWidget);
    expect(pictograms(tester), isEmpty);
  });

  testWidgets('a forced mate shows in the expert line', (tester) async {
    await pumpCard(
      tester,
      ready(
        moveIn(_startFen, 'f2f3'),
        score: const MateScore(-4),
        winChance: 0,
      ),
    );
    expect(find.text('OPPONENT MATES IN 4'), findsNothing);
    expect(find.text('EVAL -M4 | DEPTH 16 | 850k nps'), findsOneWidget);
  });

  testWidgets('castling shows the rook pictogram and its move', (tester) async {
    await pumpCard(
      tester,
      ready(moveIn('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1', 'e1g1')),
      fen: 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
    );
    expect(find.text('E1 ➔ G1'), findsOneWidget);
    expect(find.text('H1 ➔ F1'), findsOneWidget);
    expect(pictograms(tester), [
      const ChessPiece(PieceColor.white, PieceKind.rook),
    ]);
  });

  testWidgets('a promotion shows the new piece as a pictogram', (tester) async {
    await pumpCard(
      tester,
      ready(moveIn('7k/4P3/8/8/8/8/8/K7 w - - 0 1', 'e7e8q')),
      fen: '7k/4P3/8/8/8/8/8/K7 w - - 0 1',
    );
    expect(find.text('E7 ➔ E8'), findsOneWidget);
    expect(pictograms(tester), [
      const ChessPiece(PieceColor.white, PieceKind.queen),
    ]);
  });

  testWidgets('en passant names the pawn to remove', (tester) async {
    await pumpCard(
      tester,
      ready(
        moveIn(
          'rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3',
          'e5d6',
        ),
      ),
      fen: 'rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3',
    );
    expect(find.text('E5 ➔ D6 ✕'), findsOneWidget);
    expect(find.text('✕ D5'), findsOneWidget);
  });

  testWidgets('thinking: dimmed line and caption', (tester) async {
    await pumpCard(tester, const SuggestionThinking());
    expect(find.text(SuggestionCard.thinkingLabel), findsOneWidget);
    expect(colorOf(tester, SuggestionCard.emptyLine), AppColors.textSecondary);
  });

  testWidgets('no tier: the card prompts for one', (tester) async {
    await pumpCard(tester, const SuggestionNoTier());
    expect(find.text(SuggestionCard.pickTierPrompt), findsOneWidget);
  });

  testWidgets("opponent's turn: an empty line only", (tester) async {
    await pumpCard(tester, const SuggestionWaiting());
    expect(find.text(SuggestionCard.emptyLine), findsOneWidget);
    expect(find.text(SuggestionCard.pickTierPrompt), findsNothing);
  });

  testWidgets('an error offers Retry', (tester) async {
    final controller = await pumpCard(tester, const SuggestionFailed());
    expect(find.text(SuggestionCard.errorLabel), findsOneWidget);

    await tester.tap(find.byKey(SuggestionCard.retryKey));
    expect(controller.retries, 1);
  });

  testWidgets('no overflow at text scale 2.0', (tester) async {
    await pumpCard(
      tester,
      ready(moveIn('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1', 'e1c1')),
      fen: 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
      textScale: 2.0,
    );
    expect(tester.takeException(), isNull);
  });

  group('game over', () {
    testWidgets('the user wins: green', (tester) async {
      await pumpCard(
        tester,
        SuggestionGameOver(
          headline: ChessResultFormat.headline(
            const ChessCheckmate(winner: PieceColor.white),
            PieceColor.white,
          )!,
        ),
      );
      expect(colorOf(tester, 'CHECKMATE'), AppColors.accentGreen);
      expect(colorOf(tester, 'YOU WIN'), AppColors.accentGreen);
    });

    testWidgets('the user loses: red', (tester) async {
      await pumpCard(
        tester,
        SuggestionGameOver(
          headline: ChessResultFormat.headline(
            const ChessCheckmate(winner: PieceColor.black),
            PieceColor.white,
          )!,
        ),
      );
      expect(colorOf(tester, 'CHECKMATE'), AppColors.accentRed);
      expect(colorOf(tester, 'YOU LOSE'), AppColors.accentRed);
    });

    testWidgets('a draw: textPrimary, no move line', (tester) async {
      await pumpCard(
        tester,
        SuggestionGameOver(
          headline: ChessResultFormat.headline(
            const ChessDraw(reason: DrawReason.insufficientMaterial),
            PieceColor.white,
          )!,
        ),
      );
      expect(colorOf(tester, 'DRAW'), AppColors.textPrimary);
      expect(
        colorOf(tester, 'NOT ENOUGH PIECES TO WIN'),
        AppColors.textPrimary,
      );
      expect(find.text(SuggestionCard.emptyLine), findsNothing);
    });

    testWidgets('no overflow at text scale 2.0 with the longest result', (
      tester,
    ) async {
      await pumpCard(
        tester,
        SuggestionGameOver(
          headline: ChessResultFormat.headline(
            const ChessDraw(reason: DrawReason.seventyFiveMoveRule),
            PieceColor.white,
          )!,
        ),
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('claimable-draw hint', () {
    const fiftyMoveFen = 'r3k3/8/8/8/8/8/8/R3K3 w - - 100 80';
    const hint = 'DRAW POSSIBLE — 50 MOVES WITHOUT CAPTURE OR PAWN MOVE';

    testWidgets('shown under a suggestion', (tester) async {
      await pumpCard(
        tester,
        ready(moveIn(fiftyMoveFen, 'a1a2')),
        fen: fiftyMoveFen,
      );
      expect(find.text('A1 ➔ A2'), findsOneWidget);
      expect(colorOf(tester, hint), AppColors.textSecondary);
    });

    testWidgets("shown on the opponent's turn", (tester) async {
      await pumpCard(tester, const SuggestionWaiting(), fen: fiftyMoveFen);
      expect(find.text(hint), findsOneWidget);
    });

    testWidgets('absent without a claimable draw', (tester) async {
      await pumpCard(tester, const SuggestionWaiting());
      expect(find.textContaining('DRAW POSSIBLE'), findsNothing);
    });

    testWidgets('no overflow at text scale 2.0', (tester) async {
      await pumpCard(
        tester,
        ready(moveIn(fiftyMoveFen, 'a1a2')),
        fen: fiftyMoveFen,
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('no SAN, piece letters, O-O or e.p. on the card', (tester) async {
    await pumpCard(
      tester,
      ready(moveIn('3r3k/4P3/8/8/8/8/8/K7 w - - 0 1', 'e7d8q')),
      fen: '3r3k/4P3/8/8/8/8/8/K7 w - - 0 1',
    );
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join(' ');
    expect(texts, isNot(contains('O-O')));
    expect(texts, isNot(contains('e.p.')));
    expect(texts, isNot(matches(RegExp(r'\b[KQRBN][a-h]?x?[a-h][1-8]'))));
    expect(texts, isNot(matches(RegExp(r'=[QRBN]'))));
  });
}
