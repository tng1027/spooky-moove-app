import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game/player_side.dart';
import '../../persona/domain/persona_tier.dart';
import '../../persona/presentation/persona_tier_controller.dart';
import '../domain/game_kind.dart';
import '../domain/game_session.dart';
import 'game_registry.dart';

/// The current game; null until the user starts one (OB-011).
final gameSessionProvider =
    NotifierProvider<GameSessionController, GameSession?>(
      GameSessionController.new,
    );

class GameSessionController extends Notifier<GameSession?> {
  @override
  GameSession? build() => null;

  /// Every [start] is a new game, even with the same game and side.
  @override
  bool updateShouldNotify(GameSession? previous, GameSession? next) => true;

  /// Discards the current game and starts [game] from the initial position
  /// with [tier], or no persona tier when none was picked
  /// (OB-011 REQ-004, REQ-005, REQ-007).
  void start(GameKind game, PlayerSide userSide, [PersonaTier? tier]) {
    ref.read(gameControllerProvider(game)).newGame(userSide);
    ref.read(personaTierProvider.notifier).reset(tier);
    state = GameSession(game: game, userSide: userSide);
  }

  /// Ends the current game without starting another (OB-050 D1). The
  /// suggestion controller hears the change and cancels any running search.
  void discard() => state = null;
}
