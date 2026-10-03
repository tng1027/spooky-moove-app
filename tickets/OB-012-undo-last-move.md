# Ticket Analysis

> **Status: Done on iOS simulator (2026-10-03).** Physical-device pass deferred (PO testing policy 2026-10-03).
> - `ChessBoardController.undo()`: closes an open promotion chooser first (REQ-006); otherwise calls `ChessRules.undo()` (full state restore incl. castling / en passant rights and counters) and rebuilds the board snapshot, which clears any selection and the suggestion highlight (REQ-003–REQ-005, REQ-014). `selectionClick` haptic, no confirmation (REQ-013, U-A2). Works from a finished game (REQ-010); taps on the board stay blocked until then.
> - **Single history:** the rules adapter keeps the move list and its own repetition-key list and pops both in the same `undo()` step, so there is no second session history to keep in sync (replaces the Developer Handoff's "two histories" note). Game status, claimable-draw hints (REQ-011) and the turn label are derived from the restored position.
> - Suggestions: `SuggestionController` already reacts to the position change: it cancels the running search and drops stale results (REQ-007), shows nothing on the opponent's turn, and on the user's turn `PersonaSuggester`'s (position, tier) cache returns the identical suggestion without a new search, Baby included (REQ-008, REQ-009). The current tier applies (REQ-012).
> - UI: `UndoKey` (undo glyph + `UNDO`) in the status line, left of NEW GAME (U-A4). `AppKey` gained a disabled state (`onTap: null` → `keyDisabled`, `textSecondary`, semantics disabled); UNDO is disabled until a move is entered (REQ-001, REQ-002). U-A1 (multi-tap) and U-A3 (no redo) applied as written.
> - Tests: board controller (availability, restore, three undos to the start, selection, promotion chooser, from checkmate, haptic), suggestion controller (opponent-move undo cancels the search, same suggestion after a different move + undo with no new search, tier change after undo, from checkmate), `undo_key_test`, status line at 360 dp / text scale 2.0. Special-move undo is covered by the existing adapter tests. Simulator integration tests: undo out of checkmate resumes play; Baby suggestion identical after a different move + undo.

> - Follow-up (2026-10-03): a move committed with OB-041's "✓ I PLAYED IT" key is undone like any other move; the user's turn, the same suggestion and the enabled key come back (OB-041 REQ-009).

TICKET_TYPE: NEW_FEATURE
CONFIDENCE: HIGH

Undo does not exist (no code). `systemPatterns.md` lists "History Undo" in the rules layer, but no UX was defined. The PO decided on 2026-10-02 ("đúng") that **one-step undo is in the Chess Definition of Done** (OB-001 Q4). Priority P0. Confidence is HIGH because the behavior follows from decided tickets: OB-025 turn loop, OB-022 stable suggestions, OB-024 game end and OB-006 tap board. The few choices the PO did not decide are labelled assumptions (U-A1 to U-A4).

## Ticket Title
[Feature] Undo the last entered move on the tap board (Chess first)

## Summary
An **UNDO** key removes the last move entered in the app (the opponent's or the user's) and restores the previous position, turn, suggestion state and game status. It is the correction path for mis-taps and auto-commit (OB-006) and keeps the app in sync with the physical board.

## Business Context
- Smart entry auto-commits unambiguous moves (OB-006), so a mis-tap commits a legal but wrong move immediately. Without undo, the only fix is a new game, which loses the whole game.
- Every suggestion is only correct if the app matches the physical board (OB-025 BR-002).
- PO decision 2026-10-02: undo is in the Chess DoD (OB-001 Q4).

## Current Behavior
Not implemented. A mis-entered move can only be fixed by starting a new game (OB-011).

## Expected Behavior
- An **UNDO** key is shown on the advisor screen in the status line (bottom, thumb reach), using design-system keys (≥ 48 dp, `keyNormal`; `keyDisabled` when unavailable).
- One tap undoes **one move**: the last entered move, whichever side made it.
- Repeated taps undo further moves, one per tap, back to the start position (U-A1).
- After undo, the app is exactly as it was before that move was entered: position, side to move, castling/en passant rights, repetition and move counters, game status (including leaving a game-over state), and the turn status line.
- If it becomes the **user's turn** and a tier is selected, the suggestion for that position is shown. For the same position and tier, it is the **same suggestion** as before (OB-022 stability).
- If it becomes the **opponent's turn**, no suggestion is shown, and any running search is cancelled.

## User Story
As a player at a physical board
I want to take back the last move I entered with one tap
So that a mis-tap or a takeback on the board doesn't force me to restart the game.

## Functional Requirements
- REQ-001: Show an UNDO key on the advisor screen (status-line row), with a glyph and the label "UNDO". No chess notation.
- REQ-002: UNDO is **disabled** (`keyDisabled`) when no move has been entered in the current game.
- REQ-003: One tap removes the last entered move and restores the full previous game state (position, side to move, castling and en passant rights, half-move/repetition history).
- REQ-004: Repeated taps continue undoing one move per tap until the start position (U-A1).
- REQ-005: Any in-progress source selection on the board is cleared when UNDO is tapped.
- REQ-006: While the promotion chooser is open, no move is committed yet. UNDO first closes the chooser, leaving the position unchanged (same as "tap outside", OB-006 REQ-010); a further tap undoes the previous move.
- REQ-007: Any running engine search is cancelled on undo, and a late result for the removed position is never shown (OB-025 stale-result rule).
- REQ-008: After undo, the turn loop resumes from the restored position (OB-025):
  - user's turn + tier selected → show the suggestion for (position, tier);
  - user's turn + no tier → no suggestion (OB-022 REQ-002);
  - opponent's turn → no suggestion.
- REQ-009: Same position + same tier gives the same suggestion as before the undone move. Baby's random choice is not re-rolled (OB-022 cache per position and tier).
- REQ-010: Undo from a **game-over** state (OB-024) removes the final move, clears the result, re-enables the board, and resumes play.
- REQ-011: Claimable-draw hints (OB-024 A2) are recalculated for the restored position.
- REQ-012: The active tier and the user's side are not changed by undo. If the tier was changed after the undone move, the current tier is used.
- REQ-013: Haptic `selectionClick()` on undo (key tap). No confirmation dialog (U-A2).
- REQ-014: The board highlights (last-move markers, suggestion squares; OB-007) reflect the restored position.

## Business Rules
- BR-001: Undo restores exactly the state before the undone move. No partial restore.
- BR-002: Suggestions are only for the user's side (OB-021 D1). Undo never shows a suggestion on the opponent's turn.
- BR-003: Same position + same tier → same suggestion (OB-022).
- BR-004: Undo works on moves entered in the app only; it doesn't change the persona tier or the side.

## User Flow
```text
User's turn, suggestion shown
↓ user mis-taps → wrong move auto-committed → turn passes to opponent
↓ user taps [UNDO]
Position restored → user's turn → the same suggestion reappears (same tier)
↓ user enters the correct move

Alternative: opponent's move entered wrongly
↓ [UNDO] → opponent's turn again, no suggestion → enter the correct opponent move

Alternative: game over after a mis-entered mating move
↓ [UNDO] → result cleared, board enabled, play continues
```

## Acceptance Criteria
- Given a new game with no moves entered, When the advisor screen is shown, Then UNDO is disabled.
- Given the user plays Black, the opponent's move `E2 ➔ E4` was entered and a suggestion is shown, When the user taps UNDO, Then the board shows the initial position, the status is "OPPONENT TO MOVE", no suggestion is shown and UNDO is disabled.
- Given it is the user's turn with suggestion S for tier T, When the user enters a different move and then taps UNDO, Then it is the user's turn again and suggestion S is shown for tier T without a different move being picked.
- Given the Baby tier (random choice) showed suggestion S, When a move is entered and then undone, Then S is shown again (not re-randomized).
- Given a move was undone and it is the user's turn, When the user changes the tier, Then a suggestion is computed for the restored position with the new tier (OB-021 R6).
- Given three moves were entered, When the user taps UNDO three times, Then the initial position is restored and UNDO becomes disabled (U-A1).
- Given an engine search is running on the user's turn, When the user taps UNDO, Then the search is cancelled, and the position before the last move is shown with the correct turn and suggestion state.
- Given the last move was castling, en passant or a promotion, When it is undone, Then all pieces return to their exact previous squares (rook, captured pawn, original pawn), and castling and en passant rights are restored.
- Given the game ended by checkmate, When the user taps UNDO, Then the result is removed, the board is enabled, and the turn and suggestion state match the restored position.
- Given a source square is selected on the board, When the user taps UNDO, Then the selection is cleared and the last move is undone.
- Given the promotion chooser is open, When the user taps UNDO, Then the chooser closes and the position is unchanged.
- Given a claimable-draw hint is shown, When the move that caused it is undone, Then the hint disappears.

## Edge Cases
- Undo while the suggestion is still being computed (search cancelled; stale result dropped).
- Undo right after starting a game as White (no moves) → disabled; the initial suggestion stays.
- Undo past several moves when the physical board was taken back several moves (U-A1 covers it).
- Rapid repeated taps: each tap undoes exactly one move; no double-processing.
- Undo after the tier was changed: the current tier applies (REQ-012).

## In Scope
- UNDO key, multi-tap undo to the start position, full state restore, interaction with the turn loop, suggestion stability, game-over, promotion chooser and selection.
- Chess first; game-agnostic so Xiangqi (OB-009) reuses it.

## Out of Scope
- Redo (U-A3).
- Undo across games or after "New game" (the old game is discarded, OB-011).
- Persisting history after an app kill (OB-001 Q6, not in the Chess DoD).
- Move list / history viewer (OB-013).

## Dependencies
- OB-025 (turn loop), OB-022 (suggestion cache per position and tier), OB-024 (game-over state, repetition history), OB-006 (tap board, selection, promotion chooser), OB-007 (card and board highlights), OB-003 (status-line region and tokens).
- Rules module interface (OB-006) must support restoring a previous state. Concrete library = `chess` (PO decision 2026-10-02): its `undo()` restores the full state (castling rights, en passant square, counters).

## Assumptions
- **U-A1:** Repeated taps undo further moves, back to the start position. The PO approved "one-step undo"; this reads as one move per tap, without limiting the number of taps. Reason: a physical takeback or two wrong entries can span several moves, and the history is already kept for repetition detection (OB-024). Revisit if the PO wants exactly one undo at a time.
- **U-A2:** No confirmation dialog; undo is instant (correction must be fast while looking at the board).
- **U-A3:** No redo; the user re-enters the move (1–2 taps).
- **U-A4:** UNDO sits in the status-line row at the bottom of the screen (thumb reach). Exact placement is a design detail within `designSystem.md` tokens.

## Open Questions
None blocking. Non-blocking: confirm U-A1 (multi-tap undo) and U-A3 (no redo).

## Developer Handoff
- Undo = the rules adapter calls the package's `undo()`, **and** the game session drops the last entry from its own move/position history in the same step. The two must never diverge; assert that the adapter's FEN equals the history's previous FEN in tests. The own history also drives the repetition counter (OB-024 REQ-011/REQ-014).
- Reuse OB-022's (position, tier) suggestion cache so a restored position shows the identical suggestion without a new search when cached. Clear the cache only on new game.
- Cancel searches and tag results with (position, tier), as in OB-025.
- Unit tests: undo of every special move (castling both sides, en passant, each promotion piece), undo from checkmate/stalemate, repetition counters after undo. Widget tests: disabled state, multi-tap, promotion chooser and selection interactions.
