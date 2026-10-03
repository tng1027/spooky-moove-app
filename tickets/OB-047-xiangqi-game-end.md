# Ticket Analysis

> **Status: Done on iOS simulator (2026-10-04).** Xiangqi games now end.
> - `XiangqiGameStatus` (`lib/features/xiangqi/domain/xiangqi_game_status.dart`) is built from the rules facts: in progress, or `XiangqiLoss(winner, checkmate | noMoves)` for the side to move with no legal move. It has no draw or repetition branches (XQ6, XQ9).
> - `XiangqiResultFormat.headline` gives `CHECKMATE` or `NO MOVES` / `YOU WIN` or `YOU LOSE` from the user's side, and no hint.
> - `XiangqiBoardState.status` is computed on every snapshot, so undo restores it. `xiangqiActiveGameState` passes the headline through the seam, and the whole shared game-over path works for Xiangqi with no shared-code change.
> - As decided in OB-044, the check fill takes precedence over the dimmed state, so a mated general keeps its red cell while every other piece is dimmed.
> - Tests: status from FENs (checkmate and no moves for each side, a flying-general mate, generals only), headlines, controller (undo out of game over), and seam/widget tests (both mates, NO MOVES both ways, no search after a tier change or without a tier, undo restores the same suggestion, repetition goes on). The full suite has 492 tests.
> - Simulator: the new `integration_test/xiangqi_game_end_test.dart` covers God finding and confirming a mate-in-1 (`CHECKMATE` / `YOU WIN`, then UNDO resumes) and Black's mate entered on the board (`YOU LOSE`, no search after a tier pick). All 33 integration tests pass.

TICKET_TYPE: NEW_FEATURE
CONFIDENCE: HIGH

Xiangqi game end doesn't exist in the app. The game-over experience (result on two lines in the card, board locked, GAME OVER in the top bar, NEW GAME status button with a 500 ms guard, undo out of game over) is carried over from OB-024 / OB-041. The rules differ from Chess: a side with no legal moves loses, even when not in check. The scope choices were decided by the PO on 2026-10-03: no perpetual check/chase adjudication (XQ6), the `NO MOVES` wording (XQ7) and no automatic draws (XQ9).

## Ticket Title
[Feature] Detect and display the end of a Xiangqi game (checkmate, no legal moves)

## Summary
After every accepted move in a Xiangqi game, check whether the side to move has a legal move. If it hasn't, the game is over and that side has lost: `CHECKMATE` when in check, `NO MOVES` otherwise. The result is shown from the user's side (`YOU WIN` / `YOU LOSE`) using the existing game-over states. Nothing else ends the game in M1.

## Business Context
- Carry-over matrix rows 18–19 (OB-009).
- Without game end the board would show nothing to tap and no explanation, or ask the engine to search a finished position (OB-022 R2).
- In Xiangqi, being stalemated is a loss (Asian/WXF rules). Showing "DRAW" here would be wrong.

## Current Behavior
- Chess only: `ChessGameStatus` (checkmate, stalemate = draw, automatic draws, claimable hints) drives `SuggestionGameOver`, the dimmed board, `GAME OVER` in the top bar and the NEW GAME status button (OB-024, OB-041).
- After OB-042 the game-over path reads the result through the active-game seam (headline lines + tone, optional hint).

## Expected Behavior
| Situation | Card (two lines) | Tone |
|-----------|------------------|------|
| Side to move is checkmated, the user mated | `CHECKMATE` / `YOU WIN` | `accentGreen` |
| The user is checkmated | `CHECKMATE` / `YOU LOSE` | `accentRed` |
| Side to move has no legal move, not in check; it's the opponent | `NO MOVES` / `YOU WIN` | `accentGreen` |
| Same, it's the user | `NO MOVES` / `YOU LOSE` | `accentRed` |

When over (all unchanged from Chess):
- All pieces dimmed (≈ 40 % opacity, OB-044) and board taps ignored.
- Top bar center `GAME OVER`. The status line shows NEW GAME, which opens the new-game screen without the discard dialog, ignores taps for 500 ms after it appears, and BACK returns to the finished game.
- No engine search, also after a tier change. The persona row stays visible.
- UNDO takes back the last move and resumes play, with the same suggestion if it's the user's turn (OB-012 REQ-010).
- No hint line (no claimable draws in Xiangqi M1).

## User Story
As a Xiangqi player at a physical board
I want the app to say clearly when the game is over and whether I won
So that I don't keep waiting for a suggestion in a finished game.

## Functional Requirements
- REQ-001: Compose a pure Xiangqi game status from the rules facts (OB-043): in progress, or over with a winner and a reason (checkmate / no moves).
- REQ-002: Derive the status on every board snapshot, so undo restores it (as in OB-024).
- REQ-003: Provide the result headline (two lines + tone) from the user's side through the OB-042 seam.
- REQ-004: The game-over behaviour (dimmed board, blocked entry, no search, top bar, status line NEW GAME with 500 ms guard, undo) reuses the shared Chess implementation with no Xiangqi branch in shared widgets.
- REQ-005: No automatic draws, no claimable-draw hints and no repetition adjudication (XQ6, XQ9).

## Business Rules
- BR-001: The side to move with no legal move loses (checkmate or no moves).
- BR-002: Result colors: user win = `accentGreen`, user loss = `accentRed` (OB-024 BR-002).
- BR-003: Plain language: no "STALEMATE" (it means a draw in Chess), no "JIANG", no Chinese text (XQ7).
- BR-004: Endings on the physical board (resignation, agreed draw, time, repetition rulings by players) → the user taps NEW GAME. No in-app resign / draw buttons (OB-024 A3).

## User Flow
```text
Move accepted (board entry or ✓ I PLAYED IT)
↓
Status: side to move has legal moves? → yes → normal turn (OB-046)
                                      → no  → in check? CHECKMATE : NO MOVES
↓
Card: result + YOU WIN / YOU LOSE; board dimmed; top bar GAME OVER; status line [NEW GAME]
↓
UNDO → back to play    |    NEW GAME → new-game screen (no dialog)
```

## Acceptance Criteria
- Given the user (Red) confirms a suggested move that checkmates Black, When it is applied, Then the card shows `CHECKMATE` / `YOU WIN` in green, all pieces are dimmed, the top bar shows `GAME OVER` and the status line shows NEW GAME.
- Given the opponent's entered move checkmates the user, When it is accepted, Then the card shows `CHECKMATE` / `YOU LOSE` in red and no search starts.
- Given a move leaves the opponent with no legal move and not in check, When it is accepted, Then the card shows `NO MOVES` / `YOU WIN`.
- Given a move leaves the user with no legal move and not in check, When it is accepted, Then the card shows `NO MOVES` / `YOU LOSE`.
- Given a game-over state, When the user changes the tier, Then no engine search starts.
- Given a game-over state, When the user taps the board, Then nothing changes.
- Given the game-over NEW GAME button just appeared, When it is tapped within 500 ms, Then the tap is ignored; after that, it opens the new-game screen without the discard dialog, and BACK returns to the finished game.
- Given a game-over state reached by the user's confirmed move, When the user taps UNDO, Then play resumes on the user's turn with the same suggestion.
- Given the same position repeats many times (perpetual check), When moves are accepted, Then the game continues with no message (XQ6).
- Given only the two generals remain, When moves are accepted, Then the game continues (no automatic draw, XQ9), and the user can end it with NEW GAME.
- Given the status composition, When unit-tested from FENs, Then checkmate (each side), no-moves (each side, not in check) and in-progress positions return the right status and headline.

## Edge Cases
- Checkmate involving the flying-general rule (the general can't step onto the file the enemy general faces).
- No legal moves while not in check (soldiers and general blocked): a loss, not a draw.
- Game over on either side's turn, and with no tier selected.
- Undo several times from game over back to the start.
- Endless games with insufficient material to mate: the user decides on the physical board and uses NEW GAME.

## In Scope
- Xiangqi status composition, result headlines, game-over integration through the seam, unit, widget and integration tests (a short forced mate sequence in `integration_test/`).

## Out of Scope
- Perpetual check / chase rulings, any draw rules, move-count limits (XQ6, XQ9).
- Resign / draw-offer buttons. Match history (OB-013).

## Dependencies
- OB-042 (seam, shared game-over path), OB-043 (facts), OB-044 (dimmed state, entry block), OB-046 (suggestion path to confirm a mating move).
- XQ6, XQ7, XQ9 (decided, PO 2026-10-03).

## Decisions
- **XQ6 (PO 2026-10-03):** Perpetual check / perpetual chase are not detected or adjudicated in M1.
- **XQ7 (PO 2026-10-03):** The no-legal-move ending reads `NO MOVES` / `YOU WIN` or `YOU LOSE`.
- **XQ9 (PO 2026-10-03):** No automatic draws of any kind in Xiangqi M1.

## Assumptions
None.

## Open Questions
None.

## Developer Handoff
- Mirror `ChessGameStatus` (sealed, pure, built from rules facts) in `lib/features/xiangqi/domain/`. Keep the result strings next to it (as `GameResultFormat` does for Chess) or behind the seam's headline. Shared widgets only see lines + tone.
- Check the status before tier gating, like `SuggestionGameOver` today, so the result shows without a tier and on either side's turn.
