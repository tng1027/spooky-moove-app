import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Monotonic time for the double-tap guard. Overridden in tests.
final boardClockProvider = Provider<Duration Function()>((ref) {
  final stopwatch = Stopwatch()..start();
  return () => stopwatch.elapsed;
});
