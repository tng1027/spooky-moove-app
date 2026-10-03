import 'chess_models.dart';
import 'chess_rules.dart';

/// Why a game ended in a draw (OB-024 A1).
enum DrawReason {
  stalemate,
  insufficientMaterial,
  fivefoldRepetition,
  seventyFiveMoveRule,
}

/// A draw the players may claim; the game continues (OB-024 A2).
enum ClaimableDraw { threefoldRepetition, fiftyMoveRule }

/// Whether the game is still on, composed from [ChessRules] facts (OB-024).
///
/// Never derived from the `chess` package's `in_draw` / `game_over`, which
/// treat the claimable draws as automatic (REQ-009).
sealed class ChessGameStatus {
  const ChessGameStatus();

  static const int fivefoldRepetition = 5;
  static const int seventyFiveMoveHalfmoves = 150;
  static const int threefoldRepetition = 3;
  static const int fiftyMoveHalfmoves = 100;

  bool get isOver;

  /// Checkmate first: it takes precedence over the 75-move rule (REQ-012).
  static ChessGameStatus of(ChessRules rules) {
    if (rules.isCheckmate) {
      return ChessCheckmate(winner: rules.sideToMove.opposite);
    }
    if (rules.isStalemate) {
      return const ChessDraw(reason: DrawReason.stalemate);
    }
    if (rules.hasInsufficientMaterial) {
      return const ChessDraw(reason: DrawReason.insufficientMaterial);
    }
    final repetitions = rules.repetitionCount;
    final halfmoves = rules.halfmoveClock;
    if (repetitions >= fivefoldRepetition) {
      return const ChessDraw(reason: DrawReason.fivefoldRepetition);
    }
    if (halfmoves >= seventyFiveMoveHalfmoves) {
      return const ChessDraw(reason: DrawReason.seventyFiveMoveRule);
    }
    if (repetitions >= threefoldRepetition) {
      return const ChessInProgress(
        claimableDraw: ClaimableDraw.threefoldRepetition,
      );
    }
    if (halfmoves >= fiftyMoveHalfmoves) {
      return const ChessInProgress(claimableDraw: ClaimableDraw.fiftyMoveRule);
    }
    return const ChessInProgress();
  }
}

final class ChessInProgress extends ChessGameStatus {
  const ChessInProgress({this.claimableDraw});

  final ClaimableDraw? claimableDraw;

  @override
  bool get isOver => false;

  @override
  bool operator ==(Object other) =>
      other is ChessInProgress && other.claimableDraw == claimableDraw;

  @override
  int get hashCode => Object.hash(ChessInProgress, claimableDraw);

  @override
  String toString() => 'ChessInProgress(${claimableDraw?.name})';
}

final class ChessCheckmate extends ChessGameStatus {
  const ChessCheckmate({required this.winner});

  final PieceColor winner;

  @override
  bool get isOver => true;

  @override
  bool operator ==(Object other) =>
      other is ChessCheckmate && other.winner == winner;

  @override
  int get hashCode => Object.hash(ChessCheckmate, winner);

  @override
  String toString() => 'ChessCheckmate(${winner.name})';
}

final class ChessDraw extends ChessGameStatus {
  const ChessDraw({required this.reason});

  final DrawReason reason;

  @override
  bool get isOver => true;

  @override
  bool operator ==(Object other) =>
      other is ChessDraw && other.reason == reason;

  @override
  int get hashCode => Object.hash(ChessDraw, reason);

  @override
  String toString() => 'ChessDraw(${reason.name})';
}
