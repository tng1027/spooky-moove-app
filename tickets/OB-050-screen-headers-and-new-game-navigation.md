# Ticket Analysis

> **Status: Done on iOS simulator (2026-10-04).** Shared `ScreenHeader` / `HeaderKey` (`lib/core/widgets/screen_header.dart`): new-game `[BACK] CHESS [FAIR PLAY]`, game `[NEW GAME] WIN RATE [UNDO]`. Confirming NEW GAME (or the game-over key) calls `GameSessionController.discard()` and opens Home with the new-game screen for the current game on top.
>
> Previous status: Ready for development (2026-10-04). All open questions are answered by the PO (see Decisions). No separate design pass needed: the headers reuse the advisor `TopBar` pattern.

TICKET_TYPE: ENHANCEMENT
CONFIDENCE: HIGH

Both screens and every control already exist (OB-011, OB-012, OB-041, OB-049). The PO wants the controls moved into a three-slot header (left key / centre label / right key) on the new-game screen and the advisor, with NEW GAME and UNDO swapping corners, and the game discarded as soon as the user confirms NEW GAME. That's changed behaviour, not a bug: the current layout was decided by the PO (OB-041 revision 2, OB-049 Design). Not a duplicate.

## Ticket Title
[Enhancement] Three-slot headers on the new-game and game screens; NEW GAME top-left, UNDO top-right; discard on confirm

## Summary
- New-game screen: header `[BACK]  CHESS  [FAIR PLAY]`. The bottom row `[HOME] [FAIR PLAY]` goes away; START GAME stays pinned at the bottom.
- Game screen: header `[NEW GAME]  WIN RATE  [UNDO]` (corners swapped).
- In-game NEW GAME → "DISCARD THE CURRENT GAME?" → confirm discards the game immediately and opens the new-game screen for that game on top of Home. Home is the root again and never shows a BACK-to-game key, which frees its top-left corner for Settings (OB-051).

## Business Context
- PO request 2026-10-04, items 3 and 4:
  - "in New Game screen, the top left corner is a Back button (click will go back to Home screen). The top center is a name of the game (for example: chess). The right corner is the Fair Play rule."
  - "in the Game screen, the top left corner is a New Game button (click will show confirmation dialog and go back to New Game screen if user ok). the top center is a Win Rate. The top right corner is Undo button."
- Items 1–2 (Home Settings / Language) are OB-051. They need Home's top-left corner, which OB-049 used for the conditional BACK key.
- Goal: one consistent header pattern on every screen (Home, new-game, game).

## Current Behavior
Source: `new_game_screen.dart`, `home_screen.dart`, `widgets/new_game_key.dart`, `advisor/presentation/widgets/top_bar.dart`, `undo_key.dart`, `status_line.dart`, OB-049 (implemented 2026-10-04, uncommitted).
- New-game screen: title `NEW GAME · CHESS` at the top of the scrolling body (header semantics, spoken "New game, Chess"); bottom pinned row `[HOME] [FAIR PLAY]` above the green START GAME. HOME and START GAME share one double-tap guard. FAIR PLAY pushes the read-only fair-play notice.
- Game screen `TopBar` (`NavigationToolbar`, 48 dp, corner keys ≤ 30 % of the width, labels scale down): UNDO (Material undo glyph + `UNDO`, disabled until a move) top-left; centre `WIN nn%` / `WIN RATE --` / `GAME OVER`; NEW GAME top-right.
- Top-bar NEW GAME: dialog "DISCARD THE CURRENT GAME?" (CANCEL / NEW GAME). On confirm, pushes Home, then the new-game screen for the current game: route stack advisor (root) → Home → new-game. The game is discarded only by START GAME. Home shows a BACK key (top-left) because a route is beneath it; BACK returns to the unchanged game.
- Game-over: the status-line NEW GAME opens the same stack without the dialog.

## Expected Behavior
- New-game screen header, in a 48 dp row like the advisor `TopBar`:
  - left: `BACK` → Home, starts no game;
  - centre: the game name (`CHESS` / `XIANGQI`), spoken "New game, Chess" / "New game, Xiangqi";
  - right: `FAIR PLAY` → read-only fair-play notice (unchanged).
  - The bottom row is removed; START GAME stays pinned full-width at the bottom.
- Game screen header: left `NEW GAME`, centre win rate / `GAME OVER` (unchanged), right `UNDO` (unchanged behaviour, glyph and disabled state).
- NEW GAME → "DISCARD THE CURRENT GAME?" → confirm → the game is discarded at once; the new-game screen for that game opens with Home (root) beneath it. Home has no BACK key in any state.
- Game-over status-line NEW GAME (no dialog) → same result.

## User Story
As a player
I want every screen to have the same header layout, with navigation on the left and the screen's secondary action on the right
So that I always know where to go back, start over, or undo.

## Functional Requirements
- REQ-001: The new-game screen has a header row (`AppDimens.topBarHeight`, same three-slot layout and 30 % corner cap as the advisor `TopBar`): `BACK` left, game name centre, `FAIR PLAY` right. Corner labels scale down, never wrap; the centre label scales down.
- REQ-002: `BACK` on the new-game screen goes to Home and starts no game. System back / edge swipe / predictive back do the same. `BACK` and START GAME keep one shared double-tap guard (as HOME does today).
- REQ-003: The centre label shows only the game label (`CHESS` / `XIANGQI`, from `GameKind`), with header semantics, spoken "New game, Chess" / "New game, Xiangqi" (D2).
- REQ-004: The bottom `[HOME] [FAIR PLAY]` row is removed. LEVEL, YOUR SIDE, defaults, scrolling and the pinned START GAME are unchanged.
- REQ-005: The game screen `TopBar` puts NEW GAME in the leading corner and UNDO in the trailing corner. Win rate / `GAME OVER` stay centred. Each key keeps its behaviour, semantics and disabled state. Header keys are text labels; UNDO keeps its glyph (D3).
- REQ-006: Top-bar NEW GAME keeps the confirmation dialog (text unchanged). CANCEL leaves everything unchanged.
- REQ-007: Confirming the dialog discards the current game immediately (D1): session cleared, running search and timers cancelled, undo history gone. Home becomes the root, and the new-game screen for the discarded game's kind is shown on top of it.
- REQ-008: The game-over NEW GAME in the status line keeps working without a dialog and has the same result as REQ-007.
- REQ-009: Home never shows a BACK-to-game key (D1). OB-049's conditional BACK key is removed.

## Business Rules
- BR-001: Header pattern for all three screens: navigation in the leading corner, a label in the centre, a secondary action in the trailing corner; 48 dp row; corner keys ≥ 48 dp and ≤ 30 % of the width.
- BR-002 (D1): a game is discarded when the user confirms "DISCARD THE CURRENT GAME?" or taps the game-over NEW GAME. This restores OB-011 REQ-007 as written and replaces the 2026-10-03 dev rule "discarded only on START GAME" (OB-011 note, OB-049 BR-003).
- BR-003: Design system unchanged: tokens only, Latin labels, text labels on keys (UNDO glyph is the one exception), dark theme, no decorative motion, 360 dp × text scale 2.0 without overflow.
- BR-004: `GameKind` stays the only source of game names (README guardrail).

## User Flow
```text
Game screen: [NEW GAME]   WIN 62%   [UNDO]
↓ tap NEW GAME
"DISCARD THE CURRENT GAME?"  [CANCEL] [NEW GAME]
↓ NEW GAME → game discarded
New-game screen: [BACK]  CHESS  [FAIR PLAY] / LEVEL / YOUR SIDE / [START GAME]
↓ START GAME → game screen (new game)
```
Alternative flows:
- New-game screen → BACK (or system back) → Home (root, no BACK key) → XIANGQI → new-game screen for Xiangqi.
- Dialog → CANCEL → game unchanged.
- Game over → status-line NEW GAME (no dialog) → game discarded → new-game screen for that game.
- New-game screen → FAIR PLAY → notice → back → new-game screen, selections kept.

## Acceptance Criteria
New-game screen
- Given the new-game screen for Chess, When it renders, Then the header shows `BACK` on the left, `CHESS` (without "NEW GAME ·") in the centre and `FAIR PLAY` on the right, and there is no `HOME` key and no bottom `FAIR PLAY` key.
- Given the new-game screen for Xiangqi, When it renders, Then the centre label is `XIANGQI` and a screen reader announces "New game, Xiangqi" as a header.
- Given the new-game screen opened from Home, When the user taps `BACK` (or uses system back), Then Home is shown and no game has started.
- Given the new-game screen, When the user taps `FAIR PLAY`, Then the read-only fair-play notice opens; When they go back, Then LEVEL and YOUR SIDE keep their selections.
- Given the new-game screen, When the user taps `BACK` and START GAME in quick succession, Then only the first action happens.
- Given the new-game screen, When the user taps START GAME, Then the selected game, side and level start and the game screen opens (unchanged).

Game screen
- Given a game in progress, When the game screen renders, Then `NEW GAME` is in the top-left corner, the win rate in the centre and `UNDO` (with its glyph) in the top-right corner.
- Given no move entered yet, When the game screen renders, Then the top-right `UNDO` is disabled; When a move is entered, Then it is enabled and undoes one move per tap (OB-012 unchanged).
- Given a game in progress, When the user taps `NEW GAME` and then CANCEL, Then the game, side, level and suggestion are unchanged.
- Given a Xiangqi game in progress with the engine searching, When the user taps `NEW GAME` and confirms, Then the new-game screen for Xiangqi opens, the previous game is gone, and no suggestion from the old search appears later.
- Given the user confirmed NEW GAME and is on the new-game screen, When they tap `BACK`, Then Home is shown with no BACK key, and there is no way back to the discarded game.
- Given a finished game, When the user taps the status-line NEW GAME, Then the new-game screen for the current game opens without a dialog, and `BACK` leads to Home with no BACK key.
- Given a new game started from the new-game screen, When the user uses system back on the game screen, Then the app does not return to Home or the new-game screen.

Home
- Given any state (fresh launch, after a discard, after BACK from the new-game screen), When Home renders, Then it shows no BACK key.

Layout
- Given 360 × 640 at text scale 2.0, When the new-game screen and the game screen render, Then nothing overflows, corner keys stay ≥ 48 dp tall, and labels scale down instead of wrapping.

## Edge Cases
- Long label in a corner at text scale 2.0 (`FAIR PLAY`, `NEW GAME`): scales down inside the 30 % cap (same as today's top bar).
- Double tap on NEW GAME: one dialog only. Double tap on the dialog's confirm: one discard, one new-game screen.
- Confirm while the engine is searching: the search is cancelled and its result never appears on the next game.
- Confirm, then BACK, then nothing: Home with no game; a relaunch also shows Home (no resume, OB-001 Q6).
- Game over and the user taps the top-bar NEW GAME instead of the status-line one: dialog shown (unchanged); same result after confirm.

## In Scope
- New-game screen header (BACK / game name / FAIR PLAY), removal of the bottom row.
- Game screen top-bar corner swap.
- Discard on confirm (and on game-over NEW GAME); Home as root with no BACK key.
- Updated widget and integration tests (`new_game_screen_test`, `home_screen_test`, `advisor_screen_test`, `xiangqi_game_over_test`, `fair_play_gate_test`, integration tests that tap HOME / BACK / NEW GAME).

## Out of Scope
- Home Settings and Language keys and dialogs (OB-051).
- Dialog wording, LEVEL / side selection, win-rate format, undo rules.
- New icons on header keys (D3).
- Resume after app kill (OB-001 Q6); any "undo discard".

## Dependencies
- OB-049 (Home, new-game per game; implemented, uncommitted). This ticket revises its Design: new-game header, HOME key removed, Home's BACK key removed, BR-003 replaced by BR-002 here.
- OB-011 (dialog; REQ-007 discard-on-confirm restored), OB-012 (UNDO), OB-041 (top bar, revision 2/3), OB-024 / OB-041 (game-over NEW GAME), OB-008 (FAIR PLAY re-view).
- Blocks OB-051 (Home's top-left corner must be free). Ship OB-050 first or together.

## Decisions
PO, 2026-10-04:
- D1 (Q1): confirming "DISCARD THE CURRENT GAME?" discards the current game immediately. Home becomes the root again and never shows a BACK-to-game key.
- D2 (Q2): the new-game header shows only the game name (`CHESS` / `XIANGQI`); spoken "New game, Chess" / "New game, Xiangqi".
- D3 (Q3): text labels on header keys; UNDO keeps its glyph; no new icons.

## Assumptions
- A-1: "Back button (click will go back to Home screen)" replaces the bottom HOME key; the label is `BACK`, spoken "Back".
- A-2: "The right corner is the Fair Play rule" means the existing FAIR PLAY key (read-only notice), moved, not new content.
- A-3: "Go back to New Game screen" means the new-game screen for the current game (OB-049 Q1 answer), not Home.
- A-4: The game-over NEW GAME button in the status line stays (the PO only listed the header).

## Open Questions
None. Q1–Q3 answered (see Decisions).

## Developer Handoff
- New-game screen: move the title into a `TopBar`-like header (reuse the `NavigationToolbar` + 30 % cap + `FittedBox` pattern; a small shared header widget is reasonable since Home, new-game and game screens now use it). Rename `homeKey` → `backKey` (developer's call); keep the shared guard with START GAME.
- `TopBar`: swap `leading` / `trailing`.
- Discard: add a discard path on `GameSessionController` (clear the session; listeners on `gameSessionProvider` must cancel the search and timers). `_HomeGate` then shows Home as root; `NewGameKey.openNewGameScreen` captures the game kind before clearing and pushes the new-game screen for it on that root. Remove `HomeScreen.backKey` and the `canPop` header logic. START GAME's `popUntil(isFirst)` still leaves no route under the advisor.
- Verify on the iOS simulator (testing policy 2026-10-03).
