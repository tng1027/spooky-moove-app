import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:logging/logging.dart';

import '../../../core/engine/engine_models.dart';
import '../../../core/game/active_game.dart';
import '../../../core/game/game_result.dart';
import '../../new_game/presentation/game_registry.dart';
import '../../new_game/presentation/game_session_controller.dart';
import '../../persona/application/persona_suggester.dart';
import '../../persona/presentation/persona_tier_controller.dart';
import 'suggestion_providers.dart';

/// What the suggestion card shows (OB-007).
sealed class SuggestionState {
  const SuggestionState();
}

/// The user's turn, but no persona tier is chosen yet (OB-023 REQ-002).
final class SuggestionNoTier extends SuggestionState {
  const SuggestionNoTier();
}

/// The opponent's turn, or no game yet.
final class SuggestionWaiting extends SuggestionState {
  const SuggestionWaiting();
}

final class SuggestionThinking extends SuggestionState {
  const SuggestionThinking();
}

final class SuggestionReady extends SuggestionState {
  const SuggestionReady({required this.suggestion});

  final PersonaSuggestion suggestion;

  /// The suggested move in engine notation, legal in the current position.
  String get engineMove => suggestion.move;
}

/// The engine failed or timed out; the card offers Retry (REQ-008).
final class SuggestionFailed extends SuggestionState {
  const SuggestionFailed();
}

/// The game has ended; the card shows the result (OB-024).
final class SuggestionGameOver extends SuggestionState {
  const SuggestionGameOver({required this.headline});

  final GameResultHeadline headline;
}

final suggestionControllerProvider =
    NotifierProvider<SuggestionController, SuggestionState>(
      SuggestionController.new,
    );

/// Requests a persona suggestion whenever it is the user's turn with a tier
/// selected, and shows only results for the current position and tier
/// (REQ-001, REQ-009).
class SuggestionController extends Notifier<SuggestionState> {
  /// Engine cap (900 ms) plus margin; a slower search counts as a failure.
  static const Duration timeout = Duration(seconds: 2);

  static final Logger _log = Logger('SuggestionController');

  /// Incremented on every refresh; results of older requests are dropped.
  int _request = 0;
  Future<void>? _engineStarted;
  Future<void>? _variantReady;
  String? _engineVariant;
  Timer? _timeoutTimer;
  bool _engineNeedsRestart = false;
  ProviderSubscription<Object>? _positionSubscription;

  @override
  SuggestionState build() {
    ref.listen(personaTierProvider, (_, _) => _refresh());
    _listenToPosition(ref.read(activeGameStateSourceProvider));
    ref.listen(activeGameStateSourceProvider, (_, source) {
      _listenToPosition(source);
    });
    ref.listen(gameSessionProvider, (_, _) {
      ref.read(personaSuggesterProvider).clearCache();
      // Providers derived from the session (game, variant, position source)
      // are still stale while this listener runs, so the refresh waits; any
      // request already started for the new game is dropped.
      _request++;
      Future.microtask(_refresh);
    });
    final suggester = ref.read(personaSuggesterProvider);
    ref.onDispose(() {
      _request++;
      _timeoutTimer?.cancel();
      suggester.cancel();
    });
    final idle = _idleState();
    if (idle != null) return idle;
    Future.microtask(_refresh);
    return const SuggestionThinking();
  }

  /// Re-requests the suggestion after a failure.
  void retry() => _refresh();

  /// Follows the current game's position; re-subscribes when the game
  /// changes.
  void _listenToPosition(ProviderListenable<ActiveGameState> source) {
    _positionSubscription?.close();
    _positionSubscription = ref.listen(
      source.select((game) => game.positionId),
      (_, _) => _onPositionChanged(),
    );
  }

  ActiveGameState get _game =>
      ref.read(ref.read(activeGameStateSourceProvider));

  void _onPositionChanged() {
    if (_isUserTurn && _game.isInCheck) {
      HapticFeedback.heavyImpact();
    }
    _refresh();
  }

  bool get _isUserTurn {
    final session = ref.read(gameSessionProvider);
    return session != null && _game.sideToMove == session.userSide;
  }

  Future<void> _refresh() async {
    if (!ref.mounted) return;
    final request = ++_request;
    final suggester = ref.read(personaSuggesterProvider);
    final game = ref.read(activeGameControllerProvider);
    final idle = _idleState();
    if (idle != null) {
      suggester.cancel();
      game.showSuggestion(null);
      state = idle;
      return;
    }
    final legalMoveCount = _game.legalMoveCount;
    final tier = ref.read(personaTierProvider)!;

    game.showSuggestion(null);
    state = const SuggestionThinking();
    try {
      await _ensureEngine(ref.read(activeEngineVariantProvider));
      if (request != _request) return;
      final suggestion = await _withTimeout(
        suggester.suggest(
          position: game.enginePosition(),
          legalMoveCount: legalMoveCount,
          tier: tier,
        ),
      );
      if (request != _request || !ref.mounted) return;
      if (suggestion == null) {
        state = _idleState() ?? const SuggestionFailed();
        return;
      }
      if (!game.showSuggestion(suggestion.move)) {
        throw EngineFailureException(
          'Engine suggested an illegal move: ${suggestion.move}',
        );
      }
      state = SuggestionReady(suggestion: suggestion);
      unawaited(HapticFeedback.mediumImpact());
    } on SearchCancelledException {
      // Superseded by a newer request, which owns the state.
    } on TimeoutException catch (error, stackTrace) {
      suggester.cancel();
      _fail(request, error, stackTrace);
    } on EngineFailureException catch (error, stackTrace) {
      _fail(request, error, stackTrace);
    }
  }

  /// Like [Future.timeout], but the timer is owned here so dispose and newer
  /// requests can cancel it.
  Future<T> _withTimeout<T>(Future<T> future) {
    _timeoutTimer?.cancel();
    final timedOut = Completer<T>();
    final timer = Timer(timeout, () {
      timedOut.completeError(TimeoutException('Suggestion timed out', timeout));
    });
    _timeoutTimer = timer;
    return Future.any([future, timedOut.future]).whenComplete(timer.cancel);
  }

  /// The state when no search should run, or null when one should.
  SuggestionState? _idleState() {
    if (ref.read(gameSessionProvider) == null) return const SuggestionWaiting();
    final headline = _game.headline;
    if (headline != null) return SuggestionGameOver(headline: headline);
    if (ref.read(personaTierProvider) == null) return const SuggestionNoTier();
    if (!_isUserTurn) return const SuggestionWaiting();
    return null;
  }

  void _fail(int request, Object error, StackTrace stackTrace) {
    _log.severe('Suggestion failed', error, stackTrace);
    _engineStarted = null;
    _variantReady = null;
    _engineVariant = null;
    _engineNeedsRestart = true;
    if (request != _request || !ref.mounted) return;
    state = const SuggestionFailed();
  }

  /// Starts the engine once (after a failure the next request restarts it)
  /// and switches it to [variant] before the first search in that variant
  /// (OB-042 REQ-005).
  Future<void> _ensureEngine(String variant) {
    final engine = ref.read(gameEngineProvider);
    final started = _engineStarted ??= () async {
      if (_engineNeedsRestart) {
        _engineNeedsRestart = false;
        await engine.dispose();
      }
      await engine.start();
    }();
    final variantReady = _variantReady;
    if (variantReady != null && _engineVariant == variant) return variantReady;
    _engineVariant = variant;
    return _variantReady = started.then((_) => engine.setVariant(variant));
  }
}
