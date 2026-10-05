# OmniChess Advisor — Backlog (per-game plan)

Source: `memory-bank/` (all 7 files) reviewed on 2026-10-02, plus PO decisions recorded in OB-021.
Codebase status (2026-10-03): Flutter 3.47.6 / Dart 3.13.5 installed; git repository initialized; app shell scaffolded by OB-003 (originally `omni_board`, `com.thuannguyen.omniboard`); Fairy-Stockfish FFI bridge by OB-004. No feature logic yet.
App renamed 2026-10-04: **SpookyMoove** — package `spookymoove`, bundle ID `com.spookymoove.app` (earlier the same day: Cataland / `com.cataland.app`, then Ghost64 / `com.ghost64.app`).

Testing policy (PO 2026-10-03, revised 2026-10-04): every ticket is implemented and verified on the iOS simulator. The developer agent runs `flutter analyze` and `flutter test` and keeps the integration tests up to date, but does not run them; the PO runs the integration tests on the simulator. Physical-device testing (iPhone and Android) and all Android verification happen in one pass after all tickets are finished.

PO request (2026-10-02): "BA sắp xếp plan/tickets theo từng game. Bắt đầu với Chess trước" — organize the plan per game, Chess first.
PO compliance document (2026-10-02): "Legal, Architecture & Monetization Compliance" → OB-032–OB-040 (licensing architecture, licenses screen, store positioning, freemium). See "M1 release readiness".
PO answers (2026-10-02): **full-feature version first; monetization deferred** (OB-035 M-D1); **no analytics** (M-D2); Shogi/Othello will be Pro later (M-D3); audience decided by BA recommendation (OB-040); counsel, naming and copy later. Monetization tickets → "Deferred: Monetization".

## Milestones vs. phases
The per-game order does **not** change milestone scope.

| Milestone (memory bank) | Phases |
|-------------------------|--------|
| **M1** = Chess + Xiangqi (bundled) + fair-play notice + persona (OB-021 D13) | Phase 0 (shared foundation) → Phase 1 (Chess) → Phase 2 (Xiangqi) |
| **M1 store release** (full-feature, no monetization) | + "M1 release readiness" track (license boundary, licenses screen, positioning, audience), in parallel with Phases 1–2; app UI in English + Vietnamese (OB-053, PO 2026-10-05) |
| Later (PO to resume) | "Deferred: Monetization" (OB-035–OB-039) |
| Post-M1 (on-demand games, need ODDAS) | Phase 3 (shared ODDAS) → Phase 4 Shogi → Phase 5 Gomoku/Caro → Phase 6 Othello → Phase 7 Go |

Phase 1 produces the first **end-to-end, testable Chess build**. A store release is M1 (after Xiangqi) unless the PO decides to release Chess alone. Order of the later games follows `progress.md` (Shogi, Gomoku/Caro, Othello, Go).

Priorities: **P0** = needed for the Chess Definition of Done (Phases 0–1); **P1** = rest of M1 (Xiangqi, M1 polish, release readiness); **P2** = post-M1; **Later** = deferred by the PO.

**Design guardrail (non-functional, from OB-035):** the full-feature build offers every game and tier. Keep "which games/tiers are offered" as data in one place (the game list for OB-011, the tier list for OB-023/OB-022), with no scattered hard-coded checks, so a future gating step stays cheap. This is **not** a mandate to build an entitlement layer now. **No analytics or data-collecting SDKs** (OB-035 M-D2).

Every game phase must include: input (tap board, no-notation principle), undo (OB-012), suggestion card formatting, engine + WC conversion and candidate set, the 7-tier persona mapping per OB-021, game-end rules, registration in the new-game flow (OB-011), and a performance pass.

---

## Phase 0 — Shared foundation (only what Chess needs first)

| # | ID | Title | Type | Priority | Depends on | Status |
|---|----|-------|------|----------|------------|--------|
| 0.1 | [OB-001](OB-001-clarify-core-session-flow.md) | Define the core advisor session flow and move notation | NEEDS_CLARIFICATION | P0 | — | **Resolved** (2026-10-04): all questions decided. Q2 option b (OB-041); Q3, Q5 confirmed; Q6 no resume after app kill in M1; Q10 (XQ4) |
| 0.2 | [OB-002](OB-002-clarify-licensing-strategy.md) | Decide licensing strategy (GPL engines, rules library, Gomoku engine) | NEEDS_CLARIFICATION | P0 | — | **Resolved** (PO 2026-10-04): app is **GPLv3 open source**, Fairy-Stockfish in-process on both stores, IPC dropped; counsel confirms before release (OB-032). Q3 per game; Q4 in OB-017 |
| 0.2b | [OB-032](OB-032-clarify-engine-license-boundary-architecture.md) | Decide the engine license boundary and process architecture (IPC mandate vs. iOS) | NEEDS_CLARIFICATION | P0 (blocks release, not development) | Legal counsel (assignment deferred by PO) | **Release blocker**; development continues with FFI (OB-004), OB-005 stays transport-agnostic |
| 0.3 | [OB-021](OB-021-clarify-persona-purpose-and-rules.md) | Purpose and per-tier rules of the 7-tier persona system | NEEDS_CLARIFICATION | P0 | — | **Resolved** (decision record) |
| 0.4 | [OB-003](OB-003-scaffold-app-shell-and-design-tokens.md) | Scaffold Flutter app shell, design tokens, offline fonts, layout | TECHNICAL_TASK | P0 | Flutter installed | **Done** (2026-10-03); iOS minimum is 15.0 (Flutter 3.47), not 13.0 |
| 0.5 | [OB-004](OB-004-fairy-stockfish-native-build-and-ffi-bridge.md) | Fairy-Stockfish as in-process library over FFI on a background isolate | TECHNICAL_TASK | P0 | OB-003 (OB-002/OB-032 before release) | **Done on iOS simulator** (2026-10-03); physical iPhone, Android build/test and per-ABI sizes deferred to the final device pass. Working architecture until OB-032 decides |
| 0.6 | [OB-005](OB-005-engine-abstraction-and-uci-adapter.md) | Game-agnostic engine interface + UCI adapter (multi-line, depth caps, 900 ms cap) | TECHNICAL_TASK | P0 | OB-004 | **Done on iOS simulator** (2026-10-03); UCCI not needed (`UCI_Variant xiangqi`); device timing deferred to OB-010 / final device pass |
| 0.7 | [OB-022](OB-022-persona-move-selection.md) (core) | Persona tier logic core: WC conversion + 7-tier selection (pure Dart) | NEW_FEATURE | P0 | OB-003 | **Done on iOS simulator** (2026-10-03): tier logic, WC conversion, config, plus engine-facing `PersonaSuggester` (tier search limits, cache per position+tier, superseded results discarded); screen wiring in Phase 1 (row 1.5) |
| 0.8 | [OB-023](OB-023-persona-selector-ui.md) | Persona tier selector row (7 buttons, design tokens) | NEW_FEATURE | P0 | OB-003 | **Done on iOS simulator** (2026-10-03): `PersonaRow` + nullable `personaTierProvider`, card prompt until a tier is chosen; Open Question 2 (< 360 dp) still open |
| 0.9 | [OB-008](OB-008-fair-play-terms-notice.md) | One-time fair-play notice (EN/VI), acknowledged before first use | NEW_FEATURE | P0 | OB-003, OB-011 (info key) | **Done** (PO accepted 2026-10-05): EN/VI one-time gate, versioned acknowledgment; FAIR PLAY key on the new-game screen header. Wording v4 (chess/xiangqi federations, no "cheating") |

---

## Phase 1 — Chess (first end-to-end slice)

| # | ID | Title | Type | Priority | Depends on | Status |
|---|----|-------|------|----------|------------|--------|
| 1.1 | [OB-006](OB-006-chess-two-tap-keypad.md) | Chess legal-only **tap board** (1–2 taps, pictogram promotion) + rules-module interface | NEW_FEATURE | P0 | OB-003, OB-011 | **Done on iOS simulator** (2026-10-03): adapter over `chess` 0.8.1, tap board, Cburnett pictograms (`flutter_svg`); side choice and suggestion hooks wait for OB-011 / OB-007; device timing deferred to OB-010 |
| 1.2 | [OB-007](OB-007-chess-suggestion-card.md) | Chess suggestion card: coordinates + special-move lines, `WIN nn%`, board highlight, haptics | NEW_FEATURE | P0 | OB-005, OB-006, OB-022 | **Done on iOS simulator** (2026-10-03): end to end incl. engine provider and suggestion trigger (user's turn + tier, stale results dropped, timeout + Retry); card formats, board highlight incl. en passant marker, haptics; ~340 ms after the opponent's move on the simulator |
| 1.3 | [OB-011](OB-011-start-new-game.md) | Start a new game: choose game + side, then pick tier (Chess first) | NEW_FEATURE | P0 (was P1) | OB-003, OB-008, OB-023 | **Done on iOS simulator** (2026-10-03): new-game screen (CHESS + WHITE/BLACK + FAIR PLAY), NEW GAME key with confirmation; the game is discarded on confirming NEW GAME (OB-050 D1; BACK keeps it); suggestion on tier pick (REQ-006) and search cancel come with OB-025 |
| 1.4 | [OB-025](OB-025-turn-loop.md) | Turn loop: enter opponent and user moves, suggest on the user's turn | NEW_FEATURE | P0 | OB-006, OB-007, OB-011 | **Done on iOS simulator** (2026-10-03): status line "YOUR MOVE" / "OPPONENT TO MOVE" (`turnStatusProvider` + `StatusLine`); request/clear/cancel from OB-007; loop stops at game end (OB-024) |
| 1.5 | [OB-022](OB-022-persona-move-selection.md) (Chess wiring) | Tier-based Chess suggestions: all-move evaluation, depth caps, gating, recompute | NEW_FEATURE | P0 | OB-005, OB-007, OB-025, OB-023 | **Done with OB-007** (2026-10-03): provider, "no tier → no request" gating and card hookup in `SuggestionController`; recompute on tier change verified on the simulator; screen-level acceptance cases covered with OB-025 |
| 1.6 | [OB-024](OB-024-chess-game-end.md) | Chess game end: checkmate, stalemate, draws, game-over state | NEW_FEATURE | P0 | OB-006, OB-007, OB-011, OB-025 | **Done on iOS simulator** (2026-10-03): pure `ChessGameStatus` (checkmate, stalemate, insufficient material, fivefold, 75-move; threefold/50-move hints); board dimmed and entry blocked when over; result in the card, hint at the card's bottom; NEW GAME key reused |
| 1.7 | [OB-010](OB-010-milestone1-size-latency-thermal-validation.md) (Chess pass) | Size, latency per tier, input cycle, FPS, thermal for Chess | TECHNICAL_TASK | P0 | OB-004 (size), OB-022, OB-025 | Size check right after OB-004 |
| 1.8 | [OB-012](OB-012-undo-last-move.md) | Undo the last entered move: one move per tap, full state restore, same suggestion after undo | NEW_FEATURE | **P0** (PO decision 2026-10-02) | OB-025, OB-006, OB-022, OB-024 | **Done on iOS simulator** (2026-10-03): UNDO key, top right of the game header since OB-050 (disabled until a move); one move per tap back to the start, also out of game over; promotion chooser closes first; same suggestion from the (position, tier) cache. U-A1–U-A4 applied as written |
| 1.9 | [OB-041](OB-041-confirm-played-suggestion.md) | Confirm the played suggestion with one tap ("✓ I PLAYED IT"); any other board move overrides it | ENHANCEMENT | P0 (PO decision 2026-10-03) | OB-025, OB-007, OB-006, OB-012 | **Done on iOS simulator** (2026-10-03): "✓ I PLAYED IT" key in the status line (disabled while thinking), `ChessBoardController.commit`. Revision 2: top bar (UNDO / turn label / NEW GAME) and an always-visible full-width bottom button (guidance, I PLAYED IT, game-over NEW GAME without dialog); hint dropped. Revision 3: green primary I PLAYED IT with a top margin; win rate moved from the card to the top center; revises OB-025 A1 / OB-001 Q2 → option b |

### Chess Definition of Done
A Chess build on Android (API 24+) and iOS (15+) where, fully offline:
1. First launch shows the fair-play notice (OB-008).
2. The user starts a new game: picks **Chess** and exactly one side (OB-011).
3. The new-game screen preselects the middle tier, Even, and the White side (PO revision of 2026-10-03, OB-011). The user can pick any of the 7 tiers there or change it at any time during the game; a change recomputes the suggestion (OB-023, OB-022).
4. The user enters the opponent's moves on the legal-only tap board in 2 taps (OB-048), including castling, en passant and pictogram promotion, with no chess-notation knowledge needed (OB-006, OB-025). On their own turn, one tap on "✓ I PLAYED IT" applies the suggestion; any other move is entered on the board as an override (OB-041).
5. On the user's turn, the tier-based suggestion appears within ≤ 1000 ms, with haptics. It shows coordinates (`E7 ➔ E5`) with special-move instructions, `WIN nn%`, the expert line, and green squares on the board (OB-007, OB-022).
6. Checkmate, stalemate and draws are detected and shown; the board locks; "New game" is offered (OB-024).
7. **UNDO** removes the last entered move (one per tap), restoring position, turn, game status and the same suggestion for the same tier, including from a game-over state (OB-012).
8. The Chess pass of OB-010 is reported: install size, latency per tier, input cycle < 1.2 s, 60 FPS during search, thermal over a 30-minute game.
9. Rules module, tier logic, undo and formatters are unit-tested; the main flows have widget tests.

Not in the Chess DoD: custom start positions, resuming after app kill, match history (OB-013).

### What blocks Chess
- **To start Phase 0:** Flutter SDK installed. Everything in Phase 0 (OB-008 included) and OB-006/OB-007 against the rules interface can start without further PO input.
- **To finish Phase 1:** no PO blockers. The rules library is decided (`chess`, 2026-10-02) and all session-flow questions are answered (OB-001). Technical risk to check first: `chess` on Dart 3 (OB-006 REQ-016).
- **To release:** OB-002/OB-032 (GPL licensing and engine architecture, counsel); legal review of the fair-play text (OB-008); the "M1 release readiness" track below (OB-033, OB-034, OB-040).
- **Compliance answers (2026-10-02) do not change the Chess plan:** no new blockers. Monetization is out of the Chess DoD (PO decision OB-035 M-D1); all tiers are available. Development continues with the FFI engine design (OB-004).

### Memory bank updates
**Applied 2026-10-02 (PO approved):** tap board and new layout; no-chess-knowledge principle and coordinate notation; 7-tier persona summary (refers to OB-021); Chess session flow, including undo; fair-play notice format; audience decision; no analytics; monetization deferred (Shogi/Othello Pro later); Milestone 1 scope; per-game plan reference; engine execution model recorded as **provisional** (FFI in-process; iOS subprocess infeasibility noted; OB-032 pending); store positioning (app name still pending). Files: all 7 memory-bank files.

**Still to apply once decided:**
1. License boundary / engine architecture final decision (OB-032, OB-002; counsel) → `systemPatterns.md`, `techContext.md`, `projectbrief.md`.
2. App display name and tier-7 label (OB-034) → `projectbrief.md` title. Bundle ID decided 2026-10-03: `com.thuannguyen.omniboard`; changed 2026-10-04 to `com.cataland.app`, then `com.ghost64.app`, then `com.spookymoove.app` (app name **SpookyMoove**, PO 2026-10-04).
3. Final color tokens `keyDisabled` / `bgDark` (provisional `#1A1B20` / `#0F1015`, OB-003 Q1); light theme in or out (OB-003 Q2) → `designSystem.md`.
4. Input-cycle target 1.2 s vs. 1.5 s (PO sign-off) → `techContext.md`, `activeContext.md`.
5. ~~Resume after app kill (OB-001 Q6)~~ → decided 2026-10-04 (no resume in M1), applied to `productContext.md`. Intersection board, character discs and `pieceRed` token (XQ1–XQ3, decided) → `designSystem.md` (done with OB-044). (Xiangqi decisions XQ1–XQ11 applied to `productContext.md` on 2026-10-03.)
6. Licenses screen content after counsel (OB-033/OB-032) → `techContext.md`.

(Chess rules library = `chess`: applied to `techContext.md`, `systemPatterns.md`, `activeContext.md` and `progress.md` on 2026-10-02.)

---

## Phase 2 — Xiangqi (completes M1)

PO request (2026-10-03): "For chess, it is all good now. I would like to move all behavior we decide to the next game Xiangqi." BA + Designer review done 2026-10-03. **OB-009 is now the Phase 2 epic**: it holds the Chess → Xiangqi carry-over matrix (every decided Chess behaviour: reuse / adapt / N/A, with the owning ticket) and the Xiangqi Definition of Done. Work is split into small tickets:

| # | ID | Title | Type | Priority | Depends on | Status |
|---|----|-------|------|----------|------------|--------|
| 2.0 | [OB-009](OB-009-xiangqi-advisor.md) | **Epic:** Xiangqi advisor — carry every Chess behaviour over (matrix + Xiangqi DoD) | NEW_FEATURE (epic) | P1 | Phase 1 | **In progress** (2026-10-04): OB-042–OB-048 done on the iOS simulator; open: OB-010 Xiangqi pass and the real-device checks (35 dp cells on 360×640) |
| 2.1a | [OB-042](OB-042-game-agnostic-seams-for-second-game.md) | Game-agnostic seams: side model + per-game labels, active-game seam for the advisor layer, engine variant per game, aspect-aware `boardSizeFor`, shared smart entry | TECHNICAL_TASK | P1 | Phase 1 | **Done on iOS simulator** (2026-10-03): `PlayerSide` + `GameKind` labels / variant / grid; `ActiveGameState` / `ActiveGameController` seam with `game_registry.dart` as the only `GameKind` switch; shared `SmartEntry`; `boardSizeFor(files, ranks)`. Chess suite green |
| 2.1b | [OB-043](OB-043-xiangqi-rules-module.md) | Xiangqi rules module (pure Dart), perft-validated against Fairy-Stockfish | TECHNICAL_TASK | P1 | (OB-042 side type) | **Done on iOS simulator** (2026-10-03): hand-written `DartXiangqiRules` behind `XiangqiRules`; all perft counts match Fairy-Stockfish (start to depth 4 + five positions to depth 3); ~0.01 ms per position |
| 2.2 | [OB-044](OB-044-xiangqi-intersection-tap-board.md) | Intersection tap board: character discs, `pieceRed`, point states, 9×10 sizing, nearest-legal snapping, board controller | NEW_FEATURE | P1 | OB-042, OB-043 | **Done on iOS simulator** (2026-10-03): `IntersectionBoard` + `snapTap` in core, Noto Serif TC glyph SVGs (OFL), `pieceRed`, `XiangqiBoardController` on the active-game seam; not selectable until OB-045; 360×640 checked in the device pass |
| 2.3 | [OB-045](OB-045-new-game-xiangqi-and-red-black.md) | New-game screen: GAME row CHESS / XIANGQI, RED / BLACK sides | ENHANCEMENT | P1 | OB-042, OB-044 | **Done on iOS simulator** (2026-10-03): `GameKind.xiangqi` registered; GAME row CHESS / XIANGQI, RED / BLACK with 帥 / 將 discs, current game preselected; interim `H3 ➔ E3` card until OB-046 |
| 2.4 | [OB-046](OB-046-xiangqi-advisor-wiring.md) | Advisor wiring: `UCI_Variant xiangqi`, 7 tiers, card `[炮] H3 ➔ E3` + WXF expert line, highlight, I PLAYED IT, undo | NEW_FEATURE | P1 | OB-042–OB-045 | **Done on iOS simulator** (2026-10-03): card disc + `H3 ➔ E3 ✕`, WXF expert line ported from Fairy-Stockfish (`.` for sideways), `GameWidgets.expertLine` slot; fixed the stale variant on a game switch; 7 tiers + Xiangqi turn loop on the simulator |
| 2.5 | [OB-047](OB-047-xiangqi-game-end.md) | Game end: CHECKMATE / NO MOVES = loss for the side to move; no draws, no perpetual adjudication | NEW_FEATURE | P1 | OB-042–OB-044, OB-046 | **Done on iOS simulator** (2026-10-04): `XiangqiGameStatus` + `XiangqiResultFormat` (`CHECKMATE` / `NO MOVES`, `YOU WIN` / `YOU LOSE`) through the seam; shared game-over path unchanged; mate-in-1 flows on the simulator |
| 2.5b | [OB-048](OB-048-always-two-tap-entry.md) | Never commit on the first tap: always show the options, commit on the second tap (Chess and Xiangqi, shared smart entry) | ENHANCEMENT | P1 | OB-006, OB-042, OB-044 | **Done on iOS simulator** (2026-10-04): first tap always shows the options, second tap commits, both games; supersedes OB-006 REQ-005 |
| 2.5c | [OB-049](OB-049-home-game-picker.md) | Home screen with CHESS / XIANGQI buttons → new-game screen per game (level + side, no GAME row, HOME key) | ENHANCEMENT | P1 | OB-011, OB-045, OB-042 | **Done on iOS simulator** (2026-10-04): Home CHESS / XIANGQI keys → new-game screen per game; Home BACK key and HOME row later replaced by OB-050 |
| 2.5d | [OB-050](OB-050-screen-headers-and-new-game-navigation.md) | Three-slot headers: new-game `[BACK] CHESS [FAIR PLAY]` (bottom HOME row removed); game `[NEW GAME] WIN RATE [UNDO]` (corners swapped); in-game NEW GAME navigation | ENHANCEMENT | P1 | OB-049, OB-011, OB-012, OB-041 | **Done on iOS simulator** (2026-10-04): shared `ScreenHeader`; game discarded on confirming NEW GAME; Home is the root again with no BACK key. Revises OB-049 Design / BR-003 |
| 2.5e | [OB-051](OB-051-home-settings-and-language.md) | Home header `[SETTINGS] PICK A GAME [LANGUAGE]`: small Settings modal (content later) and Language modal (English only) | NEW_FEATURE | P1 | OB-050 (frees Home's top-left), OB-049, OB-008 | **Done on iOS simulator** (2026-10-04): Settings ships with `NO SETTINGS YET` + release gate (≥ 1 entry or hide the key before submission); fair-play notice keeps device language; ABOUT (OB-033) becomes a Settings row |
| 2.5f | [OB-052](OB-052-gamification-isometric-restyle.md) | Gamified isometric restyle of the app UI (boards stay top-down) + per-game identity accents: Chess `#ED96D7`, Xiangqi `#578EF5`; background stays `#0F1015` | ENHANCEMENT | P1 | OB-003, OB-049, OB-050, OB-051, OB-010 (FPS check) | **Implemented incl. Home layout revision (2026-10-05); analyze + tests pass; PO to verify on iOS simulator.** DS-9 / D9: Home rows (`surfaceDark` block, 48 dp accent icon block, upper-case name + tagline from `app_strings.dart` (OB-053; `GameCopy` removed), grey chevron, ≥ 72 dp, top-aligned), `HomeHero` removed (D10), text header keys kept; future accents recorded only (Shogi, Go, Othello, Caro). DS-1–DS-7 as before (`AppBlock`, `GameKind` accents, advisor layout; accent lines removed per D6). DS-8 / D7: new-game screen with `‹ BACK` / FAIR PLAY header, painted isometric hero (`NewGameHero`, solid faces, hidden below 700 dp body height or text scale > 1.3), `PLAYING` + accent `display` title, 6 dp surface panel with 01 / 02 sections, side cards with FIRST / SECOND MOVE and radio dot, pinned accent START GAME with arrow chip and helper text. OB-010 FPS check before / after still to run |
| 2.5g | [OB-053](OB-053-vietnamese-app-language.md) | Vietnamese app language: `TIẾNG VIỆT` in the Language dialog, all in-app UI and screen-reader labels translated, device-language default, saved choice, fair-play notice follows the app language (OB-051 D2) | ENHANCEMENT | P1 (M1 release) | OB-051, OB-008, OB-034 (copy rules, tier-7 name), OB-052 (copy settled) | **Implemented 2026-10-05, PO verifying**: awaiting PO sign-off of the VI copy table in the ticket (D2). Earlier: Ready for development (PO 2026-10-05, D1–D4): ships in M1; BA/dev draft the VI copy, PO signs off; tier names translated (tier 7 follows OB-034); default = device language. Approach: in-house typed EN/VI string catalogue + SDK `flutter_localizations` for platform strings; no `intl` / ARB. Store listing VI stays in OB-034 |
| 2.5h | [OB-054](OB-054-persona-level-descriptions.md) | Level names, icons and descriptions: Noob, Rookie, Chill guy, 50/50, Hustler, Local boss, Big brain (EN/VI); level card on the new-game screen; icon-only level keys in game | ENHANCEMENT | P1 (M1 release) | OB-021, OB-023, OB-053, OB-034 (tier-7 name) | **Implemented 2026-10-05, PO verifying** |
| 2.6 | [OB-010](OB-010-milestone1-size-latency-thermal-validation.md) (Xiangqi pass) | Performance for Xiangqi per tier; asset size; input cycle with snapping; WC slope check | TECHNICAL_TASK | P1 | OB-043–OB-047 | **In progress** (2026-10-04): harness done (9-position set, per-tier latency, input cycle with snapping, frames, WC band check); size ≈ 9.7 MB iOS / 9.5 MB Android arm64 compressed (pass); simulator latency run pending; device numbers in the final device pass |

**Order:** OB-042 ∥ OB-043 → OB-044 → OB-045 → OB-046 → OB-047 → OB-010 Xiangqi pass. OB-045 comes right after the board so Xiangqi is reachable from the UI for simulator testing.

Reused from Phase 1 without change (via OB-042): fair-play notice (OB-008), LEVEL row + default Even, BACK / FAIR PLAY / START GAME + discard prompt (OB-011), turn loop and status line states (OB-025, OB-041), I PLAYED IT / override (OB-041), undo (OB-012), persona tiers and cache (OB-021/022/023), top-bar win rate, engine timeout + RETRY (OB-007), tokens and 360 dp × text scale 2.0. N/A: promotion chooser, claimable-draw hints. Xiangqi is available to everyone (monetization deferred).

### Phase 2 PO decisions — **RESOLVED** (PO 2026-10-03: all recommended defaults accepted)
XQn = Designer question n (review 2026-10-03); XQ11 added by the BA. The "Recommended default" column is now the **decision**; each child ticket records it under "Decisions" citing "PO 2026-10-03, XQn". Phase 2 has no PO blockers.

| # | Question | Decision (was recommended default) | Ticket |
|---|----------|------------------------------------|--------|
| XQ1 | Pieces: Chinese characters on discs, or pictograms? | Characters (帥/將, 仕/士, 相/象, 傌/馬, 俥/車, 炮/砲, 兵/卒) as bundled vector assets | OB-044 |
| XQ2 | Add a board-only `pieceRed` token (≈ `#FF8A80`, distinct from `accentRed`)? | Yes | OB-044 |
| XQ3 | Accept 40 dp cells at 360 dp width (≈ 35 dp at 360×640) with nearest-legal snapping, as an exception to the 44 dp board rule? | Yes; verify on a device in the final pass | OB-044 |
| XQ4 | Xiangqi notation (= OB-001 Q10) | Absolute `A`–`I` / `1`–`10` in Red's frame + piece disc in the main line; WXF only in the expert line | OB-046 (and OB-044 edge labels) |
| XQ5 | Default side for Xiangqi | RED (the first mover, like WHITE) | OB-045 (non-blocking) |
| XQ6 | Detect / adjudicate perpetual check and perpetual chase in M1? | No | OB-047 |
| XQ7 | Wording for "no legal moves, not in check" (a loss in Xiangqi) | `NO MOVES` / `YOU WIN` or `YOU LOSE` (never "STALEMATE") | OB-047 |
| XQ8 | Game preselected on the new-game screen | Current game, else CHESS | OB-045 (non-blocking) |
| XQ9 | Any automatic draws in Xiangqi (repetition, move limit, bare generals)? | None in M1 | OB-047 |
| XQ10 | Rewrite OB-009 instead of keeping the keypad draft? | Yes (done 2026-10-03 as the epic; acknowledged) | — |
| XQ11 | Xiangqi rules module: hand-written Dart vs. a package (OB-002 Q3 covers Chess only) | Hand-written pure Dart, no new dependency | OB-043 |

Risks: 360×640 phones get ≈ 35 dp cells (OB-044, device pass; ≈ 39.1 dp at 360 dp width after OB-052, accepted in its Open Question 7); Chess-calibrated WC slope for Xiangqi (OB-010 may recalibrate, no PO decision needed).

---

## M1 release readiness — compliance (parallel track)
Source: PO compliance document + PO answers, 2026-10-02. Development of Phases 1–2 does not wait for this track; the **store submission** does.

| ID | Title | Type | Priority | Depends on / blocked by | Status |
|----|-------|------|----------|-------------------------|--------|
| [OB-032](OB-032-clarify-engine-license-boundary-architecture.md) | Engine license boundary & process architecture (listed in Phase 0) | NEEDS_CLARIFICATION | P0 for release | **Legal counsel** (assignment deferred by PO) | **Release blocker**; dev continues with FFI. Risk: process separation would be Android-only |
| [OB-033](OB-033-open-source-licenses-screen.md) | ABOUT / open-source licenses screen + reusable parental gate for external links | NEW_FEATURE | P1 | OB-003, OB-011, OB-032 (final engine list) | **Partially implemented** (2026-10-05): Settings → ABOUT & LICENSES ships (source links copied, Flutter licence page); open: app version (REQ-002), parental gate when a link opens externally |
| [OB-034](OB-034-store-positioning-compliance.md) | Store positioning & listing compliance: banned terms, name, screenshots, rating/privacy forms, copy audit | TECHNICAL_TASK | P1 | PO (app name, tier-7 name — deferred), OB-040 | Naming deferred; needed before submission |
| [OB-040](OB-040-clarify-kids-family-compliance.md) | Target audience & parental gate (decided); children's-policy legal obligations | NEEDS_CLARIFICATION | P1 | Counsel (deferred with OB-032) | **Partially resolved**: adults audience, lowest rating, parental gate, no data collected |

---

## Deferred: Monetization (Later — PO 2026-10-02: "tập trung vào phiên bản full feature trước")
Not in the Chess DoD and not in the M1 build. Kept for when the PO resumes the topic. No analytics in any future version (OB-035 M-D2).

| ID | Title | Type | Priority | Status |
|----|-------|------|----------|--------|
| [OB-035](OB-035-clarify-monetization-model.md) | Monetization decisions log + deferred questions (**single log ticket**, includes the daily limit) | NEEDS_CLARIFICATION | Later | **Deferred**; decisions M-D1–M-D5 recorded |
| [OB-036](OB-036-entitlements-and-purchases.md) | Pro purchases, restore, offline entitlement, paywall (parental gate required) | NEW_FEATURE | Later | Deferred draft |
| [OB-037](OB-037-persona-tier-gating-paywall.md) | Lock Baby/Gentle/Master/God behind Pro + tier paywalls | ENHANCEMENT | Later | Deferred draft |
| [OB-038](OB-038-free-daily-suggestion-limit.md) | Free daily suggestion limit | — | — | **Superseded — merged into OB-035** (ID kept) |
| [OB-039](OB-039-game-gating-paywall.md) | Game gating (Pro: Xiangqi, Go, Shogi, Othello; free: Chess, Caro) | NEW_FEATURE | Later | Deferred draft |

---

## Phase 3 — Shared ODDAS (prerequisite for Phases 4–7)

| ID | Title | Type | Priority | Depends on | Status |
|----|-------|------|----------|------------|--------|
| OB-014 | Design ODDAS: manifest format, hosting, lifecycle states, storage location | TECHNICAL_TASK | P2 | OB-002 | Stub |
| OB-015 | Download, verify and manage on-demand game packs (incl. storage settings) | NEW_FEATURE | P2 | OB-014 | Stub; Home row download states proposed in OB-052 DS-9 ("Design note for OB-015") |

Note (PO compliance document, 2026-10-02): monetization is deferred, so **no download gating** now; every pack is available (pack gating is parked in OB-035). OB-014 must also respect the iOS rule that downloads are **data only** (weights, books, NNUE), never executable code; the engines themselves ship in the app (OB-032).

---

## Phase 4 — Shogi
| ID | Title | Type | Priority | Depends on | Status |
|----|-------|------|----------|------------|--------|
| OB-016 | Shogi advisor: rules module, 9×9 keypad, drop tray `[P*]…[R*]`, promotion prompt, USI notation, game end (incl. repetition/impasse rules), new-game registration | NEW_FEATURE | P2 | OB-015, OB-025, OB-011 | Stub |
| OB-026 | Shogi engine: USI via Fairy-Stockfish + `shogi.nnue` pack mount, WC conversion (Fairy-Stockfish formula, recalibrated), persona mapping (all legal moves incl. drops), performance pass | TECHNICAL_TASK | P2 | OB-005, OB-015, OB-021 | Stub (new) |

## Phase 5 — Gomoku / Caro
| ID | Title | Type | Priority | Depends on | Status |
|----|-------|------|----------|------------|--------|
| OB-017 | Gomoku/Caro: rules variant, board size and engine choice | NEEDS_CLARIFICATION | P2 | OB-002 | Stub |
| OB-027 | Gomoku/Caro advisor: placement keypad, rules/win detection, suggestion card, new-game registration | NEW_FEATURE | P2 | OB-017, OB-025, OB-011 | Stub (new) |
| OB-028 | Gomoku/Caro engine integration, WC conversion, persona candidate set (≤ 900 ms), performance pass | TECHNICAL_TASK | P2 | OB-017, OB-015, OB-021 | Stub (new) |

## Phase 6 — Othello
| ID | Title | Type | Priority | Depends on | Status |
|----|-------|------|----------|------------|--------|
| OB-018 | Othello advisor: 8×8 keypad (legal flipping squares only), Pass handling, game end by disc count, suggestion card, new-game registration | NEW_FEATURE | P2 | OB-002, OB-015, OB-025, OB-011 | Stub |
| OB-029 | Othello engine: Edax 4.4 + book pack, WC conversion (disc difference, slope `s` calibrated), persona mapping (all legal moves), performance pass | TECHNICAL_TASK | P2 | OB-002, OB-015, OB-021 | Stub (new) |

## Phase 7 — Go
| ID | Title | Type | Priority | Depends on | Status |
|----|-------|------|----------|------------|--------|
| OB-019 | Go: input method, board sizes, rules/komi, Pass/Resign behavior | NEEDS_CLARIFICATION | P2 | — | Stub |
| OB-020 | Spike: KataGo performance within 1000 ms on mid-range CPU | TECHNICAL_TASK | P2 | OB-004 pattern | Stub |
| OB-030 | Go advisor: 19×19 input (per OB-019), Pass, game end/scoring display, win-rate card, new-game registration | NEW_FEATURE | P2 | OB-019, OB-025, OB-011 | Stub (new) |
| OB-031 | Go engine: KataGo + GTP adapter + weights pack, WC = winrate, persona candidate set and visit caps, performance pass | TECHNICAL_TASK | P2 | OB-019, OB-020, OB-015, OB-021 | Stub (new) |

Phases 4–7: every game is available to everyone in the full-feature build. Future access (when monetization resumes, OB-039): Caro free; Go, Shogi, Othello Pro (OB-035 M-D3). KataGo is MIT-licensed, so the GPL concern in OB-032 does not apply to Go.

## Cross-game / unscheduled
| ID | Title | Type | Priority | Depends on | Status |
|----|-------|------|----------|------------|--------|
| OB-013 | Define match history requirements | NEEDS_CLARIFICATION | P2 | — | Stub |

### Stub summaries (full tickets to be written when the phase starts)
- **OB-013 — Match history (NEEDS_CLARIFICATION, P2):** `progress.md` lists "Match history storage (SQLite / KV)", but no requirement says what is stored, whether the user can view/export it, or retention.
- **OB-014 — ODDAS design (TECHNICAL_TASK, P2):** Manifest schema, CDN choice (S3 vs. R2), checksum (MD5 vs. SHA-256), lifecycle state machine, pause/resume, checksum-failure behavior (`systemPatterns.md`).
- **OB-015 — On-demand packs (NEW_FEATURE, P2):** Download with progress/ETA, pause/resume, verify, mount, delete from storage settings. Needs PO input on Wi-Fi/mobile-data policy and where storage settings live.
- **OB-016 — Shogi advisor (NEW_FEATURE, P2):** USI notation; drop tray `[P*] [L*] [N*] [S*] [G*] [B*] [R*]`; `[Promote (+)] / [Stay]` prompt; Shogi-specific endings (sennichite repetition, impasse) need PO decisions when the phase starts.
- **OB-017 — Gomoku/Caro (NEEDS_CLARIFICATION, P2):** Gomoku vs. Caro win rules (Caro: a five blocked at both ends does not win); board size; engine (Yixin needs permission; Rapfi/custom).
- **OB-018 — Othello advisor (NEW_FEATURE, P2):** Only legal flipping squares tappable; Pass when no legal move; Edax is GPLv3 (OB-002).
- **OB-019 — Go (NEEDS_CLARIFICATION, P2):** Quadrant zoom vs. coordinate grid; 19×19 only or also 9×9/13×13; ruleset and komi; Pass/Resign meaning in an advisor; win-rate display.
- **OB-020 — KataGo spike (TECHNICAL_TASK, P2):** Validate 1000 ms with ~40 MB weights and 2 threads; may need a smaller network or visit caps.
- **OB-026–OB-031 (new stubs):** Per-game engine and persona work (WC conversion, candidate set, effort caps per OB-021 "Engine mapping", performance pass) and per-game advisor UI for Gomoku/Caro and Go. Each must include "supports all 7 tiers per OB-021" in its acceptance criteria (OB-021 D13).

---

## Persona system (summary)
PO requirement 2026-10-02 ("7-Tier Persona Engine", 🥚 Baby → 👑 God; shown as Noob … Big brain since OB-054, internal keys unchanged). Fully decided in **OB-021** (D1–D14):
- Handicap advisor: the persona changes only the move suggested to the user; no opponent mode.
- Default tier Even (PO revision of 2026-10-03, replaces "no default tier"); changeable at game start and mid-game (immediate recompute).
- Tiers are defined on the user's **win chance (WC)**, so they work for every engine. Baby = the worst moves (within 3 pp of the max loss); Gentle = loss 9–22 pp; Soft = loss 3 to < 9 pp; Even = resulting WC 47–53 % (best move when behind); Solid / Master / God = best move with depth cap 12 / 18 / none. Fallback = closest to band.
- The card shows the suggested move's eval from the user's side. All tiers ≤ 1000 ms / 2 threads / no extra download.
- M1 = Chess + Xiangqi; mandatory for every later game.

---

## Memory bank review

### Gaps (missing requirements)
1. ~~**Session flow is undefined**~~ → resolved for Chess (OB-001, 2026-10-02) and written to `productContext.md`. Persistence after app kill decided 2026-10-04: no resume in M1 (OB-001 Q6).
2. ~~**Chess promotion** is not covered by the two-tap description~~ → resolved: pictogram chooser (OB-006 REQ-010).
3. **No navigation/screens beyond the main screen** — game selection is now OB-011; settings/storage-settings screens are still undocumented (ODDAS needs storage settings; the ToS may need to be re-viewable).
4. **Match history** has no requirements at all (→ OB-013).
5. ~~**Fair-play notice** format~~ → resolved (OB-008), in `productContext.md`.
6. ~~**Business model**~~ → monetization deferred, no analytics (OB-035), in `projectbrief.md`/`productContext.md`.
7. **Localization/accessibility** are not mentioned. → Localization: PO 2026-10-05 "need to support Vietnamese" → OB-053 (EN + VI, incl. screen-reader labels).
8. **Engine strength/time settings** — superseded by the persona tiers (OB-021).
9. **Download policy** — Wi-Fi-only vs. mobile data, background download on iOS, behavior when storage is full.
10. **No Settings screen** — the licenses screen (OB-033) is placed behind an ABOUT key on the new-game screen. → PO 2026-10-04: a Settings dialog on Home (OB-051, content later); ABOUT moves there (decided).

### Contradictions
Status after the memory-bank update of 2026-10-02: rows marked **fixed** are corrected in the memory bank; the others remain open there too.

| Topic | Source A | Source B |
|-------|----------|----------|
| Engine execution model | `systemPatterns.md`: native "executables" over standard I/O pipes | iOS cannot spawn processes → **fixed**: memory bank records in-process FFI as provisional, notes iOS infeasibility, final decision OB-032 |
| Input latency target | BRD: < 1.2 s | UI consultation: < 1.5 s (`activeContext.md` treats 1.2 s as binding — needs PO sign-off) |
| `keyDisabled` color | `designSystem.md` palette `#1A1B20` | sample code `#16171E` |
| Background color | `bgDark` `#0F1015` | "or `#000000` true black" |
| Dark mode | `productContext.md`: "dark mode by default" (implies light mode exists) | `designSystem.md`: "dark mode only by default" |
| "Two-tap" entry | Name says two taps | Tap 1 is "source column + row" = two key presses → **fixed**: 1–2-tap board (OB-006) |
| Xiangqi notation | Input: column + row coordinates | Output example `P2 ➔ 5` is WXF-like (and incomplete) → **fixed** (PO 2026-10-03, XQ4): no notation in input (tap board); output in absolute `A`–`I` / `1`–`10` with piece disc, WXF only in the expert line (OB-001 Q10, OB-046); `productContext.md` updated |
| Suggestion secondary line | `productContext.md`: `Depth: 18 \| 1.2M nps` | `designSystem.md`: `EVAL: +0.4 \| DEPTH: 16 \| 850k nps` → **fixed**: `EVAL +1.4 \| DEPTH 16 \| 850k nps` (OB-007) |
| Haptic events | `productContext.md`: Move Accepted / Engine Move Ready / In-Check | `designSystem.md`: key tap / engine ready / in check → **fixed**: all four events (OB-006, OB-007); exact "move accepted" haptic chosen in OB-006 |
| 30 MB base budget | `projectbrief.md`: ≤ 30 MB with Chess + Xiangqi | `activeContext.md`: all engine binaries must ship in the app — budget likely infeasible |
| Xiangqi protocol | `systemPatterns.md`: "UCCI / UCI" | `activeContext.md`: unconfirmed whether UCCI is needed → **fixed**: UCCI not needed, `UCI_Variant xiangqi` verified (OB-005, 2026-10-03); `systemPatterns.md` and `activeContext.md` corrected |
| Checksum | "MD5/SHA-256" (both, undecided) | — |
| Storage | `techContext.md`: "SQLite or key-value store" | no storage package in the dependency list |
| Milestone 1 scope | PO (2026-10-02): persona "Milestone 1, all games" | Memory bank: M1 = Chess + Xiangqi → **fixed** (OB-021 D13, `projectbrief.md`) |
| GPL boundary | PO compliance doc: engines as separate processes (IPC), no linking | iOS: no child processes (`activeContext.md`); OB-004 in-process FFI → OB-032 (counsel deferred; dev continues with FFI) |
| Positioning | Memory bank: "real-time advisor", working title "OmniChess Advisor" | PO compliance doc: "real-time advisor/assistant" banned in store copy → description **fixed** in `projectbrief.md`; app name still open (OB-034) |
| Privacy vs. funnel | `projectbrief.md`: full privacy | PO doc: conversion funnel → **resolved**: no analytics (OB-035 M-D2) |
| Monetization conflicts | Tier access, Xiangqi Pro, 25/day limit, Paywall 2 copy | Parked with monetization (OB-035 "Known conflicts") |

### Docs vs. code
- ~~`activeContext.md` says the "starter `pubspec.yaml` [was] updated"~~ → **fixed**: now described as a snippet in `techContext.md`.
- `progress.md` accurately reflects that no implementation work has started.
- App identity: working title "OmniChess Advisor" / package `omnichess_advisor` vs. repository name `omni-board`.

### Ambiguous business rules
- ~~Evaluation perspective~~ — resolved: user's side (OB-021 D12).
- "Urgent threat" haptic — anything beyond check? (OB-007 Q1; treated as check-only.)
- ~~Xiangqi repetition rules (perpetual check/chase)~~ — decided: not adjudicated in M1 (PO 2026-10-03, XQ6, OB-047).
- ~~Chess draw rules~~ — OB-024 A1–A3, accepted assumptions (2026-10-02).
- Gomoku vs. Caro win rules; Go ruleset/komi; Go Pass/Resign meaning in an advisor app.

## Top open questions for the PO
Resolved 2026-10-02: all OB-001 Chess questions. Decisions: one side per game, undo in the Chess DoD, tap board (memory bank updated), pictogram promotion, coordinates, user-side evaluation. Accepted assumptions: initial position only, FIDE draw handling, no resign buttons. The user's own move: one-tap confirm or override on the board (PO decision 2026-10-03, OB-041; replaced "user enters every move"). Also resolved: fair-play format (OB-008); compliance answers (OB-035, OB-040).

**Chess slice status: ready to build, with no PO blockers.** Only the Flutter SDK must be installed. Rules library decided 2026-10-02: `chess` 0.8.1 (OB-002 Q3, for Chess only).

Non-blocking:
1. Undo assumptions U-A1 (repeated taps go further back) and U-A3 (no redo) (OB-012).
2. Technical check (not a PO question): `chess` on Dart 3. The fallback (vendoring the file) is pre-approved by the license.

**Blocking release / later phases:**
5. **Licensing (OB-002/OB-032):** counsel deferred by the PO ("tính sau"). It's a release blocker, not a development blocker. Also: Yixin permission or an alternative; legal review of the fair-play text.
6. **Size budget (OB-010):** If 30 MB is infeasible, what gives?
7. **Latency target:** confirm 1.2 s (not 1.5 s) as the binding input-cycle target.
8. ~~**Phase 2 Xiangqi decisions XQ1–XQ11**~~ — **resolved** (PO 2026-10-03, all defaults accepted; includes Xiangqi notation = OB-001 Q10 → XQ4 and the rules module → XQ11).
9. **App language:** ~~English-only or localized?~~ → answered (PO 2026-10-05): **support Vietnamese**, full in-app UI (OB-053). Earlier: Language picker on Home, English only (OB-051); fair-play notice follows the app language once Vietnamese ships (OB-051 D2). OB-053 decisions (PO 2026-10-05): Vietnamese ships in **M1**; BA/dev draft the copy, PO signs off; persona tier names translated (tier 7 follows OB-034); default = device language, saved choice wins. **Resolved.**

**Before store submission (deferred by the PO, not needed for development):**
10. Counsel assignment for OB-032 and OB-040's legal questions.
11. App name and tier-7 label (OB-034).

Answered 2026-10-02: monetization deferred, no analytics, Shogi/Othello Pro later (OB-035); audience and parental gate decided by BA recommendation (OB-040). All other monetization questions are parked in OB-035.
