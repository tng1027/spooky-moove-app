import 'dart:async';
import 'dart:collection';

import '../engine_models.dart';
import '../engine_transport.dart';
import '../game_engine.dart';
import 'uci_parser.dart';

/// [GameEngine] for engines speaking UCI (Fairy-Stockfish for Chess and
/// Xiangqi via `UCI_Variant`).
class UciEngine implements GameEngine {
  UciEngine({
    required this._transportFactory,
    EngineConfig? config,
    this.commandTimeout = const Duration(seconds: 5),
  }) : config = config ?? EngineConfig();

  final EngineTransport Function() _transportFactory;
  final EngineConfig config;

  /// Maximum wait for `uciok` / `readyok`.
  final Duration commandTimeout;

  EngineTransport? _transport;
  StreamSubscription<String>? _subscription;
  _Handshake? _handshake;

  /// Rejection reported since the last handshake; fails the next one, since
  /// the engine only confirms `setoption` commands through `readyok`.
  EngineFailureException? _optionRejection;
  int? _multiPv;

  /// Searches whose `bestmove` has not arrived yet, oldest first. The engine
  /// answers every `go` with exactly one `bestmove`, in order, so output
  /// always belongs to the head of this queue.
  final Queue<_UciSearch> _searches = Queue();

  bool get isRunning => _transport != null;

  @override
  Future<void> start() async {
    if (_transport != null || _subscription != null) {
      throw StateError('UciEngine is already started.');
    }
    final transport = _transportFactory();
    _subscription = transport.lines.listen(
      _onLine,
      onError: (Object error) => _fail(
        transport,
        EngineFailureException('Engine reported an error.', error),
      ),
      onDone: () => _fail(
        transport,
        const EngineFailureException('Engine exited unexpectedly.'),
      ),
    );

    try {
      await transport.start();
    } catch (error) {
      await _subscription?.cancel();
      _subscription = null;
      throw EngineFailureException('Engine failed to start.', error);
    }
    _transport = transport;
    _multiPv = null;
    _optionRejection = null;

    try {
      await _sendAndWait('uci', 'uciok');
      _send('setoption name Threads value ${config.threads}');
      _send('setoption name Hash value ${config.hashMb}');
      await _sendAndWait('isready', 'readyok');
    } catch (_) {
      await dispose();
      rethrow;
    }
  }

  @override
  Future<void> setVariant(String variant) async {
    _requireRunning();
    _cancelSearches();
    _send('setoption name UCI_Variant value $variant');
    _send('ucinewgame');
    await _sendAndWait('isready', 'readyok');
  }

  @override
  SearchHandle search(EnginePosition position, SearchLimits limits) {
    _requireRunning();
    _cancelSearches();

    if (limits.multiPv != _multiPv) {
      _send('setoption name MultiPV value ${limits.multiPv}');
      _multiPv = limits.multiPv;
    }
    _send(_positionCommand(position));
    _send(_goCommand(limits));

    final search = _UciSearch();
    _searches.add(search);
    return search;
  }

  @override
  void stop() {
    if (_transport == null) return;
    if (_searches.any((search) => !search.isCancelled)) _send('stop');
  }

  @override
  Future<void> dispose() async {
    final transport = _transport;
    _transport = null;
    _cancelSearches(sendStop: false);
    _searches.clear();
    _handshake?.fail(const EngineFailureException('Engine was disposed.'));
    _handshake = null;
    await _subscription?.cancel();
    _subscription = null;
    await transport?.dispose();
  }

  void _onLine(String line) {
    final handshake = _handshake;
    if (handshake != null && line.trim() == handshake.expected) {
      _handshake = null;
      final rejection = _optionRejection;
      _optionRejection = null;
      rejection == null ? handshake.complete() : handshake.fail(rejection);
      return;
    }
    if (line.startsWith('No such option')) {
      _optionRejection ??= EngineFailureException(
        'Engine rejected option: $line',
      );
      return;
    }
    if (line.startsWith('bestmove')) {
      _onBestMove(line);
      return;
    }
    if (line.startsWith('info') && _searches.isNotEmpty) {
      final search = _searches.first;
      if (search.isCancelled) return;
      final info = parseInfo(line);
      if (info != null) search.addInfo(info);
    }
  }

  void _onBestMove(String line) {
    if (_searches.isEmpty) return;
    final search = _searches.removeFirst();
    if (search.isCancelled) return;

    final bestMove = parseBestMove(line);
    if (bestMove == null) {
      search.fail(EngineFailureException('Malformed bestmove line: $line'));
    } else {
      search.complete(bestMove);
    }
  }

  void _fail(EngineTransport transport, EngineFailureException failure) {
    if (!identical(transport, _transport)) return;
    _transport = null;
    for (final search in _searches) {
      if (!search.isCancelled) search.fail(failure);
    }
    _searches.clear();
    _handshake?.fail(failure);
    _handshake = null;
    final subscription = _subscription;
    _subscription = null;
    unawaited(subscription?.cancel());
    // The failure above is the one reported; a second error while tearing
    // down the dead engine carries no extra information.
    transport.dispose().ignore();
  }

  void _cancelSearches({bool sendStop = true}) {
    var hadActiveSearch = false;
    for (final search in _searches) {
      if (search.isCancelled) continue;
      hadActiveSearch = true;
      search.cancel();
    }
    if (sendStop && hadActiveSearch) _send('stop');
  }

  Future<void> _sendAndWait(String command, String expected) async {
    if (_handshake != null) {
      throw StateError('Another engine command is in progress.');
    }
    final handshake = _Handshake(expected);
    _handshake = handshake;
    _send(command);
    try {
      await handshake.future.timeout(commandTimeout);
    } on TimeoutException {
      if (identical(_handshake, handshake)) _handshake = null;
      throw EngineFailureException('No "$expected" after "$command".');
    }
  }

  void _send(String line) => _transport!.send(line);

  void _requireRunning() {
    if (_transport == null) throw StateError('UciEngine is not running.');
  }

  static String _positionCommand(EnginePosition position) {
    final base = position.fen == null
        ? 'position startpos'
        : 'position fen ${position.fen}';
    return position.moves.isEmpty
        ? base
        : '$base moves ${position.moves.join(' ')}';
  }

  static String _goCommand(SearchLimits limits) {
    final depth = limits.depth;
    return 'go movetime ${limits.moveTime.inMilliseconds}'
        '${depth == null ? '' : ' depth $depth'}';
  }
}

class _Handshake {
  _Handshake(this.expected);

  final String expected;
  final Completer<void> _completer = Completer();

  Future<void> get future => _completer.future;

  void complete() {
    if (!_completer.isCompleted) _completer.complete();
  }

  void fail(Object error) {
    if (!_completer.isCompleted) _completer.completeError(error);
  }
}

class _UciSearch implements SearchHandle {
  _UciSearch() {
    // Callers may drop superseded handles without awaiting them; their
    // cancellation must not surface as an uncaught error.
    _result.future.ignore();
  }

  final StreamController<SearchInfo> _updates = StreamController.broadcast();
  final Completer<SearchResult> _result = Completer();

  /// Latest line per depth, then per multipv rank.
  final Map<int, Map<int, SearchLine>> _linesByDepth = {};
  int _lineCount = 0;
  int? _nps;
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  @override
  Stream<SearchInfo> get updates => _updates.stream;

  @override
  Future<SearchResult> get result => _result.future;

  void addInfo(SearchInfo info) {
    _nps = info.nps ?? _nps;
    final line = info.line;
    if (line != null) {
      (_linesByDepth[line.depth] ??= {})[line.multiPv] = line;
      if (line.multiPv > _lineCount) _lineCount = line.multiPv;
    }
    _updates.add(info);
  }

  void complete(BestMove bestMove) {
    final depth = _deepestCompleteDepth();
    final lines = depth == null
        ? const <SearchLine>[]
        : (_linesByDepth[depth]!.values.toList()
            ..sort((a, b) => a.multiPv.compareTo(b.multiPv)));
    _result.complete(
      SearchResult(
        bestMove: bestMove,
        lines: List.unmodifiable(lines),
        depth: depth,
        nps: _nps,
      ),
    );
    _updates.close();
  }

  void cancel() {
    _isCancelled = true;
    fail(const SearchCancelledException());
  }

  void fail(Object error) {
    if (!_result.isCompleted) _result.completeError(error);
    _updates.close();
  }

  int? _deepestCompleteDepth() {
    final depths = _linesByDepth.keys.toList()..sort();
    for (final depth in depths.reversed) {
      if (_linesByDepth[depth]!.length == _lineCount) return depth;
    }
    return null;
  }
}
