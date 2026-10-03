import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/fair_play_notice.dart';

/// Loaded once in `main()` and injected with an override, so reads are
/// synchronous on the first frame.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

/// Whether the current fair-play wording version has been acknowledged
/// (OB-008 REQ-003/REQ-004).
final fairPlayAcknowledgedProvider = NotifierProvider<FairPlayController, bool>(
  FairPlayController.new,
);

class FairPlayController extends Notifier<bool> {
  static const String acknowledgedVersionKey = 'fair_play.acknowledged_version';

  static final Logger _log = Logger('FairPlayController');

  @override
  bool build() {
    final acknowledged = ref
        .watch(sharedPreferencesProvider)
        .getInt(acknowledgedVersionKey);
    return acknowledged != null && acknowledged >= fairPlayNoticeVersion;
  }

  /// Unlocks the app for this session even if persisting fails, so the user
  /// is never trapped; the notice then simply shows again next launch.
  Future<void> acknowledge() async {
    state = true;
    try {
      final saved = await ref
          .read(sharedPreferencesProvider)
          .setInt(acknowledgedVersionKey, fairPlayNoticeVersion);
      if (!saved) {
        _log.warning('Fair-play acknowledgment was not persisted');
      }
    } catch (error, stackTrace) {
      _log.severe(
        'Failed to persist fair-play acknowledgment',
        error,
        stackTrace,
      );
    }
  }
}
