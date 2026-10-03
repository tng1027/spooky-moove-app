import '../../../core/game/player_side.dart';
import 'xiangqi_rules.dart';

/// Why the side to move lost (OB-047 BR-001).
enum XiangqiEndReason { checkmate, noMoves }

/// Whether the game is still on, composed from [XiangqiRules] facts
/// (OB-047). No draws or repetition rulings (XQ6, XQ9).
sealed class XiangqiGameStatus {
  const XiangqiGameStatus();

  bool get isOver;

  /// The side to move with no legal move loses, in check or not.
  static XiangqiGameStatus of(XiangqiRules rules) {
    if (!rules.hasNoLegalMoves) return const XiangqiInProgress();
    return XiangqiLoss(
      winner: rules.sideToMove.opposite,
      reason: rules.isCheck
          ? XiangqiEndReason.checkmate
          : XiangqiEndReason.noMoves,
    );
  }
}

final class XiangqiInProgress extends XiangqiGameStatus {
  const XiangqiInProgress();

  @override
  bool get isOver => false;

  @override
  bool operator ==(Object other) => other is XiangqiInProgress;

  @override
  int get hashCode => (XiangqiInProgress).hashCode;

  @override
  String toString() => 'XiangqiInProgress()';
}

final class XiangqiLoss extends XiangqiGameStatus {
  const XiangqiLoss({required this.winner, required this.reason});

  final PlayerSide winner;
  final XiangqiEndReason reason;

  @override
  bool get isOver => true;

  @override
  bool operator ==(Object other) =>
      other is XiangqiLoss && other.winner == winner && other.reason == reason;

  @override
  int get hashCode => Object.hash(XiangqiLoss, winner, reason);

  @override
  String toString() => 'XiangqiLoss(${winner.name}, ${reason.name})';
}
