/// Protocol-agnostic engine data types.
///
/// Scores are always from the perspective of the side to move in the searched
/// position; conversion to the user's side happens in the persona layer.
library;

/// Engine evaluation of a position.
sealed class EngineScore {
  const EngineScore();
}

final class CentipawnScore extends EngineScore {
  const CentipawnScore(this.centipawns);

  final int centipawns;

  double get pawns => centipawns / 100;

  @override
  bool operator ==(Object other) =>
      other is CentipawnScore && other.centipawns == centipawns;

  @override
  int get hashCode => centipawns.hashCode;

  @override
  String toString() => 'CentipawnScore($centipawns)';
}

/// Forced mate. Positive [moves]: the side to move mates in that many moves.
/// Negative: the side to move gets mated.
final class MateScore extends EngineScore {
  const MateScore(this.moves);

  final int moves;

  @override
  bool operator ==(Object other) => other is MateScore && other.moves == moves;

  @override
  int get hashCode => moves.hashCode;

  @override
  String toString() => 'MateScore($moves)';
}

/// Whether a score is exact or only a bound from an aspiration-window fail.
enum ScoreBound { exact, lowerBound, upperBound }

/// One principal variation reported by the engine.
class SearchLine {
  const SearchLine({
    required this.multiPv,
    required this.depth,
    required this.score,
    this.bound = ScoreBound.exact,
    this.pv = const [],
  });

  /// 1-based rank of this line (1 = best).
  final int multiPv;
  final int depth;
  final EngineScore score;
  final ScoreBound bound;

  /// Moves in engine notation (e.g. `e2e4`, `h10g8`).
  final List<String> pv;

  String? get firstMove => pv.isEmpty ? null : pv.first;
}

/// One streaming search update.
class SearchInfo {
  const SearchInfo({
    required this.depth,
    this.seldepth,
    this.nodes,
    this.nps,
    this.time,
    this.line,
  });

  final int depth;
  final int? seldepth;
  final int? nodes;
  final int? nps;
  final Duration? time;

  /// Present when the update carries a score.
  final SearchLine? line;
}

/// Final move reported by the engine.
sealed class BestMove {
  const BestMove();
}

final class EngineMove extends BestMove {
  const EngineMove(this.move, {this.ponder});

  final String move;
  final String? ponder;

  @override
  bool operator ==(Object other) =>
      other is EngineMove && other.move == move && other.ponder == ponder;

  @override
  int get hashCode => Object.hash(move, ponder);

  @override
  String toString() => 'EngineMove($move, ponder: $ponder)';
}

/// The side to move has no legal move (mate or stalemate).
final class NoLegalMove extends BestMove {
  const NoLegalMove();

  @override
  bool operator ==(Object other) => other is NoLegalMove;

  @override
  int get hashCode => (NoLegalMove).hashCode;

  @override
  String toString() => 'NoLegalMove()';
}

class SearchResult {
  const SearchResult({
    required this.bestMove,
    this.lines = const [],
    this.depth,
    this.nps,
  });

  final BestMove bestMove;

  /// Lines of the deepest iteration completed for every line, ordered by
  /// [SearchLine.multiPv]. Empty if the engine reported no scored line.
  final List<SearchLine> lines;

  /// Depth of [lines].
  final int? depth;

  /// Last reported nodes per second.
  final int? nps;
}

/// Position to search: the variant's start position or a FEN, plus moves.
class EnginePosition {
  const EnginePosition.startPos({this.moves = const []}) : fen = null;

  const EnginePosition.fen(String this.fen, {this.moves = const []});

  /// Null means the variant's start position.
  final String? fen;
  final List<String> moves;
}

class SearchLimits {
  SearchLimits({required this.moveTime, this.depth, this.multiPv = 1}) {
    if (moveTime <= Duration.zero || moveTime > maxMoveTime) {
      throw RangeError.value(
        moveTime.inMilliseconds,
        'moveTime',
        'Must be within 1..${maxMoveTime.inMilliseconds} ms',
      );
    }
    if (depth != null) RangeError.checkValueInInterval(depth!, 1, 245, 'depth');
    RangeError.checkValueInInterval(multiPv, 1, 500, 'multiPv');
  }

  /// Engine time cap per search, leaving margin within the 1000 ms budget
  /// (OB-021 D14).
  static const Duration maxMoveTime = Duration(milliseconds: 900);

  final Duration moveTime;

  /// Optional depth cap; the search stops at whichever limit comes first.
  final int? depth;

  /// Number of lines to search. Values above the number of legal moves
  /// score every legal move.
  final int multiPv;
}

/// Engine resource limits applied on start (thermal/power NFRs).
class EngineConfig {
  EngineConfig({this.threads = 2, this.hashMb = 16}) {
    RangeError.checkValueInInterval(threads, 1, 2, 'threads');
    RangeError.checkValueInInterval(hashMb, 16, 32, 'hashMb');
  }

  final int threads;
  final int hashMb;
}

/// The search was superseded by a newer search or the engine was disposed.
class SearchCancelledException implements Exception {
  const SearchCancelledException();

  @override
  String toString() => 'SearchCancelledException';
}

/// The engine failed to start, rejected a command, or crashed.
class EngineFailureException implements Exception {
  const EngineFailureException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'EngineFailureException: $message${cause == null ? '' : ' ($cause)'}';
}
