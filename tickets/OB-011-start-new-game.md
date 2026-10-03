# Ticket Analysis

> **Revision (PO, 2026-10-03): defaults + START GAME.** Supersedes "tap a side = start", REQ-005, REQ-007 (tier reset to none) and BR-001 below.
> - The new-game screen opens with **Even (🥉, the middle of the 7 levels)** and **WHITE** preselected (amber `isSelected`). Even is a free tier (OB-037).
> - WHITE / BLACK keys now only select the side. A full-width green `START GAME` key (`AppKey(isPrimary: true)`, `NewGameScreen.startKey`) pinned at the bottom starts the game with the selected game, side and level, so one tap starts a game with the defaults. The double-tap guard moved to START GAME.
> - A new game therefore always has a tier; the `PICK A LEVEL` states (card prompt, status line) stay in code but are unreachable from the UI.
> - Tests: `new_game_screen_test` (defaults, side selection without start, START with defaults, double tap on START, Even selected in the level row), `advisor_screen_test`, and the integration tests `new_game`, `persona_row`, `turn_loop`, `suggestion_card`, `chess_tap_board` updated; all pass on the iPhone 17 Pro simulator.
>
> **Status: Done on iOS simulator (2026-10-03).** Physical-device pass deferred (PO testing policy 2026-10-03).
> - Flow: fair-play notice → new-game screen (root, no BACK) → advisor. The advisor's NEW GAME key (status line) asks "DISCARD THE CURRENT GAME?"; confirming opens the new-game screen with a BACK key. The current game is discarded only when a side is tapped, so BACK leaves game, tier and side unchanged (dev decision with the PO, 2026-10-03).
> - New-game screen (Open Question 1 → single full-screen selector): game row built from `GameKind` (`lib/features/new_game/domain/game_kind.dart`, the one place listing offered games; Phase 1 = CHESS, preselected), WHITE / BLACK keys with king pictograms (tap = start), FAIR PLAY key (OB-008 REQ-005). ABOUT key left for OB-033.
> - State: `gameSessionProvider` (`GameSession?`: game + user side). `start()` calls `ChessBoardController.newGame(side)` (rules reset, entry/suggestion/commit guard cleared, side sets board orientation) and `personaTierProvider.clear()`. Double tap on a side key starts one game.
> - Shared `AppKey` design-system key (`lib/core/widgets/app_key.dart`) now used by the fair-play, new-game and confirm screens.
> - Not in this ticket: REQ-006 (suggestion right after the tier when the user plays White) and cancelling a running search come with OB-025/OB-007. No search is wired yet. OB-025 should listen to `gameSessionProvider`; `PersonaSuggester` already discards superseded results.
> - Tests: unit (`game_session_controller_test`, `newGame` in `chess_board_controller_test`), widget (`new_game_screen_test`: first use, sides, FAIR PLAY, text scale 2.0, double tap, cancel / back out / restart), integration on iPhone 17 Pro simulator (`integration_test/new_game_test.dart`; `chess_tap_board_test` and `persona_row_test` updated to start a game first).

TICKET_TYPE: NEW_FEATURE
CONFIDENCE: HIGH

No way to start a game exists (no code; no screen documented). `techContext.md` implies switching between games, and the PO decided that a tier must be chosen when a game starts (OB-021 D5). Updated 2026-10-02: side selection is a **PO decision** (D1 below), and the initial-position-only rule is an **accepted assumption** (A2), so confidence is now HIGH.

Previously a README stub. Now a full ticket, delivered first for **Chess** (Phase 1); Xiangqi and later games add themselves to the game list in their own phases.

## Ticket Title
[Feature] Start a new game: choose the game and the side the user plays, then pick a persona tier (Chess first)

## Summary
Let the user start a new game by choosing the game (Chess in Phase 1) and the side they play. The app then opens the advisor screen from the initial position with no persona tier selected, so the user must pick a tier (OB-023) before the first suggestion. The user can start a new game at any time.

## Business Context
- The product's core loop needs a defined start: game, side and tier (OB-001, OB-021 D5).
- `techContext.md`: providers must be cleanly disposed "when switching between the 6 games".
- Chess Definition of Done: "pick Chess → pick tier → enter moves → tier-based suggestion → game end" (README, Phase 1).

## Current Behavior
Not implemented. The app shell (OB-003) shows one empty advisor screen.

## Expected Behavior
- On launch, after the fair-play notice (OB-008), the user can start a new game.
- New game flow: choose game (Phase 1: Chess only) → choose side (White / Black) → advisor screen at the initial position with no tier selected.
- Once a tier is selected: if it is the user's turn (user plays White), a suggestion is computed immediately; otherwise the app waits for the opponent's move.
- A "New game" action is available at any time from the advisor screen; starting a new game discards the current game after confirmation.

## User Story
As a player sitting down at a physical board
I want to quickly tell the app which game I'm playing and which side I am
So that suggestions are computed for my side from the first move.

## Functional Requirements
- REQ-001: Provide a new-game entry: on first use (after OB-008) and from the advisor screen at any time.
- REQ-002: Game choice lists only games available in the current build/phase (Phase 1: Chess).
- REQ-003: Side choice: exactly one side, White or Black (Chess). Decision D1.
- REQ-004: The game starts from the standard initial position. Assumption A2.
- REQ-005: The advisor screen opens with **no persona tier selected**; suggestions are gated until a tier is chosen (OB-021 D5, OB-022 REQ-002, OB-023).
- REQ-006: After a tier is chosen, if the side to move is the user's side, a suggestion is computed immediately (OB-025).
- REQ-007: Starting a new game while a game is in progress asks for confirmation, then discards the current game state, cancels any running engine search, and resets the tier to "none selected".
- REQ-008: Switching games disposes the previous game's state and engine resources (`techContext.md`).

## Business Rules
- BR-001: No default tier; the tier is chosen per game (OB-021 D5).
- BR-002: Suggestions are computed only for the user's side (OB-021 D1; OB-025).
- BR-003: Selectors follow `designSystem.md` (keys ≥ 48 dp, selected = `accentActive`, no decorative motion).

## User Flow
```text
Launch → (fair-play notice, OB-008)
↓
New game: [CHESS] → side: [WHITE] [BLACK]
↓
Advisor screen, initial position, persona row with no tier selected
↓
User taps a tier
↓
User = White → suggestion computed immediately
User = Black → app waits for the opponent's (White's) move
```
Alternative flows:
- New game during a game → confirm → reset.
- User backs out of the new-game flow before choosing a side → returns to the previous screen/game unchanged.

## Acceptance Criteria
- Given a first launch after the fair-play notice, When the user proceeds, Then the new-game flow is shown with Chess as the only game in Phase 1.
- Given the user chose Chess and White, When the advisor screen opens, Then the position is the standard initial position, no tier is selected, and no suggestion is shown.
- Given the user chose White and then selects a tier, When the tier is selected, Then a suggestion for White's first move is computed and shown.
- Given the user chose Black and then selects a tier, When the tier is selected, Then no suggestion is shown, and the keypad accepts White's (the opponent's) first move.
- Given a game in progress, When the user taps "New game" and confirms, Then the previous game is discarded, any running search is cancelled, and the new-game flow starts with no tier selected.
- Given a game in progress, When the user taps "New game" and cancels, Then the current game, tier and suggestion are unchanged.

## Edge Cases
- New game tapped while the engine is thinking (search cancelled, no stale suggestion).
- Rapid double tap on a side key (one game started).
- App killed during the new-game flow (no partial game; persistence per OB-001 Q6, out of scope here).

## In Scope
- New-game flow (game + side), New game action with confirmation, reset of game/tier/engine state.
- Chess entry in the game list.

## Out of Scope
- Xiangqi and later games in the list (added in their phases). Xiangqi: OB-045 (GAME row CHESS / XIANGQI, RED / BLACK sides), on the seams of OB-042.
- Starting from a custom position (OB-001 Q3).
- Resuming a game after app kill (OB-001 Q6).
- Tier selector UI itself (OB-023).

## Dependencies
- OB-003 (shell), OB-008 (notice before first use), OB-023 (tier selector), OB-025 (turn loop), OB-022 (gating).
- OB-001 Q1 (side selection — decided), Q3 (start position — accepted assumption).
- OB-012 (undo): "New game" discards the undo history.
- Note (2026-10-02): the chosen side sets the tap-board orientation (user's side at the bottom, OB-006). Side keys show a white/black piece pictogram plus "WHITE"/"BLACK" (no chess knowledge needed). The new-game screen hosts the "FAIR PLAY" info key (OB-008 REQ-005).
- Note (PO compliance document, 2026-10-02): the new-game screen also hosts the "ABOUT" key (licenses, **OB-033**), since there is no Settings screen. Pro-only games show a lock and open the game paywall (**OB-039**); in M1, only Xiangqi is gated (pending OB-035 Q8). Tier choice on the advisor screen now has locked tiers for free users (**OB-037**).
- Update (PO 2026-10-02): monetization **deferred** (OB-035 M-D1). Every game is selectable, with no lock and no paywall; OB-037/OB-039 are deferred. The ABOUT key (OB-033) stays. Guardrail: keep the game list as data in one place (already required: "the game list is data-driven"), so availability can later be decided there without touching widgets.

## Decisions
- **D1 (OB-001 Q1, PO 2026-10-02: "ng dùng chỉ chọn 1 phe"):** The user picks **exactly one side** per game (White or Black). Suggestions are only for that side. (Was assumption A1.)

## Assumptions
- **A2 (OB-001 Q3) — Accepted assumption (PO did not object, 2026-10-02):** Phase 1 supports only the standard initial position. Can be revisited.
- **A3:** Starting a new game during a game requires a confirmation (protects against accidental taps while eyes are on the board).

## Open Questions
1. Is a separate game-selection screen wanted, or a compact selector on the advisor screen? Non-blocking; default = a simple full-screen selector using design-system keys.

## Developer Handoff
- Keep a game-session state per game (game type, user side, position, tier = null) and dispose it on new game/switch.
- The game list is data-driven, so later phases only register a new game.
- Reuse design-system key components for the game and side selectors.
