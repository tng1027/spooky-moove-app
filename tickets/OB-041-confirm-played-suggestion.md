# Ticket Analysis

> **Status: Done on iOS simulator (2026-10-03).** Physical-device pass deferred (PO testing policy 2026-10-03).
> - `ChessBoardController.commit(ChessMove)` reuses the board's commit path (apply, double-tap guard, `lightImpact`, snapshot that clears selection and highlight); illegal moves and finished games are ignored.
> - Pure `statusLineContentFor` + `statusLineContentProvider` (`status_line_content.dart`) implement the key-state table; `ConfirmPlayedKey` (`AppKey`, `accentGreen` label, semantics "I played the suggested move") commits the move held by `SuggestionReady`, never a re-derived one.
> - `StatusLine` shows the key in its left region; the REQ-010 hint uses a new optional `TapBoard.onDimmedTap` and an `ignoredBoardTapProvider` counter, shown for 2 s only while the key is enabled.
> - Tests: key-state table, `commit` (normal, castling, en passant, promotion, selection, guard, illegal, game over), key widget and semantics, status line states / hint / no overflow at 360 dp × 2.0, confirm then undo gives the same suggestion with no new search. Simulator `integration_test/turn_loop_test.dart`: confirm path and override path; 285 unit/widget tests pass.

> **Revision 3 (PO decisions after BA/design review, 2026-10-03) — done on iOS simulator:**
> - The enabled "✓ I PLAYED IT" is the primary action: `accentGreen` background with `bgDark` text (white on `#00E676` is ~1.6:1 contrast, rejected; new `AppKey.isPrimary`), with an 8 dp margin above it (status line 56 dp).
> - The top-center turn label is replaced by the **win rate** of the suggested move: `WIN RATE nn%` (green ≥ 50 %, red below), or `YOU MATE IN n` / `OPPONENT MATES IN n`; `WIN RATE --` (grey) while there is no suggestion; `GAME OVER` unchanged. The card no longer shows the win-rate line (move + expert line only). Whose turn it is is carried by the bottom button.
> - Layout order (PO 2026-10-03): top bar / persona row / suggestion card / board / status line.
>
> **Revision 2 (PO decisions after BA/design review, 2026-10-03) — supersedes the key-state table, REQ-010 and C-A1 below; done on iOS simulator:**
> - Top bar: UNDO top-left, turn label top-center (`YOUR MOVE` / `OPPONENT TO MOVE` / `GAME OVER`), NEW GAME top-right (`TopBar`, `NavigationToolbar`; corner keys capped at 30 % of the width so the label keeps room at text scale 2.0).
> - The bottom status line is **always one full-width button**:
>
>   | Situation | Button |
>   |-----------|--------|
>   | Opponent's turn | disabled `WAITING FOR OPPONENT` |
>   | User's turn, no tier | disabled `PICK A LEVEL ABOVE` |
>   | User's turn, thinking / engine error / promotion chooser open | disabled `✓ I PLAYED IT` |
>   | User's turn, suggestion ready | enabled `✓ I PLAYED IT` (green) |
>   | Game over | enabled `NEW GAME` (white): opens the new-game screen **without** the discard dialog; BACK returns to the finished game, so UNDO still works |
> - Taps on the game-over `NEW GAME` are ignored for 500 ms after it appears (a double tap on a mating "I PLAYED IT" can't leave the game).
> - REQ-010 (hint on dimmed-square taps) **dropped**: the permanent labelled button replaces it; `TapBoard.onDimmedTap` and its counter were removed.

TICKET_TYPE: ENHANCEMENT
CONFIDENCE: HIGH

Today the user enters **every** move, their own included (OB-025 A1, an accepted assumption). In practice the user plays the suggested move most of the time, so they play it on the physical board and then have to find and tap the same move again on the screen. The PO reviewed this on 2026-10-03 and chose OB-001 Q2 **option b**: a one-tap "played it" confirmation, with free board entry kept for any other move. This revises OB-025 A1. Option b was already listed in OB-025 "Out of Scope" as "only if the PO chooses it".

## Ticket Title
[Enhancement] Confirm the played suggestion with one tap; any other move entered on the board overrides it (Chess first)

## Summary
On the user's turn, when a suggestion is shown, a **"✓ I PLAYED IT"** key applies the suggested move to the app board in one tap. If the user played a different move, they enter it on the tap board as today; that move is applied and the game continues. Overriding the suggestion has no other effect.

## Business Context
- Product goal: help the user play at the chosen persona level (OB-021). The suggestion is the **tier's move**, never the engine's best move (OB-021 D12; PO confirmed 2026-10-03).
- The second entry of the suggested move is redundant and makes the user look back at the screen and aim at squares again. Target users may have no chess knowledge (OB-001 Q8), so every extra entry is a chance to make a mistake.
- The app must stay in sync with the physical board (OB-025 BR-002). An explicit confirmation keeps that guarantee; silently assuming the suggestion was played (option c) does not.

## PO decisions (2026-10-03)
- **D1:** Always show one suggested move: the active persona tier's move (not the engine's best move).
- **D2:** After the suggestion, a key lets the user confirm they played it.
- **D3:** On confirm, the app board is updated with the suggested move.
- **D4:** If the user does not confirm and instead enters another move on the board, that move is taken as an override and the game continues. Overrides are not tracked, labelled or treated differently.

## Current Behavior
- The user enters every move on the tap board, including the suggested one (OB-025 A1). With smart entry this takes 1–2 taps on the highlighted squares.
- The status line shows `YOUR MOVE` / `OPPONENT TO MOVE` on the left, and UNDO and NEW GAME on the right (OB-025, OB-012, OB-011).

## Expected Behavior
- On the user's turn, the left side of the status line becomes the **"✓ I PLAYED IT"** key in place of the `YOUR MOVE` label (states below).
- Tapping it applies the displayed suggestion exactly as if the user had entered it on the board: the same commit path, the same "move accepted" haptic, the turn passes to the opponent and the suggestion is cleared.
- The tap board keeps accepting any legal move on the user's turn. Entering the suggested move by hand is the same as confirming. Entering any other move is an override: it is applied and the game continues.

### Key states
| Situation | Status line left side |
|-----------|-----------------------|
| Opponent's turn | `OPPONENT TO MOVE` label (unchanged) |
| User's turn, no tier selected | `YOUR MOVE` label (unchanged) |
| User's turn, suggestion being computed (incl. after a tier change) | "✓ I PLAYED IT" key, **disabled** |
| User's turn, suggestion ready | "✓ I PLAYED IT" key, **enabled** (`accentGreen`) |
| User's turn, engine error | `YOUR MOVE` label (the card shows ENGINE ERROR + RETRY) |
| Game over | Nothing (unchanged, OB-024) |

Disabled and enabled share the same size and position, so the layout does not jump when the suggestion arrives.

## User Story
As a player at a physical board, even without chess knowledge
I want to confirm with one tap that I played the suggested move
So that I don't have to enter it again, and can still enter a different move when I choose to.

## Functional Requirements
- REQ-001: The suggestion is the active tier's move (OB-022); no best-move line is added (D1).
- REQ-002: On the user's turn with a tier selected, show the "✓ I PLAYED IT" key in the status line's left region, per the key-state table.
- REQ-003: Tapping the enabled key commits the **currently displayed** suggestion through the same path as board entry, so turn change, game-end check (OB-024), suggestion clear and search cancel (OB-025) behave identically.
- REQ-004: The commit includes the special-move effects shown on the card: the castling rook moves, the pawn taken en passant is removed, and the suggested promotion piece is used (no promotion chooser).
- REQ-005: If a board selection is in progress (source or destination selected), the key clears it and commits the suggestion. If the promotion chooser is open, the key is disabled until the chooser closes.
- REQ-006: The key never commits a stale suggestion: it is disabled while a suggestion for a new tier or position is being computed (OB-007 REQ-009).
- REQ-007: The tap board stays fully active on the user's turn. Any legal move entered there is applied (D4). There is no override state, label or counter.
- REQ-008: Haptics: the same "move accepted" haptic as board entry (OB-006). No extra haptic for the key.
- REQ-009: UNDO after a confirmed move restores the user's turn, the same suggestion (from the position and tier cache, OB-012 REQ-009) and the enabled key.
- REQ-010: If the user taps a square that isn't active on their turn (for example an opponent's piece) while a suggestion is shown, the status line briefly shows the hint "TAP ✓ I PLAYED IT OR ENTER YOUR MOVE" (about 2 s), then returns to the key.
- REQ-011: The key has accessibility semantics: button, label "I played the suggested move", disabled state announced.

## Business Rules
- BR-001: The suggestion shown is always the active tier's move (OB-021 D1, D12).
- BR-002: The app applies only moves the user confirmed or entered; nothing is assumed (OB-025 BR-002, unchanged in spirit).
- BR-003: The board can only change through confirmation, board entry or undo.
- BR-004: No chess notation on the key or in the hint (OB-001 Q8 principle).

## User Flow
```text
Opponent's move entered → user's turn
↓
Card: thinking → status line: [✓ I PLAYED IT] (disabled)
↓
Card: "E2 ➔ E4", board highlights E2/E4 → key enabled
↓
├─ User plays E2→E4 on the physical board → taps [✓ I PLAYED IT]
│    → E2→E4 applied, "move accepted" haptic → OPPONENT TO MOVE
└─ User plays something else (e.g. D2→D4) → enters D2→D4 on the tap board
     → D2→D4 applied → OPPONENT TO MOVE (override, nothing else happens)
```

## Wireframe (user's turn, suggestion ready)
Layout revised by the PO on 2026-10-03: UNDO moved to the top-left corner and NEW GAME to the top-right corner (new top bar), so the confirm key spans the full status line.

```text
┌──────────────────────────────────┐
│ [UNDO]                [NEW GAME] │  top bar (48 dp)
├──────────────────────────────────┤
│            E1 ➔ G1               │  suggestion card (unchanged)
│        [rook] H1 ➔ F1            │
│            WIN 58%               │
├──────────────────────────────────┤
│  persona row                     │
├──────────────────────────────────┤
│  tap board: E1 G1 H1 F1 green    │  any other legal move = override
├──────────────────────────────────┤
│ [        ✓ I PLAYED IT         ] │  status line (48 dp)
└──────────────────────────────────┘
```

## Acceptance Criteria
- Given the suggestion `E2 ➔ E4` is shown, When the user taps "✓ I PLAYED IT", Then E2→E4 is applied, the suggestion is cleared, the status reads `OPPONENT TO MOVE`, and the "move accepted" haptic fires once.
- Given the suggestion `E2 ➔ E4` is shown, When the user enters D2→D4 on the board, Then D2→D4 is applied and the turn passes to the opponent with no override message.
- Given the suggestion `E2 ➔ E4` is shown, When the user enters E2→E4 on the board, Then the result is identical to tapping the key.
- Given the suggestion is White kingside castling, When the user confirms, Then the king ends on G1 and the rook on F1.
- Given the suggestion is en passant `E5 ➔ D6 ✕`, When the user confirms, Then the pawn on D5 is removed.
- Given the suggestion is a promotion to a queen, When the user confirms, Then a queen is placed on the promotion square and no promotion chooser opens.
- Given the suggestion is being computed, When the status line is shown, Then the key is visible and disabled; tapping it does nothing.
- Given the user changes the tier while a suggestion is shown, When the new suggestion is being computed, Then the key is disabled; When it is ready, Then the key commits the new tier's move.
- Given no tier is selected on the user's turn, When the status line is shown, Then it reads `YOUR MOVE` and there is no key.
- Given it is the opponent's turn, When the status line is shown, Then there is no key.
- Given the user confirmed a suggestion, When they tap UNDO, Then it is the user's turn again, the same suggestion is shown and the key is enabled.
- Given the confirmed suggestion delivers checkmate, When the user confirms, Then the game-over state is shown (OB-024) and the key disappears.
- Given a source square is selected on the board, When the user taps the key, Then the selection is cleared and the suggestion is committed.
- Given the promotion chooser is open, When the status line is shown, Then the key is disabled.
- Given an engine error on the user's turn, When the status line is shown, Then it reads `YOUR MOVE` and there is no key.
- Given a suggestion is shown, When the user taps an opponent's piece, Then the hint "TAP ✓ I PLAYED IT OR ENTER YOUR MOVE" appears for about 2 s and the board does not change.
- Given a 360 dp wide screen at text scale 2.0, When the key is shown with UNDO and NEW GAME, Then nothing overflows (the label scales down, as the turn label does today).

## Edge Cases
- The user taps the key by mistake after playing a different move: the app and board are out of sync until the user taps UNDO (REQ-009) and enters the real move.
- Rapid double tap on the key: only one move is committed (the second tap lands on the opponent's turn, where the key is gone).
- A suggestion arrives while the user is halfway through a board entry: the selection stays; the user can finish it or tap the key (REQ-005).
- Tier change on the opponent's turn: no effect on the key (it isn't shown).
- The user plays White at game start: the first suggestion and key appear once a tier is picked.

## In Scope
- The confirm key and its states in the status line; committing the suggestion through the existing entry path; the hint for inactive taps; undo interaction; tests.
- Chess first; game-agnostic, so Xiangqi (OB-009) reuses it.

## Out of Scope
- Assuming the suggestion was played without a confirmation (OB-001 Q2 option c).
- Implicit confirmation by entering the opponent's reply (BA/design idea, 2026-10-03; possible follow-up if the inactive-tap hint shows it's needed).
- Tracking, counting or displaying overrides (D4).
- Text-to-speech reading of the suggestion.

## Dependencies
- OB-025 (turn loop), OB-007 (suggestion state and move), OB-006 (board commit path, selection, promotion chooser), OB-012 (undo and suggestion cache), OB-024 (game end), OB-003 (status-line tokens).
- Revises OB-025 A1 and OB-001 Q2 (option a → option b).

## Assumptions
- **C-A1:** The key lives in the status line's left region (48 dp, design-system minimum) instead of a separate 56 dp row, so the board keeps its current size and the layout never shifts. Revisit if testing shows it's too small to hit while looking at the physical board.
- **C-A2:** Label "✓ I PLAYED IT" (English UI, like the rest of the app apart from the fair-play notice).

## Open Questions
None blocking.

## Developer Handoff
- Reuse the board's commit path: expose a `commit(ChessMove)` on `ChessBoardController` (or equivalent) used by both the tap board and the key, so turn change, haptic, game-end check and suggestion clear stay in one place.
- The key reads the ready suggestion from `SuggestionController`'s state; the move to commit is the one in that state (never re-derived), which satisfies REQ-006.
- `StatusLine` chooses label vs. key from `turnStatusProvider` plus the suggestion state; keep the decision in a small pure function so it's unit-testable against the key-state table.
- Tests: unit tests for the key-state mapping; widget tests for each acceptance criterion; extend `integration_test/turn_loop_test.dart` with confirm and override paths.
