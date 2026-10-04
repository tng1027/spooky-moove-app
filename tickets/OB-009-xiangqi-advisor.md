# Ticket Analysis

> **Progress (2026-10-04):** OB-042–OB-047 (plus OB-048, always two-tap entry) are done on the iOS simulator. Still open: the Xiangqi pass of OB-010 (harness and size done 2026-10-04; simulator latency run pending, device numbers in the final pass) (DoD item "latency per tier, input cycle, FPS and thermal recorded"; ≤ 1000 ms on reference devices) and the real-device check of the 35 dp cells on 360×640 (XQ3).

> **Status: Rewritten as the Phase 2 epic (2026-10-03).** The keypad-era draft is superseded by the tap board (OB-006) and every later Chess decision. The work is split into OB-042–OB-047 plus the Xiangqi pass of OB-010. This file holds the carry-over matrix, the Xiangqi Definition of Done and the Phase 2 PO decisions. Implementation status lives in the child tickets.
>
> **PO decisions (2026-10-03): all recommended defaults XQ1–XQ11 accepted.** No PO blockers remain for Phase 2; OB-001 Q10 is resolved (XQ4).

TICKET_TYPE: NEW_FEATURE (epic)
CONFIDENCE: HIGH

Xiangqi does not exist in the app. PO request (2026-10-03): "For chess, it is all good now. I would like to move all behavior we decide to the next game Xiangqi." So this is a new user-facing capability that reuses every decided Chess behaviour. It changes behaviour only where Xiangqi's rules or board need it. Classification confidence is HIGH. The Xiangqi-only choices (XQ1–XQ11) were decided by the PO on 2026-10-03 and are recorded as decisions in each child ticket.

## Ticket Title
[Feature] Xiangqi advisor (Phase 2 epic): carry every Chess behaviour over to Xiangqi

## Summary
Add Xiangqi as the second bundled game. The user picks XIANGQI and RED or BLACK on the new-game screen. They enter moves on a legal-only intersection tap board with character pieces. On their turn they get the active tier's suggestion in absolute coordinates (`[炮] H3 ➔ E3`), confirm it with ✓ I PLAYED IT or override it on the board, undo moves, and see Xiangqi game end (checkmate, no legal moves). The engine is the bundled Fairy-Stockfish with `UCI_Variant xiangqi`.

## Business Context
- M1 = Chess + Xiangqi (`projectbrief.md`, README "Milestones"). Phase 2 completes M1.
- Xiangqi reuses the bundled engine, so it adds no engine size (`systemPatterns.md`). UCCI is not needed (OB-005, `techContext.md`).
- Multi-Discipline Enthusiast persona (`productContext.md`). The no-notation principle applies (OB-001 Q8).
- Persona tiers are mandatory for every game (OB-021 D13). Xiangqi is available to everyone (OB-035 M-D1).

## Current Behavior
- Only Chess is offered (`GameKind` has one value, `chess`).
- The engine bridge already supports Xiangqi. `GameEngine.setVariant('xiangqi')` works, the UCI parser reads rank 10, and the start position gives 44 legal moves (OB-005, OB-022 simulator test).
- The advisor layer reads `chessBoardControllerProvider`, `ChessMove` and `ChessGameStatus` directly, and `SuggestionController` hard-codes `_variant = 'chess'`. OB-042 lists these coupling points.

## Expected Behavior
Every decided Chess behaviour works the same way in Xiangqi, except for the adaptations in the matrix below.

### Carry-over matrix (Chess decision → Xiangqi)
| # | Chess decision (source) | Xiangqi | Ticket |
|---|-------------------------|---------|--------|
| 1 | One-time fair-play notice, FAIR PLAY key (OB-008) | Reuse as is | — |
| 2 | New-game screen: GAME row, LEVEL row (default Even), YOUR SIDE (default first mover), BACK if a game is in progress, FAIR PLAY, full-width green START GAME, double-tap guard (OB-011 rev.) | Adapt: GAME row = two stacked keys CHESS / XIANGQI; sides RED / BLACK with 帥 / 將 discs; default RED; Even kept when switching games | OB-045 |
| 3 | NEW GAME during a game asks "DISCARD THE CURRENT GAME?"; game reset only on START; BACK keeps the game (OB-011) | Reuse as is (also covers switching games mid-game) | OB-045 |
| 4 | Exactly one side per game, suggestions only for it (OB-001 Q1) | Reuse; Red moves first (like White) | OB-042, OB-045 |
| 5 | Standard initial position only (OB-001 Q3) | Reuse | OB-043 |
| 6 | Legal-only tap board, smart 1–2-tap entry, auto-commit, cancel rules, user's side at the bottom, edge labels, no notation in input (OB-006) | Adapt: intersection board, 9×10 cells centred on points, nearest-legal snapping, character discs | OB-044 |
| 7 | Promotion chooser (OB-006) | N/A (Xiangqi has no promotion) | — |
| 8 | Commit guard 250 ms; `selectionClick` on select, `lightImpact` on commit (OB-006, OB-041) | Reuse | OB-044 |
| 9 | Suggestion card: absolute coordinates, `✕` capture, instruction line for special moves, expert line, `mediumImpact` (OB-007) | Adapt: moving piece disc + coordinates in Red's frame (`[炮] H3 ➔ E3`); no instruction line; expert line starts with WXF (`C2.5 · EVAL …`) | OB-046 |
| 10 | Suggestion highlighted on the board in green (OB-007) | Adapt: green ring on the piece + green dot / ring on the destination | OB-044, OB-046 |
| 11 | Check: king square red, `heavyImpact` on the user's turn (OB-006, OB-007) | Reuse: general's cell red, `heavyImpact`, no "JIANG" text | OB-044, OB-046 |
| 12 | Win rate in the top bar: `WIN RATE nn%` / `WIN RATE --` / mate lines / `GAME OVER` (OB-041 rev. 3) | Reuse | OB-046 |
| 13 | 7-tier persona, default Even, recompute on tier change, (position, tier) cache, all legal moves as candidates, eval from the user's side (OB-021, OB-022, OB-023) | Reuse with `UCI_Variant xiangqi`; WC slope may be recalibrated in OB-010 | OB-046 |
| 14 | Turn loop; status line states WAITING FOR OPPONENT / PICK A LEVEL ABOVE / ✓ I PLAYED IT (disabled / enabled green) / NEW GAME (OB-025, OB-041 rev. 2–3) | Reuse | OB-046 |
| 15 | ✓ I PLAYED IT commits the displayed suggestion; any other legal board move is an override; never a stale suggestion (OB-041) | Reuse | OB-046 |
| 16 | UNDO: one move per tap, full restore, from game over, same suggestion from the cache (OB-012) | Reuse | OB-043, OB-044, OB-046 |
| 17 | Engine timeout 2 s, ENGINE ERROR + RETRY (OB-007) | Reuse | OB-046 |
| 18 | Game end: result on two lines in the card, board dimmed, entry blocked, GAME OVER in the top bar, NEW GAME status button with 500 ms guard, no resign/draw buttons (OB-024, OB-041) | Adapt: Xiangqi rules: checkmate, no legal moves = loss, no automatic draws, no perpetual check/chase adjudication | OB-047 |
| 19 | Claimable-draw hints (OB-024 A2) | N/A in M1 (no draw rules, XQ9) | OB-047 |
| 20 | Layout order, design tokens, `AppKey`, 360 dp × text scale 2.0 (OB-003, OB-041) | Reuse; board size becomes aspect-aware | OB-042, OB-044 |
| 21 | No analytics; every tier and game available (OB-035) | Reuse | — |
| 22 | Performance NFRs per tier (OB-010) | Xiangqi pass | OB-010 |
| 23 | Resume after app kill (OB-001 Q6) | Still out of scope | — |

## User Story
As a Xiangqi player at a physical board, even without knowing Xiangqi notation
I want the same advisor I use for Chess (tap the move, get my level's suggestion, confirm with one tap)
So that I can use one tool for both games.

## Functional Requirements
- REQ-001: Every row of the carry-over matrix marked "Reuse" behaves in Xiangqi exactly as in Chess.
- REQ-002: Every "Adapt" row is delivered by its child ticket.
- REQ-003: Chess behaviour is unchanged. All existing Chess unit, widget and integration tests still pass after every child ticket.

## Business Rules
- BR-001: Only strictly legal Xiangqi moves can be entered (Asian/WXF move rules: palace, river, elephant eye, horse leg, cannon screen, flying general).
- BR-002: A player with no legal move loses: checkmate, or no legal move without check.
- BR-003: No notation knowledge is needed for input (OB-001 Q8). Notation (WXF) appears only in the expert line (XQ4).
- BR-004: Introduce game-agnostic seams only where Xiangqi needs them (workspace rule 09). No generic framework for future games.

## User Flow
```text
New game → [XIANGQI] → side [RED] / [BLACK] → level (Even preselected) → START GAME
↓
Advisor: TopBar / PersonaRow / SuggestionCard / intersection board / StatusLine
↓
Opponent's turn: user taps the opponent's move on the board (1–2 taps, snapping)
↓
User's turn: card "[炮] H3 ➔ E3", board rings H3 / E3, top bar WIN RATE nn%
↓
✓ I PLAYED IT  — or —  another legal move on the board (override)
↓
… → checkmate / no legal moves → result in the card, NEW GAME
```

## Acceptance Criteria (Xiangqi Definition of Done)
- Given first use, When the app opens, Then the fair-play notice is shown as for Chess (OB-008).
- Given the new-game screen, When the user picks XIANGQI and RED and taps START GAME, Then the advisor opens at the Xiangqi initial position with Red at the bottom and the level Even (OB-045).
- Given any position, When the user enters the opponent's move, Then only legal moves are possible, in at most 2 taps (OB-044).
- Given the user's turn, When a suggestion is ready, Then the card shows the moving piece and absolute coordinates, the board highlights the move, the top bar shows the win rate, and ✓ I PLAYED IT is enabled, within ≤ 1000 ms on reference devices (OB-046, OB-010).
- Given the user taps UNDO, When moves exist, Then one move per tap is taken back and the same suggestion returns for the same position and tier (OB-046).
- Given checkmate or no legal moves, When the move is accepted, Then the result is shown from the user's side and the board locks (OB-047).
- Given the Chess test suite, When Phase 2 is complete, Then all Chess tests pass unchanged (REQ-003).
- Given the Xiangqi pass of OB-010, When reported, Then latency per tier, input cycle, FPS and thermal are recorded.

## Edge Cases
Covered in the child tickets: flying general, horse leg / elephant eye blocking, cannon screens, soldiers before and after the river, no legal moves without check (loss), perpetual check/chase (not adjudicated), user plays Black (board flipped), switching games mid-game, 360×640 screens (35 dp cells).

## In Scope
- Child tickets OB-042–OB-047 and the Xiangqi pass of OB-010.

## Out of Scope
- Perpetual check / chase adjudication and automatic draws (XQ6, XQ9).
- Custom start positions, resume after app kill, match history (OB-001 Q3/Q6, OB-013).
- Chinese-language UI; Chinese labels such as "JIANG" or 楚河漢界 on the board.
- Pro gating of Xiangqi (OB-039, deferred).

## Dependencies
- Phase 1 complete (done on the iOS simulator).
- PO decisions XQ1–XQ11: **resolved** 2026-10-03 (README "Phase 2 PO decisions").
- OB-002 (licensing: Xiangqi rules module, XQ11) and OB-033 (attribution of the piece glyph assets).

## Child tickets and order
| Order | ID | Title | Type |
|-------|----|-------|------|
| 1a | [OB-042](OB-042-game-agnostic-seams-for-second-game.md) | Game-agnostic seams for a second game (side model, active-game seam, engine variant, aspect-aware board size) | TECHNICAL_TASK |
| 1b | [OB-043](OB-043-xiangqi-rules-module.md) | Xiangqi rules module (pure Dart) with perft validation | TECHNICAL_TASK |
| 2 | [OB-044](OB-044-xiangqi-intersection-tap-board.md) | Xiangqi intersection tap board: character pieces, states, sizing, snapping | NEW_FEATURE |
| 3 | [OB-045](OB-045-new-game-xiangqi-and-red-black.md) | New-game screen: XIANGQI in the GAME row, RED / BLACK sides | ENHANCEMENT |
| 4 | [OB-046](OB-046-xiangqi-advisor-wiring.md) | Xiangqi advisor wiring: engine variant, suggestion card + WXF, I PLAYED IT, undo, persona | NEW_FEATURE |
| 5 | [OB-047](OB-047-xiangqi-game-end.md) | Xiangqi game end: checkmate and no legal moves | NEW_FEATURE |
| 6 | [OB-010](OB-010-milestone1-size-latency-thermal-validation.md) | Xiangqi performance pass | TECHNICAL_TASK |

1a and 1b can run in parallel.

## Decisions (PO 2026-10-03, all recommended defaults accepted)
XQn = Designer Qn; XQ11 added by the BA.
- **XQ1:** Chinese characters on discs (OB-044).
- **XQ2:** New board-only `pieceRed` token (OB-044).
- **XQ3:** 40 dp cells at 360 dp width (≈ 35 dp at 360×640) with nearest-legal snapping; device check in the final pass (OB-044).
- **XQ4 (= OB-001 Q10):** Absolute `A`–`I` / `1`–`10` in Red's frame + piece disc; WXF only in the expert line (OB-046).
- **XQ5:** Default side RED (OB-045).
- **XQ6:** No perpetual check / chase adjudication in M1 (OB-047).
- **XQ7:** `NO MOVES` / `YOU WIN` or `YOU LOSE` (OB-047).
- **XQ8:** Preselect the current game, else CHESS (OB-045).
- **XQ9:** No automatic draws (OB-047).
- **XQ10:** OB-009 rewritten as this epic (acknowledged).
- **XQ11:** Hand-written pure-Dart rules module, no new dependency (OB-043).

## Assumptions
None open at epic level (see child tickets).

## Open Questions
None. Remaining risk: tap accuracy on 360×640 phones (device pass, OB-044 / OB-010).

## Developer Handoff
- Start with OB-042 (refactor, no behaviour change, Chess tests as the safety net) and OB-043 (pure Dart, test-first against Fairy-Stockfish perft) in parallel.
- Treat the carry-over matrix as the regression checklist for Xiangqi integration tests (mirror `integration_test/turn_loop_test.dart`, `suggestion_card_test.dart`, `new_game_test.dart`).
- Add the `> **Status: ...**` block to each child ticket and update the README when it is done (ticket-status convention).
