/// Text-line transport to an engine process or library.
///
/// Protocol adapters depend only on this interface, so the transport
/// (in-process FFI today, possibly a separate process on Android per OB-032)
/// can change without touching protocol code.
abstract interface class EngineTransport {
  /// Starts the engine. Throws if it cannot be started.
  Future<void> start();

  /// Sends one command line, without a trailing newline.
  void send(String line);

  /// Engine output lines. Errors signal engine failures; the stream closes
  /// when the engine has exited.
  Stream<String> get lines;

  /// Stops the engine and releases its resources.
  Future<void> dispose();
}
