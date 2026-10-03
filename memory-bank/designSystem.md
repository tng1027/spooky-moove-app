# Design System — Industrial Utility / Terminal Neo-Brutalism

Source: UI/UX + library consultation (2026-10-02). Applies to every screen.

## Why this style
- The app is a calculation/tactics tool used while looking at a physical board. Speed and glanceability beat decoration.
- **Rejected:** Neumorphism, Glassmorphism, colorful/flashy styles. They distract and cost GPU (blur, layered shadows).
- **Inspiration:** professional instruments: DGT electronic chess clocks, military devices, Bloomberg terminal.

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

Color carries meaning (green = good, red = danger, amber = selected). Don't use accents decoratively.

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

## Shape and touch targets
- Clear geometric blocks, very small corner radius: **4–6 px**.
- Key height **48–56 dp minimum**, so a thumb can hit keys without looking closely.
- **Exception — tap board squares:** ≥ 44 dp (8×8 on a 360 dp-wide screen); ≥ 48 dp on screens ≥ 392 dp wide. Other keys (promotion chooser, UNDO, persona row) keep the 48 dp minimum (OB-006 BR-005).
- No shadows, gradients or blur.

## Screen layout (portrait) — revised 2026-10-02 for the tap board (OB-006 BR-006)
```text
┌──────────────────────────────┐
│  SUGGESTION CARD      ~25%   │   E7 ➔ E5   (40–48 sp, accentGreen)
│                              │   WIN 62%
│                              │   EVAL +0.4 | DEPTH 16 | 850k nps (small)
├──────────────────────────────┤
│  PERSONA ROW          52 dp  │   🥚 🐣 🐥 🥉 🥈 🥇 👑 (OB-023)
├──────────────────────────────┤
│  TAP BOARD   full-width sq.  │   user's side at the bottom,
│                              │   pictograms, edge labels A–H / 1–8
├──────────────────────────────┤
│  STATUS LINE  YOUR MOVE [UNDO]│  turn status + UNDO key (OB-025, OB-012)
└──────────────────────────────┘
```
Replaces the earlier 35% card / 10% status / 55% keypad split.

## Tap board (OB-006)
- Pieces as monochrome pictograms from bundled vector assets; no letters.
- Square states: normal, dimmed (`keyDisabled`, not tappable), selected/candidate (`accentActive`), suggested move (`accentGreen`), king in check (`accentRed`). Implemented (OB-006): selected and check = filled square; candidate and suggested = 3 dp outline, so the piece stays readable.
- Light/dark squares = `keyNormal` / `surfaceDark`. Pieces: Cburnett set (BSD); black pieces use a `textSecondary` outline for contrast on the dark board.
- No piece animation or drag; state changes are instant.

## Xiangqi board (OB-044)
- Intersection board: 9×10 square cells, each centred on a point (`IntersectionBoard`). Cell = min(W / 9, (H − 252) / 10).
- One painted background on `surfaceDark`: 1 dp `textSecondary` lines; the 7 inner verticals break at the river, the edge verticals run through; palace X diagonals. No checkerboard, no 楚河漢界 text.
- Pieces: `keyNormal` disc (≈ 86 % of the cell) with Noto Serif TC glyphs (OFL, `assets/pieces/xiangqi/`). Red: glyph + rim `pieceRed`. Black: glyph `textPrimary`, rim `textSecondary`.
- Point states: selected = `accentActive` cell fill; check = `accentRed` cell fill; candidate = 12 dp amber dot (empty) or 3 dp amber ring (capture); suggested = green dot (empty) or green ring (piece); dimmed = piece at 40 % opacity, no fill.
- Labels `A`–`I` / `1`–`10` in the outer half-cell, in Red's frame; flipped when the user plays Black.
- **Exception (XQ3):** cells ≥ 40 dp at 360 dp width (≈ 35 dp at 360×640), below the 44 dp board rule. Mitigation: a tap snaps to the only target point within one cell; ties are ignored.

## Persona row (OB-023)
- 7 equal keys, 52 dp high, emoji 20–22 sp. Unselected `keyNormal`; selected `accentActive`. No caption, no scale animation.

## Motion and haptics
- Animations are minimal and cheap (`flutter_animate`): number/color transitions on the suggestion only. No decorative motion.
- Haptics through Flutter's built-in `HapticFeedback` (OB-006, OB-007):
  - selecting tap / key tap (board selection, persona, UNDO): `selectionClick()`
  - move accepted (move committed): `lightImpact()` (OB-006)
  - engine move ready: `mediumImpact()`
  - in check: `heavyImpact()` ("urgent threat" beyond check is undefined; treated as check-only, OB-007 Q1)
