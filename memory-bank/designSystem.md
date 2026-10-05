# Design System — Gamified Isometric

Source: UI/UX + library consultation (2026-10-02); restyled to Gamified Isometric by OB-052 (PO 2026-10-05, D1–D5). Applies to every screen.

## Why this style
- The app is a calculation/tactics tool used while looking at a physical board. Speed and glanceability still beat decoration, so the play is in the chrome only.
- **Gamified Isometric (OB-052):** UI chrome (keys, Home tiles, cards, headers, dialogs) is built from chunky raised blocks with a solid side face and press-sink feedback, and each game has its own identity colour. "Gamified" means the visual tone only, not mechanics (no XP, streaks or badges).
- **Boards stay flat and top-down** (D1): same painting, cells and tap rules as before.
- **Still rejected:** Neumorphism, Glassmorphism, blur and layered soft shadows. They distract and cost GPU. Depth comes from solid fills only.
- Earlier style (2026-10-02 to OB-052): Industrial Utility / Terminal Neo-Brutalism, inspired by DGT chess clocks and the Bloomberg terminal. Its dark palette, typography and status-colour rules remain.

## Color
Dark mode only by default. Pure/near-black background to save OLED battery during a full game and reduce glare in both bright and dim rooms.

| Token | Hex | Meaning |
|-------|-----|---------|
| `bgDark` | `#0F1015` (or `#000000` true black) | App background |
| `surfaceDark` | `#1E2029` | Cards / surfaces |
| `keyNormal` | `#2C2D35` | Normal keypad keys |
| `keyDisabled` | `#1A1B20` (mockup code uses `#16171E`) | Disabled keys (illegal move) |
| `accentGreen` | `#00E676` | Engine-recommended move, high confidence, advantage |
| `accentRed` | `#FF5252` | Opponent threat, in check, disadvantage |
| `accentActive` | `#FFD600` (amber) | Currently selected key (active state) |
| `textPrimary` | `#FFFFFF` | Main text |
| `textSecondary` | `#8E92A4` | Secondary info (eval/depth line) |
| `pieceRed` | `#FF8A80` | Board-only: Xiangqi Red glyphs and rims (≈ 6:1 on `keyNormal`). Not a danger accent (OB-044, XQ2) |
| `accentChess` | `#ED96D7` | Chess identity (OB-052): Home tile, START GAME, new-game title and hero |
| `accentChessSide` | `#A8508F` | Side face under `accentChess` |
| `accentXiangqi` | `#578EF5` | Xiangqi identity (OB-052), same places as Chess |
| `accentXiangqiSide` | `#2A56B3` | Side face under `accentXiangqi` |
| `keyNormalSide` | `#1D1E25` | Side face under `keyNormal` |
| `surfaceSide` | `#15161D` | Side face under `surfaceDark` (card, dialogs) |
| `accentActiveSide` | `#A68B00` | Side face under amber selected keys |
| `accentGreenSide` | `#00994F` | Side face under green primary keys |
| `edgeHighlight` | `#3A3B45` | 1 dp top edge on neutral faces (`keyNormal`, `surfaceDark`) only |

Status colours carry meaning (green = good / suggestion, red = danger / check, amber = selected) and keep priority. Game identity accents only name a game; they never signal status (see Game identity accents).

Text on any accent, amber or green face is `bgDark` (pink 9.0:1, blue 6.0:1). White on a game accent is not allowed (2.1:1 / 3.2:1).

Open (no decision yet): final `keyDisabled` value (`#1A1B20` vs. `#16171E`) and `bgDark` (`#0F1015` vs. true black) — OB-003 Q1. Board light/dark square colors are to be defined from this palette in OB-003/OB-006 (no new accents).

Reference code from the consultation:
```dart
class AppColors {
  static const bgDark = Color(0xFF0F1015);
  static const surfaceDark = Color(0xFF1E2029);
  static const keyDisabled = Color(0xFF16171E);
  static const accentGreen = Color(0xFF00E676);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8E92A4);
}
```

## Typography
- Monospace or heavy sans grotesque: **JetBrains Mono** (preferred), Fira Code, Space Grotesk, Share Tech Mono.
- **Tabular (fixed-width) figures everywhere** so the layout doesn't jitter while eval/depth/nps update continuously (`FontFeature.tabularFigures()`).
- Suggestion: 48 sp. Secondary info line: small, `textSecondary`.
- Tokens (`AppTypography`): `suggestion` 48 sp w700, `display` 32 sp w700 (new-game title, colour = game accent; OB-052 DS-8), `winRate` 24 sp w700, `primary` 16 sp w700, `secondary` 12 sp w400, `boardLabel` 10 sp. Only Regular (400) and Bold (700) are bundled. Labels are upper case.

## Shape and touch targets
- Clear geometric blocks, very small corner radius: **4–6 px**. 4 dp (`radius`) on keys, Home rows, card and dialogs; 6 dp (`radiusLarge`) only on the new-game panel.
- Key height **48–56 dp minimum**, so a thumb can hit keys without looking closely.
- **Exception — tap board squares:** ≥ 44 dp (8×8 on a 360 dp-wide screen); ≥ 48 dp on screens ≥ 392 dp wide. Other keys (promotion chooser, UNDO, persona row) keep the 48 dp minimum (OB-006 BR-005).
- **Isometric block (OB-052):** keys, Home tiles, the suggestion card and dialogs are a face over a solid side face, `blockDepth` = **4 dp**, straight down, radius `AppDimens.radius` (4 dp). The depth counts **inside** the minimum key height (48 dp box = face ≥ 44 dp + 4 dp side), so region heights and `boardSizeFor` don't change. Hit target = the whole box.
- States: normal `keyNormal` / `keyNormalSide`; selected `accentActive` / `accentActiveSide`; primary `accentGreen` / `accentGreenSide`; game accent face / its side; pressed = face down 4 dp, side collapsed, box unchanged; disabled = `keyDisabled` at the lowered position, no side, no highlight.
- Neutral faces get a 1 dp `edgeHighlight` top edge; accent, amber and green faces don't.
- Solid fills only: no blur, no gradients, no blurred `BoxShadow`, no `BackdropFilter`. `ScreenHeader` rows aren't blocks; their keys are.

## Screen layout (portrait) — advisor, revised 2026-10-05 (OB-052 DS-7, PO mockup)
```text
┌──────────────────────────────────┐
│ [NEW GAME]  WIN RATE   [↶ UNDO]  │ 48 dp  TopBar; value 24 sp green / red / grey
│               62%                │        (OB-050 corners, OB-041 rev 3 win rate)
│ [•¹][♟²][♞³][♝⁴][♜⁵][♛⁶][♚⁷]     │ 52 dp  PersonaRow, amber = selected (OB-023)
│ ┌ • SUGGESTION ─────────────────┐ │ ≥ 88   SuggestionCard (takes the slack)
│ │        E2 ➔ E4  (48 sp green)│ │
│ │ EVAL +0.4 • DEPTH 16 • 850k  │ │
│ └──────────────────────────────┘ │
│┌── board tray, 4 dp padding ────┐│ board + 12 dp (4 + 4 padding, 4 side face)
││ tap board, unchanged           ││ user's side at the bottom, edge labels
│└────────────────────────────────┘│
│ [ [✓] I PLAYED IT       (green)] │ 52 dp  StatusLine: 4 dp gap + 48 dp key
└──────────────────────────────────┘
```
- Fixed heights subtracted by `boardSizeFor`: 48 + 52 + 88 + 12 + 52 = 252 dp. Cell = `min((W − 8) / files, (H − 252) / ranks)`; the 8 dp is the tray's side padding. Chess at 360 dp: 44 dp cells (≥ 44 ✔); at ≥ 392 dp: ≥ 48 ✔. Height-limited boards keep their earlier size.
- Top bar: corner keys neutral, ≤ 30 % width. Centre is two lines: caption (`secondary`) `WIN RATE` / `YOU MATE IN` / `OPPONENT MATES IN`, value (`winRate`, 24 sp) `62%` / `4` / `--`; green when favourable (rounded win ≥ 50 % or the user mates), red otherwise, `textSecondary` with no suggestion; `GAME OVER` single line. Scales down at text scale 2.0.
- Suggestion card: outer padding 8 dp sides / 4 dp top-bottom; `• SUGGESTION` caption (green dot) in the ready and thinking states; move in `accentGreen`; expert line separated by ` • `.
- Board tray: neutral surface block (`surfaceDark` / `surfaceSide` / highlight), not pressable, 4 dp padding all round, no accent frame. Full width when the board is width-limited.
- Status line: the single full-width key carries the turn status (OB-041 table: `WAITING FOR OPPONENT`, `PICK A LEVEL ABOVE`, I PLAYED IT, `NEW GAME`). I PLAYED IT = green block with a 24 dp `bgDark` check chip (18 dp white check) + label in `bgDark`. UNDO lives in the top bar.
- Earlier layouts (card / persona / board / status with `YOUR MOVE [UNDO]`, 2026-10-02; 35 / 10 / 55 % keypad split) are superseded.

## Tap board (OB-006)
- Pieces as monochrome pictograms from bundled vector assets; no letters.
- Square states: normal, dimmed (`keyDisabled`, not tappable), selected/candidate (`accentActive`), suggested move (`accentGreen`), king in check (`accentRed`). Implemented (OB-006): selected and check = filled square; candidate and suggested = 3 dp outline, so the piece stays readable.
- Light/dark squares = `keyNormal` / `surfaceDark`. Pieces: Cburnett set (BSD); black pieces use a `textSecondary` outline for contrast on the dark board.
- No piece animation or drag; state changes are instant.

## Xiangqi board (OB-044)
- Intersection board: 9×10 square cells, each centred on a point (`IntersectionBoard`). Cell = min((W − 8) / 9, (H − 252) / 10) (the 8 dp is the board tray's side padding, OB-052 DS-7).
- One painted background on `surfaceDark`: 1 dp `textSecondary` lines; the 7 inner verticals break at the river, the edge verticals run through; palace X diagonals. No checkerboard, no 楚河漢界 text.
- Pieces: `keyNormal` disc (≈ 86 % of the cell) with Noto Serif TC glyphs (OFL, `assets/pieces/xiangqi/`). Red: glyph + rim `pieceRed`. Black: glyph `textPrimary`, rim `textSecondary`.
- Point states: selected = `accentActive` cell fill; check = `accentRed` cell fill; candidate = 12 dp amber dot (empty) or 3 dp amber ring (capture); suggested = green dot (empty) or green ring (piece); dimmed = piece at 40 % opacity, no fill.
- Labels `A`–`I` / `1`–`10` in the outer half-cell, in Red's frame; flipped when the user plays Black.
- **Exception (XQ3):** cells ≥ 40 dp at 360 dp width (≈ 35 dp at 360×640), below the 44 dp board rule. Mitigation: a tap snaps to the only target point within one cell; ties are ignored.

## Persona row (OB-023, revised OB-052 DS-7, OB-054)
- 7 equal isometric keys (48 dp incl. depth) in a 52 dp row; the same `PersonaTierKeys` on the advisor and the new-game screen. Unselected neutral block; selected `accentActive` block. No caption, no scale animation.
- Names (OB-054 D3): 1 NOOB / GÀ MỜ, 2 ROOKIE / TÂN BINH, 3 CHILL GUY / CHILL CHILL, 4 50/50 / HÊN XUI, 5 HUSTLER / CÁO GIÀ, 6 LOCAL BOSS / ÔNG TRÙM, 7 BIG BRAIN / CAO THỦ. Names, spoken forms and short descriptions live in `PersonaTierCopy`.
- One game-agnostic icon set (OB-054 D9, replaces the DS-7 piece pictograms): Material Icons `egg_alt`, `military_tech`, `local_cafe`, `balance`, `pets`, `business_center`, `psychology` (`PersonaTierIcon`), 24 dp, one colour: `textPrimary` on normal, `bgDark` on amber. Emoji are never rendered in the app.
- Number badge 1–7: 14 dp `bgDark` circle with a 10 sp w700 `textPrimary` digit, 2 dp inside the face's bottom-right corner. Icon and badge don't scale with text. Semantics label "Level 4 of 7, Fifty-fifty"; the description is a hint on the new-game keys only. In-game keys show icon + number only (OB-054 D5).
- All 7 tiers are always enabled and look the same (no gating in M1; the mockup's dimmed tiers 5–7 aren't adopted).

## Game identity accents (OB-052)
- One accent pair (face + side) per `GameKind`, from one mapping; adding a game without an accent must not compile.
- Used only on: that game's Home row icon block, new-game title (accent `display` text on `bgDark`), new-game hero slab, START GAME (accent block, `bgDark` text; no longer green).
- No accent lines: the header rail and board frame were removed at PO request (2026-10-05).
- Never on: board squares / points, pieces, win rate, suggestion text, status messages, selected keys (amber wins), I PLAYED IT (green).
- App-level chrome stays neutral: Home header and row faces, Settings / Language / discard dialogs, fair-play screen.
- **Future game accents (D9, approved, not in code until the game exists):** chosen to stay clear of green / red / amber status hues. `bgDark` text on all (≥ 6.9:1); white text not allowed.

| Game | Face | Side | Face vs `bgDark` |
|------|------|------|------------------|
| Shogi | `#E0BE85` (sand / wood) | `#9C7A45` | 10.7:1 |
| Go | `#4FC8DC` (cyan) | `#1F8798` | 9.6:1 |
| Othello | `#A68CF2` (violet) | `#6448B8` | 6.9:1 |
| Caro / Gomoku | `#AEB8CC` (slate) | `#6E7890` | 9.5:1 |

## Home (OB-049, OB-051, OB-052 DS-9, D9 — PO mockup 2026-10-05)
```text
[SETTINGS]        PICK A GAME        [LANGUAGE]   48  header, neutral text keys
┌ row: surfaceDark block ───────────────────────┐
│ [▣♔] CHESS                                 ›  │ ≥ 72 incl. depth
│      CLASSIC STRATEGY                         │
└───────────────────────────────────────────────┘
```
- Header `[SETTINGS] PICK A GAME [LANGUAGE]`, neutral text keys (no gear / flag icons).
- Padding 16 dp; content top-aligned under the header, scrolls. Rows with 8 dp gaps.
- **No Home hero** (OB-052 D10, removed 2026-10-05). The DS-9 hero spec in the ticket is kept as reference.
- **Game row** (one per `GameKind.values`): pressable `surfaceDark` / `surfaceSide` block with highlight, radius 4, ≥ 72 dp incl. depth, padding 12 / 10 dp. Content: 48 dp accent `AppBlock` icon (game accent pair, 32 dp `sidePictogram`, fixed size) · 12 dp · name (`primary`, `textPrimary`, upper case, one line scale-down) over tagline (`secondary`, `textSecondary` 5.3:1, ≤ 2 lines) · 8 dp · 24 dp `chevron_right` in `textSecondary`. Taglines are per-game data: `CLASSIC STRATEGY`, `CHINESE CHESS`.
- Rows aren't `keyNormal`: `textSecondary` on `keyNormal` is 4.4:1 (fails 12 sp).
- Semantics: one button per row, "Chess, classic strategy"; icon and chevron excluded. Tap opens that game's new-game screen (unchanged).
- Not on Home: count pill, coming-soon / download rows (download row states are a proposal for OB-015, see OB-052 DS-9).

## New game screen (OB-052 DS-8, D7 — PO mockup 2026-10-05)
```text
[‹ BACK]                     [FAIR PLAY]   48  header (middle empty)
   ◇ isometric accent slab, 2 pieces ◇     min(25 % H, 200), optional
 PLAYING                                   16  secondary w700, textSecondary
 CHESS                                     40  display 32 sp, game accent
┌ surfaceDark panel, radius 6, pad 8 ────┐
│ 01  LEVEL                              │  section header (static, OB-054)
│ [◯¹][✪²][☕³][▓⚖⁴▓][✿⁵][▣⁶][✺⁷]        │  48  PersonaTierKeys, amber = selected
│ ┌ level card, bgDark well ───────────┐ │
│ │ ⚖ 50/50             ■■■■□□□        │ │  icon · name · strength bar
│ │ Keeps it 50/50: eases up when …    │ │  short description, wraps
│ └────────────────────────────────────┘ │
│ 02  YOUR SIDE                          │
│ [♔ WHITE ◉ FIRST MOVE][♚ BLACK ○ SECOND MOVE]  60  side cards
└────────────────────────────────────────┘
[       START GAME  [›]       ]            48  accent block, pinned
  YOU CAN CHANGE THE LEVEL WHILE PLAYING     pinned helper
```
- Screen padding 8 dp sides, 16 dp top / bottom. Header and bottom block are fixed; hero, title and panel scroll. START GAME is always visible.
- **Hero:** static `CustomPainter`: 2:1 isometric slab, top face game accent, side faces game side colour (0.1 × width deep); Chess = 4 × 4 checker, Xiangqi = intersection grid with a river gap; two upright `sidePictogram` pieces (kings / 帥 將). Solid fills only, **no glow**, no animation, no semantics. **Shown only at ≥ 700 dp body height and text scale ≤ 1.3**; height `min(0.25 × H, 200)`. Hidden on 360 × 640 / 360 × 600.
- Title: `PLAYING` caption + upper-case game label in `AppTypography.display`, accent colour; semantics header "New game, Chess".
- Panel: non-pressable `surfaceDark` / `surfaceSide` block, highlight, radius 6 dp. Section headers `01` / `02` (`secondary`, `textSecondary`) + title (`primary`). No level pill, no divider lines.
- Level card (OB-054, `LevelCard`): non-pressable `bgDark` well, radius 4, padding 8, 8 dp under the keys. Icon 24 dp + upper-case name (`primary`, scale-down, one line) and a 7-segment bar (10 × 6 dp, filled `textPrimary`, empty `keyNormal`) in a `Wrap`; short description below (`secondary`, line height 1.4, wraps, no ellipsis). Height fixed to the longest of the 7 descriptions; excluded from semantics. Spec: `docs/design/OB-054-level-descriptions-design.md`.
- Side cards: `AppKey`, ≥ 60 dp incl. depth; 32 dp side pictogram + label + sub-label `FIRST MOVE` / `SECOND MOVE` (from `PlayerSide`); text `textPrimary` on normal, `bgDark` on amber. 12 dp radio dot top-right (ring `textSecondary`; selected: `bgDark` ring + dot). Selected = amber block, never an accent outline (D6). Semantics "White, first move".
- START GAME: game accent block, `bgDark` label + 24 dp `bgDark` arrow chip (`chevron_right` 18 dp white), like I PLAYED IT's check chip.
- Xiangqi: same layout in blue; side cards RED / BLACK with 帥 / 將 discs.

## Languages (OB-053)
- English and Vietnamese. All UI copy, visible and spoken, lives in `AppStrings` (`lib/core/l10n/`); widgets read `AppStrings.of(context)`, never literals. Persona copy: `PersonaTierCopy`; fair-play notice: `FairPlayNoticeText`.
- Vietnamese labels are upper case like English and often longer: keep one-line labels in a scale-down `FittedBox`, check 360 × 640 × 2.0 with diacritics unclipped.
- Never translated: app name, move coordinates and marks, the engine expert line, Xiangqi characters, license texts.

## Motion and haptics
- Animations are minimal and cheap (`flutter_animate`): number/color transitions on the suggestion only.
- **Press-sink (OB-052)** is the only UI-chrome motion: on pointer down the pressed key's face moves down 4 dp over 80 ms `easeOut`, and returns the same way on release / cancel. The action fires on tap up without waiting. Reduce motion → instant. Only the pressed key's paint moves. No entry, idle or celebration animation; boards have no motion.
- Haptics through Flutter's built-in `HapticFeedback` (OB-006, OB-007):
  - selecting tap / key tap (board selection, persona, UNDO): `selectionClick()`
  - move accepted (move committed): `lightImpact()` (OB-006)
  - engine move ready: `mediumImpact()`
  - in check: `heavyImpact()` ("urgent threat" beyond check is undefined; treated as check-only, OB-007 Q1)
