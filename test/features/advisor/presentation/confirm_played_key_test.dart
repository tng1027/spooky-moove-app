import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cataland/core/engine/engine_models.dart';
import 'package:cataland/core/theme/app_colors.dart';
import 'package:cataland/core/widgets/app_key.dart';
import 'package:cataland/features/advisor/presentation/suggestion_controller.dart';
import 'package:cataland/features/advisor/presentation/widgets/confirm_played_key.dart';
import 'package:cataland/features/chess/data/chess_package_rules.dart';
import 'package:cataland/features/chess/domain/chess_models.dart';
import 'package:cataland/features/chess/presentation/chess_board_controller.dart';
import 'package:cataland/features/persona/application/persona_suggester.dart';

class FixedSuggestionController extends SuggestionController {
  FixedSuggestionController(this.fixed);

  final SuggestionState fixed;

  @override
  SuggestionState build() => fixed;
}

void main() {
  late ProviderContainer container;

  const ready = SuggestionReady(
    suggestion: PersonaSuggestion(
      move: 'e2e4',
      score: CentipawnScore(30),
      winChance: 0.55,
    ),
  );

  Future<void> pumpKey(
    WidgetTester tester, {
    required bool isEnabled,
    required SuggestionState suggestion,
  }) async {
    container = ProviderContainer(
      overrides: [
        chessRulesProvider.overrideWithValue(ChessPackageRules()),
        suggestionControllerProvider.overrideWith(
          () => FixedSuggestionController(suggestion),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: ConfirmPlayedKey(isEnabled: isEnabled)),
          ),
        ),
      ),
    );
  }

  AppKey appKey(WidgetTester tester) => tester.widget<AppKey>(
    find.descendant(
      of: find.byKey(ConfirmPlayedKey.regionKey),
      matching: find.byType(AppKey),
    ),
  );

  Color? labelColor(WidgetTester tester) =>
      tester.widget<Text>(find.text(ConfirmPlayedKey.label)).style?.color;

  testWidgets('enabled: primary (dark label); a tap commits the suggestion', (
    tester,
  ) async {
    await pumpKey(tester, isEnabled: true, suggestion: ready);
    expect(appKey(tester).onTap, isNotNull);
    expect(appKey(tester).isPrimary, isTrue);
    expect(labelColor(tester), AppColors.bgDark);

    await tester.tap(find.byKey(ConfirmPlayedKey.regionKey));
    final board = container.read(chessBoardControllerProvider);
    expect(board.pieces[ChessSquare.parse('e4')], isNotNull);
    expect(board.pieces[ChessSquare.parse('e2')], isNull);
    expect(board.sideToMove, PieceColor.black);
  });

  testWidgets('disabled: no tap handler, secondary label', (tester) async {
    await pumpKey(tester, isEnabled: false, suggestion: ready);
    expect(appKey(tester).onTap, isNull);
    expect(labelColor(tester), AppColors.textSecondary);

    await tester.tap(find.byKey(ConfirmPlayedKey.regionKey));
    expect(
      container.read(chessBoardControllerProvider).pieces[ChessSquare.parse(
        'e2',
      )],
      isNotNull,
    );
  });

  testWidgets('without a ready suggestion a tap commits nothing', (
    tester,
  ) async {
    await pumpKey(
      tester,
      isEnabled: true,
      suggestion: const SuggestionThinking(),
    );

    await tester.tap(find.byKey(ConfirmPlayedKey.regionKey));
    expect(container.read(chessBoardControllerProvider).canUndo, isFalse);
  });

  testWidgets('announces itself as a button with a plain label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpKey(tester, isEnabled: true, suggestion: ready);

    expect(
      tester.getSemantics(find.byKey(ConfirmPlayedKey.regionKey)),
      matchesSemantics(
        label: ConfirmPlayedKey.semanticsLabel,
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        hasSelectedState: true,
      ),
    );
    semantics.dispose();
  });
}
