import 'dart:math' as math;

import '../../../core/engine/engine_models.dart';
import '../../../core/engine/game_engine.dart';
import '../domain/persona_config.dart';
import '../domain/persona_tier.dart';
import '../domain/tier_selection.dart';
import '../domain/win_chance.dart';

/// The move suggested by a persona tier, with its evaluation from the
/// user's side (OB-022 REQ-014).
class PersonaSuggestion {
  const PersonaSuggestion({
    required this.move,
    required this.score,
    required this.winChance,
    this.depth,
    this.nps,
  });

  /// Engine notation.
  final String move;
  final EngineScore score;
  final double winChance;
  final int? depth;
  final int? nps;
}

/// Turns a position and a persona tier into a suggestion through
/// [GameEngine] (OB-022).
///
/// Searched positions must have the user to move, so engine scores are
/// already from the user's side. Suggestions are cached per (position,
/// tier) for stability; call [clearCache] when a new game starts, since the
/// cache key does not include the variant.
class PersonaSuggester {
  PersonaSuggester({required this._engine, math.Random? random})
    : _random = random ?? math.Random();

  final GameEngine _engine;
  final math.Random _random;
  final Map<(String, PersonaTier), PersonaSuggestion> _cache = {};

  /// Incremented by every [suggest] call; a search whose generation is no
  /// longer current is superseded.
  int _generation = 0;
  bool _isSearching = false;

  /// Null when [legalMoveCount] is 0 (game end).
  ///
  /// Fails with [SearchCancelledException] when a newer call supersedes
  /// this one, and with [EngineFailureException] when the engine fails or
  /// reports no scored line.
  Future<PersonaSuggestion?> suggest({
    required EnginePosition position,
    required int legalMoveCount,
    required PersonaTier tier,
  }) async {
    final generation = ++_generation;
    if (legalMoveCount == 0) {
      _stopRunningSearch();
      return null;
    }
    final key = (_positionKey(position), tier);
    final cached = _cache[key];
    if (cached != null) {
      _stopRunningSearch();
      return cached;
    }

    _isSearching = true;
    final SearchResult result;
    try {
      result = await _engine
          .search(position, limitsFor(tier, legalMoveCount))
          .result;
    } finally {
      if (generation == _generation) _isSearching = false;
    }
    // A search ended early by stop() is shallower, so it is not cached.
    if (generation != _generation) throw const SearchCancelledException();

    final suggestion = _select(result, tier);
    _cache[key] = suggestion;
    return suggestion;
  }

  void clearCache() => _cache.clear();

  /// Supersedes the pending [suggest] call (it fails with
  /// [SearchCancelledException]) and stops its search.
  void cancel() {
    _generation++;
    _stopRunningSearch();
  }

  static SearchLimits limitsFor(PersonaTier tier, int legalMoveCount) {
    return switch (tier) {
      PersonaTier.baby ||
      PersonaTier.gentle ||
      PersonaTier.soft ||
      PersonaTier.even => SearchLimits(
        moveTime: PersonaConfig.searchCap,
        depth: PersonaConfig.allMoveDepth,
        multiPv: legalMoveCount,
      ),
      PersonaTier.solid => SearchLimits(
        moveTime: PersonaConfig.searchCap,
        depth: PersonaConfig.solidDepth,
      ),
      PersonaTier.master => SearchLimits(
        moveTime: PersonaConfig.searchCap,
        depth: PersonaConfig.masterDepth,
      ),
      PersonaTier.god => SearchLimits(moveTime: PersonaConfig.searchCap),
    };
  }

  void _stopRunningSearch() {
    if (!_isSearching) return;
    _isSearching = false;
    _engine.stop();
  }

  PersonaSuggestion _select(SearchResult result, PersonaTier tier) {
    final lineByCandidate = <MoveCandidate, SearchLine>{};
    for (final line in result.lines) {
      final move = line.firstMove;
      if (move == null) continue;
      final score = line.score;
      final candidate = MoveCandidate(
        move: move,
        winChance: winChance(score),
        userMatedIn: score is MateScore && score.moves < 0
            ? -score.moves
            : null,
      );
      lineByCandidate[candidate] = line;
    }
    if (lineByCandidate.isEmpty) {
      throw const EngineFailureException('Engine reported no scored line.');
    }

    final chosen = selectMove(lineByCandidate.keys.toList(), tier, _random);
    return PersonaSuggestion(
      move: chosen.move,
      score: lineByCandidate[chosen]!.score,
      winChance: chosen.winChance,
      depth: result.depth,
      nps: result.nps,
    );
  }

  static String _positionKey(EnginePosition position) =>
      '${position.fen ?? 'startpos'}|${position.moves.join(' ')}';
}
