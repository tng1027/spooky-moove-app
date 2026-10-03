import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import '../engine_transport.dart';
import 'fairy_stockfish_bindings.dart';

/// Thrown or emitted on [FairyStockfishEngine.lines] when the native engine
/// or its isolate fails.
class FairyStockfishException implements Exception {
  const FairyStockfishException(this.message);

  final String message;

  @override
  String toString() => 'FairyStockfishException: $message';
}

enum _EngineState { idle, starting, running, disposing, disposed }

/// Runs Fairy-Stockfish in-process and exchanges raw text protocol lines.
///
/// The native engine runs on its own native thread; a dedicated background
/// isolate owns the FFI calls, so the calling isolate never blocks. Only one
/// engine can run per process. Each instance is single-use: after [dispose],
/// create a new instance to restart the engine.
class FairyStockfishEngine implements EngineTransport {
  final StreamController<String> _lines = StreamController.broadcast();
  final ReceivePort _fromEngine = ReceivePort('fairy_stockfish.fromEngine');
  final Completer<void> _exited = Completer();

  _EngineState _state = _EngineState.idle;
  SendPort? _commands;

  /// Engine output lines, without trailing newlines. Native exceptions and
  /// isolate failures are delivered as [FairyStockfishException] errors.
  @override
  Stream<String> get lines => _lines.stream;

  bool get isRunning => _state == _EngineState.running;

  /// Spawns the engine isolate and starts the native engine.
  ///
  /// Throws [StateError] if this instance was already started or another
  /// engine is running in the process.
  @override
  Future<void> start() async {
    if (_state != _EngineState.idle) {
      throw StateError('FairyStockfishEngine can only be started once.');
    }
    _state = _EngineState.starting;

    final ready = Completer<SendPort>();
    _fromEngine.listen((message) => _onEngineMessage(message, ready));

    try {
      await Isolate.spawn(
        _engineIsolateMain,
        _fromEngine.sendPort,
        debugName: 'fairy_stockfish',
        onError: _fromEngine.sendPort,
        onExit: _fromEngine.sendPort,
      );
      _commands = await ready.future;
    } catch (_) {
      _state = _EngineState.disposed;
      _fromEngine.close();
      if (!_exited.isCompleted) _exited.complete();
      await _lines.close();
      rethrow;
    }
    _state = _EngineState.running;
  }

  /// Sends one command line (e.g. `uci`, `go movetime 500`) to the engine.
  @override
  void send(String line) {
    if (_state != _EngineState.running) {
      throw StateError('FairyStockfishEngine is not running.');
    }
    _commands!.send(line);
  }

  /// Stops any search, quits the engine and releases the native thread.
  ///
  /// Safe to call during a search. Throws [TimeoutException] if the engine
  /// does not exit within [timeout]; the isolate is then left alive because
  /// killing it while the native thread still calls back is unsafe.
  @override
  Future<void> dispose({Duration timeout = const Duration(seconds: 3)}) async {
    switch (_state) {
      case _EngineState.idle:
        _state = _EngineState.disposed;
        _fromEngine.close();
        _exited.complete();
        await _lines.close();
        return;
      case _EngineState.starting:
        throw StateError('Cannot dispose while the engine is starting.');
      case _EngineState.disposing:
      case _EngineState.disposed:
        return _exited.future;
      case _EngineState.running:
        break;
    }

    _state = _EngineState.disposing;
    _commands!
      ..send('stop')
      ..send('quit');
    await _exited.future.timeout(timeout);
  }

  void _onEngineMessage(Object? message, Completer<SendPort> ready) {
    switch (message) {
      case final String line:
        if (line.startsWith(fsErrorPrefix)) {
          _lines.addError(
            FairyStockfishException(line.substring(fsErrorPrefix.length)),
          );
        } else {
          _lines.add(line);
        }
      case _EngineReady(:final commands):
        ready.complete(commands);
      case _EngineStartFailed(:final code):
        ready.completeError(
          code == fsAlreadyRunning
              ? StateError('Another Fairy-Stockfish engine is already running.')
              : FairyStockfishException('fs_start failed with code $code.'),
        );
      case _EngineExited():
        if (_state != _EngineState.disposing) {
          _lines.addError(
            const FairyStockfishException('Engine exited unexpectedly.'),
          );
        }
      case [final Object? error, final Object? stackTrace]:
        final failure = FairyStockfishException(
          'Engine isolate error: $error\n$stackTrace',
        );
        if (!ready.isCompleted) {
          ready.completeError(failure);
        } else {
          _lines.addError(failure);
        }
      case null:
        _onIsolateExit(ready);
    }
  }

  void _onIsolateExit(Completer<SendPort> ready) {
    if (!ready.isCompleted) {
      ready.completeError(
        const FairyStockfishException('Engine isolate exited during start.'),
      );
    }
    _state = _EngineState.disposed;
    _commands = null;
    _fromEngine.close();
    unawaited(_lines.close());
    if (!_exited.isCompleted) _exited.complete();
  }
}

final class _EngineReady {
  const _EngineReady(this.commands);

  final SendPort commands;
}

final class _EngineStartFailed {
  const _EngineStartFailed(this.code);

  final int code;
}

final class _EngineExited {
  const _EngineExited();
}

/// Entry point of the engine isolate. Owns every FFI call into the engine.
void _engineIsolateMain(SendPort toOwner) {
  final commands = ReceivePort('fairy_stockfish.commands');
  late final NativeCallable<FsLineCallback> onLine;

  void shutDown() {
    fsJoin();
    onLine.close();
    commands.close();
    toOwner.send(const _EngineExited());
  }

  onLine = NativeCallable<FsLineCallback>.listener((Pointer<Utf8> native) {
    final line = native.toDartString();
    fsFree(native);
    if (line == fsExitSentinel) {
      shutDown();
    } else {
      toOwner.send(line);
    }
  });

  final code = fsStart(onLine.nativeFunction);
  if (code != fsOk) {
    onLine.close();
    commands.close();
    toOwner.send(_EngineStartFailed(code));
    return;
  }

  commands.listen((message) {
    final native = (message as String).toNativeUtf8();
    try {
      fsSend(native);
    } finally {
      malloc.free(native);
    }
  });
  toOwner.send(_EngineReady(commands.sendPort));
}
