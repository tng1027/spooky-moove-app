# Ticket Analysis

> **Status: Implemented incl. Home layout revision (2026-10-05); analyze + tests pass; PO to verify on iOS simulator.**

TICKET_TYPE: ENHANCEMENT
CONFIDENCE: HIGH

The app UI already exists, with a deliberately flat style ("Industrial Utility / Terminal Neo-Brutalism", `designSystem.md`). The PO wants the same screens and behaviour in a new visual style (gamification, isometric) plus a colour per game. Nothing new is added that the user can do, so this is an enhancement, not a new feature. It's not a bug, because the flat style was a design decision and works as specified. Not a duplicate: no ticket covers a restyle or per-game colours. Confidence is HIGH because D1–D5 settle scope, colours and the conflict with the current design rules.

## Ticket Title
[Enhancement] Restyle the app UI to a gamified isometric look with a colour per game (Chess `#ED96D7`, Xiangqi `#578EF5`)

## Summary
Home game tiles, keys, cards, headers and dialogs become chunky isometric blocks: a raised face with solid side faces and a press-sink effect on tap. Each game gets an identity colour: pink `#ED96D7` for Chess and blue `#578EF5` for Xiangqi. It's used on that game's Home tile, its screen headers, its START GAME key and its board frame. The background stays `#0F1015`. Boards stay top-down and work exactly as today.

## Business Context
- PO request 2026-10-05 (verbatim): "PO wants to follow the Gamification and Isometric style. Keeps using the background color is "#0F1015". Màu của cờ vua sẽ là màu "#ED96D7". Màu của cờ tướng là màu "#578EF5"" (chess colour `#ED96D7`, xiangqi colour `#578EF5`).
- A friendlier, more playful look, with each game easy to recognise at a glance. More games are coming in Phases 4–7, so the per-game colour must scale with the game list (README guardrail: games are data in one place).
- **Gamification in this ticket** means the visual tone only: chunky isometric blocks, press-sink feedback and colourful game identity. Game mechanics (streaks, badges, XP, rewards, levels-up) are out of scope (Open Question 1).

## Current Behavior
Source: `memory-bank/designSystem.md`, `lib/core/theme/app_colors.dart`, `app_dimens.dart`, `app_theme.dart`, `app_typography.dart`, `lib/core/widgets/app_key.dart`, `screen_header.dart`, `app_dialog.dart`, `home_screen.dart`, `new_game_screen.dart`, `new_game_key.dart`, `advisor_screen.dart`, `top_bar.dart`, `game_registry.dart`, `game_kind.dart`.
- Style: flat, "No shadows, gradients or blur", "Don't use accents decoratively", "No decorative motion" (`designSystem.md`). `AppTheme.dark()` sets `shadowColor: transparent`, `NoSplash`, card `elevation: 0`. No `BoxShadow`, gradient, `BackdropFilter` or `flutter_animate` use exists in `lib/`.
- Colours (`AppColors`): `bgDark #0F1015`, `surfaceDark #1E2029`, `keyNormal #2C2D35`, `keyDisabled #1A1B20`, `accentGreen` (good / suggestion / primary action), `accentRed` (check / danger), `accentActive` amber (selected), `textPrimary`, `textSecondary`, board-only `pieceRed`. No per-game colour.
- `AppKey`: flat block, radius 4 dp, min height 48 dp; background `keyNormal`, amber when selected, green when primary (OB-041), `keyDisabled` when disabled. No pressed visual (no ripple, no colour flash, OB-049 Design).
- `ScreenHeader`: 48 dp three-slot row (`NavigationToolbar`), corner `HeaderKey`s capped at 30 % of the width, labels scale down.
- `AppDialog`: flat `surfaceDark` dialog, `elevation: 0`, radius 4 dp, scrolling content.
- Home: header `[SETTINGS] PICK A GAME [LANGUAGE]` (OB-051); one full-width `AppKey` per `GameKind.values`, min 112 dp (`gameKeyMinHeight`), 56 dp pictogram (white king / 帥 disc via `GameWidgets.sidePictogram`), `keyNormal`, bottom-aligned, scrolls at large text.
- New-game screen: header `[BACK] CHESS|XIANGQI [FAIR PLAY]`, LEVEL row, YOUR SIDE keys (amber when selected), green START GAME (`isPrimary`).
- Advisor: `TopBar` `[NEW GAME] WIN RATE [UNDO]` (win rate green / red by sign), persona row, suggestion card, board, status line with green I PLAYED IT. The board is drawn edge to edge with **no frame** (`AdvisorScreen` centres `GameWidgets.board`); its size comes from `boardSizeFor`, which subtracts the fixed heights of the top bar, persona row, status line and the card's minimum.
- Per-game widgets are picked in one place, `game_registry.dart` (`GameWidgets`, the only `GameKind` switch, OB-042 REQ-008). `GameKind` holds per-game data (label, variant, grid, side labels).

## Expected Behavior
- All app UI chrome (Home tiles, keys, cards, headers, dialogs) uses an isometric block look: a top face plus solid, darker side faces giving depth. Pressing a key sinks it toward its base; releasing restores it (press-sink feedback).
- Each game has an identity accent: Chess `#ED96D7`, Xiangqi `#578EF5`. It appears on that game's Home tile, its new-game header, its advisor header, its START GAME key and its board frame.
- Background stays `#0F1015`. Status colours keep their meaning: green = suggestion / good, red = check / danger, amber = selected.
- Chess and Xiangqi boards stay top-down and flat, with the same cell sizes, tap rules and hit targets.

## User Story
As a player
I want a playful, colourful look where each game has its own colour
So that the app feels fun to use and I recognise which game I'm in at a glance.

## Functional Requirements
- REQ-001: Add two identity colour tokens, Chess `#ED96D7` and Xiangqi `#578EF5`, next to the existing colour tokens. Each `GameKind` value has exactly one identity accent, taken from one mapping keyed by `GameKind`.
- REQ-002: `AppKey` (and every key built on it: `HeaderKey`, persona tier keys, side keys, dialog keys, NEW GAME, UNDO, I PLAYED IT, START GAME, Home tiles) renders as an isometric block with solid side faces. The fill colours per state (normal, selected amber, primary green, disabled) stay as today unless REQ-005 / REQ-006 say otherwise.
- REQ-003: Pressing an enabled key shows press-sink feedback: the top face moves down toward its base while held and returns on release or cancel. Disabled keys show no press feedback. Existing haptics are unchanged (no new haptic for press-sink).
- REQ-004: Cards (suggestion card), headers (`ScreenHeader` rows) and dialogs (`AppDialog`: Settings, Language, discard prompt) use the same isometric block language as keys.
- REQ-005: Home: each game tile uses that game's accent (D2). Labels and pictograms stay readable on it (BR-006).
- REQ-006: New-game screen: the header for the game shows its accent, and START GAME uses the game's accent instead of green (D2).
- REQ-007: Advisor: the header (`TopBar`) shows the current game's accent, and the board has a frame in that accent (D2). The win-rate label keeps its green / red / grey status colours.
- REQ-008: Boards (chess tap board, Xiangqi intersection board) stay top-down and flat. Cell size, square / point states, snapping, edge labels and tap behaviour are unchanged (D1).
- REQ-009: Background stays `bgDark #0F1015` on every screen (D3).
- REQ-010: Update `memory-bank/designSystem.md` to the new style: keep the colour meaning rules, replace the flat rules for UI chrome (D5), and add the identity accent rule (BR-001).

## Business Rules
- BR-001 (identity only, D4): game accents identify a game. They never mean good, bad, selected, check, legal, suggested or any other status. They're never used on board squares or points, piece glyphs, the win-rate label, the suggestion move text or status messages.
- BR-002: Status colours are unchanged and keep priority: green = suggestion / good / I PLAYED IT, red = check / danger, amber = selected. A selected key inside a game-accented area is still amber.
- BR-003: Tokens in one place: identity accents, side-face shades, extrusion depth and press-sink values are design tokens in `lib/core/theme/` (`AppColors` / `AppDimens`), not literals in widgets.
- BR-004: Accent per game comes from `GameKind` data through one mapping (README guardrail, OB-042 REQ-008). No `game == GameKind.chess`-style checks in widgets. A new game is registered by adding its accent in that one place, and a missing accent is a compile-time error.
- BR-005: App-level chrome that doesn't belong to one game (Home header, Settings / Language dialogs, fair-play screen, discard prompt) uses neutral colours, not a game accent.
- BR-006: Text and pictograms on an accent surface use `bgDark` (Chess pink ≈ 9.0:1, Xiangqi blue ≈ 6.0:1). White text on an accent is not allowed (≈ 2.1:1 on pink, ≈ 3.2:1 on blue, below WCAG AA 4.5:1 for 16 sp bold).
- BR-007: Existing rules stay: JetBrains Mono, tabular figures, Latin labels, text labels on keys (no icons), dark theme only.
- BR-008 (D5): within the UI chrome, this ticket replaces the `designSystem.md` rules "No shadows, gradients or blur", "Don't use accents decoratively" and "No decorative motion". Blur stays forbidden (NFR-004). Boards keep the old rules: flat, no piece animation.

## Non-Functional Requirements
- NFR-001: Every key keeps a hit target ≥ 48 dp tall, measured on the tappable area including the extrusion. The corner header keys stay ≥ 48 × 48 dp.
- NFR-002: Board tap rules unchanged: chess squares ≥ 44 dp (≥ 48 dp on ≥ 392 dp screens), Xiangqi cells per OB-044 / XQ3, nearest-legal snapping, two-tap entry (OB-048). The board frame and extruded chrome must not shrink the board computed by `boardSizeFor` on any supported screen size.
- NFR-003: No overflow on 360 × 640 (and 360 × 600) at text scale 2.0 on Home, new-game, advisor, fair-play and all dialogs. Extrusion and press-sink must not cause layout shift: pressing a key never moves other widgets.
- NFR-004: No FPS regression (OB-010): extrusion is drawn as solid offset faces (plain fills / paths). No blur, no `BoxShadow` with blur radius, no `BackdropFilter`, no saveLayer-heavy effects. Press-sink is a short transform of the pressed key only. 60 FPS during an engine search is kept, measured with the OB-010 frame harness before and after.
- NFR-005: Contrast: text ≥ 4.5:1 on every surface (BR-006); accents ≥ 3:1 against `bgDark` and `keyNormal` as non-text UI (pink ≈ 9.0:1 / 6.5:1, blue ≈ 6.0:1 / 4.3:1).
- NFR-006: No new dependency unless the design pass shows one is needed (developer's call; Flutter's built-in widgets are enough for solid faces and a press transform).

## User Flow
```text
Home: [SETTINGS]  PICK A GAME  [LANGUAGE]          (neutral, isometric keys)
      [♔ CHESS]   pink block tile
      [帥 XIANGQI] blue block tile
↓ press XIANGQI (tile sinks, then the page transition)
New game · XIANGQI: blue header / LEVEL / YOUR SIDE (selected = amber) / blue START GAME
↓ START GAME
Advisor: blue header [NEW GAME] WIN 54% (green) [UNDO] / persona row / card /
         board in a blue frame (top-down, unchanged) / green I PLAYED IT
```
Alternative: Chess follows the same flow in pink. Dialogs (Settings, Language, discard prompt) open as neutral isometric blocks.

## Acceptance Criteria
- Given the Home screen, When it renders, Then the CHESS tile is an isometric block in `#ED96D7` and the XIANGQI tile an isometric block in `#578EF5`, both with dark labels and their pictograms, on a `#0F1015` background.
- Given the Home screen, When it renders, Then the header and SETTINGS / LANGUAGE keys are isometric and use no game accent.
- Given any enabled key, When the user presses and holds it, Then its top face sinks toward its base, and When released, Then it returns and the key's action runs once.
- Given any enabled key, When the user presses it and drags off before releasing, Then the key returns to rest and no action runs.
- Given a disabled key (for example UNDO before any move), When the user presses it, Then it shows no press-sink and nothing happens.
- Given the new-game screen for Chess, When it renders, Then the header shows the Chess accent and START GAME is a pink block with dark text; the selected level and side keys are amber.
- Given the new-game screen for Xiangqi, When it renders, Then the header shows the Xiangqi accent and START GAME is a blue block with dark text.
- Given a Chess game on the advisor, When it renders, Then the top bar shows the Chess accent, the board has a pink frame, and the board's squares, pieces, labels and cell size are identical to before this ticket.
- Given a Xiangqi game on the advisor, When it renders, Then the top bar shows the Xiangqi accent and the board has a blue frame; the intersection board is unchanged.
- Given a suggestion on the advisor, When it shows, Then the suggested squares / points, move text and I PLAYED IT are green, and no game accent is used for them.
- Given a king or general in check, When the board renders, Then the check marking is red as today and the board frame stays the game accent.
- Given the user's side is losing, When the win rate shows, Then it's red as today, inside the accented header.
- Given the Settings, Language or discard dialog, When it opens, Then it's an isometric block in neutral colours, with isometric keys.
- Given 360 × 640 at text scale 2.0, When Home, new-game, advisor, fair-play and each dialog render, Then nothing overflows and every key's hit target is ≥ 48 dp tall.
- Given any supported screen size, When the advisor renders, Then the board size equals what `boardSizeFor` returned before this ticket for the same screen and game.
- Given an engine search running, When the user presses keys repeatedly, Then the OB-010 frame check still meets 60 FPS (no regression against the pre-restyle baseline).
- Given the Chess and Xiangqi tap flows, When the user enters moves (two taps, snapping, promotion chooser), Then behaviour and hit areas are unchanged (existing widget and integration tests pass without changes to tap logic).
- Given a screen reader, When focus moves over any restyled key or header, Then the spoken labels and roles are unchanged.

## Edge Cases
- Quick tap: press-sink still shows briefly (or is skipped by design) but the action always runs exactly once; double-tap guards (Home, new-game, dialogs) keep working.
- Long press, drag off, or a second finger: key returns to rest, no action.
- Selected key in an accented screen (amber side key on the Xiangqi new-game screen): amber wins on the key; the accent stays on header and START GAME only.
- Primary action conflict: START GAME switches from green to the game accent (D2); I PLAYED IT stays green because it applies the suggestion (D4).
- Game over: the board is dimmed as today; the frame keeps the accent (identity, not status).
- Colour-vision deficiency: pink vs. `accentRed` and blue vs. nothing; status never relies on the accent, so meaning is kept (BR-001). The design pass checks pink frame vs. red check square stays distinguishable.
- Text scale 2.0 inside an extruded key: the label grows the top face; the extrusion depth is fixed and never clips text.
- Short screens (360 × 600): the board frame must fit without shrinking cells (NFR-002); this is the tightest layout and the design pass must show it.
- A future game added to `GameKind` without an accent: must not compile (BR-004).
- Reduce-motion OS setting on: press-sink may be reduced to an instant state change (design decides); the key still shows a pressed state.

## In Scope
- Isometric look for `AppKey`, `HeaderKey`, `ScreenHeader`, `AppDialog`, the suggestion card, the persona row keys, side keys, Home tiles, status-line keys.
- Press-sink feedback on all enabled keys.
- Two identity accent tokens and one `GameKind` → accent mapping; accent on Home tile, new-game header, advisor header, START GAME and board frame.
- Board frame around both boards without changing board geometry.
- Theme tokens for side faces, extrusion depth and press-sink (one place).
- `memory-bank/designSystem.md` update (REQ-010).
- Update widget tests for restyled widgets (states, press-sink, no tap regressions) and golden / visual checks if the project adds them; OB-010 frame check before and after.

## Out of Scope
- Gamification mechanics: streaks, badges, XP, rewards, levels, achievements, sounds (Open Question 1, Open Question 4).
- Isometric or 3D boards, piece restyle, piece animation, board colour changes (D1).
- Any change to status colours, tap rules, layout order, flows, copy or navigation.
- Light theme; new screens; app icon, splash and store screenshots (Open Question 2).
- Entry / idle / celebration animations beyond press-sink (Open Question 3).

## Dependencies
- **Design pass**: done 2026-10-05, see the Design section below.
- OB-003 (tokens, `AppKey`, theme), OB-049 (Home tiles), OB-050 (`ScreenHeader`), OB-051 (Home header, `AppDialog` dialogs), OB-011 / OB-041 (START GAME, I PLAYED IT primary green), OB-023 (persona row), OB-044 (`pieceRed`, Xiangqi cell exception XQ3), OB-006 / OB-048 (tap board rules).
- OB-010: frame-rate harness for the before / after FPS check.
- OB-042: `GameKind` / `game_registry.dart` as the single per-game seam.
- OB-034: store screenshots will need to be retaken after this ticket (not part of it).

## Decisions
PO, 2026-10-05:
- D1: Isometric style applies to app UI only (Home game tiles, keys, cards, headers, dialogs). Chess and xiangqi boards stay top-down; tap geometry and hit targets unchanged.
- D2: Each game's color is a per-game identity accent: applied to that game's Home tile, its screen header (new-game and advisor), its START GAME key, and its board frame.
- D3: Background stays `#0F1015` (`AppColors.bgDark`).
- D4: Existing accent semantics unchanged: green = suggestion/good, red = check/danger, amber = selected. Game accents are identity only and must never act as status signals.
- D5: This ticket supersedes the flat rules in `memory-bank/designSystem.md` ("No shadows, gradients or blur", "Don't use accents decoratively", "No decorative motion") for the UI chrome.
- D6 (PO 2026-10-05, after simulator review): no accent lines. The header rail and the board frame are removed; the board tray stays. This overrides the header/board-frame parts of D2, DS-4 and DS-7.
- D7 (PO 2026-10-05, new-game mockup review): new-game layout per DS-8. Keep an isometric board hero, painted in code (solid faces, game accent pair, existing piece pictograms), no glow, hidden on short screens and at large text. START GAME stays a game-accent block with `bgDark` text, plus a dark arrow chip. Selected level / side = amber block, plus a radio dot on side cards; no accent outlines (D6). Keep the BACK text key (glyph + label) and FAIR PLAY; uppercase JetBrains Mono; level keys = shared `PersonaTierKeys`; title in a new uppercase display style in the game accent, with a `PLAYING` caption. Default level stays Even. Adopt numbered section headers (01 / 02), side cards with `FIRST MOVE` / `SECOND MOVE` sub-labels, a grouped `surfaceDark` panel at 6 dp radius, START GAME pinned at the bottom with scrolling content. Xiangqi: blue accent, intersection-grid hero with 帥 / 將 discs, RED / BLACK side cards. Designer's calls within D7: the level pill is dropped (repeats `LEVEL · EVEN`); helper text `LEVEL CAN BE CHANGED DURING THE GAME` is kept.
- D8 (PO 2026-10-05, play-game mockup re-review): no changes to DS-7. Keep the current dark board (the mockup's yellow / blue squares hide the amber, green and red highlights), green suggestion text and highlight, all 7 tiers enabled (the mockup's dimmed tiers 5–7 are a placeholder; OB-037 stays deferred), NEW GAME left / UNDO right (OB-050), I PLAYED IT at 48 dp, 4 dp radius.
- D9 (PO 2026-10-05, Home mockup review): Home layout per DS-9. Mockup-style rows for `GameKind.values` only (Chess, Xiangqi): neutral `surfaceDark` row block (for tagline contrast), 48 dp accent icon block with the 32 dp side pictogram, upper-case name and tagline (`CLASSIC STRATEGY`, `CHINESE CHESS`), `textSecondary` chevron, min 72 dp incl. depth, top-aligned, scrolling; navigation unchanged. No count pill, no coming-soon rows. Hero = static neutral surface card (caption + title only; no arc, dice, pink headline or QUICK MATCH), shown only under the `NewGameHero` rule (body ≥ 700 dp, text scale ≤ 1.3); copy proposed in DS-9, needs PO / OB-034 copy check. Header keeps `SETTINGS` / `LANGUAGE` text keys. Future accent palette approved and recorded, not used in code yet: Shogi `#E0BE85` / `#9C7A45`, Go `#4FC8DC` / `#1F8798`, Othello `#A68CF2` / `#6448B8`, Caro `#AEB8CC` / `#6E7890`, `bgDark` text on all. Download states out of scope (design note for OB-015 in DS-9).
- D10 (PO 2026-10-05, simulator review): the Home hero card from DS-9 is removed for now; Home shows the header and the game rows only. The DS-9 hero spec stays as reference if it returns.

## Assumptions
- A-1: "Gamification" means a playful visual tone only (isometric chunky blocks, press-sink feedback, colourful game identity), not game mechanics (Open Question 1).
- A-2: "Isometric" means a 2.5D block look on flat UI (top face + solid side faces at a fixed offset), not a true isometric projection of screens.
- A-3: Side-face shades are darker variants of each face colour (per state and per accent), defined as tokens by the design pass.
- A-4: Disabled keys look flat or lowered (not raised), so they read as not pressable; exact look by the design pass.
- A-5: Press-sink is the only new motion; it's short and touches only the pressed key.
- A-6: The fair-play screen and dialogs follow the isometric style with neutral colours (BR-005).

## Open Questions
All non-blocking; the defaults apply if unanswered.
1. **Gamification mechanics:** does the PO want streaks, badges, XP or rewards later? Default: no, visual tone only (A-1). Mechanics would be separate tickets and need storage decisions.
2. **App icon, splash and store screenshots:** restyle them to match? Default: not in this ticket; follow-up with OB-034.
3. **Motion beyond press-sink:** playful entry or celebration animations (tiles bouncing in, a pop on game over)? Default: press-sink only (A-5), to protect FPS (OB-010).
4. **Sound effects:** tap or move sounds as part of the gamified tone? Default: none (the app has no audio today).
5. **Visual reference:** does the PO have reference apps or a moodboard for "Gamification and Isometric style"? Default: the design pass proposes the look from D1–D5. *Answered 2026-10-05:* advisor mockup, used as layout reference (DS-7).
6. **Top-bar corners:** the mockup puts UNDO left and NEW GAME right, the reverse of the PO's OB-050 decision. Default: keep OB-050 (NEW GAME left, UNDO right). Swapping is a one-line change if the PO confirms the mockup order.
7. **Xiangqi cells on tall 360 dp phones:** the board tray's side padding takes Xiangqi cells from 40 to 39.1 dp where the board is width-limited (for example 360 × 780). XQ3 already accepts ≈ 35 dp with snapping. Default: accept 39 dp as the XQ3 floor at 360 dp width.

## Design
Design pass 2026-10-05 (UI/UX). Matches the current widgets: `AppKey`, `HeaderKey` / `ScreenHeader`, `AppDialog`, `SuggestionCard` (`Card`), `PersonaRow` / `PersonaTierKeys`, `StatusLine`, `HomeScreen._gameKey`, `NewGameScreen`, `TopBar`, `AdvisorScreen`.

### DS-1 Tokens
Colours (`AppColors`). Existing tokens keep their hex values.

| Dart name | Hex | Use |
|-----------|-----|-----|
| `bgDark` | `#0F1015` | Background (unchanged, D3). Also the text / pictogram colour on every accent, amber and green face (on-accent text) |
| `accentChess` | `#ED96D7` | Chess identity face: Home tile, START GAME, header title text, header rail, board rail |
| `accentChessSide` | `#A8508F` | Extrusion face under `accentChess` |
| `accentXiangqi` | `#578EF5` | Xiangqi identity face (same places as Chess) |
| `accentXiangqiSide` | `#2A56B3` | Extrusion face under `accentXiangqi` |
| `keyNormalSide` | `#1D1E25` | Extrusion face under `keyNormal` (neutral keys) |
| `surfaceSide` | `#15161D` | Extrusion face under `surfaceDark` (suggestion card, dialogs) |
| `accentActiveSide` | `#A68B00` | Extrusion face under amber selected keys |
| `accentGreenSide` | `#00994F` | Extrusion face under green primary keys (I PLAYED IT) |
| `edgeHighlight` | `#3A3B45` | 1 dp top highlight on neutral faces only (`keyNormal`, `surfaceDark`) |

- On-accent text: `bgDark` (9.0:1 on pink, 6.0:1 on blue). White on an accent is forbidden (2.1:1 pink, 3.2:1 blue), BR-006.
- One `GameKind` → accent pair (face + side) mapping, BR-004. No other per-game colours.

Sizes (`AppDimens`):

| Dart name | Value | Use |
|-----------|-------|-----|
| `blockDepth` | `4` dp | Extrusion depth of every raised block (keys, tiles, card, dialogs); also the press-sink distance |
| `accentRail` | `2` dp | Thickness of the header rail and the board rail |
| `radius` | `4` dp (existing) | Corner radius of the face and the extrusion |

Motion (`AppDimens` or a small motion constant next to it, developer's call): `pressSinkDuration = 80 ms`, curve `Curves.easeOut`.

### DS-2 Isometric block (keys, tiles, card, dialogs)
```text
 rest                     pressed                  disabled
 ┌──────────────┐ ← 1 dp edgeHighlight (neutral only)
 │     FACE     │         .                        .
 │              │         ┌──────────────┐         ┌──────────────┐
 ├──────────────┤ 4 dp    │     FACE     │         │  keyDisabled │
 └──────────────┘ side    └──────────────┘         └──────────────┘
 └─ layout box = 48 dp min, identical in all three states ─┘
```
- **Construction:** two solid rounded rectangles in the same layout box. The side face fills the box; the top face sits `blockDepth` (4 dp) above the bottom edge, so a 4 dp band of the side colour shows under the face. Both use `AppDimens.radius` (4 dp). No blur, no gradient, no blurred `BoxShadow`, no `BackdropFilter`. Straight down only (no sideways offset), so blocks in rows and full-width blocks line up with no extra horizontal space.
- **Depth counts inside the minimum height.** `AppKey`'s 48 dp minimum stays the outer box (face ≥ 44 dp + 4 dp side). Every fixed-height region (`topBarHeight` 48, `personaRowHeight` 52, `statusLineHeight` 56, `minSuggestionCardHeight` 96, `gameKeyMinHeight` 112) keeps its value, so `boardSizeFor` returns the same sizes (NFR-002). Hit target = the whole box (≥ 48 dp), at rest and while pressed (NFR-001).
- **Top highlight:** 1 dp `edgeHighlight` line along the top edge of the face, inset by the radius, on neutral faces only (`keyNormal`, `surfaceDark`). The neutral side faces are only ≈ 1.1:1 against `bgDark`, so this edge is what makes neutral blocks read as raised. Accent, amber and green faces don't get it.
- **States:**

| State | Face | Side (4 dp) | Text | Highlight |
|-------|------|-------------|------|-----------|
| Normal | `keyNormal` | `keyNormalSide` | `textPrimary` | yes |
| Selected (level, side, persona) | `accentActive` | `accentActiveSide` | `bgDark` | no |
| Primary (I PLAYED IT) | `accentGreen` | `accentGreenSide` | `bgDark` | no |
| Game accent (Home tile, START GAME) | game accent | game accent side | `bgDark` | no |
| Pressed (any enabled) | same face, moved down 4 dp | collapsed to 0 | unchanged | moves with the face |
| Disabled | `keyDisabled`, at the pressed (lowered) position | none | `textSecondary` | no |

- Selected wins over accent: an amber key inside a game screen stays amber with an amber side (BR-002).
- Pressing a selected key sinks it like any other key; selection colour doesn't change while held.
- **Surfaces** (suggestion card, `AppDialog`): same construction with `surfaceDark` / `surfaceSide` / `edgeHighlight`, never pressable, never sink. The card keeps its 8 dp outer padding; its 4 dp side sits inside the card's box. The dialog's 4 dp side sits inside the dialog's box; the barrier stays the default scrim (no blur).
- **Header row:** `ScreenHeader` itself isn't a block (it's a row on `bgDark`); its corner `HeaderKey`s are neutral blocks, 48 dp tall incl. depth.

### DS-3 Press-sink motion
- Pointer down on an enabled key: face moves down 4 dp and the side collapses, over 80 ms `easeOut`. Release or cancel (drag off, second finger, scroll): back to rest over 80 ms `easeOut`.
- The action fires on tap up exactly as today, with no wait for the animation. A quick tap may show only part of the sink; that's fine. Navigation starts at once.
- Only the pressed key's paint moves (a translate inside its fixed box). Its layout box and every other widget stay put (NFR-003).
- Reduce motion (`MediaQuery.disableAnimations`): pressed state switches instantly (0 ms), still shown.
- No other new motion: no entry, idle, bounce or celebration animation. Haptics unchanged.

### DS-4 Game identity accents (where, and nowhere else)
- **Home tile** (one per `GameKind.values`, order unchanged): accent face + accent side, ≥ 112 dp incl. depth (already about twice a normal key, unchanged token). Pictogram (56 dp, `GameWidgets.sidePictogram(game, first)`) unchanged: the white king keeps its black outline and the 帥 disc keeps its `keyNormal` disc, so both read on pink / blue. Label `game.label` in `bgDark`.
- **New-game screen:** header title (`CHESS` / `XIANGQI`) in the game accent text (9.0:1 / 6.0:1 on `bgDark`), plus the header rail (below). BACK and FAIR PLAY stay neutral keys. **START GAME becomes a game-accent block with `bgDark` text, no longer green** (D2): green keeps the single meaning "apply the suggestion / good" (I PLAYED IT). LEVEL and YOUR SIDE keys unchanged (neutral, amber when selected).
- **Advisor `TopBar`:** header rail (below). NEW GAME and UNDO stay neutral; the middle label keeps green / red / `textSecondary` status colours (BR-001).
- **Header rail:** a 2 dp (`accentRail`) full-width line in the game accent directly under the 48 dp header row. It takes no layout space: on the advisor it's painted in the persona row's existing 2 dp top padding (`spacingSmall / 2`), on the new-game screen in the top 2 dp of the existing 16 dp gap under the header. The header keys look like they sit on the rail.
- **Board rail (the board frame):** two 2 dp lines in the game accent, exactly the board's width (`boardSize.width`, centred with the board), flush against the board's top and bottom edges, **no side lines** (the chess board is full width at 360 dp and there's no horizontal room). Both lines are painted outside the board's layout box, in gaps that already exist:
  - top line in the bottom 2 dp of the suggestion card's 8 dp outer padding (leaves 2 dp between the card's side face and the rail),
  - bottom line in the top 2 dp of the status line's 8 dp top padding (leaves 6 dp above the button).
  - `boardSizeFor`, the board's cells and its hit area are unchanged; the rail never takes taps. On 360 × 600 (tightest, height-limited board) the layout is pixel-identical apart from the two painted lines.
  - Game over: the board dims as today, the rail stays full accent (identity, not status).
- Neutral everywhere else (BR-005): Home header and SETTINGS / LANGUAGE, Settings / Language / discard dialogs and their keys, fair-play screen, persona row, status-line keys, RETRY.

```text
Advisor · Xiangqi (360 dp)              New game · Chess
[NEW GAME]  WIN 54%  [UNDO]             [BACK]   CHESS(pink)  [FAIR PLAY]
════════════ blue rail 2 dp ═══════     ═════════ pink rail 2 dp ═════════
[🥚][🐣][🐥][🥉][🥈][🥇][👑]            LEVEL · EVEN
┌ suggestion card (surface block) ┐     [🥚][🐣][🐥][🥉][🥈][🥇][👑]
└─────────────────────────────────┘     YOUR SIDE
   ══════ blue rail (board width) ══      [♔ WHITE amber] [♚ BLACK]
   │ board, unchanged          │
   ══════ blue rail (board width) ══    [ START GAME ] pink block, dark text
[        I PLAYED IT (green)       ]
```

### DS-5 Boards
Unchanged: top-down, same painting, colours, cell size, states, labels, hit areas (D1, REQ-008). The only addition is the board rail outside the board's box. Promotion chooser unchanged in this ticket.

### DS-6 Accessibility
| Text / element | On | Ratio | Rule |
|----------------|----|-------|------|
| `bgDark` text (tile label, START GAME) | `accentChess` | 9.0:1 | ≥ 4.5 ✔ |
| `bgDark` text | `accentXiangqi` | 6.0:1 | ≥ 4.5 ✔ |
| `textPrimary` (white) | `accentChess` / `accentXiangqi` | 2.1 / 3.2:1 | ✘ forbidden |
| `accentChess` title text | `bgDark` | 9.0:1 | ✔ |
| `accentXiangqi` title text | `bgDark` | 6.0:1 | ✔ |
| `bgDark` text | `accentActive` / `accentGreen` | 13.5 / 11.4:1 | ✔ |
| `textPrimary` | `keyNormal` / `surfaceDark` | 13.7 / 16.2:1 | ✔ |
| `textSecondary` | `keyDisabled` / `surfaceDark` | 5.6 / 5.3:1 | ✔ |
| Win rate green / red / grey | `bgDark` | 11.4 / 6.0 / 6.2:1 | ✔ |
| Rail pink / blue (non-text) | `bgDark` | 9.0 / 6.0:1 | ≥ 3 ✔ |
| Rail pink / blue next to board edge | `keyNormal` | 6.5 / 4.3:1 | ≥ 3 ✔ |

- Side faces and the highlight are decorative depth cues, not required to meet 3:1 (block edges are already defined by the face). Accent sides vs `bgDark`: 3.8 (pink), 2.8 (blue).
- Pink rail vs red check square (1.5:1, close in hue for some colour-vision deficiencies): told apart by shape and place (2 dp line outside the board vs a filled square inside), and check doesn't rely on the rail. Pink vs blue isn't needed to tell games apart: the header title and pictograms name the game.
- Text scale 2.0 at 360 × 640 and 360 × 600: labels grow the face; the 4 dp depth is fixed and never clips text. Header keys stay 48 dp (face 44 dp) and their labels keep scaling down (`FittedBox`). Home tiles grow and scroll as today. No overflow allowed on Home, new-game, advisor, fair-play and dialogs (NFR-003).
- Semantics unchanged: same labels, roles, `selected` / `enabled` flags. Rails and side faces are excluded from semantics.

### DS-7 Advisor layout (PO mockup 2026-10-05)
PO input 2026-10-05: a mockup of the Chess advisor, to be used as a **layout and component reference only**. OB-052 colour rules stay: game accent `#ED96D7` / `#578EF5` for identity only, green = suggestion / good, red = check / danger, amber = selected, current board colours, `bgDark` background, 4 dp extrusion. This section revises DS-4 for the advisor only (Home and new-game screens are unchanged).

```text
360 dp, Chess, user's turn                               height (dp)
[NEW GAME]      WIN RATE        [↶ UNDO]                 48  TopBar
                  62%  (green)
═══════════════ pink header rail 2 dp ═══════════        (in persona row's top padding)
[ •¹][ ♟²][ ♞³][▓♝⁴▓][ ♜⁵][ ♛⁶][ ♚⁷]                       52  PersonaRow (amber = selected)
┌ • BEST MOVE ───────────────────────┐                    ≥ 88 SuggestionCard (Expanded)
│            E2 ➔ E4   (green 48 sp) │
│   EVAL +0.4 • DEPTH 16 • 850k nps  │
└────────────────────────────────────┘
┌──────────── board tray ────────────┐ 4 dp padding      board + 12 tray
│┏━━━━━━━━━ pink frame 2 dp ━━━━━━━┓│
│┃  board, unchanged (44 dp cells)  ┃│
│┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛│
└────────────────────────────────────┘ + 4 dp side face
[ [✓]  I PLAYED IT          (green) ]                    52  StatusLine (4 gap + 48 key)
```

**Vertical budget** (fixed parts subtracted by `boardSizeFor`): top bar 48 + persona row 52 + card minimum 88 + board tray overhead 12 (4 top padding + 4 bottom padding + 4 side face) + status line 52 = **252 dp**, the same total as today (48 + 52 + 96 + 56). So height-limited boards (Xiangqi on most phones, Chess at 360 × 600) keep exactly their current cell size.

**Horizontal budget:** the tray's 4 dp side padding costs 8 dp of board width. New cell = `min((W − 8) / files, (H − 252) / ranks)`.

| Screen | Chess cell today → new | Xiangqi cell today → new |
|--------|------------------------|--------------------------|
| 360 × 640 | 45 → **44** (rule ≥ 44 ✔) | 38.8 → 38.8 (height-limited) |
| 360 × 600 | 43.5 → 43.5 (height-limited, as today) | 34.8 → 34.8 |
| 392 × 800 | 49 → **48** (rule ≥ 48 on ≥ 392 dp ✔) | 43.6 → 42.7 |
| 360 × 780 (tall 360 dp phone) | 45 → 44 ✔ | 40 → **39.1** (Open Question 7) |

This amends NFR-002 ("board size unchanged") for the advisor: width-limited boards lose 8 dp of width and stay within the board rules (≥ 44 dp at 360 dp, ≥ 48 dp at ≥ 392 dp). Height-limited boards are unchanged. Tap rules, snapping and hit areas are unchanged.

#### Top bar (`TopBar`, 48 dp, unchanged height)
- Corners unchanged: **NEW GAME left, UNDO right** (OB-050 REQ-005, PO wording 2026-10-04). UNDO keeps its glyph + label. Both are neutral 48 dp keys, ≤ 30 % of the width.
- The win rate is **already in the top bar** (OB-041 revision 3, `TopBar._winRateLabel`), not in the card, so nothing moves. Only its layout changes, from one line `WIN RATE 62%` to two stacked lines, centred:

| State | Caption (`AppTypography.secondary`, 12 sp, `textSecondary`) | Value (new `AppTypography.winRate`: 24 sp, w700, tabular) |
|-------|------|------|
| Centipawn score | `WIN RATE` | `62%`, `accentGreen` when rounded win ≥ 50 %, else `accentRed` (existing `isFavorable` rule, no neutral band) |
| Mate for the user | `YOU MATE IN` | `4`, `accentGreen` |
| Mate for the opponent | `OPPONENT MATES IN` | `4`, `accentRed` |
| No suggestion yet | `WIN RATE` | `--`, `textSecondary` |
| Game over | none | `GAME OVER` in `AppTypography.primary`, `textSecondary` (as today) |

- Caption and value in one `FittedBox(scaleDown)` column (≈ 14 + 29 dp at text scale 1.0, fits in 48). At text scale 2.0 the column scales down and never wraps or overflows.
- Spoken as one label, e.g. "Win rate 62 percent", "You mate in 4", "Game over".
- The pink / blue 2 dp header rail under the top bar stays (DS-4).

#### Persona row (`PersonaRow`, 52 dp; `PersonaTierKeys`, also used on the new-game screen)
- Emoji are replaced by **one game-agnostic progression of chess-piece silhouettes**, the same on Chess and Xiangqi screens (tiers are identical for every game, OB-022). Rising piece value reads as rising strength:

| Tier | 1 Baby | 2 Gentle | 3 Soft | 4 Even | 5 Solid | 6 Master | 7 God |
|------|--------|----------|--------|--------|---------|----------|-------|
| Pictogram | dot (8 dp circle) | pawn `bP` | knight `bN` | bishop `bB` | rook `bR` | queen `bQ` | king `bK` |

- Pictograms: existing Cburnett SVGs in `assets/pieces/cburnett/` (BSD), drawn as one-colour silhouettes (source-in colour filter), 24 dp. Colour `textPrimary` on a normal key (13.7:1), `bgDark` on the selected amber key (13.5:1).
- Number badge: 14 dp circle, fill `bgDark`, digit `1`–`7` in 10 sp w700 tabular `textPrimary` (19:1), 2 dp inside the face's bottom-right corner. It moves with the face on press. Badge and pictogram don't grow with text scale (fixed size inside a 44 dp face), so they never clip; the tier name stays in semantics ("Even") and in the new-game `LEVEL · EVEN` heading.
- States unchanged: normal neutral block, selected amber block (`accentActive` / `accentActiveSide`). **All 7 tiers are always enabled and at full strength**; no dimming (see deviations).
- Keys stay 48 dp incl. depth, equal width, 4 dp gaps on the advisor (≈ 46.9 dp wide at 360 dp) and 2 dp gaps on the new-game screen.

#### Suggestion card (`SuggestionCard`)
- Outer padding changes from 8 dp all round to **8 dp left / right, 4 dp top / bottom**. `minSuggestionCardHeight` 96 → **88** (the block's own minimum stays 80 dp incl. its 4 dp side). Inner padding 8 dp, neutral surface block as today.
- New caption row at the top, only in the ready and thinking states: 8 dp `accentGreen` dot + 4 dp + `BEST MOVE` (`AppTypography.secondary`, `textSecondary`). Green, not the game accent, because it labels the suggestion. Hidden in pick-a-level, waiting, error and game-over states (their content is unchanged).
- Move: the existing per-game suggested-move widgets, unchanged (48 sp `accentGreen`, existing `➔` arrow, promotion / castling extras).
- Expert line: separator ` | ` becomes ` • ` (`EVAL +0.4 • DEPTH 16 • 850k nps`), one style (`secondary`, `textSecondary`), shared by both games.
- The whole content keeps the existing `FittedBox(scaleDown)`, so at the 88 dp minimum or at text scale 2.0 it scales down instead of overflowing.

#### Board tray (replaces the two board rails of DS-4)
- The board sits in a **raised, non-pressable surface block**: face `surfaceDark`, side `surfaceSide` (4 dp), 1 dp `edgeHighlight`, radius 4 dp, **4 dp padding on all four sides** of the board inside the face.
- **Accent frame:** a 2 dp stroke in the game accent, flush around all four board edges, drawn in the inner 2 dp of the tray padding (2 dp of tray face stays visible outside it). It replaces the two `AccentRail` lines above / below the board. The header rail under the top bar stays.
- Tray size = board size + 8 dp wide, + 12 dp tall; centred. On width-limited boards (Chess at 360 dp) the tray spans the full screen width and the board's edges line up with the 4 dp side padding of the top bar, persona row and status line. On height-limited boards (Xiangqi) the tray hugs the narrower board.
- The tray and frame take no taps and have no semantics. Board content is unchanged: current square / grid colours, pieces, edge labels (A–H / 1–8 in the squares for Chess; A–I / 1–10 in the outer half-cell for Xiangqi), selection amber, suggestion green, check red, game-over dimming. The frame stays full accent at game over.

#### Status line (`StatusLine`, 52 dp)
- Height `statusLineHeight` = `minKeyHeight + spacingSmall` = **52 dp** (4 dp gap above, 48 dp key incl. depth; 4 dp side padding).
- Still the single always-visible full-width key with the OB-041 table. It carries the turn status (OB-025, as revised by OB-041 on 2026-10-03): `WAITING FOR OPPONENT` (disabled, opponent's turn), `PICK A LEVEL ABOVE` (disabled), I PLAYED IT (user's turn), `NEW GAME` (game over). No separate status text is added.
- I PLAYED IT (`ConfirmPlayedKey`): green primary block. Content row centred: **check chip** 24 × 24 dp, fill `bgDark`, radius 4 dp, `Icons.check` 18 dp `textPrimary` (19:1), then 8 dp, then `I PLAYED IT` (`primary`, `bgDark`, 11.4:1). The `✓` glyph leaves the label text; semantics stay "I played the suggested move". Disabled: lowered `keyDisabled` face, chip `keyNormal` with a `textSecondary` check, label `textSecondary`. The row is in a `FittedBox(scaleDown)` for text scale 2.0.
- UNDO stays in the top bar (OB-050); the bottom key never holds UNDO.

#### Tokens added / changed
| Token | Value | Note |
|-------|-------|------|
| `AppDimens.boardTrayPadding` | 4 dp | Tray padding on all sides (= `spacingSmall`) |
| `AppDimens.minSuggestionCardHeight` | 96 → 88 dp | Outer padding 4 dp top / bottom |
| `AppDimens.statusLineHeight` | 56 → 52 dp | `minKeyHeight + spacingSmall` |
| `AppTypography.winRate` | 24 sp, w700, tabular | Top-bar value; colour set per state |
| `AppTypography.tierEmoji` | removed | Emoji replaced by pictograms |
| Persona sizes | pictogram 24 dp, dot 8 dp, badge 14 dp / 10 sp | Developer may keep them local to `PersonaTierKeys` |
| Check chip | 24 dp, icon 18 dp | Local to `ConfirmPlayedKey` |

No new colours.

#### Widgets that change
`AdvisorScreen` (tray replaces the board `AccentRail`; `boardSizeFor` subtracts tray padding from width and the new fixed heights), `TopBar` (two-line label), `EvalFormat.headline` (caption + value instead of one string; the developer picks the shape), `EvalFormat.expertLine` (separator), `SuggestionCard` (padding, caption), `PersonaTierKeys` + `PersonaTier` (pictogram + badge instead of emoji), `StatusLine` (top padding 8 → 4), `ConfirmPlayedKey` (check chip), `AppDimens` / `AppTypography`. Unchanged: `UndoKey`, `NewGameKey`, `ScreenHeader`, boards, promotion chooser, Home, new-game screen (apart from the shared persona keys).

#### Text scale 2.0 at 360 × 640 and 360 × 600
No overflow on the advisor in any state, Chess and Xiangqi. Fixed rows keep their heights; the top-bar label, card content, header keys and status-line key scale down (`FittedBox`); persona pictograms and badges have fixed sizes.

#### Deviations from the mockup
| Mockup | Spec | Why |
|--------|------|-----|
| UNDO top-left, NEW GAME top-right | NEW GAME left, UNDO right | PO's explicit OB-050 decision (2026-10-04), header rule "navigation left" (Open Question 6) |
| Yellow / blue checkerboard | Current board colours | PO: keep board colours (D1) |
| Blue move text and blue dot | Green move text and dot | Green = suggestion (D4); game accents never mark the suggestion (BR-001) |
| Red outlined squares for the suggested move | Green suggestion highlight | Red = check / danger only |
| Tiers 5–7 dimmed | All 7 tiers enabled, full strength | No tier gating in M1 (monetization deferred) |
| Taller bottom key (≈ 56 dp) | 48 dp incl. depth | A taller key would shrink height-limited boards (Xiangqi) |
| Board tray with wide margins | 4 dp padding, full width at 360 dp | Keeps Chess cells ≥ 44 dp at 360 dp |
| EVAL / DEPTH values highlighted | One text colour | Keeps the existing shared expert-line style; small gain |
| `→` arrow | Existing `➔` | Existing move format (OB-007), unchanged |

### DS-8 New Game layout (PO mockup 2026-10-05)
PO input 2026-10-05: a mockup of the Chess new-game screen; PO choices recorded as D7. This section replaces the new-game parts of DS-4 (header title, header rail already removed by D6). OB-052 colour rules stay: amber = selected, the game accent for identity only, `bgDark` text on accent / amber faces, solid fills only (no glow, blur or gradient), no accent lines (D6).

```text
360 dp, Chess, hero shown (available height ≥ 700 dp)    height (dp)
 padding 16 top
[‹ BACK]                              [FAIR PLAY]        48  ScreenHeader (middle empty)
                                                          8
        ◇ isometric pink slab, two king discs ◇          min(25 % H, 200)  hero (optional)
                                                          8
  PLAYING                    (caption, textSecondary)    16
  CHESS                      (display 32 sp, pink)       40
                                                         16
┌ panel: surfaceDark block, radius 6, padding 8 ──────┐
│ 01  LEVEL · EVEN                                    │  21  section header
│ [•¹][♟²][♞³][▓♝⁴▓][♜⁵][♛⁶][♚⁷]   PersonaTierKeys   │  48  (amber = selected)
│                                                     │  16
│ 02  YOUR SIDE                                       │  21  section header
│ [♔ WHITE        ◉]  [♚ BLACK         ○]             │  60  side cards (amber = selected)
│ [  FIRST MOVE     ]  [  SECOND MOVE    ]            │
└─────────────────────────────────────────────────────┘ + 8 padding top/bottom, 4 side
     ↑ everything from hero to panel scrolls ↑           16
[        START GAME  [›]        ] pink block, pinned     48
   LEVEL CAN BE CHANGED DURING THE GAME                  4 + 16, pinned
 padding 16 bottom
```

#### Screen frame
- Padding: **8 dp left / right** (was 16), 16 dp top / bottom. The 8 dp keeps the level keys as wide as today (panel padding 8 → 328 dp inner width at 360 dp, ≈ 45 dp per key with 2 dp gaps).
- Three parts in a `Column`: header (fixed), scrollable content (`Expanded` + `SingleChildScrollView`: hero, title, panel), bottom block (fixed: 16 dp gap, START GAME, helper text). START GAME is always visible without scrolling.

#### Header (`ScreenHeader`, 48 dp, unchanged height)
- Leading: BACK key, label **`‹ BACK`** (glyph + label, like `↶ UNDO`), semantics "Back" (unchanged), `NewGameScreen.backKey`.
- Trailing: FAIR PLAY key, unchanged (`NewGameScreen.fairPlayKey`, semantics "Fair play").
- Middle: empty. The game name moves to the title block below; no language key on this screen (language stays on Home).

#### Hero (`NewGameHero`, new, decorative)
- **Shown only when** the body height inside `SafeArea` is **≥ 700 dp** and the text scale (`MediaQuery.textScalerOf(context).scale(1)`) is **≤ 1.3**. Otherwise it's not built at all (no placeholder, no gap). Measured with a `LayoutBuilder` on the body; re-evaluated on rotation / resize.
- **Height** = `min(0.25 × H, 200)` dp where H = body height (175–200 dp in practice), full content width, 8 dp gap above and below.
- **Painting** (`CustomPainter`, static, repaints only when game or size changes; no animation, no blur, no gradient, no shadow):
  - A slab seen at 2:1 isometric: top face = a diamond, width `w = min(0.75 × box width, 1.6 × box height)`, height `w / 2`, centred. Below it, two side faces (left and right lower edges) **0.1 × w** deep, both in the game's side colour (`accentChessSide` / `accentXiangqiSide`). Top face in the game accent (`accentChess` / `accentXiangqi`). Corners rounded ≈ 4 dp (`AppDimens.radius`) where the painter allows; sharp is acceptable.
  - Top-face pattern, picked per game in `game_registry.dart` (the only `GameKind` switch, BR-004):
    - Chess: 4 × 4 checker projected onto the diamond; dark cells = game side colour at 40 % over the accent, precomputed into one solid colour (`Color.alphaBlend`), no layer blending.
    - Xiangqi: simplified intersection grid projected onto the diamond: 5 files × 6 ranks of 1.5 dp lines in the side colour, the middle rank gap left open as the river.
  - Two upright pieces standing on the top face at ⅓ and ⅔ along the long diagonal, each `0.22 × w` square, drawn with the existing `GameWidgets.sidePictogram(game, side)` (Chess: white king / black king pictograms; Xiangqi: 帥 / 將 `XiangqiPieceDisc`s). Under each, a flat ellipse shadow-shape `0.22 × w` wide, `0.08 × w` tall in the side colour (solid, not blurred). Pieces may be widgets in a `Stack` laid out from the painter's geometry (developer's call). No new assets.
- **No backdrop:** the mockup's radial pink glow is not adopted; the hero sits on `bgDark`.
- Semantics: excluded (`ExcludeSemantics`); it adds no information.

#### Title block
- Line 1: `PLAYING`, `AppTypography.secondary` w700, `textSecondary` (6.2:1 on `bgDark`), 16 dp line.
- Line 2: game label in upper case (`CHESS` / `XIANGQI`), **new token `AppTypography.display`**: JetBrains Mono 32 sp, w700 (only 400 / 700 are bundled), height 1.25, tabular; colour = game accent (pink 9.0:1, blue 6.0:1 on `bgDark`).
- Start-aligned with an 8 dp inset (lines up with the panel content). One `FittedBox(scaleDown)` per line so a long future game name never wraps.
- Semantics: one node, `header: true`, label "New game, Chess" / "New game, Xiangqi" (moved from today's header middle; same text).

#### Panel (non-pressable surface block)
- `AppBlock` with face `surfaceDark`, side `surfaceSide` (4 dp), 1 dp `edgeHighlight`, **radius 6 dp (`AppDimens.radiusLarge`)**, no `onTap`. Padding 8 dp all round inside the face. `AppBlock` needs an optional radius (default `AppDimens.radius`); the panel is the only 6 dp block.
- No divider line between the two sections (the mockup's hairline isn't adopted); 16 dp gap instead.
- **Section header** (both sections): number + 8 dp + title in one row.
  - Number `01` / `02`: `AppTypography.secondary`, `textSecondary` (5.3:1 on `surfaceDark`).
  - Title: `AppTypography.primary`, `textPrimary`: `LEVEL · EVEN` (tier name follows the selection, as today's `_levelHeading`) and `YOUR SIDE`.
  - Semantics: `header: true`, label "Level, Even" / "Your side"; the number is excluded.
  - **No level pill:** the mockup's `Casual` pill would repeat the tier name already in the heading.
- **Level row:** `PersonaTierKeys`, unchanged widget, 48 dp tall, 2 dp gaps (`spacingSmall / 2`), `NewGameScreen.tierKey`. Selected = amber block. Default tier Even (4).

#### Side cards (2 × `AppKey`, `NewGameScreen.sideKey`)
- Row of two equal cards, 8 dp gap. Card min height **60 dp incl. 4 dp depth**; AppKey's 8 dp padding.
- Content (horizontal): pictogram **32 dp** (was 40; `GameWidgets.sidePictogram`, unchanged art), 8 dp, a text column in `Flexible` + `FittedBox(scaleDown)`:
  - Label `game.sideLabel(side)`: `WHITE` / `BLACK` (Chess), `RED` / `BLACK` (Xiangqi), `AppTypography.primary`.
  - Sub-label: `FIRST MOVE` for `PlayerSide.first`, `SECOND MOVE` for `PlayerSide.second` (game-agnostic; White and Red move first), `AppTypography.secondary`.
  - Colours: normal card → label and sub-label `textPrimary` (13.7:1; `textSecondary` on `keyNormal` is only 4.3:1, so it's not used); selected (amber) → both `bgDark` (13.5:1).
- **Radio dot:** 12 dp circle, `Positioned` 6 dp from the face's top-right corner (outside the text flow, so it never squeezes the labels). Normal: 1.5 dp ring `textSecondary` (≥ 3:1 non-text on `keyNormal`). Selected: 1.5 dp ring + 6 dp centre dot, both `bgDark`. It moves with the face on press. Second cue besides the amber fill (colour-vision safe).
- No pink tile behind the pictogram and no outline (D6); selection is the amber block.
- Semantics: one node per card, label "White, first move" / "Black, second move" / "Red, first move", `button` + `selected` from `AppKey`; pictogram and radio dot excluded.

#### Bottom block (pinned)
- 16 dp gap above START GAME.
- **START GAME:** `AppKey` with the game accent pair (unchanged, D2), 48 dp incl. depth, `NewGameScreen.startKey`. Content row centred in a `FittedBox(scaleDown)`: `START GAME` (`primary`, `bgDark`, 9.0:1 / 6.0:1) + 8 dp + **arrow chip** 24 × 24 dp, fill `bgDark`, radius 4 dp, `Icons.chevron_right` 18 dp `textPrimary` (19:1). Same chip construction as I PLAYED IT's check chip. Semantics unchanged (key label); chip excluded. Double-tap guard unchanged.
- **Helper text:** 4 dp below the key, `LEVEL CAN BE CHANGED DURING THE GAME`, `AppTypography.secondary`, `textSecondary` (6.2:1 on `bgDark`), centred, one line in `FittedBox(scaleDown)` (stays ≈ 16–21 dp tall at any text scale). True statement: the advisor's persona row changes the level mid-game; the side needs a new game, so the mockup's "change these settings anytime" isn't used.

#### Vertical budget
Fixed: padding 16 + header 48 + bottom block (16 + 48 + 4 + 16) + padding 16 = **164 dp**. Scroll content without hero: 8 + title 56 + 16 + panel (8 + 21 + 8 + 48 + 16 + 21 + 8 + 60 + 8 + 4 = 202) = **282 dp**.

| Screen (body height ≈) | Text scale | Hero | Scroll content vs. viewport | Result |
|--------|-----|------|------|------|
| 360 × 640 (≈ 616) | 1.0 | hidden (< 700) | 282 vs. 452 | fits, no scroll |
| 360 × 600 (≈ 576) | 1.0 | hidden | 282 vs. 412 | fits |
| 360 × 640 | 2.0 | hidden | ≈ 400 (title 116, panel ≈ 260) vs. 452 | fits |
| 360 × 600 | 2.0 | hidden | ≈ 400 vs. 412 | fits; scrolls if fonts render larger |
| 392 × 800 (≈ 760) | 1.0 | 190 dp | 282 + 190 + 8 = 480 vs. 596 | fits |
| 392 × 800 | 1.5 | hidden (> 1.3) | ≈ 330 vs. 596 | fits |

Text scale 2.0: the header keys, START GAME row and helper text scale down (`FittedBox`); the title, section headers and side-card labels grow; persona pictograms / badges and the radio dot have fixed sizes; nothing clips or overflows on 360 × 640 / 360 × 600, and START GAME stays visible.

#### Xiangqi
Same layout and sizes. Accent `accentXiangqi` / `accentXiangqiSide` on the hero slab, `XIANGQI` title and START GAME. Hero top face = intersection grid with 帥 / 將 discs. Side cards `RED` (帥 disc, `pieceRed` rim) `FIRST MOVE` / `BLACK` (將 disc) `SECOND MOVE`. Blue title text 6.0:1, `bgDark` on blue 6.0:1.

#### Widgets that change
- `NewGameScreen`: new layout (header middle empty, `‹ BACK`, title block, panel, section headers, side cards with sub-label + radio dot, pinned bottom block, helper text, hero visibility rule, 8 dp side padding).
- New `NewGameHero` (+ its painter) under `lib/features/new_game/presentation/widgets/`; per-game top-face pattern from `game_registry.dart`.
- `AppBlock`: optional radius (default `AppDimens.radius`).
- `AppTypography.display` (new token).
- Unchanged: `PersonaTierKeys`, `AppKey`, `ScreenHeader` / `HeaderKey`, `GameKind` data, `game.sideLabel`, Home, advisor, `FairPlayScreen`, navigation, defaults (Even, first mover).
- Tests: `new_game_screen_test.dart` (title semantics moved out of the header; sub-labels; radio state; hero shown at ≥ 700 dp / hidden at 360 × 640 and at text scale > 1.3; no overflow at 360 × 640 and 360 × 600 at text scale 2.0; START GAME visible without scrolling), integration tests that find the header title.

#### Deviations from the mockup
| Mockup | Spec | Why |
|--------|------|-----|
| Radial pink glow behind the hero | No backdrop, flat slab on `bgDark` | Blur / gradient banned (NFR-004) |
| Hero always shown | Hidden below 700 dp body height or text scale > 1.3 | Fits 360 × 640 without scrolling START GAME away |
| Knight pieces on the hero | King pictograms / 帥 將 discs (`sidePictogram`) | Reuse existing art, same as side cards |
| Icon-only back key | `‹ BACK` | Text labels on keys (BR-007) |
| UK-flag language key | FAIR PLAY key | Language is app-level (Home); flags name countries, not languages |
| Mixed-case sans `Chess` | `CHESS`, JetBrains Mono 32 sp, accent | BR-007 |
| Pink level key / pink outlined side card | Amber block (+ radio dot on side cards) | Amber = selected (BR-002); no accent lines (D6) |
| Number-only level keys, `3` selected | `PersonaTierKeys` (pictogram + badge), Even (4) default | Shared with the advisor (DS-7); default unchanged |
| `Casual` pill | Dropped | Not a tier name; repeats `LEVEL · EVEN` |
| Pink knight tiles on side cards, same icon on both | Side pictogram on the card face (white / black king, 帥 / 將) | Accent is identity only (DS-4); each side shows its own piece |
| Hairline divider between sections | 16 dp gap | No decorative lines (D6) |
| ≈ 24 dp panel radius | 6 dp (`radiusLarge`) | Shape rule 4–6 dp |
| Green START GAME, taller (≈ 56 dp) | Game-accent block, 48 dp incl. depth | D2: green = suggestion only; standard key height |
| Small grey sub-labels (≈ 9 sp) | 12 sp `textPrimary` / `bgDark` | ≥ 4.5:1 contrast and ≥ 12 sp |
| "You can change these settings anytime" | `LEVEL CAN BE CHANGED DURING THE GAME` | Side can't change mid-game |

### DS-9 Home layout (PO mockup 2026-10-05)
PO input 2026-10-05: a mockup of the Home screen; PO choices recorded as D9. This section replaces the Home parts of DS-4 (accent tiles). OB-052 colour rules stay: the game accent for identity only, `bgDark` on accent faces, app-level chrome neutral (BR-005), solid fills only, no accent lines (D6), no motion beyond press-sink, uppercase JetBrains Mono, text-label keys (BR-007).

```text
360 dp, hero shown (body ≥ 700 dp, text scale ≤ 1.3)    height (dp)
 padding 16 top
[SETTINGS]        PICK A GAME        [LANGUAGE]          48  ScreenHeader, unchanged
                                                         16
┌ hero: surfaceDark block, radius 6, padding 16 ───────┐
│ SPOOKYMOOVE              (caption, textSecondary)    │  16
│                                                      │   8
│ PICK A GAME.             (display 32 sp, textPrimary)│  40–80 (1–2 lines)
│ PLAY IT ON YOUR BOARD.                               │
└──────────────────────────────────────────────────────┘ + 4 side
                                                         16
┌ row: surfaceDark block ───────────────────────────────┐
│ [▣ ♔]  CHESS                                       ›  │  72 min incl. depth
│ pink   CLASSIC STRATEGY                               │
└───────────────────────────────────────────────────────┘
                                                          8
┌───────────────────────────────────────────────────────┐
│ [▣ 帥]  XIANGQI                                     ›  │  72
│ blue   CHINESE CHESS                                  │
└───────────────────────────────────────────────────────┘
     ↑ hero + rows scroll, top-aligned ↑
 padding 16 bottom
```

#### Screen frame
- Padding 16 dp all round (unchanged). Header fixed; below it one `SingleChildScrollView`: [hero + 16 dp gap] (optional), then the rows with 8 dp gaps.
- **Top-aligned** (was bottom-aligned): content starts 16 dp under the header; spare space is left empty at the bottom.

#### Header (`ScreenHeader`, 48 dp, unchanged)
- `[SETTINGS]  PICK A GAME  [LANGUAGE]`, neutral text keys, same keys, labels and semantics (OB-051). No gear icon, no flag.
- The title stays in the header middle, so the mockup's "Pick a game" section heading is not added (it would repeat the header).

#### Hero (static, no decoration, optional)
- **Shown only under the `NewGameHero` rule:** body height inside `SafeArea` ≥ 700 dp **and** text scale ≤ 1.3. Otherwise not built (no placeholder, no gap). Both screens must use the same two thresholds from one place.
- Non-pressable `AppBlock`: face `surfaceDark`, side `surfaceSide` (4 dp), 1 dp `edgeHighlight`, radius 6 dp (`AppDimens.radiusLarge`). Padding 16 dp inside the face. Height follows content (≈ 92–132 dp incl. depth), full content width.
- Content, start-aligned:
  - Caption: `AppTypography.secondary` w700, `textSecondary` (5.3:1 on `surfaceDark`), one line.
  - 8 dp.
  - Title: `AppTypography.display` (32 sp w700), **`textPrimary`** (16.2:1), max 2 lines, one sentence per line. Not a game accent: the hero is app-level chrome (BR-005).
- Nothing else: no arc, no dice, no subtitle, no pink line, no `⚡ QUICK MATCH`, no image, no animation.
- **Copy (proposed, needs PO + OB-034 copy check before release):**
  - Default: caption `SPOOKYMOOVE`, title `PICK A GAME.` / `PLAY IT ON YOUR BOARD.`
  - Alternative: caption `TRAINING BOARD`, title `PICK A BOARD.` / `GET A HINT.` (shorter, but "hint" may read as in-game help during play; counsel to confirm against OB-034 BR-001 / BR-003).
  - Must not use banned terms (cheat, hack, bot, auto-move, undetected, "win every game", OB-034 BR-001). Strings go through the same string source as other UI labels.
- Semantics: one node with the title text (not a header; the header middle stays the page heading). Caption excluded.

#### Game row (one per `GameKind.values`, order unchanged)
- Pressable `AppBlock`, face **`surfaceDark`** (not `keyNormal`: `textSecondary` on `keyNormal` is 4.4:1 and fails 12 sp text; on `surfaceDark` it's 5.3:1), side `surfaceSide`, 1 dp `edgeHighlight`, radius 4 dp. Press-sink as every key (DS-3); the whole row is the hit target. Not amber/selected ever (no selection on Home).
- **Min height 72 dp incl. 4 dp depth** (face ≥ 68 dp); grows with text. Full content width.
- Face padding: 12 dp left / right, 10 dp top / bottom. Content row, vertically centred:
  1. **Icon block** 48 × 48 dp incl. depth: non-pressable `AppBlock` with the game accent pair (`game.accent` / `game.accentSide`), no highlight, radius 4 dp. Face 48 × 44 dp holds the **32 dp** `GameWidgets.sidePictogram(game, PlayerSide.first)`, centred. Moves with the row when pressed. Fixed size (doesn't scale with text).
  2. 12 dp gap.
  3. Text column (`Expanded`, start-aligned):
     - Name: `game.label` upper case (`CHESS` / `XIANGQI`), `AppTypography.primary` (16 sp w700), `textPrimary` (16.2:1). One line, `FittedBox(scaleDown)`.
     - 2 dp gap.
     - Tagline: `AppTypography.secondary` (12 sp w400), `textSecondary` (5.3:1). Up to 2 lines, then ellipsis.
  4. 8 dp gap.
  5. Chevron: `Icons.chevron_right` 24 dp, `textSecondary` (5.3:1 non-text). Not the game accent. Fixed size. Excluded from semantics.
- **Taglines** (per-game data next to `label`, one place; a game without a tagline must not compile, BR-004): Chess `CLASSIC STRATEGY`, Xiangqi `CHINESE CHESS`.
- Semantics: one node per row, `button`, label "Chess, classic strategy" / "Xiangqi, Chinese chess" (spoken label + tagline in sentence case); children excluded. Keys unchanged: `HomeScreen.gameKey(game)`.
- Navigation unchanged: tap opens the new-game screen for that game (`HomeScreen.openNewGame`), double-tap guard unchanged.
- Not added: count pill, coming-soon / locked / download rows (only `GameKind.values` are listed).

#### Vertical budget
Fixed: 16 + header 48 + 16 gap + 16 bottom = 96 dp. Rows at 1.0: 72 + 8 + 72 = 152 dp. Hero ≈ 132 dp (2-line title) + 16 gap.

| Screen (body ≈) | Text scale | Hero | Content vs. viewport | Result |
|--------|-----|------|------|------|
| 360 × 640 (≈ 616) | 1.0 | hidden | 152 vs. 520 | fits |
| 360 × 600 (≈ 576) | 1.0 | hidden | 152 vs. 480 | fits |
| 360 × 640 | 2.0 | hidden | rows ≈ 96–126 each (tagline wraps to 2 lines at ≈ 212 dp text width) → ≈ 260 vs. 520 | fits |
| 360 × 600 | 2.0 | hidden | ≈ 260 vs. 480 | fits |
| 392 × 800 (≈ 760) | 1.0 | ≈ 132 + 16 | 300 vs. 664 | fits |
| 392 × 800 | 1.5 | hidden (> 1.3) | ≈ 200 vs. 664 | fits |

Text scale 2.0: header keys and title scale down (`FittedBox`, unchanged); row name scales down to one line, tagline grows and wraps; icon block, pictogram and chevron keep their size; nothing overflows; the list scrolls if a future game list or font exceeds the viewport.

#### Widgets that change
- `HomeScreen`: game key → game row (spec above), content top-aligned, rows gap 8 dp, optional hero.
- New small hero widget (Home only, under `lib/features/new_game/presentation/widgets/`); visibility thresholds shared with `NewGameScreen` / `NewGameHero` (one constant pair, developer's call where).
- `GameKind`: `tagline` per game.
- `AppDimens`: `gameKeyMinHeight` (112) / `gamePictogramSize` (56) replaced by row tokens: row min height 72, icon block 48, icon pictogram 32 (names developer's call).
- The row uses `AppBlock` directly with `button` semantics (or an `AppKey` option for a `surfaceDark` face; developer's call; no change to `AppKey`'s existing states).
- Unchanged: `ScreenHeader` / `HeaderKey`, Settings / Language dialogs, `NewGameScreen`, `NewGameHero`, accents, navigation.
- Tests: `home_screen_test.dart` (row per `GameKind`, name + tagline, semantics label, surface face + accent icon block, no accent on header, hero shown at ≥ 700 dp / hidden at 360 × 640 and text scale > 1.3, top alignment, no overflow at 360 × 640 / 360 × 600 at text scale 2.0, tap opens the right new-game screen once); integration tests that find Home tiles by key keep working.

#### Deviations from the mockup
| Mockup | Spec | Why |
|--------|------|-----|
| Gear icon / UK flag keys | `SETTINGS` / `LANGUAGE` text keys | Text labels on keys (BR-007); flags name countries |
| `⚡ QUICK MATCH`, pink second line, subtitle | Neutral caption + `textPrimary` title, no subtitle | App-level chrome neutral (BR-005); no quick-match feature |
| Dark ring arc, floating dice blocks | None | No decoration / motion beyond press-sink (DS-3) |
| Hero always shown | Hidden below 700 dp body or text scale > 1.3 | Same rule as `NewGameHero` |
| "Pick a game" heading + `6 games` pill | Title stays in header; no pill | Repeats the header; count adds nothing |
| Mixed-case sans names / taglines | Upper-case JetBrains Mono | BR-007 |
| Tilted isometric tile icons | Flat accent `AppBlock` (face + 4 dp side) with `sidePictogram` | Reuses the block language and existing art; no new painter |
| Xiangqi orange, Go blue | Xiangqi `#578EF5`; future games per the D9 palette | Xiangqi colour set by PO (D2) |
| Accent chevrons | `textSecondary` chevron | Accent only on the icon block (DS-4) |
| ≈ 16–24 dp card radius | 4 dp rows, 6 dp hero | Shape rule 4–6 dp |
| Caro / Othello / Go rows, dashed "Tap to download", green downloading row | Not shown | Only `GameKind.values`; download states belong to OB-015 (note below) |

#### Design note for OB-015 (on-demand packs; not in this ticket)
Proposed neutral row states, same row anatomy; status colours keep their meaning (green = good / suggestion, so no green tint or bar), no dashed outlines (D6), no spinner (motion):
- **Not installed:** normal row, icon block in full accent (identity, not status). Tagline → `NOT INSTALLED · 42 MB`. Trailing: small neutral `[↓ GET]` key (≥ 48 dp hit target) instead of the chevron. Semantics "Othello, not installed, 42 megabytes, download, button".
- **Downloading:** tagline → `DOWNLOADING 68%` (tabular figures) above a 4 dp bar: fill `textPrimary`, track `keyNormalSide`, radius 2 dp, determinate only. Trailing `[CANCEL]` neutral key (or row tap asks to cancel; OB-015 decides). Semantics: progress value, announced at most every 10 %.
- **Failed:** tagline → `DOWNLOAD FAILED` in `textPrimary` with a 16 dp `accentRed` ⚠ glyph (red text on the row is too low for 12 sp; the glyph is ≥ 3:1). Trailing neutral `[RETRY]` key. Semantics "Othello, download failed, retry, button".
- Installed: normal row as above.

## Developer Handoff
- Tokens first (`lib/core/theme/`): two identity accents, side-face shades, extrusion depth, press-sink values. One `GameKind` → accent mapping (on `GameKind` data or in `game_registry.dart`, developer's call); no game checks in widgets.
- Restyle the shared widgets (`AppKey`, `HeaderKey`, `ScreenHeader`, `AppDialog`, suggestion card) so screens pick up the look mostly for free. Press-sink lives in `AppKey`; keep hit area and layout size fixed while pressed.
- Accent hooks: Home tile, new-game header + START GAME, `TopBar`, board frame in `AdvisorScreen`. Keep `boardSizeFor` results unchanged; the frame must fit in existing space.
- Extrusion as solid offset fills only (no blur, no blurred `BoxShadow`, no `BackdropFilter`); run the OB-010 frame check before and after.
- Update `designSystem.md` (REQ-010) and widget tests; check 360 × 640 / 360 × 600 at text scale 2.0. Verify on the iOS simulator (testing policy 2026-10-03).
- **Advisor layout revision (DS-7):** board tray replaces the board rails; `boardSizeFor` now subtracts 8 dp of tray padding from the width and uses the new fixed heights (total still 252 dp), so the "board size unchanged" test becomes "squares ≥ 44 dp at 360 dp / ≥ 48 dp at ≥ 392 dp, height-limited boards unchanged". Two-line win rate, piece-silhouette persona keys with number badges (no emoji, no dimming), BEST MOVE caption, ` • ` expert separator, check chip on I PLAYED IT. Corners stay NEW GAME left / UNDO right.
- **New-game layout revision (DS-8, D7):** restructure `NewGameScreen` (header `‹ BACK` / empty / FAIR PLAY; scrolling hero + `PLAYING` / title + panel; START GAME with arrow chip and helper text pinned at the bottom), add `NewGameHero` (static `CustomPainter`, accent pair, `sidePictogram` pieces, shown only at ≥ 700 dp body height and text scale ≤ 1.3), `AppTypography.display`, optional `AppBlock` radius. Side cards get `FIRST MOVE` / `SECOND MOVE` sub-labels and a radio dot; selection stays amber. Verify 360 × 640 / 360 × 600 at text scale 2.0 and both games on the iOS simulator.
- **Home layout revision (DS-9, D9):** replace the accent tiles with `surfaceDark` rows (48 dp accent icon block + 32 dp pictogram, upper-case name + tagline, `textSecondary` chevron, ≥ 72 dp), top-aligned and scrolling; add `tagline` to `GameKind`; add the optional neutral hero card with the same visibility thresholds as `NewGameHero` (shared constants). Header, keys, navigation and dialogs unchanged. Hero copy is a placeholder until the PO / OB-034 check. Future accents (D9) are documented only; don't add tokens until those games exist. Verify 360 × 640 / 360 × 600 at text scale 2.0 on the iOS simulator.
