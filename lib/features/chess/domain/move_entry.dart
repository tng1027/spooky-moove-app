import '../../../core/board/smart_entry.dart' as entry;
import 'chess_models.dart';

/// The shared smart entry typed on Chess squares and moves.
typedef EntryState = entry.EntryState<ChessSquare, ChessMove>;
typedef EntryIdle = entry.EntryIdle<ChessSquare, ChessMove>;
typedef SourceSelected = entry.SourceSelected<ChessSquare, ChessMove>;
typedef DestinationSelected = entry.DestinationSelected<ChessSquare, ChessMove>;
typedef EntryOutcome = entry.EntryOutcome<ChessSquare, ChessMove>;

/// From and to are known; the user picks the promotion piece. Options hold
/// one move per promotion piece, in chooser order (queen first).
typedef PromotionPending = entry.ChoicePending<ChessSquare, ChessMove>;

/// Chess move entry (OB-006): the shared smart entry plus promotion.
abstract final class MoveEntry {
  static Set<ChessSquare> activeSquares(List<ChessMove> legalMoves) =>
      entry.SmartEntry.activeSquares(legalMoves);

  /// Handles a tap on [square]. A tap on an inactive square returns [state]
  /// unchanged.
  static EntryOutcome tap(
    EntryState state,
    ChessSquare square,
    List<ChessMove> legalMoves,
  ) {
    final outcome = entry.SmartEntry.tap(state, square, legalMoves);
    final pending = outcome.state;
    if (pending is! PromotionPending) return outcome;
    return EntryOutcome(
      PromotionPending(pending.from, pending.to, [
        for (final kind in PieceKind.promotionChoices)
          ...pending.options.where((move) => move.promotion == kind),
      ]),
    );
  }

  /// Commits the promotion to [kind]. Ignored unless a promotion is pending.
  static EntryOutcome choosePromotion(EntryState state, PieceKind kind) {
    if (state is! PromotionPending) return EntryOutcome(state);
    for (final move in state.options) {
      if (move.promotion == kind) {
        return EntryOutcome(const EntryIdle(), committed: move);
      }
    }
    return EntryOutcome(state);
  }
}
