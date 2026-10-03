import 'engine_models.dart';

/// Protocol-agnostic engine used by the state layer.
abstract interface class GameEngine {
  /// Starts the engine and applies resource defaults. Can be called again
  /// after [dispose] or after a failure to restart the engine.
  Future<void> start();

  /// Selects the game variant (e.g. `chess`, `xiangqi`) and resets engine
  /// game state.
  Future<void> setVariant(String variant);

  /// Starts a search. A running search is cancelled first: its
  /// [SearchHandle.result] fails with [SearchCancelledException] and none of
  /// its output is delivered afterwards.
  SearchHandle search(EnginePosition position, SearchLimits limits);

  /// Ends the running search early; its result is still delivered.
  void stop();

  /// Cancels any running search and shuts the engine down.
  Future<void> dispose();
}

/// Handle to one search.
abstract interface class SearchHandle {
  /// Streaming updates; closes when the search finishes or is cancelled.
  Stream<SearchInfo> get updates;

  /// Final result. Fails with [SearchCancelledException] when superseded or
  /// with [EngineFailureException] when the engine fails.
  Future<SearchResult> get result;
}
