import 'dart:async';

import 'package:spookymoove/core/engine/engine_models.dart';
import 'package:spookymoove/core/engine/game_engine.dart';

class FakeSearch implements SearchHandle {
  FakeSearch(this.position, this.limits) {
    _result.future.ignore();
  }

  final EnginePosition position;
  final SearchLimits limits;
  final Completer<SearchResult> _result = Completer();

  @override
  Stream<SearchInfo> get updates => const Stream.empty();

  @override
  Future<SearchResult> get result => _result.future;

  bool get isPending => !_result.isCompleted;

  void complete(List<SearchLine> lines, {int depth = 8}) {
    _result.complete(
      SearchResult(
        bestMove: lines.isEmpty
            ? const NoLegalMove()
            : EngineMove(lines.first.firstMove!),
        lines: lines,
        depth: lines.isEmpty ? null : depth,
        nps: 500000,
      ),
    );
  }

  void fail(Object error) {
    if (isPending) _result.completeError(error);
  }
}

/// Mirrors [GameEngine]'s contract: a new search cancels the running one.
class FakeGameEngine implements GameEngine {
  final List<FakeSearch> searches = [];
  final List<String> variants = [];
  int stopCount = 0;
  int startCount = 0;
  int disposeCount = 0;

  /// The next [start] fails with this, then the flag clears.
  Object? startError;

  FakeSearch get last => searches.last;

  @override
  SearchHandle search(EnginePosition position, SearchLimits limits) {
    for (final s in searches) {
      s.fail(const SearchCancelledException());
    }
    final search = FakeSearch(position, limits);
    searches.add(search);
    return search;
  }

  @override
  void stop() => stopCount++;

  @override
  Future<void> start() async {
    startCount++;
    final error = startError;
    startError = null;
    if (error != null) throw error;
  }

  @override
  Future<void> setVariant(String variant) async => variants.add(variant);

  @override
  Future<void> dispose() async {
    disposeCount++;
    for (final s in searches) {
      s.fail(const SearchCancelledException());
    }
  }
}

SearchLine fakeLine(
  int rank,
  String move,
  EngineScore score, {
  int depth = 8,
}) => SearchLine(multiPv: rank, depth: depth, score: score, pv: [move]);
