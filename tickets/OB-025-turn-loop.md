# Ticket Analysis

> **Status: Done on iOS simulator (2026-10-03).** Physical-device pass deferred (PO testing policy 2026-10-03).
> - Suggestion request / clear / cancel / stale-drop were already delivered by OB-007's `SuggestionController` (REQ-004, REQ-005, REQ-008, REQ-009, BR-003). This ticket adds the turn status: `turnStatusProvider` (`lib/features/advisor/presentation/turn_status.dart`, derived from the game session's user side and the board's side to move) and `StatusLine` (`YOUR MOVE` / `OPPONENT TO MOVE` on the left in `textSecondary`, NEW GAME on the right; UNDO from OB-012 will join the right side).
> - Game end (REQ-007): since OB-024, the loop stops on every ending (checkmate, stalemate, automatic draws): no turn label, board fully dimmed, no search even on a tier change; the card shows the result.
> - Tests: controller acceptance cases (a move other than the suggestion, moves without a tier then a tier, tier change on the opponent's turn, tier round-trip reuses the cached move, checkmate stops the loop), `turn_status_test`, `status_line_test`. Simulator integration test `integration_test/turn_loop_test.dart` (user plays Black, Even tier): first suggestion 573 ms incl. engine start, next 346 ms.

> **Revised by OB-041 (PO decision 2026-10-03):** A1 is replaced by OB-001 Q2 option b. On the user's turn, a "✓ I PLAYED IT" key commits the suggestion in one tap; any other legal move entered on the board is an override and the game continues. The rest of this ticket (turn alternation, suggestion timing, cancellation, game end) is unchanged. Layout (OB-041 revision 2): the turn label now sits top-center in the top bar, and shows `GAME OVER` when the game has ended.

TICKET_TYPE: NEW_FEATURE
CONFIDENCE: HIGH

No ticket owns the turn-by-turn loop. OB-006 enters a move, OB-007 shows a suggestion, OB-022 picks the move by tier, but nothing defines whose move is being entered, when a suggestion is requested, or how the user's own move gets into the game state. That is the core of OB-001 Q2. Updated 2026-10-02: A1 ("user enters every move") is an **accepted assumption** (the PO did not object), so it is ready to implement. Built first for Chess; game-agnostic so Xiangqi (OB-009) reuses it.

## Ticket Title
[Feature] Run the game turn loop: enter opponent and user moves, and suggest only on the user's turn (Chess first)

## Summary
Keep the app in sync with the physical board by alternating turns. The keypad is used to enter **every** move played on the board (opponent's and user's). A tier-based suggestion is computed only when it is the user's turn. A status line shows whose move is being entered.

## Business Context
- Core value: "enter the opponent's move → get the best reply" (`projectbrief.md`). Every suggestion is only correct if the app's position matches the physical board.
- OB-021 D1: the persona affects only the move suggested to the user.
- Chess Definition of Done (README, Phase 1).

## Current Behavior
Not implemented. Individual pieces are specified (OB-006 keypad, OB-007 card, OB-022 tier selection) but not the loop connecting them.

## Expected Behavior
- **Opponent's turn:** status "OPPONENT TO MOVE"; the keypad accepts the opponent's move; no suggestion is shown.
- After the opponent's move is accepted: if the game didn't end (OB-024), the turn passes to the user, and a suggestion is computed with the active tier (OB-022) and shown (OB-007).
- **User's turn:** status "YOUR MOVE"; the suggestion is shown; the keypad accepts the move the user **actually played** on the board, whether or not it is the suggested move (Assumption A1).
- After the user's move is accepted: the suggestion is cleared and the turn passes to the opponent.

## User Story
As a player at a physical board
I want to enter each move as it happens on the board, and get a suggestion when it's my turn
So that the app always matches the real game, even when I don't play the suggested move.

## Functional Requirements
- REQ-001: The game state tracks the side to move and the user's side (OB-011).
- REQ-002: The keypad (OB-006) enters moves for whichever side is to move.
- REQ-003: A status line shows "YOUR MOVE" or "OPPONENT TO MOVE" (`textSecondary`, tabular monospace).
- REQ-004: When the turn passes to the user and a tier is selected, request a suggestion (OB-022) and show it (OB-007).
- REQ-005: When the user's move is accepted, clear the suggestion and cancel any running search.
- REQ-006: The user may enter any legal move on their turn, including one different from the suggestion (A1).
- REQ-007: Before each turn change, check game end (OB-024). If the game ended, stop the loop.
- REQ-008: While no tier is selected, moves can still be entered for both sides; suggestions appear as soon as a tier is chosen on the user's turn (OB-022 REQ-002/REQ-012).
- REQ-009: Haptics: "move accepted" on each accepted move (OB-006); "engine move ready" only when a suggestion is shown (OB-007).

## Business Rules
- BR-001: Suggestions are only computed for the user's side (OB-021 D1).
- BR-002: The app's position must reflect every move entered; no move is assumed (A1).
- BR-003: Changing the tier on the user's turn recomputes the suggestion for the current position; on the opponent's turn it applies to the next suggestion (OB-021 D5, R6).

## User Flow
```text
Opponent's turn ("OPPONENT TO MOVE")
↓ user enters opponent's move (keypad)
Game end? → yes: OB-024 / no ↓
User's turn ("YOUR MOVE") → suggestion computed with active tier → card shows it
↓ user plays a move on the board and enters it (suggested or not)
Suggestion cleared → back to opponent's turn
```

## Acceptance Criteria
- Given the user plays Black and a tier is selected, When the opponent's (White's) move is entered, Then the status changes to "YOUR MOVE" and a suggestion for Black is shown.
- Given it is the user's turn with a suggestion shown, When the user enters the suggested move, Then the suggestion is cleared, the status changes to "OPPONENT TO MOVE", and no new suggestion is computed.
- Given it is the user's turn with a suggestion shown, When the user enters a different legal move, Then that move is applied, the suggestion is cleared, and the turn passes to the opponent.
- Given it is the opponent's turn, When the screen is shown, Then no suggestion is visible.
- Given no tier is selected, When moves are entered for both sides, Then they are applied and no suggestion is shown; When a tier is then selected on the user's turn, Then a suggestion for the current position appears.
- Given the opponent's move ends the game, When it is accepted, Then no suggestion is computed and the game-over state is shown (OB-024).
- Given it is the opponent's turn, When the user changes the tier, Then no search starts; the new tier is used for the next suggestion.

## Edge Cases
- User enters their move before the suggestion arrives (search cancelled, stale result never shown).
- Mis-entered move: corrected via UNDO (OB-012, in the Chess DoD). Undo restores the turn and suggestion state of the previous position.
- User plays White: the first suggestion is computed at game start once a tier is selected (OB-011).

## In Scope
- Turn alternation, status line, suggestion request/clear timing, cancellation.
- Game-agnostic loop; Chess is the first game wired to it.

## Out of Scope
- "Played the suggestion" one-tap confirmation (OB-001 Q2 option b) — chosen by the PO on 2026-10-03; delivered in OB-041.
- Undo UI and state restore (OB-012; this loop must resume correctly from a restored position), custom start positions (OB-001 Q3), resuming after app kill (OB-001 Q6).

## Dependencies
- OB-006 (keypad), OB-007 (card), OB-022 (tier selection), OB-011 (user side, start), OB-024 (game end).
- OB-001 Q2 (how the user's own move is entered).
- Note (2026-10-02): "keypad" in this ticket now means the tap board (OB-006). With smart entry, entering the suggested move usually takes 1–2 taps; the green highlight on the board shows where to tap.

## Assumptions
- **A1 (OB-001 Q2, option a) — Superseded 2026-10-03 by OB-041 (option b).** Original text, kept for history: The user enters **every** move, including their own, as actually played on the board. This keeps the app in sync even when the user deviates from the suggestion. It costs one extra move entry per turn, within the < 1.2 s input-cycle target per move.

## Open Questions
None blocking. A1 can be revisited by the PO (option b: one-tap "played suggestion"; option c: assume the suggestion was played).

## Developer Handoff
- A small game-session controller (state: position, side to move, user side, tier, suggestion state) drives the keypad, card and engine; widgets stay dumb.
- Cancel in-flight searches on every accepted move, tier change or new game; tag results with position + tier to drop stale ones.
- Keep it game-agnostic: the rules module supplies legal moves and end detection per game.
