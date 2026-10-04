import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/engine/engine_models.dart';
import 'package:spookymoove/core/game/player_side.dart';
import 'package:spookymoove/features/advisor/presentation/suggestion_controller.dart';
import 'package:spookymoove/features/advisor/presentation/suggestion_providers.dart';
import 'package:spookymoove/features/chess/domain/chess_models.dart';
import 'package:spookymoove/features/chess/presentation/chess_board_controller.dart';
import 'package:spookymoove/features/new_game/domain/game_kind.dart';
import 'package:spookymoove/features/new_game/presentation/game_session_controller.dart';
import 'package:spookymoove/features/persona/domain/persona_tier.dart';
import 'package:spookymoove/features/xiangqi/data/dart_xiangqi_rules.dart';
import 'package:spookymoove/features/xiangqi/domain/xiangqi_models.dart';
import 'package:spookymoove/features/xiangqi/presentation/xiangqi_board_controller.dart';

import '../../persona/fake_game_engine.dart';

/// Real `GameKind.xiangqi` sessions through the OB-042 seam (OB-046).
class Harness {
  Harness({String? xiangqiFen}) {
    container = ProviderContainer(
      overrides: [
        gameEngineProvider.overrideWithValue(engine),
        boardClockProvider.overrideWithValue(() => now),
        if (xiangqiFen != null)
          xiangqiRulesProvider.overrideWithValue(
            DartXiangqiRules(fen: xiangqiFen),
          ),
      ],
    );
    container.read(suggestionControllerProvider);
  }

  final FakeGameEngine engine = FakeGameEngine();
  late final ProviderContainer container;
  Duration now = Duration.zero;

  SuggestionState get state => container.read(suggestionControllerProvider);
  XiangqiBoardState get xiangqi =>
      container.read(xiangqiBoardControllerProvider);
  ChessBoardState get chess => container.read(chessBoardControllerProvider);

  void start(GameKind game, PlayerSide side, [PersonaTier? tier]) =>
      container.read(gameSessionProvider.notifier).start(game, side, tier);

  /// Enters [uci] on the Xiangqi board as the user would.
  void play(String uci) {
    now += XiangqiBoardController.commitGuard;
    final controller = container.read(xiangqiBoardControllerProvider.notifier);
    controller.commitEngineMove(uci);
  }

  void dispose() => container.dispose();
}

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

  Harness harness({String? xiangqiFen}) {
    final h = Harness(xiangqiFen: xiangqiFen);
    addTearDown(h.dispose);
    return h;
  }

  test('the variant goes chess, xiangqi, chess; each first suggestion is '
      'legal and nothing is reused from the previous game', () async {
    final h = harness()
      ..start(GameKind.chess, PlayerSide.first, PersonaTier.god);
    await settle();
    h.engine.last.complete([fakeLine(1, 'e2e4', const CentipawnScore(40))]);
    await settle();
    expect(h.chess.suggestedMove, isNotNull);

    h.start(GameKind.xiangqi, PlayerSide.first, PersonaTier.god);
    await settle();
    expect(h.engine.variants, ['chess', 'xiangqi']);
    expect(h.state, isA<SuggestionThinking>());
    expect(h.engine.last.position.moves, isEmpty);
    h.engine.last.complete([fakeLine(1, 'h3e3', const CentipawnScore(30))]);
    await settle();
    expect((h.state as SuggestionReady).engineMove, 'h3e3');
    expect(h.xiangqi.suggestedMove?.uci, 'h3e3');

    h.start(GameKind.chess, PlayerSide.first, PersonaTier.god);
    await settle();
    expect(h.engine.variants, ['chess', 'xiangqi', 'chess']);
    expect(h.state, isA<SuggestionThinking>(), reason: 'cache cleared');
    h.engine.last.complete([fakeLine(1, 'd2d4', const CentipawnScore(20))]);
    await settle();
    expect((h.state as SuggestionReady).engineMove, 'd2d4');
    expect(
      h.chess.suggestedMove,
      ChessMove(from: ChessSquare.parse('d2'), to: ChessSquare.parse('d4')),
    );
    expect(h.engine.searches, hasLength(3));
  });

  test('a Black move checking the Red general plays heavyImpact', () async {
    final h = harness(xiangqiFen: '3k5/9/9/9/9/9/9/9/r8/4K4 b - - 0 1')
      ..start(GameKind.xiangqi, PlayerSide.first);
    await settle();

    h.play('a2a1');
    await settle();
    expect(h.xiangqi.checkedGeneral, const XiangqiPoint(4, 0));
    expect(haptics, contains('HapticFeedbackType.heavyImpact'));
  });

  testWidgets('a timeout shows ENGINE ERROR; RETRY searches again', (
    tester,
  ) async {
    final h = harness()
      ..start(GameKind.xiangqi, PlayerSide.first, PersonaTier.god);
    await tester.pump();
    expect(h.engine.searches, hasLength(1));

    await tester.pump(SuggestionController.timeout);
    expect(h.state, isA<SuggestionFailed>());

    h.container.read(suggestionControllerProvider.notifier).retry();
    await tester.pump();
    expect(h.state, isA<SuggestionThinking>());
    expect(h.engine.searches, hasLength(2));
    expect(h.engine.variants.last, 'xiangqi');

    h.engine.last.complete([fakeLine(1, 'h3e3', const CentipawnScore(30))]);
    await tester.pump();
    expect((h.state as SuggestionReady).engineMove, 'h3e3');
  });
}
