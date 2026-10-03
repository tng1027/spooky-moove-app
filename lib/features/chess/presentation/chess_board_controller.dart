import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/board/board_clock.dart';
import '../../../core/engine/engine_models.dart';
import '../../../core/game/active_game.dart';
import '../../../core/game/player_side.dart';
import '../data/chess_package_rules.dart';
import '../domain/chess_game_status.dart';
import '../domain/chess_models.dart';
import '../domain/chess_result_format.dart';
import '../domain/chess_rules.dart';
import '../domain/move_entry.dart';

export '../../../core/board/board_clock.dart' show boardClockProvider;

/// Rules of the current Chess game. Overridden in tests.
final chessRulesProvider = Provider<ChessRules>((ref) => ChessPackageRules());

final chessBoardControllerProvider =
    NotifierProvider<ChessBoardController, ChessBoardState>(
      ChessBoardController.new,
    );

/// The Chess board as the advisor layer sees it (OB-042 REQ-002).
ActiveGameState chessActiveGameState(ChessBoardState board) {
  final isPromotionPending = board.entry is PromotionPending;
  return ActiveGameState(
    sideToMove: board.sideToMove.side,
    positionId: board.legalMoves,
    legalMoveCount: board.legalMoves.length,
    isInCheck: board.checkedKing != null,
    canUndo: board.canUndo || isPromotionPending,
    isEntryBlocked: isPromotionPending,
    headline: ChessResultFormat.headline(board.status, board.userSide),
    hint: ChessResultFormat.hint(board.status),
  );
}

/// Immutable snapshot of the board for rendering. Legal moves are computed
/// once per position, never during build.
class ChessBoardState {
  const ChessBoardState({
    required this.pieces,
    required this.legalMoves,
    required this.activeSquares,
    required this.sideToMove,
    required this.checkedKing,
    required this.entry,
    this.status = const ChessInProgress(),
    this.canUndo = false,
    this.userSide = PieceColor.white,
    this.suggestedMove,
  });

  final Map<ChessSquare, ChessPiece> pieces;
  final List<ChessMove> legalMoves;
  final Set<ChessSquare> activeSquares;
  final PieceColor sideToMove;

  /// The side to move's king square when it is in check.
  final ChessSquare? checkedKing;
  final EntryState entry;

  /// When over, every square is dimmed and taps are ignored (OB-024).
  final ChessGameStatus status;

  /// At least one move has been entered in this game (OB-012).
  final bool canUndo;

  /// Shown at the bottom of the board (set by OB-011's new game).
  final PieceColor userSide;

  /// Highlighted in green (OB-007 sets it).
  final ChessMove? suggestedMove;

  ChessBoardState copyWith({
    EntryState? entry,
    PieceColor? userSide,
    ChessMove? Function()? suggestedMove,
  }) => ChessBoardState(
    pieces: pieces,
    legalMoves: legalMoves,
    activeSquares: activeSquares,
    sideToMove: sideToMove,
    checkedKing: checkedKing,
    entry: entry ?? this.entry,
    status: status,
    canUndo: canUndo,
    userSide: userSide ?? this.userSide,
    suggestedMove: suggestedMove == null ? this.suggestedMove : suggestedMove(),
  );
}

class ChessBoardController extends Notifier<ChessBoardState>
    implements ActiveGameController {
  /// Taps this soon after a commit are ignored, so a double tap cannot also
  /// enter a reply for the other side.
  static const Duration commitGuard = Duration(milliseconds: 250);

  late ChessRules _rules;
  late Duration Function() _clock;
  Duration? _lastCommitAt;

  @override
  ChessBoardState build() {
    _rules = ref.watch(chessRulesProvider);
    _clock = ref.watch(boardClockProvider);
    return _snapshot(const EntryIdle());
  }

  void tap(ChessSquare square) {
    if (state.status.isOver || _isWithinCommitGuard()) return;
    _handle(MoveEntry.tap(state.entry, square, state.legalMoves));
  }

  void choosePromotion(PieceKind kind) {
    if (state.status.isOver) return;
    _handle(MoveEntry.choosePromotion(state.entry, kind));
  }

  /// Clears a pending selection or closes the promotion chooser.
  void cancelEntry() {
    if (state.entry is EntryIdle) return;
    state = state.copyWith(entry: const EntryIdle());
  }

  /// Takes back the last entered move with a full state restore, also from a
  /// finished game (OB-012). An open promotion chooser is only closed: its
  /// move is not committed yet (REQ-006).
  @override
  void undo() {
    if (state.entry is PromotionPending) {
      cancelEntry();
    } else if (state.canUndo) {
      _rules.undo();
      state = _snapshot(const EntryIdle(), userSide: state.userSide);
    } else {
      return;
    }
    HapticFeedback.selectionClick();
  }

  /// Back to the start position with [userSide] at the bottom (OB-011).
  @override
  void newGame(PlayerSide userSide) {
    _rules.reset();
    _lastCommitAt = null;
    state = _snapshot(const EntryIdle(), userSide: PieceColor.of(userSide));
  }

  /// Commits [move] as if it had been entered on the board (OB-041). Clears
  /// any pending selection. Ignored when [move] is not legal here.
  void commit(ChessMove move) {
    if (state.status.isOver || _isWithinCommitGuard()) return;
    if (!state.legalMoves.contains(move)) return;
    _handle(EntryOutcome(const EntryIdle(), committed: move));
  }

  @override
  void commitEngineMove(String engineMove) {
    final move = _rules.moveFromUci(engineMove);
    if (move != null) commit(move);
  }

  /// Highlights [move] in green; null clears the highlight.
  void showSuggestedMove(ChessMove? move) {
    if (state.suggestedMove == move) return;
    state = state.copyWith(suggestedMove: () => move);
  }

  @override
  bool showSuggestion(String? engineMove) {
    final move = engineMove == null ? null : _rules.moveFromUci(engineMove);
    showSuggestedMove(move);
    return engineMove == null || move != null;
  }

  @override
  EnginePosition enginePosition() => _rules.toEnginePosition();

  void _handle(EntryOutcome outcome) {
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
  ChessBoardState _snapshot(
    EntryState entry, {
    PieceColor userSide = PieceColor.white,
  }) {
    final pieces = <ChessSquare, ChessPiece>{};
    ChessSquare? king;
    final side = _rules.sideToMove;
    for (var file = 0; file < 8; file++) {
      for (var rank = 0; rank < 8; rank++) {
        final square = ChessSquare(file, rank);
        final piece = _rules.pieceAt(square);
        if (piece == null) continue;
        pieces[square] = piece;
        if (piece == ChessPiece(side, PieceKind.king)) king = square;
      }
    }
    final legalMoves = _rules.legalMoves;
    final status = ChessGameStatus.of(_rules);
    return ChessBoardState(
      pieces: Map.unmodifiable(pieces),
      legalMoves: legalMoves,
      activeSquares: status.isOver
          ? const {}
          : Set.unmodifiable(MoveEntry.activeSquares(legalMoves)),
      sideToMove: side,
      checkedKing: _rules.isCheck ? king : null,
      entry: entry,
      status: status,
      canUndo: _rules.moveCount > 0,
      userSide: userSide,
    );
  }
}
