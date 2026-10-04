# Ticket Analysis

> **Status: Done on iOS simulator (2026-10-04).** `HomeScreen` with CHESS / XIANGQI keys built from `GameKind` opens `NewGameScreen` for that game (level + side, no GAME row). Revised by OB-050: Home is the root again with no BACK key, and the new-game screen's HOME row moved to the header BACK key.
>
> Previous status: Ready for development (2026-10-04). Design is filled in and Open Questions 1–3 are answered.

TICKET_TYPE: ENHANCEMENT
CONFIDENCE: MEDIUM

Game selection already exists: the GAME row (CHESS / XIANGQI) on the new-game screen (OB-011, OB-045). The PO wants it moved to its own Home screen with two big buttons, and the new-game screen reduced to level and side for the chosen game, plus a way back to Home. This changes the existing flow and navigation, so it's an enhancement, not a new feature or a bug. Not a duplicate: OB-011 Open Question 1 settled on a single full-screen selector, and no ticket plans a separate Home screen. Confidence is MEDIUM because the open questions about the in-progress game and the advisor's NEW GAME entry change the acceptance criteria.

## Ticket Title
[Enhancement] Add a Home screen to pick the game (CHESS / XIANGQI) before the new-game screen

## Summary
Add a Home screen with two big buttons, CHESS and XIANGQI. Tapping one opens the new-game screen for that game, where the user picks level and side and taps START GAME as today. The new-game screen loses its GAME row and gets a HOME key that returns to the Home screen.

## Business Context
- PO request (2026-10-04): "need a new home page, where user could pick game; currently 2 big buttons only: Chess & Xiangqi; pick a game → New Game page to pick level and sides; New Game should have a button to go back to Home."
- Picking the game first gives each game its own entry point. Later games (Phases 4–7) add a button here, and future game gating (OB-039) gets a natural place for the lock.
- Guardrail (README, OB-035): the list of offered games stays data in one place (`GameKind`). The Home buttons must come from that list, not from hard-coded checks.

## Current Behavior
Source: `lib/app.dart`, `new_game_screen.dart`, `widgets/new_game_key.dart`, `status_line.dart`, OB-011 and OB-045.
- Launch: the fair-play notice (OB-008) until acknowledged, then the **new-game screen as the root** (`_HomeGate`). Once a session exists, the root becomes the advisor screen.
- New-game screen: title `NEW GAME`; GAME row with stacked full-width CHESS / XIANGQI keys (preselected: the current game, else CHESS, XQ8); LEVEL (Even default); YOUR SIDE (first mover default, kept when switching games); bottom row BACK (only when a route is underneath) + FAIR PLAY; full-width green START GAME with a double-tap guard.
- Advisor: the top-bar NEW GAME key asks "DISCARD THE CURRENT GAME?". Confirming pushes the new-game screen over the advisor, and BACK returns to the unchanged game. At game over, the status-line NEW GAME opens the new-game screen without the dialog. The old game is discarded only on START GAME.
- There is no Home screen. The session lives in memory only (resume after app kill is OB-001 Q6, open).

## Expected Behavior
- After the fair-play notice, the user lands on the **Home screen** with two big buttons, CHESS and XIANGQI, one per `GameKind` value in enum order.
- Tapping a game button opens the **new-game screen for that game**. The screen shows which game it's for and has LEVEL and YOUR SIDE (labels and pictograms for that game) and START GAME, all working as they do today. **No GAME row.**
- The new-game screen has a **HOME** key that returns to the Home screen without starting a game.
- START GAME starts the game and opens the advisor, as today.
- In-game entry points (advisor NEW GAME, game-over NEW GAME) follow Open Questions 1–2. Recommended default: they open the new-game screen for the **current** game (as today), with HOME available to switch games.

## User Story
As a player who plays both Chess and Xiangqi
I want to pick the game first on a simple Home screen
So that I go straight to the right setup without scanning a combined screen.

## Functional Requirements
- REQ-001: Add a Home screen shown after the fair-play notice when no game is in progress. It replaces the new-game screen as the root of the "no session" state.
- REQ-002: Home shows one large button per `GameKind` value, in enum order (today: CHESS, XIANGQI). No other buttons in this ticket, unless Open Question 4 says otherwise.
- REQ-003: Tapping a game button opens the new-game screen for that game. A rapid double tap opens only one new-game screen.
- REQ-004: The new-game screen receives the game as input and shows it (for example, in the title). The GAME row is removed. LEVEL, YOUR SIDE, FAIR PLAY and START GAME are unchanged, including the defaults (Even, first mover) and the START GAME double-tap guard.
- REQ-005: The new-game screen has a HOME key that returns to the Home screen and starts no game. The system back gesture or button does the same when the screen was opened from Home.
- REQ-006: START GAME starts the selected game, side and level from the initial position (OB-011), then shows the advisor. Going back from the advisor must not return to Home or the new-game screen (the advisor is the root while a game is in progress, as today).
- REQ-007: In-game entry to the new-game screen (advisor NEW GAME after the discard prompt, game-over NEW GAME) follows the answer to Open Questions 1–2.
- REQ-008: Game buttons and the HOME key use design-system keys with button semantics and spoken labels ("Chess", "Xiangqi", "Home"), like the existing keys.

## Business Rules
- BR-001: The game list comes only from `GameKind`. No hard-coded game checks in widgets (README guardrail, OB-045 BR-002).
- BR-002: All games are available to everyone. No lock and no paywall on Home (monetization deferred, OB-035 M-D1; OB-039 deferred).
- BR-003: Leaving the new-game screen through HOME never discards or changes the current game. A game is discarded only by START GAME (OB-011, unchanged).
- BR-004: Design system: keys ≥ 48 dp, design tokens only, Latin labels only, dark theme, no decorative motion; 360 dp × text scale 2.0 without overflow (OB-003, OB-045 BR-003).

## User Flow
```text
Launch → fair-play notice (first use only, OB-008)
↓
Home: [CHESS] [XIANGQI]
↓
Tap XIANGQI
↓
New game · XIANGQI: LEVEL (Even) / YOUR SIDE [帥 RED] [將 BLACK] / HOME · FAIR PLAY / START GAME
↓
START GAME → Xiangqi advisor (Red at the bottom)
```
Alternative flows:
- On the new-game screen, HOME (or system back) → Home → tap CHESS → new-game screen for Chess.
- During a game: NEW GAME → "DISCARD THE CURRENT GAME?" → YES → new-game screen for the current game (recommended default, Open Question 1) → HOME → Home → pick the other game → START GAME. The old game is discarded only at START GAME.
- Game over → NEW GAME → same as above, without the dialog.

## Acceptance Criteria
- Given a first launch, When the user acknowledges the fair-play notice, Then the Home screen shows exactly two game buttons, CHESS and XIANGQI, in that order, and no new-game controls.
- Given a returning launch (notice already acknowledged, no game in progress), When the app opens, Then the Home screen is shown.
- Given the Home screen, When the user taps CHESS, Then the new-game screen for Chess opens with no GAME row, WHITE / BLACK side keys with WHITE selected, and level Even.
- Given the Home screen, When the user taps XIANGQI, Then the new-game screen for Xiangqi opens with RED / BLACK side keys (帥 / 將 discs) with RED selected, level Even, and the word "WHITE" nowhere on the screen.
- Given the new-game screen opened from Home, When the user taps HOME, Then the Home screen is shown and no game has started.
- Given the new-game screen opened from Home, When the user uses the system back gesture or button, Then the Home screen is shown and no game has started.
- Given the new-game screen for Xiangqi with BLACK and level Solid selected, When the user taps START GAME, Then the Xiangqi advisor opens with Black at the bottom, level Solid, and the status line reads WAITING FOR OPPONENT.
- Given a game in progress, When the user goes from the advisor to the new-game screen and then to Home, Then the current game is unchanged until START GAME is tapped on a new-game screen.
- Given a game in progress reached Home through the new-game screen, When the user returns without starting a game, Then the current game, side, level and suggestion are unchanged (exact path per Open Question 3).
- Given the Home screen, When the user double-taps a game button, Then exactly one new-game screen opens.
- Given the new-game screen, When the user double-taps START GAME, Then exactly one game starts.
- Given the advisor of a started game, When the user uses system back, Then the app does not return to the Home or new-game screen.
- Given a 360 × 640 screen at text scale 2.0, When the Home screen and the new-game screen render, Then nothing overflows and every key stays ≥ 48 dp tall.
- Given a screen reader, When focus moves over Home, Then the buttons are announced as "Chess" and "Xiangqi", each as a button.

## Edge Cases
- Double tap on a game button, or a game button and HOME tapped in quick succession: one navigation only.
- A game is in progress and the user opens Home: Home must not look like the current game was lost (see Open Question 3).
- A game is in progress and the user picks the same game again on Home: the old game is still discarded only on START GAME.
- Game over: NEW GAME opens the new-game screen without the dialog (OB-024 / OB-041 behaviour kept).
- App killed on Home or on the new-game screen: no partial game. Next launch shows Home (no resume, OB-001 Q6).
- Engine search running when the user leaves the advisor: unchanged from today. The search is cancelled when a new game starts, not when screens are pushed.
- Small screens at text scale 2.0 with two big buttons: the buttons stay large but must not overflow.

## Design
Designer, 2026-10-04. Same visual language as the fair-play and new-game screens: `bgDark` scaffold, `SafeArea` on all sides, `AppDimens.spacingLarge` (16 dp) padding, `AppKey` blocks, JetBrains Mono, Latin labels, no icons, no shadows, no gradients and no decorative motion.

**New tokens** (in `AppDimens`, the only new values):
- `gameKeyMinHeight = 112`: minimum height of a Home game key, equal to `2 × minKeyHeight + spacingLarge`. This makes the key clearly "big" (more than twice a normal key) while six keys (Phases 4–7) still fit on a 640 dp screen at text scale 1.0. It's a minimum: the key grows with text scale.
- `gamePictogramSize = 56`: artwork size on a Home game key. It's 1.4× the 40 dp side-key pictogram, so it reads at arm's length, and it matches the top of the 48–56 dp key range in `designSystem.md`.

### Home screen
- **Header (Open Question 6):** a top-left title `PICK A GAME` (`AppTypography.primary`, `Semantics(header: true)`, spoken "Pick a game"). It doesn't show the app name, because the name may still change after store review (OB-034) and the brand already appears on the launcher icon and the fair-play notice. A verb title also matches the existing screen titles (`NEW GAME`).
- **Header corners:** the title sits in a 48 dp row (`AppDimens.topBarHeight`) built like the advisor's `TopBar` (`NavigationToolbar`, corner keys sized to their content, capped at 30% of the width).
  - **Leading corner:** a `BACK` key, shown **only when a route is beneath Home**, which means a game is in progress (see In-progress game below). With no game, the title starts at the left edge.
  - **Trailing corner:** left empty. It's reserved for the future ABOUT key (OB-033).
- **Game keys:** one `AppKey` per `GameKind.values` value, in enum order, full width, `minHeight: gameKeyMinHeight`, with `spacingLarge` between keys. The style is `keyNormal` with `textPrimary`, which is neither `isSelected` (Home has no selection) nor `isPrimary` (green is reserved for the screen's one main action, and two equal choices don't have one).
- **Key content:** a centred column with the artwork (`gamePictogramSize` square), then `AppDimens.spacing`, then the label (`game.label`, `AppTypography.primary`, centred, free to wrap, no `FittedBox`).
- **Artwork:** `GameWidgets.sidePictogram(game, PlayerSide.first)`, which gives the white king (Cburnett) for Chess and the 帥 disc for Xiangqi. It reuses the registry, so it needs no new per-game method and no game checks in the widget (BR-001). A later game provides its first-side pictogram through the same switch.
- **Vertical placement:** the header is at the top. The game keys form a group aligned to the **bottom** of the content area, in the thumb zone and in the same place as START GAME on the new-game screen. Free space goes between the header and the keys. If the content is taller than the screen (text scale 2.0, more games later), the whole body scrolls (`SingleChildScrollView` with a `minHeight` equal to the viewport and `MainAxisAlignment.end`).
- **Small vs large phones:** the layout is the same on all phones (portrait only). Keys always fill the width minus 2 × 16 dp, and they never grow taller to fill a tall screen. The extra height on large phones becomes free space above the keys. At 360×640 and text scale 2.0, the header plus two keys (about 120 dp each) use about 300 of the roughly 580 dp available, so nothing scrolls.
- **Future lock marker (OB-039, not built):** a disabled or locked game would use the existing disabled `AppKey` (`keyDisabled` background, `textSecondary` text) with a secondary-style caption under the label. No layout change is needed.

### New-game screen
- **Header:** `NEW GAME · CHESS` / `NEW GAME · XIANGQI` (`AppTypography.primary`, `Semantics(header: true)`, spoken "New game, Chess"). It uses the same middle-dot pattern as `LEVEL · EVEN`. The title may wrap after the dot at large text scales, and it's never scaled down.
- **Body:** the GAME heading and keys are removed (agrees with Open Question 5). LEVEL, YOUR SIDE, the scroll behaviour and the pinned bottom area are unchanged.
- **HOME key:** takes the place of today's BACK key in the bottom row: `[HOME] [FAIR PLAY]`, two equal `Expanded` keys with `AppDimens.spacing` between them, above the full-width green START GAME key.
  - It's **always shown**, unlike today's BACK, which was conditional.
  - Label `HOME`, spoken "Home", text only and no house icon. The design system has no icons on keys, and BACK and NEW GAME are text too.
  - It sits in the same slot as BACK, so users who know today's screen find it where they expect, and the bottom row stays in the thumb zone.
  - It isn't a top-left key: that would put it out of thumb reach and leave an empty corner opposite it.
- **FAIR PLAY (Open Question 4):** stays on the new-game screen (agrees with the BA). Home keeps only the game keys plus the conditional BACK. ABOUT (OB-033) goes in Home's trailing corner when it's built.

### Navigation, back gesture and Android back
- **No game in progress:** Home is the root.
  - Tapping a game key pushes the new-game screen with the platform's default page transition, the same as FAIR PLAY today (navigation feedback, not decoration).
  - On the new-game screen, HOME, Android back, predictive back and the iOS edge swipe all pop to Home.
  - On Home, Android back leaves the app (default behaviour, no "press again to exit").
- **Game in progress (Open Questions 1–3):**
  - **Questions 1 and 2:** agree with the BA. NEW GAME (after the discard dialog) and the game-over NEW GAME open the new-game screen for the **current** game, so restarting the same game takes one tap.
  - **Route stack:** advisor (root) → Home → new-game screen.
    - HOME or back on the new-game screen goes to Home.
    - Home's corner BACK key or system back goes to the advisor, with the game unchanged (BR-003).
  - **Question 3:** this is the BA's option (a) plus a **visible** BACK corner key on Home. iOS has no back button and the edge swipe is hard to discover. Without a visible key, Home looks like the game was lost (Edge Cases).
    - The corner key isn't a big button, so "2 big buttons" still holds.
    - Cost: going back to the game from the new-game screen now takes 2 taps (HOME, then BACK) instead of 1. The user only reaches this screen after confirming "DISCARD THE CURRENT GAME?", so the extra tap is acceptable.
- **After START GAME:** no Home or new-game route is left under the advisor. Back on the advisor exits the app, the same as today (REQ-006).

### States
- **Normal:** `keyNormal` with `textPrimary`. The Xiangqi disc's `pieceRed` rim and glyph and the king's outline are unchanged.
- **Pressed:** no separate pressed visual (no ripple, no colour flash), the same as every other `AppKey`. The response is the page transition itself. No haptic on navigation keys (game keys, HOME, BACK), which matches BACK and FAIR PLAY today. `selectionClick` stays reserved for selections.
- **Disabled:** none in this ticket. Keys are never greyed out during navigation.
- **Double-tap guard:** a guard flag ignores taps while a game-key push is in progress, and is cleared when that route pops, so the user can pick again after HOME.
- **Shared guard on the new-game screen:** HOME and START GAME share one guard, so whichever is tapped first wins and the second tap is ignored.

### Accessibility
- **Semantics:**
  - Game keys are buttons announced "Chess" and "Xiangqi". The artwork is excluded from semantics (wrap the key content in `Semantics(label:, excludeSemantics: true)`, like the side keys).
  - HOME: "Home". Home's BACK: "Back".
  - Titles are headers with mixed-case spoken labels, because upper-case labels would be spelled out (same rule as `_spoken`).
- **Focus order:** BACK (if shown), then the title, then the game keys in enum order. On the new-game screen it stays as today, with HOME before FAIR PLAY.
- **Tap targets:** game keys are at least 112 dp tall and full width. HOME and BACK are at least 48 dp tall (`AppKey`). The corner BACK key is at least 48 × 48 dp.
- **Text scaling:** no fixed text heights. Key heights are minimums, labels wrap, and both screens scroll above a pinned bottom (new-game) or scroll as a whole (Home). Check 360×640 and 360×600 at text scale 2.0 for no overflow and keys at least 48 dp. The corner BACK key may scale its label down (`FittedBox`), like the advisor's corner keys.
- **Contrast (WCAG):**
  - `textPrimary` on `keyNormal`: about 13.7:1.
  - `textSecondary` on `bgDark`: about 6.1:1.
  - `textSecondary` on `keyDisabled` (future lock): about 5.6:1.
  - `pieceRed` on `keyNormal`: about 6:1 (OB-044).
  - `bgDark` on `accentGreen` (START GAME): unchanged.
  - All pass AA.

### Wireframes
Home, no game in progress (all phones; extra height becomes free space above the keys):
```text
┌────────────────────────────────┐
│ PICK A GAME                    │  48 dp header row
│                                │
│                                │
│          (free space)          │
│                                │
│ ┌────────────────────────────┐ │
│ │            ♔               │ │  56 dp pictogram
│ │          CHESS             │ │  min 112 dp
│ └────────────────────────────┘ │
│                                │  16 dp
│ ┌────────────────────────────┐ │
│ │           (帥)             │ │
│ │         XIANGQI            │ │  min 112 dp
│ └────────────────────────────┘ │
└────────────────────────────────┘  16 dp padding inside the safe area
```
Home, game in progress (reached through NEW GAME, then HOME):
```text
┌────────────────────────────────┐
│ [BACK]  PICK A GAME            │  BACK returns to the advisor
│          (free space)          │
│ [        ♔  CHESS            ] │
│ [       (帥) XIANGQI         ] │
└────────────────────────────────┘
```
New-game screen, Chess (Xiangqi: header `NEW GAME · XIANGQI`, side keys `(帥) RED` / `(將) BLACK`):
```text
┌────────────────────────────────┐
│ NEW GAME · CHESS               │  header
│                                │
│ LEVEL · EVEN                   │
│ [🥚][🐣][🐥][🥉][🥈][🥇][👑]    │
│                                │
│ YOUR SIDE                      │
│ [   ♔ WHITE   ][   ♚ BLACK   ] │  WHITE amber (selected)
│          (scrolls)             │
├────────────────────────────────┤
│ [    HOME     ][  FAIR PLAY  ] │  pinned
│ [          START GAME        ] │  green, pinned
└────────────────────────────────┘
```
360×640 at text scale 2.0:
```text
Home                           New game (Xiangqi)
┌──────────────────┐           ┌──────────────────┐
│ PICK A GAME      │           │ NEW GAME ·       │
│   (free space)   │           │ XIANGQI          │
│ ┌──────────────┐ │           │ LEVEL ·          │
│ │     ♔        │ │           │ EVEN             │
│ │   CHESS      │ │           │ [🥚🐣🐥🥉🥈🥇👑]   │
│ └──────────────┘ │           │ YOUR SIDE        │
│ ┌──────────────┐ │           │ [(帥)  ][(將)   ] │
│ │    (帥)      │ │           │ [RED   ][BLACK  ] │
│ │  XIANGQI     │ │           │     (scrolls)    │
│ └──────────────┘ │           ├──────────────────┤
└──────────────────┘           │ [HOME ][FAIR    ]│
                               │ [     ][PLAY    ]│
                               │ [ START GAME    ]│
                               └──────────────────┘
```

## In Scope
- Home screen with one button per `GameKind` (CHESS, XIANGQI).
- App root: fair-play notice → Home when there is no game in progress.
- New-game screen takes the game as input, drops the GAME row, adds the HOME key and back behaviour.
- In-game entry points updated per the answers to Open Questions 1–3.
- Tests: update `new_game_screen_test` (no GAME row, HOME key, game passed in), add Home screen widget tests, update `integration_test/new_game_test.dart` and the other integration tests that start a game through the new-game screen.

## Out of Scope
- Game gating, lock markers and paywalls (OB-039, OB-036 — deferred).
- Resume after app kill or a persistent "continue game" (OB-001 Q6), unless the PO chooses it in Open Question 3.
- Settings screen, ABOUT / licenses screen (OB-033), match history (OB-013).
- Changes to LEVEL, side selection, the advisor layout, the discard dialog text, or game rules.
- Adding new games to Home (each game phase registers itself in `GameKind`).
- Localization of Home labels (README open question 9).

## Dependencies
- OB-011 (new-game screen, discard-on-START rule), OB-045 (`GameKind` with CHESS / XIANGQI, per-game side labels and pictograms, XQ5 / XQ8), OB-042 (`GameKind` / registry seam, session start).
- OB-008 (fair-play notice precedes Home; FAIR PLAY key placement).
- OB-003 (app shell, design tokens, `AppKey`).
- OB-024 / OB-041 (game-over NEW GAME button in the status line).
- OB-033 (ABOUT key placement, not built yet).
- OB-039 (future lock markers will live on Home; its "new-game list" wording should point to Home when it resumes).
- Design: the Design section above.

## Decisions
None yet.

## Assumptions
- A-1: "Pick level and sides" means the existing LEVEL row and YOUR SIDE keys, unchanged (defaults Even and first mover).
- A-2: The GAME row is removed from the new-game screen, because Home now picks the game and the PO's new-game page lists only level and sides. If the PO wants to keep it, see Open Question 5.
- A-3: FAIR PLAY stays on the new-game screen until Open Question 4 is answered.
- A-4: No app-wide router package is needed. Plain navigation as used today is enough (developer's call).
- A-5: The fair-play notice still comes first on first launch, before Home.

## Open Questions
1. **Advisor NEW GAME during a game:** after "DISCARD THE CURRENT GAME?", open the new-game screen for the current game (HOME available to switch), or go straight to Home? Recommended: the new-game screen for the current game. It keeps one tap to restart the same game, and HOME covers switching.
   **Answered (PO, 2026-10-04):** the new-game screen for the current game, with HOME to switch.
2. **Game-over NEW GAME:** same choice as Question 1. Recommended: same answer as Question 1.
   **Answered (PO, 2026-10-04):** same as Question 1.
3. **In-progress game and Home:** when a game is in progress and the user reaches Home, how do they get back to it? Options: (a) system back / the screen's back path only, with no extra button on Home; (b) a CONTINUE GAME button on Home (this breaks "2 buttons only"); (c) going to Home discards the game (needs its own confirmation). Recommended: (a), and the PO confirms that the in-progress game is kept until START GAME (BR-003).
   **Answered (PO, 2026-10-04):** the Designer's option: system back plus a small BACK corner key on Home, shown only while a game is in progress (see Design). The game is kept until START GAME (BR-003).
4. **FAIR PLAY and the future ABOUT key:** keep them on the new-game screen, or move them to Home? Recommended: keep them on the new-game screen now. Home stays "2 big buttons only".
5. **GAME row on the new-game screen:** remove it (assumed, A-2), or keep it as a second way to switch games? Recommended: remove it.
6. **Home header:** show the app name (Cataland) or a title like "PICK A GAME", or nothing? Can be decided by the Designer unless the PO has a preference. The app name is still pending store review (OB-034).

## Developer Handoff
- Root (`lib/app.dart`, `_HomeGate`): fair-play notice → Home when `gameSessionProvider` is null → advisor when a session exists. Home replaces `NewGameScreen` as the root of the no-session state.
- New Home screen under `lib/features/new_game/presentation/` (or a small `home` feature, developer's call), built from `GameKind.values` with `AppKey`. Tapping pushes `NewGameScreen(game: ...)`, with a guard against double taps.
- `NewGameScreen`: replace `initialGame` with a required game, remove the GAME row and `_selectGame`, keep the side and level logic. Show the game in the header. Replace the conditional BACK key with HOME (pop to Home). The header keys (`gameKey`) move to the Home screen.
- `NewGameKey.openNewGameScreen` and the status-line game-over key: follow Open Questions 1–2. With the recommended defaults, push the new-game screen for the current game. HOME from there must reach Home without discarding the session (for example, Home pushed under the new-game screen with the advisor still at the root, or an equivalent that keeps BR-003 and REQ-006).
- Keep the discard rule in one place: only `GameSessionController.start` discards the old game.
- Tests: `test/features/new_game/new_game_screen_test.dart`, a new Home widget test, `integration_test/new_game_test.dart` and the integration tests that start games (`turn_loop`, `persona_row`, `suggestion_card`, `chess_tap_board`) need an extra tap on Home. Verify on the iOS simulator (testing policy 2026-10-03).
