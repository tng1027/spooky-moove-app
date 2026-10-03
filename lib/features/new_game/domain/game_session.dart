import '../../../core/game/player_side.dart';
import 'game_kind.dart';

/// The game being played and the one side the user plays (OB-011 D1).
final class GameSession {
  const GameSession({required this.game, required this.userSide});

  final GameKind game;
  final PlayerSide userSide;

  @override
  bool operator ==(Object other) =>
      other is GameSession && other.game == game && other.userSide == userSide;

  @override
  int get hashCode => Object.hash(game, userSide);

  @override
  String toString() => 'GameSession(${game.name}, ${userSide.name})';
}
