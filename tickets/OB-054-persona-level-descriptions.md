# Ticket Analysis

> **Status: Ready for development (PO 2026-10-05). Priority P1, part of the M1 store release (tier names and copy ship with OB-053 and close the OB-034 tier-7 item).** All questions answered (Decisions D1–D9): short on-screen copy approved (D8), icon set approved (D9). The design spec `docs/design/OB-054-level-descriptions-design.md` is the **source of truth for layout and semantics**; the approved copy and icons are recorded in this ticket.
>
> Previous status: Ready for design finalization (2026-10-05, Q7 open); before that Draft (Q1–Q6 open).

TICKET_TYPE: ENHANCEMENT
CONFIDENCE: HIGH

The 7 persona tiers already exist (OB-021, OB-022, OB-023) with English names (`Baby` … `God`) and planned Vietnamese names (OB-053 D3). The request renames them, adds a description per tier and (PO 2026-10-05) a per-level icon. Nothing new is computed, so this is an enhancement, not a new feature. It is not a bug: no rule says descriptions must exist today. Not a duplicate: OB-053 translates the names only, and OB-034 lists the tier-7 rename as an open decision without copy. Confidence raised to HIGH after the PO decisions; copy and icons are approved.

## Ticket Title
[Enhancement] Rename the 7 persona levels, give each an icon and show a short EN/VI description on the new-game screen

## Summary
Replace the tier names with the PO's new names (EN + VI), give each level its own one-colour icon, and show the selected level's name, strength bar and short description in a level card on the new-game screen, in the app language (OB-053). The descriptions match what each level really does: the persona only changes **the move suggested to the user**; the app never plays against anyone (OB-021). During the game, level keys show the icon only.

## Business Context
- PO request 2026-10-05 (verbatim): "Bảng mapping mô tả các cấp độ. Cần designer thiết kế để show được mô tả cho các cấp độ." ("Mapping table describing the levels. A designer must design how to show the descriptions of the levels.")
- PO addition 2026-10-05: a per-level icon based on the level's name.
- Today the user sees only a pictogram and a number per level (OB-052 DS-7) and one word in the new-game heading (`LEVEL · EVEN`). Users who do not know chess (`productContext.md`) cannot tell what level 2 or 6 does before picking it.
- Closes the tier-7 naming item of OB-034 (Q2) and `docs/fairy-stockfish-app-store-compliance-qa.md` Q34 ("God" + "full strength" claims) (D3, D1).
- Store copy rules apply (`docs/marketing-feature-list.md` §4–5, OB-034): no "Grandmaster", "unbeatable", ratings or absolute strength claims; no cheat / bot wording; positioning "Family Companion & Training Assistant"; App Store Guideline 2.3 (accurate descriptions).

### PO mapping table (verbatim, 2026-10-05)

| Level | VI name | EN name | VI description | EN description |
|---|---|---|---|---|
| 1 | Gà Mờ | Noob | Đi bậy đi bạ, toàn "thả" quân biếu không. Cực kỳ thích hợp để nhường trẻ nhỏ hoặc người mới tập chơi lấy hên. | Plays totally random and gives pieces away for free. Perfect for toddlers and total beginners to win with confidence. |
| 2 | Tân Binh | Rookie | Biết đi đúng luật rồi nhưng ham ăn quân, tính toán ngắn và rất dễ sập bẫy. | Follows the rules but gets greedy for piece captures; makes simple blunders and falls into obvious traps. |
| 3 | Chill Chill | Chill Guy | Đánh cờ thư giãn, giao lưu là chính. Nước cờ căn bản, không cay cú, không giăng bẫy hiểm. | Plays relaxed and friendly moves with solid basics. No sneaky tricks, just pure casual fun over coffee. |
| 4 | Hên Xui | 50/50 | (Chế độ Even) Tự nắn gân theo tay người chơi: bạn đi hay nó đi hay, bạn lỡ tay nó châm chước để ván cờ luôn giằng co cân não. | (Even Mode) Mirrors your skill dynamically: plays better when you do, eases up on mistakes to keep games neck-and-neck. |
| 5 | Cáo Già | Hustler | Nước cờ ranh mãnh, nhiều mẹo vặt vỉa hè. Hay giăng bẫy kín, sơ hở một nhịp là "bay màu" ngay. | Street-smart and sneaky. Sets clever tactical traps and punishes oversights without mercy. |
| 6 | Ông Trùm | Local Boss | Lão làng già dơ, công thủ toàn diện, đòn đánh chắc nịch chuẩn dân cờ độ không có kẽ hở. | Seasoned and rock-solid. Seamless coordination between offense and defense with zero cheap mistakes. |
| 7 | Cao Thủ | Big Brain | Engine chạy hết công suất, tính trước hàng chục nước, nhìn thấu toàn bộ bàn cờ mà không có bất kỳ sai số nào. | Full-throttle engine power. Calculates dozens of plies ahead, seeing every flawless tactic with absolute precision. |

## Current Behavior
Source: `persona/domain/persona_tier.dart`, `persona_config.dart`, `tier_selection.dart`, `persona/application/persona_suggester.dart`, `core/engine/engine_models.dart`, `persona/presentation/widgets/persona_tier_keys.dart`, `new_game/presentation/new_game_screen.dart`; rules in OB-021 (D8, D14).

**What each level actually does.** Every level runs Fairy-Stockfish for at most **900 ms with ≤ 2 threads** (`SearchLimits.maxMoveTime`, `EngineConfig`). Stockfish "Skill Level" / `UCI_Elo` / `UCI_LimitStrength` are **not used** (dropped by OB-021 D8). Levels differ only in which move is picked from the engine result, measured as the user's win chance (WC):

| Level | Enum / current EN name | Engine search | Move picked (suggested to the user) |
|---|---|---|---|
| 1 | `baby` / Baby | All legal moves, depth 8, 900 ms cap | The **worst** moves: random pick among moves within 3 pp of the biggest WC loss; a move that allows the fastest mate against the user wins. Deliberate, not random. |
| 2 | `gentle` / Gentle | Same | Random pick among moves losing **9–22 pp** WC vs. the best move (≈ 1–2.5 pawns); else the closest move. No capture preference (dropped in OB-021 D8). |
| 3 | `soft` / Soft | Same | Random pick among moves losing **3 to < 9 pp** WC. |
| 4 | `even` / Even (default) | Same | Random pick among moves leaving the user's WC at **47–53 %**; if none, the closest: the best move when behind, the mildest "give-back" when ahead. Position-based each move; no memory of past moves or games, no skill model. |
| 5 | `solid` / Solid | Single best line, depth cap 12, 900 ms cap | The engine's best move. |
| 6 | `master` / Master | Single best line, depth cap 18, 900 ms cap | The engine's best move. |
| 7 | `god` / God | Single best line, time cap only (900 ms) | The engine's best move. Reachable depth on devices is not measured yet (OB-010). If depth 18 is not reached in 900 ms, levels 6 and 7 suggest the same move. |

**Where names are shown.** Advisor screen: the 7 level keys show a pictogram (dot, pawn … king, OB-052 DS-7) and the number 1–7; the name is only the screen-reader label (`tier.label`). New-game screen: same keys, heading `01  LEVEL · EVEN` (`_selectedTier.label.toUpperCase()`) and helper text `LEVEL CAN BE CHANGED DURING THE GAME`. No description is shown anywhere. `docs/marketing-feature-list.md` §2.3 has a short "what it suggests" line per level (not in the app).

**Planned names.** OB-053 D3 (VI): `EM BÉ`, `NHẸ NHÀNG`, `DỄ`, `CÂN BẰNG`, `VỮNG`, `CAO THỦ` (tier 6), tier 7 pending OB-034. **Superseded by this ticket (D3).**

### Mismatches and risks in the PO draft
Resolution per PO decisions in the last column.

| Level | Issue | Type | Severity | Resolution |
|---|---|---|---|---|
| All | Written as an **opponent** ("plays", "nó đi", "sets traps"). The app never plays; it suggests moves to the user (OB-021, marketing §2.3). Describing a playing AI misrepresents the app (Guideline 2.3) and drifts toward "bot" positioning (banned, OB-034). | Accuracy / compliance | High | Fixed: "suggests …" framing (D1) |
| 1 | "Plays totally random": the level deliberately picks the worst moves. "Đi bậy đi bạ" can read as illegal moves; every suggestion is legal. | Accuracy | Medium | Fixed in copy (D1) |
| 1 | "toddlers": toddlers cannot play chess, and naming them invites Kids-category scrutiny; audience is adults, lowest rating (OB-040). | Compliance / tone | Medium | Fixed: "young child" (D1) |
| 2 | "greedy for piece captures", "falls into obvious traps": no capture or trap logic (capture rules dropped, OB-021 D8). It is a 9–22 pp loss band. | Accuracy | Medium | Fixed in copy (D1) |
| 3 | "Chill Guy" is the name of a widely shared meme character whose creator has publicly asserted rights over commercial use. | IP / naming | Medium | **Kept; risk accepted by PO** (D4) |
| 4 | "Mirrors your skill dynamically / plays better when you do": no skill model. The level reacts to the **position** (WC 47–53 % band) each move. "(Even Mode)" / "(Chế độ Even)" leaks the old name. | Accuracy | High | Fixed: accurate copy, no adaptive mode (D2) |
| 4 | "Hên Xui" (luck of the draw) suggests chance, while the level is balancing. | Tone | Low | Kept (D4) |
| 5 | "Sets clever tactical traps", "mẹo vặt vỉa hè": no trap logic; it is the best move at depth 12. "Without mercy" / "bay màu" is harsher than the family positioning. "Hustler" means someone who plays chess for money (and is an adult-magazine brand). | Accuracy / tone / naming | Medium | Copy fixed (D1); name **kept, risk accepted by PO** (D4) |
| 6 | "chuẩn dân **cờ độ**" = betting chess: gambling connotation. "zero cheap mistakes" / "không có kẽ hở" is an absolute claim. "Ông Trùm" evokes "The Godfather" (low). | Compliance / accuracy | High (cờ độ) | Copy fixed (D1); name **kept, risk accepted by PO** (D4) |
| 7 | "Full-throttle", "dozens of plies ahead", "absolute precision", "không có bất kỳ sai số nào": engine is capped at 900 ms / 2 threads, depth is unmeasured, and the engine can be wrong. "plies" is jargon. | Accuracy / compliance | High | Fixed in copy (D1) |
| 7 | "Cao Thủ" was tier 6 in OB-053 D3; now tier 7. | Consistency | Low | Resolved: OB-053 D3 superseded (D3) |
| 6 vs 7 | Copy must not promise a large gap: both pick the best move; the only difference is the depth cap. | Accuracy | Medium | Fixed in copy ("deeper" / "full thinking time") |

## Expected Behavior
- Each level has a new name, an icon and a description in English and Vietnamese, shown in the app language (OB-053).
- New-game screen: a level card under the level keys shows the selected level's name, strength bar and short description, updating immediately when another level is picked.
- Advisor screen: level keys show the icon only; no name or description text is visible (D5).
- Descriptions say what the **suggestions** do, stay accurate to the engine behavior above, and pass the OB-034 banned-terms / claim rules in both languages.
- Level behavior, default (level 4) and the tier logic do not change.

## User Story
As a player (often one who does not know chess well)
I want to recognise each level at a glance and read what it does before I start
So that I pick the right handicap, for example letting my child win or keeping a game close with a friend.

## Functional Requirements
- REQ-001: Each of the 7 levels has a user-facing name, spoken name, icon, full description and short on-screen description in EN and VI, kept as data in one place next to the tier list (OB-035 design guardrail; same catalogue as OB-053). The tier enum and its order stay unchanged.
- REQ-002: On the new-game screen the LEVEL section heading becomes static: `01  LEVEL` (VI `01  CẤP ĐỘ`); it no longer shows the level name (design spec §13; the spoken header still includes the name, design §8). Under the 7 level keys a **level card** shows the selected level's icon (per design), name, a 7-segment strength bar (segments filled = level number) and the short description (design §4–5). New names replace the current ones everywhere they appear: level card and screen-reader labels of the level keys (D3). Upper-case where the design system uses upper-case labels.
- REQ-003: The level card always shows the selected level; changing the level updates name, icon, strength bar and description at once. With the default (level 4) the card shows level 4 on open.
- REQ-004: Advisor screen (D5): the level keys show the icon only, with no name or description text. The screen-reader label stays (level number, name, selected state); no description hint in-game.
- REQ-005: New-game screen: screen readers announce level number, name and selected state as the label, and the description as the hint, in the app language (design §8).
- REQ-006: On-screen copy in the level card = the **approved short copy** in "Approved on-screen copy" below (D8; same strings as design spec §11 "Final on-screen copy"; the design's "Alternatives" table is **not** used). The full descriptions are the factual reference only. Screen-reader hints on the new-game keys use the same short copy unless the design spec §8 says otherwise. Copy must not be changed in code without updating this ticket and the design spec.
- REQ-007: Layout, typography, length budget and text-scale behavior follow the design spec (§5–7): both languages fit at 360 × 640 and text scale 2.0 without clipping, overflow or clipped diacritics.
- REQ-008 (D7, D9): Each level shows its approved icon ("Approved icons" below): Material Icons by name, one colour, 24 dp, tinted by the key's foreground state like today's pictograms. Shown on the level keys of the new-game screen and the advisor screen, and in the level card. The set **replaces the OB-052 DS-7 piece pictograms** (dot, pawn … king). Material Icons ship with the Flutter SDK (`uses-material-design: true` is already set), so no new asset or dependency is added. Emojis are not rendered in the app.

## Business Rules
- BR-001: A description may only claim behavior the level actually has (Current Behavior table). Any change to tier logic (OB-021 bands, depth caps, 900 ms) requires re-checking this copy.
- BR-002: Descriptions describe the move suggested to the user, never an opponent that "plays" (OB-021: handicap advisor, no opponent mode).
- BR-003: No absolute or unverified strength claims ("flawless", "absolute precision", "zero mistakes", "unbeatable", "Grandmaster", ratings, depth numbers) in either language, unless benchmarked and PO-approved (marketing §4, Q34). Relative claims are allowed ("our strongest level").
- BR-004: No gambling, cheating or bot wording in descriptions in either language (e.g. `cờ độ`, `cá cược`, `kèo`, `gian lận`, `bot`) and no reference to toddlers; "kids" / "bé" in the approved level-1 copy is accepted (D8). The level names approved in D4 are an accepted exception.
- BR-005: Plain words for people who do not know chess: no jargon such as "plies", "depth", "centipawn" (`productContext.md`).
- BR-006: English and Vietnamese say the same thing; tone may differ (moderate slang allowed, D1), facts may not.
- BR-007: Level icons are one-colour, follow the existing key foreground tokens, and come from the approved Material Icons set (D9). Emojis 🐣🪖😎⚖️🦊💼🧠 are for marketing / communication only and never rendered in the app.

## Approved on-screen copy (D8)
Names approved as listed (D3, D4). Short copy approved by the PO as is (design spec §11 "Final on-screen copy", ≤ 90 characters, NFC). These are the strings shown in the level card.

| Lvl | EN name | VI name | EN on-screen (chars) | VI on-screen (chars) |
|---|---|---|---|---|
| 1 | NOOB | GÀ MỜ | Suggests comically bad moves that gift pieces away. Perfect for letting kids win. (81) | Gợi ý toàn nước "tấu hài", thả quân biếu không. Nhường bé thắng là chuẩn bài! (77) |
| 2 | ROOKIE | TÂN BINH | Knows the rules, still learning. Suggests clearly weaker moves for easy games. (78) | Biết luật nhưng còn non: gợi ý nước yếu thấy rõ. Chơi nhẹ nhàng với người mới. (78) |
| 3 | CHILL GUY | CHILL CHILL | Solid, laid-back moves, a notch below its best. Grab a coffee and enjoy. (72) | Gợi ý nước chắc, nhẹ tay một chút. Cà phê, cờ nhẹ, không cay cú. (64) |
| 4 | 50/50 | HÊN XUI | Keeps it 50/50: eases up when you lead, brings its best when you fall behind. (77) | Giữ ván sát nút: bạn dẫn thì nương tay, bạn bị dẫn thì gợi ý nước tốt nhất. (75) |
| 5 | HUSTLER | CÁO GIÀ | Quick and crafty: the best move it sees on a short look ahead. Slip up and it pounces. (86) | Lanh lẹ, mắt tinh: gợi ý nước mạnh nhất trong tầm ngắn. Sơ hở là bị bắt bài. (76) |
| 6 | LOCAL BOSS | ÔNG TRÙM | Thinks deeper, hits harder. Solid in attack and defence, hard to catch out. (75) | Tính sâu hơn, đánh lì hơn. Công thủ toàn diện, khó mà bắt lỗi. (62) |
| 7 | BIG BRAIN | CAO THỦ | Full thinking time for the strongest move the app can find. Our toughest level. (79) | Dùng trọn thời gian suy nghĩ, gợi ý nước mạnh nhất app tìm được. Cấp mạnh nhất! (79) |

Note: level 6 "hits harder" is to be reviewed after OB-010 measures depth (design spec §11): if levels 6 and 7 suggest the same moves on most devices, the BA proposes softer wording to the PO.

## Approved icons (D9)
Material Icons (Flutter SDK), one colour, 24 dp. Emoji = marketing / communication only, not in-app.

| Lvl | Name (EN / VI) | Material icon | Emoji (marketing only) |
|---|---|---|---|
| 1 | NOOB / GÀ MỜ | `egg_alt` | 🐣 |
| 2 | ROOKIE / TÂN BINH | `military_tech` | 🪖 |
| 3 | CHILL GUY / CHILL CHILL | `local_cafe` | 😎 |
| 4 | 50/50 / HÊN XUI | `balance` | ⚖️ |
| 5 | HUSTLER / CÁO GIÀ | `pets` | 🦊 |
| 6 | LOCAL BOSS / ÔNG TRÙM | `business_center` | 💼 |
| 7 | BIG BRAIN / CAO THỦ | `psychology` | 🧠 |

## Full descriptions (factual reference, not shown on screen)
Approved in meaning (D1, D2). Used to check that the on-screen copy stays accurate (BR-001).

| Lvl | VI name | EN name | VI description (full) | EN description (full) |
|---|---|---|---|---|
| 1 | GÀ MỜ | NOOB | Toàn gợi ý nước tệ nhất, hay "thả" quân biếu không. Hợp để nhường trẻ nhỏ hoặc người mới tập chơi thắng lấy hên. | Suggests the weakest moves, often giving pieces away. Perfect for letting a young child or a total beginner win. |
| 2 | TÂN BINH | ROOKIE | Tính ngắn, hay hớ những lỗi đơn giản: gợi ý nước yếu rõ rệt. Hợp để chơi nhẹ nhàng với người mới. | Thinks short and slips often: suggests clearly weaker moves. Good for easy games with beginners. |
| 3 | CHILL CHILL | CHILL GUY | Gợi ý nước cờ căn bản, nhẹ tay hơn một chút. Chơi thư giãn, giao lưu là chính, không cay cú. | Suggests solid but slightly softer moves. Relaxed, friendly games with a light handicap. |
| 4 | HÊN XUI | 50/50 | Giữ ván cờ quanh mức 50/50: bạn đang dẫn thì nhẹ tay lại, bạn bị dẫn thì gợi ý nước tốt nhất. Ván nào cũng giằng co. | Keeps the game close to 50/50: eases up when you pull ahead, suggests the best move when you fall behind. |
| 5 | CÁO GIÀ | HUSTLER | Gợi ý nước mạnh nhất tìm được với tầm tính vừa phải. Sắc bén, sơ hở một nhịp là bị bắt bài ngay. | Suggests the strongest move it finds with a short look ahead. Quick to punish loose moves. |
| 6 | ÔNG TRÙM | LOCAL BOSS | Gợi ý nước mạnh nhất tìm được với tầm tính sâu hơn. Công thủ toàn diện, chắc chắn, khó bắt lỗi. | Suggests the strongest move it finds with a deeper look ahead. Balanced attack and defence, hard to catch out. |
| 7 | CAO THỦ | BIG BRAIN | Gợi ý nước mạnh nhất app tìm được, dùng trọn thời gian suy nghĩ trên máy bạn. Cấp mạnh nhất của app. | Suggests the strongest move the app can find, using its full thinking time on your phone. Our strongest level. |

Numbers 1–7 on the keys: per design spec.

## User Flow
```text
Home → CHESS / XIANGQI → New-game screen
↓ LEVEL section: static heading "01  LEVEL", 7 icon keys, level 4 preselected
Level card under the keys: icon + "50/50" + strength bar 4/7 + short description
↓ tap level 1
Level card: icon + "NOOB" + strength bar 1/7 + level-1 short description (immediately)
↓ START GAME → advisor screen
Level keys show icons only; screen reader reads number + name + selected
↓ tap another level mid-game
Suggestion recomputes (unchanged, OB-022); no description shown
```
Alternative: app language Vietnamese → same flow with heading `01  CẤP ĐỘ` and VI names and descriptions in the card (`HÊN XUI`).

## Acceptance Criteria
- Given the new-game screen opens, When nothing is changed, Then the section heading reads `01  LEVEL` (VI `01  CẤP ĐỘ`) and the level card under the keys shows level 4's icon and new name, a strength bar with 4 of 7 segments filled and the level-4 short description.
- Given the new-game screen, When the user taps each of the 7 levels in turn, Then the heading stays unchanged and the level card switches at once to that level's approved icon, name, a strength bar with segments filled up to that level, and its short description.
- Given the app language is Vietnamese, When the new-game screen is shown, Then names and descriptions are the approved Vietnamese versions; in English, the English versions.
- Given VoiceOver / TalkBack on the new-game screen, When focus lands on a level key, Then it announces the level number, the new name, the selected state and the description, in the app language.
- Given the advisor screen, When it is shown, Then the level keys show only their icons (no name or description text), and VoiceOver / TalkBack announce level number, new name and selected state, without a description.
- Given the new-game keys, the level card and the advisor keys, When they are shown, Then each level shows its Material icon from the "Approved icons" table (1 `egg_alt` … 7 `psychology`) at 24 dp in one colour, tinted for the selected / unselected state; no piece pictogram, emoji, new asset or new dependency is used.
- Given 360 × 640 and text scale 2.0 in both languages, When the longest name and the longest short description are shown in the level card, Then nothing overflows or is clipped and keys stay ≥ 48 dp.
- Given the level card, When any short description is shown, Then it matches the "Approved on-screen copy" table exactly, in the app language.
- Given the approved EN and VI on-screen copy, When it is checked against the OB-034 banned-terms list and BR-003 / BR-004, Then no match remains (no "God", "flawless", "absolute", "zero mistakes", `cờ độ`, `kèo`, "toddler", "bot", "cheat"); the D4 level names are the accepted exception.
- Given any level, When its description is compared with the Current Behavior table, Then every behavior it claims is true (checked by the BA against the approved copy, D8).
- Given any level is selected, When a suggestion is computed, Then the suggested move is the same as before this ticket (no logic change; existing tier tests stay green).
- Given the old names, When the app is searched for user-facing `Baby`, `Gentle`, `Soft`, `Even`, `Solid`, `Master`, `God` (EN) or the OB-053 D3 VI names, Then none remain in the UI or screen-reader labels.

## Edge Cases
- Language switched on Home, then the new-game screen opened: names and descriptions in the new language.
- Longest strings: VI level-4 description; names `CHILL CHILL`, `LOCAL BOSS`, `BIG BRAIN`, `ÔNG TRÙM` on the card's name line at text scale 2.0 (the heading is static, so it never grows).
- New-game hero hidden below 700 dp body height (OB-052 DS-8): the card must still fit without pushing START GAME off screen.
- Level changed rapidly (double tap, quick taps across levels): the card shows the last selected level only.
- No level selected in-game (nullable provider, OB-023 path): existing prompt unchanged.
- "50/50" next to the top-center win rate (`WIN nn%`): only on the new-game screen now (the advisor shows icons only), so no clash in-game.
- Icons must stay distinguishable at the key size and in both selected / unselected tints (no meaning carried by colour alone).

## In Scope
- New EN/VI names for the 7 levels (D3, D4); EN/VI descriptions (full + final short).
- New-game screen: static `01  LEVEL` / `01  CẤP ĐỘ` heading and a level card (icon, name, 7-segment strength bar, short description) under the level keys, per the design spec.
- Per-level Material icons on the new-game keys, advisor keys and level card (REQ-008, D9), replacing the OB-052 DS-7 pictograms.
- Screen-reader labels (both screens) and description hints (new-game only).
- Tests: names/descriptions/icons per tier in both languages, card update on selection, 360 × 640 × 2.0 in both languages, banned-terms check on the descriptions.

## Out of Scope
- Any change to tier behavior, bands, depth caps, time cap or default level. No adaptive "mirror your skill" mode and no new-feature ticket for it (D2).
- Description text or hints on the advisor screen (D5).
- New colors; emoji rendering in the app (BR-007); new icon packs, assets or dependencies.
- Deleting the now-unused Cburnett piece SVGs: they stay, the boards still use them.
- Store listing, screenshots and `docs/marketing-feature-list.md` §2.3 wording (OB-034; to be aligned with the approved copy).
- Editing OB-053 (follow-up below) and memory-bank updates (applied by the BA after approval).
- Strength benchmarks / Elo (Q34 follow-up, OB-010).

## Dependencies
- OB-053 (Ready for development): EN/VI string catalogue and app-language provider; this ticket adds names and descriptions to it and **supersedes its D3 / R3 tier-name table** (D3). If OB-053 lands first, add strings there; if not, both tickets coordinate on one catalogue.
- OB-034: tier-7 label settled as `BIG BRAIN` / `CAO THỦ` (D3); banned-terms list applies to descriptions; level-name risks accepted by the PO (D4).
- OB-021 / OB-022: source of truth for tier behavior (BR-001).
- OB-052 DS-7 / DS-8: level keys (pictograms replaced by the D9 icons) and new-game layout the design extends.
- OB-010: measured depth per tier on devices; if level 6 and 7 turn out identical in practice, the copy for 6/7 is reviewed.
- Design spec `docs/design/OB-054-level-descriptions-design.md` (layout, semantics, test IDs).
- OB-033: Material Icons font licence (Apache 2.0) is already registered by Flutter's license registry; no extra licenses-screen entry expected (developer confirms).

### Follow-ups (BA / PO, not part of this ticket)
- **OB-053:** its tier-name table (D3, R3: `EM BÉ` … `CAO THỦ` for tier 6, tier 7 via OB-034) is superseded by OB-054 D3. BA to add a pointer in OB-053 after PO confirmation; OB-053 is not edited here.
- **OB-034:** record the tier-7 decision (`BIG BRAIN` / `CAO THỦ`) and the PO's accepted naming risk (D4).
- **`docs/marketing-feature-list.md` §2.3** and compliance Q34: align with the approved names and copy.
- **`memory-bank/designSystem.md`** persona section: new names, level card, Material icons replacing the piece pictograms.
- **README** persona summary names and the OB-052 DS-7 pictogram note.

## Design handoff
**Done (2026-10-05).** `docs/design/OB-054-level-descriptions-design.md` is the source of truth for layout and semantics (its §13 overrides the earlier heading flow; this ticket is updated to match): static heading, level card under the keys (icon, name, 7-segment strength bar, short description), advisor keys icon-only (D5), key spec incl. the 1–7 number badge and icon position in the card. Short copy (D8) and icons (D9) are approved and recorded above.

## Decisions
PO, 2026-10-05:
- D1 (Q1): descriptions use the "suggests …" framing with the corrected claims (Approved names and full descriptions table). Moderate slang is OK (e.g. "thả quân biếu không", "lấy hên", "bắt bài"); "bay màu" and "cờ độ" stay out.
- D2 (Q2): level 4 uses the accurate copy (keeps the game close to 50/50, position-based). No adaptive / skill-mirroring mode and no new-feature ticket for it.
- D3 (Q3): the new names **replace** `Baby` … `God` (the user-facing `PersonaTier` labels) and OB-053's Vietnamese tier names (OB-053 D3 / R3). Tier 7 = `BIG BRAIN` / `CAO THỦ` settles the OB-034 tier-7 rename. OB-053's tier-name table is superseded (follow-up listed above; OB-053 not edited here).
- D4 (Q4): **all PO names kept**, including `CHILL GUY`, `HUSTLER`, `ÔNG TRÙM`, `NOOB`, `HÊN XUI`. The residual risks (meme IP for "Chill Guy"; money-hustling / adult-brand association for "Hustler"; mob-boss connotation for "Ông Trùm") are **accepted by the PO**.
- D5 (Q5): descriptions appear on the **new-game screen only**. During the game the level keys show the icon only (no name, no description text); the spoken label (number + name + selected) stays for accessibility, with no description hint.
- D6 (Q6): the Designer's first short on-screen copy must be improved; the Designer is rewriting it in the design spec. On-screen copy = the design spec's **final** short copy, subject to PO sign-off (signed off in D8).
- D7 (new scope): each level gets its own icon based on its name (Designer proposes emoji reference + in-app icon in the design spec). Requirements in REQ-008 / BR-007; approval of the set is Q7.
- D8 (Q6 final): the Designer's final short on-screen copy (design spec §11 "Final on-screen copy") is **approved as is**; final picks, not the alternatives. Recorded in "Approved on-screen copy".
- D9 (Q7): icon set = Material Icons by name, one colour, 24 dp: 1 `egg_alt`, 2 `military_tech`, 3 `local_cafe`, 4 `balance`, 5 `pets`, 6 `business_center`, 7 `psychology`. Emoji 🐣🪖😎⚖️🦊💼🧠 for marketing / communication only, not in-app. **Replaces the OB-052 DS-7 piece pictograms.**

## Assumptions
- A-1: ~~Wording can be corrected for accuracy and compliance~~ → decided (D1).
- A-2: Vietnamese is the source tone; English carries the same facts (BR-006).
- A-3: Tier behavior does not change in this ticket; copy follows the code.
- A-4: Internal enum names (`baby` … `god`) may stay; only user-facing text changes (developer decides).
- A-5: ~~Pictograms stay (OB-052 DS-7)~~ → replaced by the Material icons (D9). Whether the 1–7 number badge stays on the keys follows the design spec.

## Open Questions
1. ~~Q1 — Voice and accuracy~~ → answered (D1).
2. ~~Q2 — Level 4 adaptive vs. accurate copy~~ → answered (D2).
3. ~~Q3 — Names supersede~~ → answered (D3).
4. ~~Q4 — Risky names~~ → answered (D4): all kept, risk accepted.
5. ~~Q5 — Where descriptions show~~ → answered (D5).
6. ~~Q6 — Copy approval~~ → answered (D6): short copy being rewritten; PO signs off the final version.
7. ~~Q7 — Icon set~~ → answered (D9): Material Icons, replacing the OB-052 DS-7 pictograms.

None open.

## Developer Handoff
- Add per-tier name, spoken name and approved short on-screen description (EN/VI, "Approved on-screen copy") to the OB-053 catalogue (full descriptions stay in this ticket as reference only), keyed by `PersonaTier`; replace `PersonaTier.label` uses (`new_game_screen.dart` heading, `persona_tier_keys.dart` semantics) with catalogue lookups. Keep enum order, `level` and all of `persona_config.dart` / `tier_selection.dart` / `persona_suggester.dart` untouched.
- Follow `docs/design/OB-054-level-descriptions-design.md` for layout, keys/test IDs and semantics: static `01  LEVEL` heading, level card under the keys (icon, name, 7-segment strength bar, short description).
- Icons (D9): replace `_TierPictogram`'s dot / Cburnett SVGs in `persona_tier_keys.dart` with the Material icons from "Approved icons" (24 dp, tinted by the existing foreground colour), shared by new-game and advisor keys and the level card; keep the per-tier mapping in one place. No new dependency.
- Semantics: label = number + name (+ selected) on both screens; description hint on the new-game keys only.
- Tests: unit test that every tier has non-empty EN and VI name and short description (≤ 90 characters) matching the approved table, and its D9 icon; widget tests for the static heading and level-card update (icon, name, bar, description) in both languages and 360 × 640 × 2.0; advisor keys show no text and carry no description hint; a copy test against the banned-terms list (BR-003 / BR-004). Existing tier-selection tests must stay green. Verify on the iOS simulator in both languages (testing policy 2026-10-03).
