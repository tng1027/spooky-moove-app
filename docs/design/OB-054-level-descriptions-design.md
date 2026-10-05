# OB-054 — Level names, descriptions and icons: design spec

Design pass 2026-10-05 (Product / UI). Follows `memory-bank/designSystem.md` (Gamified Isometric, OB-052) and OB-053 (EN / VI). Reconciled with the BA ticket `tickets/OB-054-persona-level-descriptions.md`, and updated with the PO answers of 2026-10-05 (Q1–Q6, section 15). The BA's Current Behavior table is the **accuracy source of truth** for every description. Where this spec and the BA flow differ, section 14 says which one the developer follows.

## 1. Context

- The level is picked on the **new-game screen** (`NewGameScreen._panel`, section `01`) and changed mid-game on the **advisor** (`PersonaRow`). Both use the shared `PersonaTierKeys`: 7 equal icon-only keys (pictogram + 1–7 badge), 48 dp incl. depth. Nowhere on screen do they say what a level does. The only text is the heading `LEVEL · EVEN`.
- The persona changes **only the move suggested to the user**. The app never plays an opponent (`productContext.md`). Descriptions therefore say what the **suggestions** do for the user, and "you / bạn" always means the app user (BA BR-002, PO Q1).
- Space: the new-game scroll content uses 282 dp of a 452 dp viewport at 360 × 640 (OB-052 DS-8 budget), so ≈ 170 dp is free at text scale 1.0. The advisor has **no free height**: 252 dp of fixed rows decide the board cell size (`boardSizeFor`).
- **Names (PO-approved, Q3 / Q4):** `NOOB` / `GÀ MỜ`, `ROOKIE` / `TÂN BINH`, `CHILL GUY` / `CHILL CHILL`, `50/50` / `HÊN XUI`, `HUSTLER` / `CÁO GIÀ`, `LOCAL BOSS` / `ÔNG TRÙM`, `BIG BRAIN` / `CAO THỦ`. They replace `PersonaTier.label` (Baby … God) and the OB-053 D3 Vietnamese names. `CAO THỦ` is tier 7 only. `PersonaTier` enum identifiers (`baby` … `god`) stay as they are, so test keys don't change.

## 2. Options considered

| Option | Verdict |
|---|---|
| A. **Level card under the picker**: one inset card in the level section showing the selected level's icon, name, a strength bar and a description | **Chosen** |
| B. Expandable / list rows: 7 full-width rows (name + description), selected one expanded | Rejected |
| C. Info `i` key next to `01 LEVEL` that opens an `AppDialog` listing all 7 | Rejected |

Why A:
- **Picking a key is the preview.** Selecting a level is free and can be undone with one tap, and the card updates at once. A user can tap 1 → 7 and read each description in place, with no extra step or dialog to dismiss.
- **Reuses everything:** `PersonaTierKeys` stays shared with the advisor, the panel layout stays the same, and there are no new interactive components. The card is a plain, non-interactive area made from existing tokens.
- **Fits the budget:** about +100 dp at scale 1.0 still fits 360 × 600 without scrolling. At 2.0 the content scrolls, but START GAME stays pinned and the defaults are valid.
- B would replace the shared key row with about 340 dp of rows on one screen only. That gives two level pickers to maintain, pushes `02 YOUR SIDE` below the fold at every scale, and conflicts with DS-8 (D7: level keys = shared `PersonaTierKeys`).
- C hides the information behind a tap that most users won't find. Seven descriptions in a dialog make a long scrolling list at scale 2.0, and comparing levels gains little when tapping a key previews it anyway.

## 3. Placement

- **New-game screen (only place with names and descriptions, PO Q5):** inside the existing panel, directly below the level keys: heading → keys → **level card** → `02 YOUR SIDE`. It is always visible, because the screen always has a selection (default level 4).
- **Advisor screen:** the level keys show **icon + number badge only**, with no visible name or description and no description hint for screen readers (PO Q5). Screen readers still hear the level name in the key label (section 9). The board budget is unchanged. The helper `YOU CAN CHANGE THE LEVEL WHILE PLAYING` already tells users the advisor row is the same picker.
- No tooltip or long-press. Hidden gestures conflict with the "glanceable" rule.

## 4. Wireframes

Key-row legend (Material Icons proposal, section 6): `◯` egg, `✪` medal, `☕` cup, `⚖` scales, `✿` paw, `▣` briefcase, `✺` brain; `▓▓` = amber selected key; superscript = number badge.

360 dp, text scale 1.0, Chess, EN (hero hidden below 700 dp body height):

```text
|<──────────────────── 360 dp ────────────────────>|
 [‹ BACK]                            [FAIR PLAY]     48  header
 PLAYING                                             16
 CHESS                                               40  display, accentChess
┌─ panel  surfaceDark / surfaceSide, r 6, pad 8 ──┐
│ 01  LEVEL                                       │  21  section header
│ [ ◯¹][ ✪²][ ☕³][▓▓⚖⁴▓▓][ ✿⁵][ ▣⁶][ ✺⁷]          │  48  PersonaTierKeys (amber = 4)
│                                                 │   8
│ ┌─ level card  bgDark well, r 4, pad 8 ───────┐ │
│ │ ⚖ 50/50                      ■ ■ ■ ■ □ □ □  │ │  24  icon · name · strength bar
│ │                                             │ │   4
│ │ Keeps it 50/50: eases up when you lead,     │ │
│ │ brings its best when you fall behind.       │ │  ≤ 3 × 17  description
│ └─────────────────────────────────────────────┘ │
│                                                 │  16
│ 02  YOUR SIDE                                   │  21
│ [♔ WHITE        ◉][♚ BLACK        ○]            │  60  side cards
└─────────────────────────────────────────────────┘
 [            START GAME  [›]            ]           48  pinned, accent block
     YOU CAN CHANGE THE LEVEL WHILE PLAYING                pinned helper
```

Same screen in Vietnamese:

```text
│ 01  CẤP ĐỘ                                      │
│ [ ◯¹][ ✪²][ ☕³][▓▓⚖⁴▓▓][ ✿⁵][ ▣⁶][ ✺⁷]          │
│ ┌─────────────────────────────────────────────┐ │
│ │ ⚖ HÊN XUI                    ■ ■ ■ ■ □ □ □  │ │
│ │ Giữ ván sát nút: bạn dẫn thì nương tay, bạn │ │
│ │ bị dẫn thì gợi ý nước tốt nhất.             │ │
│ └─────────────────────────────────────────────┘ │
```

320 dp at text scale 2.0 (VI, level 3): the strength bar wraps under the name, and the description wraps:

```text
│ ┌──────────────────────────────┐ │
│ │ ☕ CHILL CHILL               │ │  icon + name, one line, name scales down if needed
│ │ ■ ■ ■ □ □ □ □                │ │  bar wrapped (fixed size)
│ │ Gợi ý nước chắc,             │ │
│ │ nhẹ tay một chút.            │ │
│ │ Cà phê, cờ nhẹ,              │ │
│ │ không cay cú.                │ │
│ └──────────────────────────────┘ │
```

Advisor (unchanged layout, icons only):

```text
│ [ ◯¹][ ✪²][ ☕³][▓▓⚖⁴▓▓][ ✿⁵][ ▣⁶][ ✺⁷]           │  52  PersonaRow, no text
```

## 5. Component anatomy: level card (`_LevelCard`, local to `new_game_screen.dart`)

The card shows information only: no `onTap`, no side face, no press-sink. It is a **recessed well** rather than a raised block, so it doesn't look like a key (raised = pressable in this design language) and it reads like a clock display, which suits the terminal heritage.

| Part | Spec (existing tokens only) |
|---|---|
| Container | `Container`, fill `AppColors.bgDark`, radius `AppDimens.radius` (4), padding `AppDimens.spacing` (8) all round, full panel width. No border, highlight, `blockDepth`, shadow or gradient. |
| Gap above card | `AppDimens.spacing` (8) below the key row. The gap below the card to `02` stays `AppDimens.spacingLarge` (16). |
| Name line | `Wrap(spacing: AppDimens.spacing, runSpacing: AppDimens.spacingSmall, crossAxisAlignment: center, alignment: spaceBetween)` with two children: **icon + name** and **strength bar**. When both fit (360 dp at 1.0, VI and EN) the bar sits at the right end; otherwise it wraps below. |
| Icon | The level's icon (section 6), 24 dp, `AppColors.textPrimary`, fixed size (doesn't scale with text), excluded from semantics. `AppDimens.spacing` (8) gap before the name. The same glyph as on the selected key, so the card visibly belongs to that key. |
| Name | Upper case, `AppTypography.primary` (16 sp w700), `AppColors.textPrimary` (19:1 on `bgDark`). One line in `FittedBox(fit: BoxFit.scaleDown, alignment: centerLeft)`; it never wraps or ellipsizes. |
| Strength bar | 7 segments, each 10 × 6 dp, gap `AppDimens.spacingSmall` (4), total 94 dp, fixed size, square corners. Filled segments (`1…level`) are `AppColors.textPrimary`; empty segments are `AppColors.keyNormal`. The filled/empty contrast is ≈ 13:1, and the empty-on-well contrast is decorative because the count is also in semantics. Now that the icons follow the names, the bar carries the strength progression. |
| Gap | `AppDimens.spacingSmall` (4) between the name line and the description. |
| Description | Sentence case (body text, not a label), `AppTypography.secondary.copyWith(height: 1.4)` (12 sp w400; the 1.4 line height keeps stacked Vietnamese diacritics such as Ệ / Ỗ from clipping between lines). Colour `AppColors.textSecondary` (6.2:1 on `bgDark`, AA). It wraps freely: no `maxLines`, no ellipsis, no `FittedBox`. |
| Stable height | The card is as tall as the **tallest of the 7 descriptions** at the current width and text scale, so `02 YOUR SIDE` doesn't jump when the level changes. Build it as a `Stack` of all 7 description `Text`s: the selected one visible, the rest `Visibility(visible: false, maintainSize: true, maintainAnimation: true, maintainState: true)` inside `ExcludeSemantics`. |

**Section header change:** `01  LEVEL · EVEN` becomes `01  LEVEL` (VI `01  CẤP ĐỘ`), because the name now appears in the card and would otherwise show twice. The header's spoken label still carries the name ("Level, Fifty-fifty").

**Strength-bar colour rationale:** green/red mean good/danger and amber means the selected key, so none of them can label a strength. Game accents are only for game identity, and white-on-dark fits the neutral chrome.

**Level 4:** it uses the same bar (4/7) with no "mode" chip. It is not adaptive to the user's skill (PO Q2): it picks moves from the current position to keep the user's win chance near 50 %.

**`50/50` vs the win rate:** names appear only on the new-game screen, where no win rate is shown, so `50/50` never sits next to `WIN nn%` (BA edge case).

## 6. Level icons (proposal for PO approval)

Today's keys use one-colour Cburnett piece silhouettes (dot, pawn … king; OB-052 DS-7), chosen as a generic strength progression when the names were Baby … God. The approved names now have personalities, so the PO asked for an icon per name.

### Options

| | Keep piece pictograms | **Material Icons by name** | Colour emoji |
|---|---|---|---|
| iOS / Android consistency | Same everywhere (bundled SVG) | Same everywhere (font bundled by Flutter) | **Differs**: Apple vs Noto art; JetBrains Mono has no emoji glyphs, so each platform falls back to its own font, and the size and baseline vary |
| Design system | Matches DS-7 as built | One-colour, recolours to `textPrimary` / `bgDark` on amber like today; needs a DS-7 update in `designSystem.md` | Breaks it: fixed colours can't turn `bgDark` on amber, clash with status colours, and BR-007 / DS-7 already removed emoji |
| Matches names / kids | Weak: a queen says nothing about "Local boss"; the levels read as abstract | Strong: egg, coffee, scales, brain read at a glance, even for non-chess users | Strongest and playful, but noisy in a dark utility UI |
| Accessibility | Fixed 24 dp, excluded from semantics; name in label | Same | Same, but some screen readers read emoji names if they aren't excluded |
| Licensing / deps | Cburnett (already bundled) | Material Icons, Apache-2.0, already shipped (`uses-material-design: true`); `const IconData` is tree-shaken; no new asset or package | Rendered by the OS font: no in-app licence. Apple emoji art can't be reused as standalone marketing art; use Noto Emoji (OFL) or Twemoji (CC-BY) for marketing |
| Cost | None | Small: `_TierPictogram` switches from SVG to `Icon`; badge, sizes and colours unchanged | Small code, high visual and QA cost |

**Recommendation: Material Icons by name** on all 7 keys (new-game and advisor) and in the level card. Use one icon family for all seven; don't mix in piece silhouettes, because two drawing styles in one 7-key row look accidental. The 1–7 badge and the card's strength bar keep the strength order readable. Emoji stay for PO, store and marketing communication only. Fallback if the PO prefers no change: keep the piece pictograms. The card then shows the piece glyph, and the rest of this spec is unaffected.

### Per level

All `Icons.*` constants were verified in the installed SDK (Flutter 3.47.6 stable, `packages/flutter/lib/src/material/icons.dart`). There is no `Icons.crown`, and there is no fox icon.

| Lv | Name EN / VI | Reference emoji | In-app icon (recommended) | Alternative | Why |
|---|---|---|---|---|---|
| 1 | NOOB / GÀ MỜ | 🐣 | `Icons.egg_alt` | `Icons.egg` | "Gà mờ" = a not-yet-hatched chick; an egg is the earliest stage |
| 2 | ROOKIE / TÂN BINH | 🪖 | `Icons.military_tech` | `Icons.school` | "Tân binh" = new recruit; the ribbon with a rank chevron reads as first rank |
| 3 | CHILL GUY / CHILL CHILL | 😎 | `Icons.local_cafe` | `Icons.self_improvement` | The PO's "casual fun over coffee"; "cà phê, cờ nhẹ" in the VI copy |
| 4 | 50/50 / HÊN XUI | ⚖️ | `Icons.balance` | `Icons.contrast` (half-filled circle) | Scales = keeps the game even. Avoid `Icons.casino` / 🎲 (gambling) |
| 5 | HUSTLER / CÁO GIÀ | 🦊 | `Icons.pets` (paw) | `Icons.theater_comedy` (masks) | Material has no fox, so the paw stands for the "old fox". This is the weakest match; the masks lean toward deception, so they're only the alternative |
| 6 | LOCAL BOSS / ÔNG TRÙM | 💼 | `Icons.business_center` (briefcase) | `Icons.workspace_premium` | The boss's briefcase: neutral, no crown or mob imagery |
| 7 | BIG BRAIN / CAO THỦ | 🧠 | `Icons.psychology` (head with gear) | `Icons.tips_and_updates` | Literal "big brain"; the strongest level |

Icon rendering spec:
- `Icon(icon, size: 24, color: isSelected ? AppColors.bgDark : AppColors.textPrimary)` in the existing 24 dp pictogram slot.
- Number badge (14 dp, bottom-right) unchanged. No scaling with text. Excluded from semantics (the key and card already exclude child semantics).
- Material icons are drawn on a 24 dp grid, so they render crisp at this size.
- Use filled (default) variants only, not `_outlined` / `_rounded`, so the set stays uniform.

## 7. States

| Element | Default | Selected | Pressed | Disabled |
|---|---|---|---|---|
| Tier key | `keyNormal` / `keyNormalSide`, `edgeHighlight`, `textPrimary` icon | `accentActive` / `accentActiveSide`, `bgDark` icon | face sinks `AppDimens.blockDepth` (4 dp) over `AppDimens.pressSinkDuration` (80 ms) `AppDimens.pressSinkCurve`; box unchanged; selection applies on tap up | Not used (all 7 always enabled, OB-052 D8). If gating ever returns: `keyDisabled`, lowered, no side, icon `textSecondary` |
| Level card | Shows the selected tier (level 4 on open) | Content swaps **instantly** when another key is selected | none (not pressable) | n/a |

The card never shows an empty state on the new-game screen, because the tier there is never null.

## 8. Length budget and text-scale behaviour

Measured with JetBrains Mono at about 0.6 em per character: 12 sp ≈ 7.2 dp per char, 16 sp ≈ 9.6 dp.

| Width | Card content width | Description chars / line at 1.0 | at 2.0 |
|---|---|---|---|
| 320 dp | 272 dp | ≈ 37 | ≈ 18 |
| 360 dp | 312 dp | ≈ 43 | ≈ 21 |
| 430 dp | 382 dp | ≈ 53 | ≈ 26 |

- **Name:** ≤ 12 characters (longest: EN `LOCAL BOSS` 10, VI `CHILL CHILL` 11). Icon (24 dp) + 8 dp + name on one line; the name scales down at large text scales instead of wrapping.
- **Description (on-screen):** ≤ **90 characters** in both EN and VI, which is **≤ 3 lines at 360 dp, scale 1.0** (word wrap may add a 4th line at 320 dp for 85–90-char strings; the stable-height rule absorbs it). Vietnamese tends to run longer, so check the VI string separately. All final and alternative strings in section 11 are 62–86 characters.
- Card height at 360 dp, scale 1.0: 8 + 24 + 4 + 3 × 17 + 8 ≈ **95 dp**, so the panel grows by about 103 dp. Scroll content is then ≈ 385 dp against viewports of 452 dp (360 × 640) and 412 dp (360 × 600): it **fits without scrolling**. 392 × 800 with the hero: 385 + 198 = 583 against 596, which fits.
- **Text scale 2.0, 360 × 640:** the bar wraps, giving ≈ 8 + 42 + 4 + 6 + 4 + 6 × 34 + 8 ≈ 276 dp, so the content scrolls by about 200 dp. START GAME and the helper stay pinned and visible, so a user can start with the defaults without scrolling. `02 YOUR SIDE` is reached by scrolling, which is accepted under the DS-8 rule (content scrolls, START GAME pinned). Nothing clips or overflows, and every key stays ≥ 48 dp.
- **Never** truncate a description with an ellipsis: a cut-off strength description misleads more than a longer card does.

## 9. Screen-reader labels

Upper-case visible names would be spelled out letter by letter, so each name has a spoken form (this follows the `NewGameScreen.spoken` / `semanticsLabel` pattern). The spoken text lives in the OB-053 string catalogue next to the visible text.

| Lv | Visible EN | Spoken EN | Visible VI | Spoken VI |
|---|---|---|---|---|
| 1 | `NOOB` | Noob | `GÀ MỜ` | Gà mờ |
| 2 | `ROOKIE` | Rookie | `TÂN BINH` | Tân binh |
| 3 | `CHILL GUY` | Chill guy | `CHILL CHILL` | Chill chill |
| 4 | `50/50` | Fifty-fifty | `HÊN XUI` | Hên xui |
| 5 | `HUSTLER` | Hustler | `CÁO GIÀ` | Cáo già |
| 6 | `LOCAL BOSS` | Local boss | `ÔNG TRÙM` | Ông trùm |
| 7 | `BIG BRAIN` | Big brain | `CAO THỦ` | Cao thủ |

`50/50` must have its spoken override, or VoiceOver says "fifty slash fifty".

- **Tier key, both screens:** one node, `button`, `selected`, label EN `Level 4 of 7, Fifty-fifty` / VI `Cấp 4 trên 7, Hên xui`. The icon is excluded.
- **Tier key, new-game screen only:** hint = the on-screen description (section 11), read after the label on focus.
- **Tier key, advisor:** **no hint** (PO Q5). `PersonaTierKeys` takes the hint as an optional input (e.g. a nullable `hintOf` callback): the new-game screen passes the descriptions, and `PersonaRow` passes nothing.
- **Section header** `01`: `header: true`, label EN `Level, Fifty-fifty` / VI `Cấp độ, Hên xui`.
- **Level card:** `ExcludeSemantics`. It mirrors the selected key's label and hint, so reading it again would duplicate the information.
- No `liveRegion`: iOS ignores it, and a selection change is already announced by the key's selected state.

## 10. Keys / test IDs

| Element | Key |
|---|---|
| Tier keys (unchanged) | `newGame.tier.<tier.name>` (`NewGameScreen.tierKey`), `personaRow.<tier.name>` (`PersonaRow.tierKey`) |
| Level card | `NewGameScreen.levelCardKey` = `Key('newGame.levelCard')` |
| Icon | `NewGameScreen.levelIconKey` = `Key('newGame.levelCard.icon')` |
| Name text | `NewGameScreen.levelNameKey` = `Key('newGame.levelCard.name')` |
| Strength bar | `NewGameScreen.levelBarKey` = `Key('newGame.levelCard.bar')` |
| Visible description | `NewGameScreen.levelDescriptionKey` = `Key('newGame.levelCard.description')` (only on the visible text; the hidden height-sizers have no key) |

Widget-test checks:
- Each tap on a tier swaps the icon, name and description.
- The card height is constant across all 7 tiers.
- 320 × 568 and 360 × 640 at text scale 2.0 in EN and VI: no overflow, START GAME visible.
- New-game keys: the semantics label and hint per tier match the catalogue. Advisor keys: label only, with an empty hint.

## 11. Copy

The rules (PO Q1, Q2, Q6; BA BR-001…BR-006):
- Say what the **suggestions** do.
- Be punchy, playful and family-friendly, with light slang in moderation.
- Fit each name's personality.
- Make no absolute strength claims, no gambling or cheating tone, and no age-targeting beyond "kids" / "bé".
- Write the Vietnamese natively, not as a translation.
- Stay within 90 characters.

Facts each line must stay true to (BA Current Behavior):
- Lv 1 suggests the weakest moves.
- Lv 2 suggests clearly weaker moves.
- Lv 3 suggests slightly softer moves.
- Lv 4 keeps the user's win chance near 50 % (eases up when ahead, best move when behind).
- Lv 5 / 6 suggest the best move with a short / deeper look ahead.
- Lv 7 uses the full thinking time and is the app's strongest level.

### Final on-screen copy (recommended)

| Lv | Name | EN (chars) | VI (chars) |
|---|---|---|---|
| 1 | NOOB / GÀ MỜ | Suggests comically bad moves that gift pieces away. Perfect for letting kids win. (81) | Gợi ý toàn nước "tấu hài", thả quân biếu không. Nhường bé thắng là chuẩn bài! (77) |
| 2 | ROOKIE / TÂN BINH | Knows the rules, still learning. Suggests clearly weaker moves for easy games. (78) | Biết luật nhưng còn non: gợi ý nước yếu thấy rõ. Chơi nhẹ nhàng với người mới. (78) |
| 3 | CHILL GUY / CHILL CHILL | Solid, laid-back moves, a notch below its best. Grab a coffee and enjoy. (72) | Gợi ý nước chắc, nhẹ tay một chút. Cà phê, cờ nhẹ, không cay cú. (64) |
| 4 | 50/50 / HÊN XUI | Keeps it 50/50: eases up when you lead, brings its best when you fall behind. (77) | Giữ ván sát nút: bạn dẫn thì nương tay, bạn bị dẫn thì gợi ý nước tốt nhất. (75) |
| 5 | HUSTLER / CÁO GIÀ | Quick and crafty: the best move it sees on a short look ahead. Slip up and it pounces. (86) | Lanh lẹ, mắt tinh: gợi ý nước mạnh nhất trong tầm ngắn. Sơ hở là bị bắt bài. (76) |
| 6 | LOCAL BOSS / ÔNG TRÙM | Thinks deeper, hits harder. Solid in attack and defence, hard to catch out. (75) | Tính sâu hơn, đánh lì hơn. Công thủ toàn diện, khó mà bắt lỗi. (62) |
| 7 | BIG BRAIN / CAO THỦ | Full thinking time for the strongest move the app can find. Our toughest level. (79) | Dùng trọn thời gian suy nghĩ, gợi ý nước mạnh nhất app tìm được. Cấp mạnh nhất! (79) |

### Alternatives (one per level)

| Lv | EN (chars) | VI (chars) |
|---|---|---|
| 1 | Clumsy on purpose: gives pieces away so kids and beginners get the win. (71) | Gợi ý hớ đâu hớ đó, quân cứ thế mà biếu. Để bé và người mới thắng lấy hên. (74) |
| 2 | Eager but green: suggests clearly weaker moves. Great for learning together. (76) | Lính mới tò te: gợi ý nước còn hớ nhiều. Hợp vừa chơi vừa tập với người mới. (76) |
| 3 | Easygoing moves with a light handicap. Relaxed games, no stress. (64) | Nước cơ bản, nương tay chút đỉnh. Đánh cho vui, giao lưu là chính! (66) |
| 4 | Keeps it close: softer when you're ahead, full effort when you're behind. (73) | Cân não 50/50: bạn hơn thì nhẹ tay lại, bạn đuối thì tung nước tốt nhất. (72) |
| 5 | Street-smart and fast: strong moves on a short look ahead. Loose moves get punished. (84) | Tính nhanh, ra đòn gọn: nước mạnh nhất nó thấy. Hớ một nhịp là bị tóm ngay. (75) |
| 6 | Runs the block: the best move it sees with a deeper look ahead. Tough to crack. (79) | Trùm khu phố: gợi ý nước mạnh với tầm tính sâu. Công thủ chắc, khó bắt bài. (75) |
| 7 | Brain on max: uses all its thinking time to find the strongest move it can. (75) | Vắt óc hết cỡ: tìm nước mạnh nhất app có thể. Cấp cao nhất của app. (67) |

Character counts are Unicode characters (NFC), measured 2026-10-05.

Copy notes:
- **"Thả quân biếu không", "tấu hài", "chuẩn bài", "bắt bài", "lì", "tò te":** light slang, at most one or two per line (PO Q1, "in moderation").
- **"kèo" avoided** in level 4: it comes from betting odds. The draft "Giữ kèo sát nút" became "Giữ ván sát nút" (BR-004).
- **Lv 5 "crafty / pounces / bắt bài":** personality, not a trap-setting claim. The level plays the best move it sees, which naturally punishes loose moves.
- **Lv 6 vs 7:** only relative wording ("deeper", "full thinking time", "toughest / mạnh nhất" = the app's own strongest). No depth numbers, ratings or "flawless" (BR-003). Review after OB-010 measures depth: if levels 6 and 7 suggest the same moves on most devices, soften "hits harder".
- **Banned-terms check (OB-034 / BA BR-004):** no cheat, hack, bot, God, flawless, absolute, zero mistakes, `cờ độ`, `cá cược`, toddler in any final or alternative line.
- BA full texts (Proposed copy table in the BA ticket) remain the factual reference; the BA ticket's copy table should be updated to these on-screen strings once the PO picks (REQ-006).

## 12. Motion and haptics

- Tier keys: press-sink only (4 dp, 80 ms `easeOut`, back on release/cancel; reduce motion = instant) and `HapticFeedback.selectionClick()` on change. Both are unchanged.
- Level card: **no animation.** Icon, name, bar and description swap instantly when the selection changes (the design system allows no entry or cross-fade motion in chrome). The stable height means nothing below moves.

## 13. Out of scope

- Any visible name or description on the advisor, and descriptions in advisor screen-reader hints (PO Q5).
- The info dialog (option C), tooltips, long-press.
- Tier gating / disabled tiers, new third-party art, new tokens, new packages, colour emoji in the app.
- Any change to tier behaviour; no adaptive mode (PO Q2).

## 14. Ticket alignment (BA OB-054)

Where the BA ticket and this spec differ, **the developer follows this design spec** for layout, icons and semantics. The BA ticket stays the source of truth for the meaning of the copy.

| Topic | BA ticket | This spec | Status |
|---|---|---|---|
| Heading | REQ-002, User Flow and AC 1–2: `LEVEL · 50/50` / `CẤP ĐỘ · HÊN XUI`, the heading changes with the selection | `01  LEVEL` / `01  CẤP ĐỘ`, static; the name moves into the level card. The spoken header keeps the name | **Overrides the BA flow.** The BA should reword REQ-002 / AC to "the level card shows…" |
| Advisor | REQ-004 per Q5 | Icon-only keys, label = level number + name, no description hint | Aligned with PO Q5 |
| Description copy | Full BA text | Rewritten on-screen copy ≤ 90 chars (section 11), same facts | BA updates its copy table after the PO picks (REQ-006) |
| Level 4 | Not adaptive; position-based 50/50 | Same | Aligned (PO Q2) |
| Semantics | Label = number + name + selected, hint = description (REQ-005) | Same on new-game; advisor without hint | Aligned (PO Q5) |
| Icons | "No new pictograms" (Out of Scope, A-5) | Material Icons per name (section 6) | **New, requested by the PO after the BA draft.** Pending PO approval of the icon option; updates OB-052 DS-7 and `designSystem.md` (persona row) if approved |
| Longest-case mocks | VI level 4; `CHILL CHILL` / `LOCAL BOSS` / `BIG BRAIN` / `ÔNG TRÙM` | Section 4 (VI level 4, `CHILL CHILL` at 320 × 2.0). Every name is ≤ 11 chars, on the card's name line, not in the heading | Aligned |
| Null tier in-game | No description, prompt unchanged | No card on the advisor | Aligned |

## 15. PO decisions (2026-10-05)

| Q | Decision | Effect on this spec |
|---|---|---|
| Q1 | Descriptions say what the suggestions do; slang OK in moderation | Section 11 copy rules |
| Q2 | Accurate level-4 copy (keeps the game close to 50/50); no adaptive mode | No "adaptive" wording; bar 4/7, no mode chip |
| Q3 | New names replace Baby … God and the OB-053 D3 VI names | `CAO THỦ` = tier 7 only; no duplicate name |
| Q4 | All names kept as approved | Names final; no name alternatives |
| Q5 | Descriptions on the new-game screen only; advisor keys icon-only | No advisor hint; advisor label = level number + name |
| Q6 | Better short copy | Section 11: final pick + 1 alternative per level, EN + VI |
| Open | Icon option (section 6) and the final copy pick per level | PO picks; then the BA updates the copy table and `designSystem.md` DS-7 is revised if icons change |

Strings live in the OB-053 typed catalogue (name, spoken name, on-screen description per `PersonaTier`, exhaustive `switch`), and the icon mapping lives next to the tier pictogram mapping (exhaustive `switch` on `PersonaTier`), so a missing entry fails at compile time.
