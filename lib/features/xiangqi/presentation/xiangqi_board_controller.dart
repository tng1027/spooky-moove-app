import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/board/board_clock.dart';
import '../../../core/board/smart_entry.dart';
import '../../../core/engine/engine_models.dart';
import '../../../core/game/active_game.dart';
import '../../../core/game/player_side.dart';
import '../../../core/l10n/app_strings.dart';
import '../data/dart_xiangqi_rules.dart';
import '../domain/xiangqi_game_status.dart';
import '../domain/xiangqi_models.dart';
import '../domain/xiangqi_result_format.dart';
import '../domain/xiangqi_rules.dart';

typedef XiangqiEntry = EntryState<XiangqiPoint, XiangqiMove>;
typedef XiangqiEntryIdle = EntryIdle<XiangqiPoint, XiangqiMove>;
typedef XiangqiEntryOutcome = EntryOutcome<XiangqiPoint, XiangqiMove>;

/// Rules of the current Xiangqi game. Overridden in tests.
final xiangqiRulesProvider = Provider<XiangqiRules>(
  (ref) => DartXiangqiRules(),
);

final xiangqiBoardControllerProvider =
    NotifierProvider<XiangqiBoardController, XiangqiBoardState>(
      XiangqiBoardController.new,
    );

/// The Xiangqi board as the advisor layer sees it (OB-042 REQ-002).
ActiveGameState xiangqiActiveGameState(
  XiangqiBoardState board,
  AppStrings strings,
) => ActiveGameState(
  sideToMove: board.sideToMove,
  positionId: board.legalMoves,
  legalMoveCount: board.legalMoves.length,
  isInCheck: board.checkedGeneral != null,
  canUndo: board.canUndo,
  headline: XiangqiResultFormat.headline(board.status, board.userSide, strings),
);

/// Immutable snapshot of the board for rendering. Legal moves are computed
/// once per position, never during build (REQ-009).
class XiangqiBoardState {
  const XiangqiBoardState({
    required this.pieces,
    required this.legalMoves,
    required this.activePoints,
    required this.sideToMove,
    required this.checkedGeneral,
    required this.entry,
    this.status = const XiangqiInProgress(),
    this.canUndo = false,
    this.userSide = PlayerSide.first,
    this.suggestedMove,
  });

  final Map<XiangqiPoint, XiangqiPiece> pieces;
  final List<XiangqiMove> legalMoves;

  /// Points that take part in a legal move; empty when the game is over.
  final Set<XiangqiPoint> activePoints;
  final PlayerSide sideToMove;

  /// The side to move's general when it is in check.
  final XiangqiPoint? checkedGeneral;
  final XiangqiEntry entry;

  final XiangqiGameStatus status;

  /// The side to move has no legal move: everything is dimmed (OB-047).
  bool get isOver => status.isOver;

  /// At least one move has been entered in this game.
  final bool canUndo;

  /// Shown at the bottom of the board.
  final PlayerSide userSide;

  /// Highlighted in green.
  final XiangqiMove? suggestedMove;

  /// Points a tap acts on in the current entry state (OB-044 XQ3): every
  /// active point when idle, the candidates plus the selected point while a
  /// selection is pending.
  Set<XiangqiPoint> get targets => switch (entry) {
    EntryIdle() => activePoints,
    SourceSelected(:final source, :final destinations) => {
      source,
      ...destinations,
    },
    DestinationSelected(:final destination, :final sources) => {
      destination,
      ...sources,
    },
    ChoicePending() => const {},
  };

  XiangqiBoardState copyWith({
    XiangqiEntry? entry,
    XiangqiMove? Function()? suggestedMove,
  }) => XiangqiBoardState(
    pieces: pieces,
    legalMoves: legalMoves,
    activePoints: activePoints,
    sideToMove: sideToMove,
    checkedGeneral: checkedGeneral,
    entry: entry ?? this.entry,
    status: status,
    canUndo: canUndo,
    userSide: userSide,
    suggestedMove: suggestedMove == null ? this.suggestedMove : suggestedMove(),
  );
}

class XiangqiBoardController extends Notifier<XiangqiBoardState>
    implements ActiveGameController {
  /// Taps this soon after a commit are ignored, so a double tap cannot also
  /// enter a reply for the other side.
  static const Duration commitGuard = Duration(milliseconds: 250);

  late XiangqiRules _rules;
  late Duration Function() _clock;
  Duration? _lastCommitAt;

  @override
  XiangqiBoardState build() {
    _rules = ref.watch(xiangqiRulesProvider);
    _clock = ref.watch(boardClockProvider);
    return _snapshot(const XiangqiEntryIdle());
  }

  void tap(XiangqiPoint point) {
    if (state.isOver || _isWithinCommitGuard()) return;
    _handle(SmartEntry.tap(state.entry, point, state.legalMoves));
  }

  /// Clears a pending selection.
  void cancelEntry() {
    if (state.entry is EntryIdle) return;
    state = state.copyWith(entry: const XiangqiEntryIdle());
  }

  /// Takes back the last entered move with a full state restore, also from a
  /// finished game.
  @override
  void undo() {
    if (!state.canUndo) return;
    _rules.undo();
    state = _snapshot(const XiangqiEntryIdle(), userSide: state.userSide);
    HapticFeedback.selectionClick();
  }

  /// Back to the start position with [userSide] at the bottom.
  @override
  void newGame(PlayerSide userSide) {
    _rules.reset();
    _lastCommitAt = null;
    state = _snapshot(const XiangqiEntryIdle(), userSide: userSide);
  }

  /// Commits [move] as if it had been entered on the board. Clears any
  /// pending selection. Ignored when [move] is not legal here.
  void commit(XiangqiMove move) {
    if (state.isOver || _isWithinCommitGuard()) return;
    if (!state.legalMoves.contains(move)) return;
    _handle(XiangqiEntryOutcome(const XiangqiEntryIdle(), committed: move));
  }

  @override
  void commitEngineMove(String engineMove) {
    final move = _rules.moveFromUci(engineMove);
    if (move != null) commit(move);
  }

  @override
  bool showSuggestion(String? engineMove) {
    final move = engineMove == null ? null : _rules.moveFromUci(engineMove);
    if (state.suggestedMove != move) {
      state = state.copyWith(suggestedMove: () => move);
    }
    return engineMove == null || move != null;
  }

  @override
  EnginePosition enginePosition() => _rules.toEnginePosition();

  void _handle(XiangqiEntryOutcome outcome) {
    final committed = outcome.committed;
    if (committed != null) {
      _rules.apply(committed);
      _lastCommitAt = _clock();
      state = _snapshot(outcome.state, userSide: state.userSide);
      HapticFeedback.lightImpact();
      return;
    }
    if (identical(outcome.state, state.entry)) return;
    state = state.copyWith(entry: outcome.state);
    if (outcome.state is! EntryIdle) HapticFeedback.selectionClick();
  }

  bool _isWithinCommitGuard() {
    final last = _lastCommitAt;
    return last != null && _clock() - last < commitGuard;
  }

  /// The suggestion belongs to the previous position, so it is dropped.
  XiangqiBoardState _snapshot(
    XiangqiEntry entry, {
    PlayerSide userSide = PlayerSide.first,
  }) {
    final pieces = <XiangqiPoint, XiangqiPiece>{};
    XiangqiPoint? general;
    final side = _rules.sideToMove;
    for (var rank = 0; rank < XiangqiPoint.ranks; rank++) {
      for (var file = 0; file < XiangqiPoint.files; file++) {
        final point = XiangqiPoint(file, rank);
        final piece = _rules.pieceAt(point);
        if (piece == null) continue;
        pieces[point] = piece;
        if (piece == XiangqiPiece(side, XiangqiPieceKind.general)) {
          general = point;
        }
      }
    }
    final legalMoves = _rules.legalMoves;
    final status = XiangqiGameStatus.of(_rules);
    return XiangqiBoardState(
      pieces: Map.unmodifiable(pieces),
      legalMoves: legalMoves,
      activePoints: status.isOver
          ? const {}
          : Set.unmodifiable(SmartEntry.activeSquares(legalMoves)),
      sideToMove: side,
      checkedGeneral: _rules.isCheck ? general : null,
      entry: entry,
      status: status,
      canUndo: _rules.moveCount > 0,
      userSide: userSide,
    );
  }
}
