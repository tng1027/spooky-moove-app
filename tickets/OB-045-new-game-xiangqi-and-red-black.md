# Ticket Analysis

> **Status: Done on iOS simulator (2026-10-03).** Xiangqi can now be selected and played end to end.
> - `GameKind.xiangqi` (`XIANGQI`, variant `xiangqi`, 9×10, `RED` / `BLACK`). `game_registry.dart` maps it to `XiangqiBoardController`, `XiangqiBoard`, the 帥 / 將 general discs on the side keys, and an interim `XiangqiSuggestedMove` (`H3 ➔ E3`; OB-046 adds the disc, the `✕` mark and the WXF line).
> - `NewGameScreen(initialGame:)`: NEW GAME passes the session's game (XQ8), and the root screen defaults to CHESS. Switching games plays `selectionClick` and keeps the side position and the level. Game and side keys announce "Chess" / "Xiangqi" / "White" / "Red" / "Black" (new `AppKey.semanticsLabel`).
> - Tests: game kind, session/registry, and 13 new-game/advisor widget tests: relabel, side kept, preselection, BACK keeps Chess, xiangqi variant + card, Black waiting, no "WHITE", and no overflow at text scale 2.0 on 360×640, 392×800, 360×800 and 360×600, which covers the advisor layout check deferred from OB-044.
> - Simulator: `integration_test/new_game_test.dart` has a Xiangqi flow with the real engine (Even suggested `h1i3` for Red; Black at the bottom with WAITING FOR OPPONENT). The full suite (420 tests) and all 28 integration tests pass.
> - Known gap: Xiangqi game end has no headline yet (OB-047).

TICKET_TYPE: ENHANCEMENT
CONFIDENCE: HIGH

The new-game screen exists (OB-011, revision of 2026-10-03: defaults Even + first side, START GAME). This ticket extends it with a second game and per-game side labels. The behaviour is otherwise unchanged. The Designer's review gives the full spec; its defaults were decided by the PO on 2026-10-03 (XQ5 RED, XQ8 preselection).

## Ticket Title
[Enhancement] New-game screen: add XIANGQI to the GAME row and RED / BLACK side keys

## Summary
Register Xiangqi in `GameKind`. The GAME row becomes two stacked full-width keys, CHESS and XIANGQI. Selecting a game changes only the side keys' labels and pictograms: WHITE / BLACK with king pictograms for Chess, RED / BLACK with 帥 / 將 discs for Xiangqi. The LEVEL row, side selection, BACK, FAIR PLAY, START GAME and the discard prompt work as they do today.

## Business Context
- Carry-over matrix rows 2–4 (OB-009).
- `GameKind` is the single list of offered games (README guardrail). Xiangqi is available to everyone (OB-035 M-D1).

## Current Behavior
- GAME row: one key, CHESS, always preselected (`GameKind.values.first`).
- YOUR SIDE: WHITE / BLACK keys with Cburnett king pictograms, WHITE preselected.
- LEVEL: 7 emoji tiers, Even preselected. BACK appears only with a game in progress. FAIR PLAY. Full-width green START GAME with a double-tap guard.
- NEW GAME on the advisor asks "DISCARD THE CURRENT GAME?" first. The old game is discarded only on START GAME, and BACK keeps it. On game over, NEW GAME opens the screen without the dialog.

## Expected Behavior
- GAME row: two stacked full-width keys, `CHESS` then `XIANGQI`, with Latin labels only. The selected key is amber (`isSelected`).
- Preselection (XQ8): the current session's game if there is one, else CHESS.
- YOUR SIDE: two keys. Chess: `WHITE` / `BLACK` with king pictograms. Xiangqi: `RED` / `BLACK` with the 帥 (Red) / 將 (Black) discs from OB-044.
- Default side (XQ5): the first mover (WHITE / RED). Switching the game keeps the selected side position (first / second) and changes only labels and pictograms.
- LEVEL: unchanged; Even by default; the chosen level is kept when switching games.
- START GAME starts the selected game, side and level from the initial position (OB-011). For Xiangqi the advisor shows the Xiangqi board (OB-044) with the user's side at the bottom.
- Switching games mid-game needs no extra prompt: the screen is only reached after the discard prompt (or from game over), and the old game is discarded only on START GAME. BACK returns to the unchanged current game.

## User Story
As a player who plays both Chess and Xiangqi
I want to pick Xiangqi and my colour on the same new-game screen I use for Chess
So that starting either game takes the same few taps.

## Functional Requirements
- REQ-001: Add `xiangqi` to `GameKind` with label `XIANGQI`, engine variant `xiangqi` and side labels `RED` / `BLACK` (OB-042 REQ-001).
- REQ-002: Render one full-width key per `GameKind` value, stacked, in enum order.
- REQ-003: Preselect the current session's game, else the first game (CHESS) (XQ8).
- REQ-004: Side keys take label and pictogram from the selected game. The selected side position is kept when switching games. Default = first mover (XQ5).
- REQ-005: START GAME calls `onStart(game, side, tier)`. The session starts the selected game through the OB-042 seam.
- REQ-006: Selecting a game key plays `selectionClick` (same as side and level keys).
- REQ-007: Semantics: game keys are buttons with labels "Chess" / "Xiangqi" and a selected state. Side keys announce "Red" / "Black" for Xiangqi.

## Business Rules
- BR-001: Latin labels only on the new-game screen. Characters appear only inside the piece discs.
- BR-002: The game list comes only from `GameKind`. No hard-coded game checks in widgets.
- BR-003: Design-system keys (≥ 48 dp, amber selected), 360 dp × text scale 2.0 without overflow.

## User Flow
```text
NEW GAME (advisor) → "DISCARD THE CURRENT GAME?" → YES
↓
New-game screen: [CHESS] (selected, current game) / [XIANGQI]
↓
User taps XIANGQI → side keys become [帥 RED] (selected) / [將 BLACK]; level stays Even
↓
START GAME → Xiangqi advisor, Red at the bottom
```
Alternative: BACK → current Chess game unchanged.

## Acceptance Criteria
- Given first use (no session), When the new-game screen opens, Then CHESS is selected, WHITE is selected and the level is Even.
- Given a Xiangqi game in progress, When the user opens the new-game screen via NEW GAME → discard, Then XIANGQI is preselected.
- Given CHESS is selected, When the user taps XIANGQI, Then the side keys read RED / BLACK with 帥 / 將 discs, the first-mover key stays selected, and the level is unchanged.
- Given XIANGQI with BLACK selected, When the user taps CHESS, Then the side keys read WHITE / BLACK and BLACK stays selected.
- Given XIANGQI and RED with Even, When the user taps START GAME, Then the advisor shows the Xiangqi initial position with Red at the bottom, level Even, and a suggestion for Red's first move.
- Given XIANGQI and BLACK, When the user taps START GAME, Then Black is at the bottom and the status line reads WAITING FOR OPPONENT.
- Given a Chess game in progress and the screen opened via the discard prompt, When the user taps XIANGQI and then BACK, Then the Chess game, side and level are unchanged.
- Given a rapid double tap on START GAME, When it lands, Then exactly one game starts.
- Given a 360 dp screen at text scale 2.0, When the screen renders with both game keys, Then nothing overflows (the content scrolls; START GAME stays pinned).
- Given the Xiangqi flow, When any screen is inspected, Then the word "WHITE" never appears.

## Edge Cases
- Game over in Xiangqi → NEW GAME opens the screen without the dialog, with XIANGQI preselected.
- Switching games several times before START: only the last selection counts.
- Engine variant switch happens on START, not on selecting the key (OB-042 REQ-005).

## In Scope
- `GameKind.xiangqi`, GAME row, per-game side keys, preselection, tests (`new_game_screen_test`, `integration_test/new_game_test.dart` extended for Xiangqi).

## Out of Scope
- Board and advisor behaviour (OB-044, OB-046). ABOUT key (OB-033). Game gating (OB-039, deferred).

## Dependencies
- OB-042 (side model, per-game labels, session start through the seam), OB-044 (board and discs to show after START). OB-008 (FAIR PLAY), OB-011 (screen).
- XQ5, XQ8 (decided, PO 2026-10-03).

## Decisions
- **XQ5 (PO 2026-10-03):** default side RED (the first mover, like WHITE).
- **XQ8 (PO 2026-10-03):** preselect the current game, else CHESS.

## Assumptions
- A-1: Stacked full-width game keys (not one row) keep ≥ 48 dp height and readable labels at text scale 2.0, and leave room for later games.

## Open Questions
None blocking.

## Developer Handoff
- `NewGameScreen` takes the current game (or null) to preselect. Keep `_selectedSide` as the shared side type, so switching games keeps the position.
- Reuse the Xiangqi disc widget from OB-044 for the side pictograms (40 dp like the Chess pictogram).
- Update keys: `NewGameScreen.gameKey(GameKind.xiangqi)`, and side keys keyed by side position, not by the Chess color enum.
