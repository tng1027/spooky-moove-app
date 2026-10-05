import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/engine/engine_models.dart';
import 'package:spookymoove/core/game/active_game.dart';
import 'package:spookymoove/core/game/player_side.dart';
import 'package:spookymoove/features/advisor/presentation/suggestion_controller.dart';
import 'package:spookymoove/features/advisor/presentation/suggestion_providers.dart';
import 'package:spookymoove/features/chess/presentation/chess_board_controller.dart';
import 'package:spookymoove/features/new_game/domain/game_kind.dart';
import 'package:spookymoove/features/new_game/presentation/game_registry.dart';
import 'package:spookymoove/features/new_game/presentation/game_session_controller.dart';
import 'package:spookymoove/features/persona/domain/persona_tier.dart';
import 'package:spookymoove/core/l10n/app_strings.dart';
import 'package:spookymoove/features/settings/application/app_language_controller.dart';

import '../../persona/fake_game_engine.dart';

/// A new identity per position (a const object would always be identical).
class _Position {}

/// A second game that exists only in this test.
class FakeGame extends Notifier<ActiveGameState>
    implements ActiveGameController {
  @override
  ActiveGameState build() => ActiveGameState(
    sideToMove: PlayerSide.first,
    positionId: _Position(),
    legalMoveCount: 44,
  );

  @override
  void newGame(PlayerSide userSide) => state = build();

  @override
  void undo() {}

  @override
  void commitEngineMove(String engineMove) {}

  @override
  bool showSuggestion(String? engineMove) => true;

  @override
  EnginePosition enginePosition() => const EnginePosition.startPos();
}

final fakeGameProvider = NotifierProvider<FakeGame, ActiveGameState>(
  FakeGame.new,
);

class UseFakeGame extends Notifier<bool> {
  @override
  bool build() => false;

  void enable() => state = true;
}

final useFakeGameProvider = NotifierProvider<UseFakeGame, bool>(
  UseFakeGame.new,
);

/// Records the order of variant switches and searches.
class LoggingEngine extends FakeGameEngine {
  final List<String> log = [];

  @override
  Future<void> setVariant(String variant) {
    log.add('variant $variant');
    return super.setVariant(variant);
  }

  @override
  FakeSearch search(EnginePosition position, SearchLimits limits) {
    log.add('search');
    return super.search(position, limits) as FakeSearch;
  }
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LoggingEngine engine;
  late ProviderContainer container;

  setUp(() {
    engine = LoggingEngine();
    container = ProviderContainer(
      overrides: [
        appStringsProvider.overrideWithValue(AppStrings.english),
        gameEngineProvider.overrideWithValue(engine),
        activeGameStateSourceProvider.overrideWith(
          (ref) => ref.watch(useFakeGameProvider)
              ? fakeGameProvider
              : chessBoardControllerProvider.select(
                  (b) => chessActiveGameState(b, AppStrings.english),
                ),
        ),
        activeGameControllerProvider.overrideWith(
          (ref) => ref.watch(useFakeGameProvider)
              ? ref.watch(fakeGameProvider.notifier)
              : ref.watch(chessBoardControllerProvider.notifier),
        ),
        activeEngineVariantProvider.overrideWith(
          (ref) => ref.watch(useFakeGameProvider) ? 'fake' : 'chess',
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(suggestionControllerProvider);
  });

  void start() => container
      .read(gameSessionProvider.notifier)
      .start(GameKind.chess, PlayerSide.first, PersonaTier.god);

  test('Chess sets its variant before the first search', () async {
    start();
    await settle();
    expect(engine.log, ['variant chess', 'search']);
  });

  test('a second game switches the variant before its first search; the Chess '
      'search cannot deliver', () async {
    start();
    await settle();
    final chessSearch = engine.last;

    container.read(useFakeGameProvider.notifier).enable();
    start();
    await settle();

    expect(engine.log, ['variant chess', 'search', 'variant fake', 'search']);
    expect(chessSearch.isPending, isFalse, reason: 'cancelled');
    expect(
      container.read(suggestionControllerProvider),
      isA<SuggestionThinking>(),
    );

    engine.last.complete([fakeLine(1, 'a1a2', const CentipawnScore(10))]);
    await settle();
    final state = container.read(suggestionControllerProvider);
    expect((state as SuggestionReady).engineMove, 'a1a2');
    expect(engine.startCount, 1);
  });

  test('a new game in the same variant does not switch again', () async {
    start();
    await settle();
    start();
    await settle();
    expect(engine.log.where((e) => e.startsWith('variant')), ['variant chess']);
  });
}
