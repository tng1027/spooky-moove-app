# Product Context

## Problem
- Existing chess/board-game apps are built for playing on screen against bots or online opponents. Their busy UIs are impractical for someone sitting at a physical board who needs fast move entry.
- Bundling top AI engines (especially neural nets for Go/Shogi) inflates the app binary to 100 MB+, which hurts App Store / Play Store conversion.
- Players of several disciplines must juggle separate apps with inconsistent UX.

## Value proposition
1. **Zero-distraction input:** a minimal legal-only tap board that mirrors the physical board; every move takes 2 taps: the first shows the options, the second picks (OB-006, OB-048).
2. **100% offline autonomy:** no servers, no latency, private. No analytics (OB-035 M-D2).
3. **Lean install:** Chess + Xiangqi baseline < 30 MB; other engines' data downloaded on demand in the background.
4. **Grandmaster-grade calculation:** Fairy-Stockfish, KataGo, Edax, Yixin.
5. **Persona tiers:** the same engine can suggest anything from deliberately weak moves (play gently with a child) to full strength (OB-021).

## Personas
- **Serious Student / Analyst:** club or casual player wanting instant post-move validation during friendly physical games.
- **Multi-Discipline Enthusiast:** plays Eastern and Western strategy games (Chess, Xiangqi, Shogi, Go) and wants one tool.
- **Rapid Tactician:** wants quick hints with no board animations or deep menus.
- **Family player (positioning, OB-034):** a parent playing balanced games with a child on a physical board; may have **no chess-notation knowledge**.

## UX principles
- **Usable without chess-notation knowledge:** no piece letters, SAN, `O-O` or `e.p.` anywhere; pieces are pictograms; coordinates only as board edge labels and in the suggestion (PO 2026-10-02; OB-006, OB-007).
- A **minimal legal-only tap board** (pictograms, edge coordinates, no animations) replaces the earlier "no on-screen board" principle (PO 2026-10-02). It doubles as a sync check against the physical board.
- Only legal options are tappable; everything else is dimmed/disabled.
- Large, high-contrast output; dark mode by default (whether a light theme is ever in scope is open, OB-003).
- Haptics confirm actions so the user can keep their eyes on the board.

### Session flow (Chess; OB-001, OB-011, OB-025, OB-024, OB-012)
- New game: choose the game, then **exactly one side** (decision). Start from the standard initial position (accepted assumption).
- The new-game screen preselects the middle persona tier (Even) and White; START GAME starts with the selections (PO, 2026-10-03). The tier can be changed at any time; a change recomputes the suggestion.
- The user enters the opponent's move on the board. A suggestion (the active tier's move) appears only on the user's turn. If the user played it, one tap on **"✓ I PLAYED IT"** applies it; otherwise they enter the move they actually played, which overrides the suggestion and the game continues (PO decision 2026-10-03, OB-041; replaces "the user enters every move").
- **Undo:** one tap removes the last entered move (either side); repeated taps go further back (OB-012; in the Chess DoD).
- Game end: checkmate, stalemate and automatic FIDE draws detected; claimable draws shown as a plain-language hint; no resign/draw buttons (accepted assumptions, OB-024).
- "Accepted assumption" = the PO did not object (2026-10-02); can be revisited.
- No resume after the app is killed in M1: the app always opens at Home (OB-001 Q6, PO 2026-10-04).

### Move entry (tap board, OB-006)
- **Move-based (Chess, Xiangqi):** smart 1–2-tap entry. The first tap on an own movable piece = source; on any other square = destination. The move auto-commits when unambiguous. Chess promotion = a 4-pictogram chooser (queen first). Xiangqi: see "Xiangqi (Phase 2)" below.
- **Placement-based (Gomoku, Go, Othello):** target point only. Details per game phase.
  - Othello: only legal flipping coordinates are tappable.
  - Go 19×19: quadrant zoom or coordinate grid, plus `[Pass]` / `[Resign]`; all still open (OB-019).
- **Shogi extras (to be revisited in its phase for the no-notation principle):** in-hand drop tray and a promotion prompt.

### Suggestion card (output, OB-007)
- Centered type, 40–48 sp, high contrast.
- Chess move in absolute coordinates: `E7 ➔ E5`; capture `E4 ➔ D5 ✕`; castling shows the king move plus a rook instruction line (`[rook] H1 ➔ F1`); en passant adds `✕ D5`; promotion shows the piece pictogram. Xiangqi format: see below.
- Evaluation of the **suggested** move from the **user's side**: `WIN 62%`, or `YOU MATE IN 4` / `OPPONENT MATES IN 4`.
- Secondary expert line (small): `EVAL +1.4 | DEPTH 16 | 850k nps`.
- The suggested move is highlighted on the board in green.
- Haptics: move accepted (on commit), engine move ready (`mediumImpact`), in check (`heavyImpact`).

### Xiangqi (Phase 2; PO decisions 2026-10-03, XQ1–XQ11; epic OB-009)
Every decided Chess behaviour carries over (new-game flow, persona, turn loop, ✓ I PLAYED IT, undo, top-bar win rate, game-over handling). Xiangqi-specific:
- New game: GAME row CHESS / XIANGQI (current game preselected, else CHESS); sides RED / BLACK with 帥 / 將 discs, default RED (XQ5, XQ8).
- Board: intersection board (grid, river gap, palace diagonals), 9×10 cells centred on points, cell = min(W/9, (H−252)/10). Accepts 40 dp at 360 dp width (≈ 35 dp on 360×640) with nearest-legal snapping; device check in the final pass (XQ3).
- Pieces: Chinese characters on discs (bundled vector assets); Red uses the board-only `pieceRed` token (XQ1, XQ2).
- Suggestion: piece disc + absolute coordinates in Red's frame, `A`–`I` / `1`–`10`, `✕` for captures (`[炮] H3 ➔ E3`). WXF only in the expert line (`C2.5 · EVAL +0.3 | …`) (XQ4 = OB-001 Q10).
- Game end: the side to move with no legal move loses: `CHECKMATE` or `NO MOVES` / `YOU WIN` or `YOU LOSE` (XQ7). No automatic draws and no perpetual check/chase adjudication in M1 (XQ6, XQ9).
- Rules module: hand-written pure Dart, no new dependency (XQ11).

### Persona tiers (OB-021 is the source of truth)
- 🥚 Baby, 🐣 Gentle, 🐥 Soft, 🥉 Even, 🥈 Solid, 🥇 Master, 👑 God. The same tiers in every game.
- The persona changes only the move **suggested to the user**; the app never plays as an opponent.
- Tiers are defined on the user's win chance, so they work for every engine. All tiers respect the ≤ 1000 ms / 2-thread budget. Exact bands and rules: OB-021, OB-022.

## Fair-play and ethics (OB-008)
For personal training, casual study, handicap analysis and offline recreational games only. Format:
- A one-time, blocking, full-screen notice with one button ("I UNDERSTAND" / "TÔI ĐÃ HIỂU").
- EN/VI in the app language (device language until Vietnamese ships as an app language, OB-051 D2 / OB-053).

## App language (OB-051, OB-053)
- M1 ships in English and Vietnamese (PO 2026-10-05). Language picked from the LANGUAGE key on Home (`ENGLISH`, `TIẾNG VIỆT`); applies immediately and is saved on the device.
- Default without a saved choice: Vietnamese on a Vietnamese device, English otherwise; a saved choice wins.
- All in-app text and screen-reader labels are translated, incl. game names (`CỜ VUA` / `CỜ TƯỚNG`) and persona tier names (tier-7 name follows OB-034). Not translated: app name, move coordinates, engine/expert line, Xiangqi characters, license texts.
- Vietnamese copy: drafted by BA/developer, signed off by the PO; same plain-wording and positioning rules as English.
- Versioned: shown again when the wording version changes.
- Re-viewable from a "FAIR PLAY" key on the new-game screen.
- Forbids competitive/rated/tournament use without arbiter permission.

## Store positioning and audience (OB-034, OB-040)
- Positioning: "Family Companion & Training Assistant". Never use: cheat, hack, stealth, bot, auto-move, undetected (and similar). App name and the tier-7 label are still to be decided.
- Audience: adults; listing copy addresses parents. Content rating 4+ / Everyone. No data collected. Parental gate before purchases and external links (e.g. license source links on the ABOUT screen, OB-033).

## Monetization
Deferred (OB-035): full-feature version first; all games and tiers available. Later plan: Xiangqi, Go, Shogi and Othello as Pro. No analytics in any version.
