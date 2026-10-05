import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/engine/engine_models.dart';
import 'package:spookymoove/core/game/player_side.dart';
import 'package:spookymoove/features/advisor/presentation/suggestion_controller.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/suggestion_card.dart';
import 'package:spookymoove/features/new_game/domain/game_kind.dart';
import 'package:spookymoove/features/new_game/presentation/game_registry.dart';
import 'package:spookymoove/features/persona/application/persona_suggester.dart';
import 'package:spookymoove/features/xiangqi/data/dart_xiangqi_rules.dart';
import 'package:spookymoove/features/xiangqi/domain/xiangqi_models.dart';
import 'package:spookymoove/features/xiangqi/presentation/widgets/xiangqi_piece_disc.dart';
import 'package:spookymoove/features/xiangqi/presentation/widgets/xiangqi_suggested_move.dart';
import 'package:spookymoove/features/xiangqi/presentation/xiangqi_board_controller.dart';

import 'suggestion_card_test.dart' show FixedSuggestionController;

const _startFen =
    'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1';

SuggestionReady ready(String uci) => SuggestionReady(
  suggestion: PersonaSuggestion(
    move: uci,
    score: const CentipawnScore(30),
    winChance: 55,
    depth: 16,
    nps: 850000,
  ),
);

Future<void> pumpCard(
  WidgetTester tester,
  SuggestionState state, {
  String fen = _startFen,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = const Size(360, 240);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        suggestionControllerProvider.overrideWith(
          () => FixedSuggestionController(state),
        ),
        activeGameKindProvider.overrideWithValue(GameKind.xiangqi),
        xiangqiRulesProvider.overrideWithValue(DartXiangqiRules(fen: fen)),
      ],
      child: const MaterialApp(home: Scaffold(body: SuggestionCard())),
    ),
  );
}

XiangqiPiece discPiece(WidgetTester tester) => tester
    .widget<XiangqiPieceDisc>(
      find.descendant(
        of: find.byType(XiangqiSuggestedMove),
        matching: find.byType(XiangqiPieceDisc),
      ),
    )
    .piece;

void main() {
  testWidgets('Red cannon: disc, absolute line and WXF expert line', (
    tester,
  ) async {
    await pumpCard(tester, ready('h3e3'));

    expect(
      discPiece(tester),
      const XiangqiPiece(PlayerSide.first, XiangqiPieceKind.cannon),
    );
    expect(find.text('H3 ➔ E3'), findsOneWidget);
    expect(find.text('C2.5 · EVAL +0.3 • DEPTH 16 • 850k nps'), findsOneWidget);
  });

  testWidgets('Black cannon: WXF from Black, line still in Red frame', (
    tester,
  ) async {
    await pumpCard(
      tester,
      ready('b8e8'),
      fen: 'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/4C2C1/9/RNBAKABNR b - - 1 1',
    );

    expect(
      discPiece(tester),
      const XiangqiPiece(PlayerSide.second, XiangqiPieceKind.cannon),
    );
    expect(find.text('B8 ➔ E8'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^C2\.5 · EVAL')), findsOneWidget);
  });

  testWidgets('a capture ends with the capture mark', (tester) async {
    await pumpCard(tester, ready('h3h10'));

    expect(find.text('H3 ➔ H10 ✕'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^C2\+7 · EVAL')), findsOneWidget);
  });

  testWidgets('a move not legal here: empty line and the bare eval', (
    tester,
  ) async {
    await pumpCard(tester, ready('a1a9'));

    expect(find.byType(XiangqiPieceDisc), findsNothing);
    expect(find.text(SuggestionCard.emptyLine), findsOneWidget);
    expect(find.text('EVAL +0.3 • DEPTH 16 • 850k nps'), findsOneWidget);
  });

  testWidgets('no overflow at text scale 2.0', (tester) async {
    await pumpCard(tester, ready('h3h10'), textScale: 2.0);
    expect(tester.takeException(), isNull);
  });
}
