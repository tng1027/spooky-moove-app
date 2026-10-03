# Ticket Analysis

> **Status: Done on iOS simulator (2026-10-03).** Physical-device pass deferred (PO testing policy 2026-10-03).
> - Pure `ChessGameStatus` (`lib/features/chess/domain/chess_game_status.dart`) built from the adapter's facts: checkmate, then stalemate, insufficient material, fivefold repetition, 75-move rule; otherwise in progress with an optional claimable draw (threefold, then 50-move). Thresholds are named constants. The adapter's own repetition counter (FIDE en passant rule, decremented on undo) and `half_moves` are used; `in_draw` / `game_over` / `in_threefold_repetition` are not (REQ-009–REQ-014).
> - `ChessBoardState.status` is derived from the rules on every snapshot, so undo (OB-012) restores it. When over: every square dimmed, taps and promotion ignored (also for automatic draws that still have legal moves).
> - `SuggestionGameOver` replaces `SuggestionNoMoves`; it is checked before the tier, so the result shows on either side's turn and without a tier, and tier changes start no search. The turn label is hidden.
> - Card (dev decisions with the PO, 2026-10-03): result on two lines (`CHECKMATE` / `YOU WIN` in `accentGreen`, `YOU LOSE` in `accentRed`, draws in `textPrimary`). Claimable-draw hint as a `textSecondary` line at the bottom of the card, under whatever the card shows. "New game" reuses the status line's NEW GAME key (no extra key). Wording: `STALEMATE — DRAW`, `DRAW — NOT ENOUGH PIECES TO WIN`, `DRAW — SAME POSITION 5 TIMES`, `DRAW — 75 MOVES WITHOUT CAPTURE OR PAWN MOVE`; hints `DRAW POSSIBLE — SAME POSITION 3 TIMES`, `DRAW POSSIBLE — 50 MOVES WITHOUT CAPTURE OR PAWN MOVE` (Open Question 1 answered with English uppercase).
> - Tests: status unit tests with FENs (both winners, stalemate, K v K / K+B / K+N, threefold hint, fivefold + undo, 50/75-move, mate on the 150th half-move), board controller, suggestion controller, turn status, card and formatter tests. Simulator integration test (in `integration_test/turn_loop_test.dart`): fool's mate shows `CHECKMATE` / `YOU LOSE`, board dimmed, no search after a tier pick.

TICKET_TYPE: NEW_FEATURE
CONFIDENCE: HIGH

Game-end handling does not exist and is not specified. OB-007 REQ-007 only says "show an explicit state when there is no legal move", and OB-001 Q5 asks the PO which endings to detect. The Chess Definition of Done requires game-end handling, so this ticket owns the Chess ending rules and the game-over state. Checkmate and stalemate follow FIDE rules. The draw rules A1–A3 are **accepted assumptions** (the PO did not object, 2026-10-02), so the ticket is ready.

## Ticket Title
[Feature] Detect and display the end of a Chess game (checkmate, stalemate, draws)

## Summary
After every accepted move, detect whether the Chess game has ended. If it has, stop suggestions, disable the keypad, and show the result in the hero region from the user's point of view, with a way to start a new game.

## Business Context
- Without game-end handling, the app would keep a disabled keypad with no explanation, or ask the engine for a move in a finished position.
- OB-022 R2 / REQ-011: no legal moves → game-end state, no suggestion.
- Chess Definition of Done (README, Phase 1).

## Current Behavior
Not implemented. OB-007 shows "an explicit state" when there are no legal moves; OB-006 disables the keypad when no legal moves exist. Neither defines the ending types or the result text.

## Expected Behavior
- **Checkmate:** "CHECKMATE" with the result from the user's side ("YOU WIN" in `accentGreen` / "YOU LOSE" in `accentRed`).
- **Stalemate:** "STALEMATE — DRAW".
- **Insufficient material** (e.g. K vs K, K+B vs K, K+N vs K): "DRAW — INSUFFICIENT MATERIAL". Assumption A1.
- **Fivefold repetition / 75-move rule:** game ends as a draw automatically. Assumption A1.
- **Threefold repetition / 50-move rule:** not a game end; a non-blocking "DRAW CAN BE CLAIMED" hint in `textSecondary`, and the game continues. Assumption A2.
- On game end: the keypad is disabled, no engine search runs, the persona row stays visible but has no effect, and a "New game" action (OB-011) is offered.

## User Story
As a player at a physical board
I want the app to tell me clearly when the game is over and who won
So that I don't keep entering moves or waiting for a suggestion in a finished game.

## Functional Requirements
- REQ-001: After each accepted move, evaluate end conditions on the rules module, before requesting a suggestion.
- REQ-002: Detect checkmate and stalemate (FIDE).
- REQ-003: Detect insufficient material, fivefold repetition and the 75-move rule as automatic draws (A1).
- REQ-004: Detect threefold repetition and the 50-move rule and show a non-blocking "draw can be claimed" hint (A2).
- REQ-005: On game end, show the result in the hero region from the user's point of view; disable the keypad; cancel or skip the engine search.
- REQ-006: Offer "New game" (OB-011) from the game-over state.
- REQ-007: Changing the tier after game end doesn't trigger a search.
- REQ-008: Undo from a game-over state returns to play (implemented in OB-012 REQ-010; this ticket keeps the end status derivable from the restored position).

### Game-end composition in the rules adapter (rules library = `chess`, OB-006)
- REQ-009: The game-end status is **composed in our rules adapter**. **Do not use the package's `in_draw` or `game_over`**: they treat the 50-move rule (`half_moves >= 100`) and threefold repetition as automatic draws, which contradicts A1/A2.
- REQ-010: From the package, use only `in_checkmate`, `in_stalemate`, `insufficient_material` and `half_moves`.
- REQ-011: **Own repetition counter:** count occurrences of each position in the game's own history. The key is piece placement + side to move + castling rights + en passant square, with the en passant square **included only when an en passant capture is actually legal** (FIDE "same position"). This avoids the package's deviation, which detects some repetitions one cycle late. The package's `in_threefold_repetition` is not used.
- REQ-012: Automatic draws: insufficient material (package); **fivefold repetition** (own counter ≥ 5); **75-move rule** (`half_moves >= 150`), unless the move delivered checkmate (checkmate takes precedence).
- REQ-013: Claimable hints: threefold repetition (own counter ≥ 3) and the **50-move rule** (`half_moves >= 100`). The game continues.
- REQ-014: The repetition counter stays in sync with undo (OB-012): undoing a move decrements its position's count.

## Business Rules
- BR-001: Checkmate and stalemate follow FIDE Laws of Chess.
- BR-002: Result colors: user win = `accentGreen`, user loss = `accentRed`, draw = `textPrimary` (`designSystem.md` color meanings).
- BR-003: No engine search runs in a finished position.
- BR-004: Draw rules per A1/A2 (accepted assumptions, 2026-10-02).

## User Flow
```text
User enters a move (OB-006)
↓
Rules module checks end conditions
↓
Ended → hero shows result (e.g. "CHECKMATE — YOU WIN"), keypad disabled, [NEW GAME]
Not ended, claimable draw → small "DRAW CAN BE CLAIMED" hint, play continues
Not ended → normal turn flow (OB-025)
```

## Acceptance Criteria
- Given the user (White) enters a move that checkmates Black, When the move is accepted, Then the hero shows "CHECKMATE — YOU WIN" in `accentGreen`, the keypad is disabled and no suggestion is computed.
- Given the opponent's entered move checkmates the user, When the move is accepted, Then the hero shows "CHECKMATE — YOU LOSE" in `accentRed`, the keypad is disabled and no suggestion is computed.
- Given a move leaves the side to move with no legal moves and not in check, When it is accepted, Then the hero shows "STALEMATE — DRAW" and the keypad is disabled.
- Given a move leaves only K vs K (or K+B vs K, or K+N vs K), When it is accepted, Then the hero shows "DRAW — INSUFFICIENT MATERIAL" (A1).
- Given the same position occurs for the third time, When the move is accepted, Then a non-blocking "DRAW CAN BE CLAIMED" hint appears and play continues (A2).
- Given the same position occurs for the fifth time, or 75 moves pass by each side without a capture or pawn move, When the move is accepted, Then the game ends as a draw (A1).
- Given a game-over state, When the user taps "New game", Then the new-game flow (OB-011) starts.
- Given a game-over state, When the user changes the tier, Then no engine search starts.

- Given a position repeated three times through the adapter, When the package's `in_draw` would report a draw, Then the app shows only the claimable-draw hint and play continues (REQ-009, REQ-013).
- Given 150 half-moves without a capture or pawn move, When the next move is accepted and is not checkmate, Then the game ends as a draw (REQ-012).
- Given a pawn double-push where no en passant capture is legal, When the same position recurs, Then it counts as a repetition of the earlier position (REQ-011).
- Given a fivefold repetition was reached and the last move is undone, When the position is restored, Then the game is no longer over and the repetition count is decremented (REQ-014).

## Edge Cases
- Checkmate delivered by promotion (works with OB-006 promotion).
- Checkmate by castling or en passant.
- Insufficient material reached by a capture (e.g. last pawn captured).
- Repetition counting must consider side to move, castling rights and en passant rights (FIDE "same position").
- A game ended on the physical board (resignation, agreed draw, time) — the user uses "New game" (OB-011); no in-app resign/draw buttons (A3).

## In Scope
- Chess end detection (rules module) and the game-over state in the hero region.
- Claimable-draw hint.

## Out of Scope
- Resign / agree-draw / clock flag buttons (A3).
- Xiangqi endings (OB-009) and other games (their phases).
- Match history of finished games (OB-013).

## Dependencies
- OB-006 (rules module, keypad disable), OB-007 (hero region rendering), OB-011 (New game), OB-025 (turn loop), OB-022 (no search on game end).
- OB-001 Q5 (which endings to detect).
- Note (2026-10-02, no-chess-knowledge principle): the claimable-draw hint must use plain language instead of "DRAW CAN BE CLAIMED": `DRAW POSSIBLE — SAME POSITION 3 TIMES` / `DRAW POSSIBLE — 50 MOVES WITHOUT CAPTURE OR PAWN MOVE`. Results stay plain (`CHECKMATE — YOU WIN`, `STALEMATE — DRAW`, `DRAW — NOT ENOUGH PIECES TO WIN`, replacing "INSUFFICIENT MATERIAL"). On game end, the tap board stays visible with all squares dimmed.

## Assumptions
A1–A3 are **accepted assumptions (PO did not object, 2026-10-02)**. They are not explicit decisions and can be revisited.
- **A1 (OB-001 Q5):** Automatic draws (FIDE): stalemate, insufficient material (dead position, limited to standard material cases), fivefold repetition, 75-move rule.
- **A2 (OB-001 Q5):** Threefold repetition and the 50-move rule are claim-based in FIDE, so the app only shows a hint and does not end the game.
- **A3:** Endings that happen only on the physical board (resignation, agreement, time) are handled by starting a new game. No dedicated buttons.

## Open Questions
1. Exact result wording/language (English uppercase per the terminal style is assumed; localization is not documented).

## Developer Handoff
- Put the end detection in the Chess rules module (pure Dart, unit-tested with known FEN positions for each ending).
- The hero region renders a "game over" view model; OB-007's REQ-007 state is implemented by this ticket's content.
- Keep the repetition history in the game state (needed later for undo too).
