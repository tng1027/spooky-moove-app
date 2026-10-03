import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/fairy_stockfish/fairy_stockfish_engine.dart';
import '../../../core/engine/game_engine.dart';
import '../../../core/engine/uci/uci_engine.dart';
import '../../persona/application/persona_suggester.dart';

/// The app's engine (Fairy-Stockfish over FFI). Started lazily by the
/// suggestion controller. Overridden in tests.
final gameEngineProvider = Provider<GameEngine>((ref) {
  final engine = UciEngine(transportFactory: FairyStockfishEngine.new);
  ref.onDispose(engine.dispose);
  return engine;
});

final personaSuggesterProvider = Provider<PersonaSuggester>(
  (ref) => PersonaSuggester(engine: ref.watch(gameEngineProvider)),
);
