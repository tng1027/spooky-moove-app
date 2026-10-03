/// A move as far as tap entry is concerned: a piece moves from one point to
/// another. [S] is the game's square/point type and must define `==`.
abstract interface class EntryMove<S> {
  S get from;
  S get to;
}

/// Where the user is in entering one move on the tap board.
sealed class EntryState<S, M extends EntryMove<S>> {
  const EntryState();
}

final class EntryIdle<S, M extends EntryMove<S>> extends EntryState<S, M> {
  const EntryIdle();

  @override
  bool operator ==(Object other) => other is EntryIdle;

  @override
  int get hashCode => (EntryIdle).hashCode;
}

/// A piece was tapped first; [destinations] are its legal targets.
final class SourceSelected<S, M extends EntryMove<S>> extends EntryState<S, M> {
  const SourceSelected(this.source, this.destinations);

  final S source;
  final Set<S> destinations;
}

/// A target was tapped first; [sources] are the pieces that can reach it.
final class DestinationSelected<S, M extends EntryMove<S>>
    extends EntryState<S, M> {
  const DestinationSelected(this.destination, this.sources);

  final S destination;
  final Set<S> sources;
}

/// From and to are known but several legal moves share them (Chess
/// promotion); the user picks one of [options].
final class ChoicePending<S, M extends EntryMove<S>> extends EntryState<S, M> {
  const ChoicePending(this.from, this.to, this.options);

  final S from;
  final S to;
  final List<M> options;
}

final class EntryOutcome<S, M extends EntryMove<S>> {
  const EntryOutcome(this.state, {this.committed});

  final EntryState<S, M> state;

  /// Set when the tap completed a move; [state] is then [EntryIdle].
  final M? committed;
}

/// Two-tap move entry shared by every tap-board game (OB-006, OB-042
/// REQ-007, OB-048). Pure: depends only on its inputs.
abstract final class SmartEntry {
  /// Squares that take part in at least one legal move. All others are
  /// dimmed and ignore taps.
  static Set<S> activeSquares<S>(Iterable<EntryMove<S>> legalMoves) => {
    for (final move in legalMoves) ...[move.from, move.to],
  };

  /// Handles a tap on [square]. A tap on an inactive square returns [state]
  /// unchanged.
  static EntryOutcome<S, M> tap<S, M extends EntryMove<S>>(
    EntryState<S, M> state,
    S square,
    List<M> legalMoves,
  ) {
    final isActive = legalMoves.any(
      (move) => move.from == square || move.to == square,
    );
    if (!isActive) return EntryOutcome(state);

    return switch (state) {
      EntryIdle() => _firstTap(square, legalMoves),
      SourceSelected(:final source, :final destinations) =>
        destinations.contains(square)
            ? _resolve(source, square, legalMoves)
            : EntryOutcome(EntryIdle<S, M>()),
      DestinationSelected(:final destination, :final sources) =>
        sources.contains(square)
            ? _resolve(square, destination, legalMoves)
            : EntryOutcome(EntryIdle<S, M>()),
      ChoicePending() => EntryOutcome(EntryIdle<S, M>()),
    };
  }

  /// A tap on a movable piece of the side to move selects a source (no
  /// legal move ends on such a square); any other active square is a target.
  /// The first tap never commits, even with a single option (OB-048).
  static EntryOutcome<S, M> _firstTap<S, M extends EntryMove<S>>(
    S square,
    List<M> moves,
  ) {
    final destinations = {
      for (final move in moves)
        if (move.from == square) move.to,
    };
    if (destinations.isNotEmpty) {
      return EntryOutcome(SourceSelected<S, M>(square, destinations));
    }

    final sources = {
      for (final move in moves)
        if (move.to == square) move.from,
    };
    return EntryOutcome(DestinationSelected<S, M>(square, sources));
  }

  /// From and to are known: commit, or ask which of the matching moves.
  static EntryOutcome<S, M> _resolve<S, M extends EntryMove<S>>(
    S from,
    S to,
    List<M> moves,
  ) {
    final matching = [
      for (final move in moves)
        if (move.from == from && move.to == to) move,
    ];
    if (matching.length == 1) {
      return EntryOutcome(EntryIdle<S, M>(), committed: matching.single);
    }
    return EntryOutcome(ChoicePending<S, M>(from, to, matching));
  }
}
