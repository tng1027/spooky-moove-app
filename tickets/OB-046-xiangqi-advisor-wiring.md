# Ticket Analysis

> **Status: Done on iOS simulator (2026-10-03).** The Xiangqi card is complete.
> - Main line: a 48 dp disc for the moving piece, then `H3 ➔ E3` in Red's frame, with ` ✕` for a capture (`XiangqiMoveFormat`).
> - Expert line: `C2.5 · EVAL …` (`XiangqiWxf`, a port of Fairy-Stockfish's `NOTATION_XIANGQI_WXF`). Two differences in scope: a sideways move uses `.` where Fairy-Stockfish writes `=`, and the tandem rules (`H++7`, `P-+1`, `15.6`, `26.5`) follow Fairy-Stockfish exactly.
> - Seam: the new slot `GameWidgets.expertLine` means the shared card has no Xiangqi branch. Chess output is unchanged.
> - Fix in `SuggestionController`: when a session switched games (Chess → Xiangqi or back), the first search ran on the previous game's variant and position, because Riverpod notifies the session listener before the derived providers are stale-marked. The refresh now runs one microtask later, and any request already in flight is dropped.
> - Tests: every WXF case from Fairy-Stockfish's `test.py` plus the ticket's cases and tandems; Xiangqi card widget tests; a real Xiangqi session on the fake engine (variant switches chess → xiangqi → chess, heavyImpact on check, timeout then RETRY). The full suite has 471 tests.
> - Simulator: all 7 tiers suggest legal moves (Master and God take 900 ms); the Baby search scores all 44 moves; the new `xiangqi_turn_loop_test` covers confirm, Black's reply, override, undo restoring the same suggestion, tier change with the key disabled, and Black waiting for Red. All 31 integration tests pass.

TICKET_TYPE: NEW_FEATURE
CONFIDENCE: HIGH

Xiangqi suggestions don't exist in the app. Everything except the move text is carried over from decided Chess behaviour: turn loop (OB-025), persona (OB-021/022/023), I PLAYED IT (OB-041), undo (OB-012), top-bar win rate, engine timeout and RETRY (OB-007). The move text follows the Designer's spec: absolute coordinates with the moving piece, WXF in the expert line (PO 2026-10-03, XQ4 = OB-001 Q10).

## Ticket Title
[Feature] Xiangqi advisor wiring: tier-based suggestions with `UCI_Variant xiangqi`, absolute-coordinate card with WXF expert line, I PLAYED IT and undo

## Summary
On the user's turn in a Xiangqi game, compute the active tier's move with Fairy-Stockfish in the `xiangqi` variant. The card shows it as the moving piece's disc plus absolute coordinates in Red's frame (`[炮] H3 ➔ E3`, `✕` for a capture), with the expert line `C2.5 · EVAL +0.3 | DEPTH 16 | 850k nps`. The board highlights the move and the top bar shows the win rate. ✓ I PLAYED IT commits it, any other board move overrides it, and UNDO restores the same suggestion.

## Business Context
- Carry-over matrix rows 9–17 (OB-009).
- No-notation principle (OB-001 Q8): coordinates match the board edge labels. WXF is for experts only, in the de-emphasised line.

## Current Behavior
- Shared advisor states exist for Chess: `SuggestionController` (no tier / waiting / thinking / ready / failed / game over), status line states, `TopBar` win rate, `ConfirmPlayedKey`, `UndoKey`. After OB-042 they read the game through the active-game seam.
- The engine already returns legal Xiangqi moves; `PersonaSuggester` already handles Xiangqi (OB-022 simulator test: Baby scores 44 moves in 311 ms).

## Expected Behavior
### Card format (XQ4)
| Move | Main line (suggestion style, `accentGreen`) | Expert line (`textSecondary`) |
|------|---------------------------------------------|-------------------------------|
| Normal | `[炮 disc] H3 ➔ E3` | `C2.5 · EVAL +0.3 \| DEPTH 16 \| 850k nps` |
| Capture | `[俥 disc] A1 ➔ A7 ✕` | `R9+6 · EVAL +1.2 \| …` |

- The disc is the moving piece in the user's colour (OB-044 asset). Coordinates are uppercase file `A`–`I` + rank `1`–`10`, absolute in Red's frame, matching the board edge labels whichever side the user plays.
- No instruction line (Xiangqi has no castling, en passant or promotion).
- WXF from the mover's own side: files numbered 1–9 from the mover's right; `+` forward, `-` backward, `.` sideways; tandem pieces per the WXF standard. Mates in the expert line use `M4` / `-M4` as in Chess.
- Top bar: `WIN RATE nn%` (green ≥ 50 %, red below), `YOU MATE IN n` / `OPPONENT MATES IN n`, `WIN RATE --` with no suggestion, `GAME OVER` (unchanged, OB-041 rev. 3).

### Behaviour carried over unchanged
- A suggestion is requested only on the user's turn with a tier and a game in progress. A tier change recomputes it, results for an old position or tier are dropped, and the (position, tier) cache gives the same move for the same position and tier (OB-022, OB-007 REQ-009).
- Thinking → ready with `mediumImpact`. Timeout 2 s or engine failure → `ENGINE ERROR` + RETRY.
- `heavyImpact` when the opponent's move puts the user's general in check (the cell is already red, OB-044).
- Status line: WAITING FOR OPPONENT / PICK A LEVEL ABOVE / ✓ I PLAYED IT disabled while thinking or failed / enabled green when ready / NEW GAME at game over (OB-047).
- ✓ I PLAYED IT commits exactly the displayed move through the board's commit path (250 ms guard, `lightImpact`). Any other legal board move is an override with no special handling (OB-041 D4).
- UNDO: one move per tap; after undo onto the user's turn, the same suggestion and the enabled key come back without a new search (OB-012 REQ-009).

## User Story
As a Xiangqi player at a physical board
I want my level's suggested move shown as the piece and the two board points, and to confirm it with one tap
So that I can play it on the real board at a glance without reading notation.

## Functional Requirements
- REQ-001: Search with variant `xiangqi` for Xiangqi sessions (OB-042 REQ-005), using the position from the rules module (OB-043 `toEnginePosition`).
- REQ-002: All 7 tiers work as specified in OB-021 (all legal moves as candidates for tiers 1–4, depth caps 12 / 18 / none), with the current WC slope (OB-021 note: may be recalibrated per variant in OB-010).
- REQ-003: Convert the engine move with `moveFromUci`. An illegal or unknown move is an engine failure (ENGINE ERROR + RETRY), as in Chess.
- REQ-004: A Xiangqi move formatter (pure Dart): main line `FROM ➔ TO` with `✕` for captures; disc kind = moving piece.
- REQ-005: A WXF formatter (pure Dart) for the expert line, prefixed to the existing `EvalFormat.expertLine` with ` · `.
- REQ-006: A Xiangqi card move widget (OB-042 REQ-004): disc + main line, then the expert line.
- REQ-007: Board highlight via `showSuggestion` (OB-044 suggested states). It is cleared when the move is committed or the position changes.
- REQ-008: Turn loop, status line, top bar, I PLAYED IT and UNDO behave exactly as in Chess. Nothing is added to these shared widgets beyond the OB-042 seam.

## Business Rules
- BR-001: The suggestion is always the active tier's move (OB-021 D1, D12; OB-041 D1).
- BR-002: The evaluation is from the user's side and describes the suggested move (OB-021 D12).
- BR-003: No notation in the main line. WXF appears only in the expert line (XQ4).
- BR-004: Coordinates are absolute in Red's frame, the same for both sides, matching the edge labels (as Chess uses White's frame, OB-007).

## User Flow
```text
User is Red, tier Even → START GAME
↓
Card THINKING… → "[炮] H3 ➔ E3", expert "C2.5 · EVAL +0.3 | DEPTH 8 | …"
Board: green ring on H3, green dot on E3; top bar WIN RATE 52%; [✓ I PLAYED IT] enabled
↓
├─ taps ✓ I PLAYED IT → H3→E3 applied → WAITING FOR OPPONENT
└─ enters H1→G3 on the board → applied (override) → WAITING FOR OPPONENT
↓
User enters Black's reply → next suggestion
```

## Acceptance Criteria
- Given a new Xiangqi game as Red with tier Even, When the advisor opens, Then a legal Red move is suggested within the 2 s timeout on the simulator (≤ 1000 ms target on reference devices, OB-010), with `mediumImpact`.
- Given the suggestion is the cannon H3→E3, When the card renders, Then the main line shows the Red cannon disc and `H3 ➔ E3`, and the expert line starts with `C2.5 · EVAL`.
- Given a suggested capture, When the card renders, Then the main line ends with `✕` and the board shows a green ring on the target piece.
- Given the user plays Black and the suggestion is the Black cannon from B8 to E8, When the card renders, Then the main line reads `B8 ➔ E8` (Red's frame) and the expert line starts with `C2.5` (Black numbers files from its own right, so file B is Black's 2).
- Given a suggestion is ready, When the user taps ✓ I PLAYED IT, Then exactly that move is applied, `lightImpact` fires once and the status line reads WAITING FOR OPPONENT.
- Given a suggestion is ready, When the user enters a different legal move on the board, Then it is applied with no override message.
- Given a suggestion is being computed (including after a tier change), When the status line renders, Then ✓ I PLAYED IT is visible and disabled.
- Given the user confirmed a suggestion, When they tap UNDO, Then it is their turn again, the same suggestion is shown without a new search, and the key is enabled.
- Given each of the 7 tiers in the initial position, When a suggestion is computed, Then it is a legal move, Baby scores all 44 moves, and the selection follows the tier rules (OB-022 tests reused with Xiangqi positions).
- Given the opponent's move puts the user in check, When it is accepted, Then `heavyImpact` fires and the general's cell is red.
- Given the engine times out, When 2 s pass, Then the card shows ENGINE ERROR + RETRY, and RETRY recomputes.
- Given a Chess game after a Xiangqi game (or the reverse), When the first suggestion arrives, Then it is legal in the new game (variant switched, cache cleared).
- Given WXF formatting, When unit-tested, Then advances, retreats, sideways moves for all piece kinds, both sides, and two same pieces on one file (tandem) produce the WXF standard strings.
- Given the main-line text, When inspected for both sides, Then it never contains WXF letters.

## Edge Cases
- Tandem pieces (two chariots, cannons, horses or soldiers on one file) and three or more soldiers on a file: WXF disambiguation.
- Mate scores (`YOU MATE IN n` in the top bar, `M n` in the expert line).
- Tier change during thinking; NEW GAME during thinking (no stale suggestion, OB-011).
- User plays Black at game start: no suggestion until Red's move is entered.
- The suggestion arrives while a selection is pending on the board: the selection stays (OB-041 REQ-005).

## In Scope
- Variant wiring, Xiangqi move and WXF formatters, Xiangqi card move widget, board highlight hookup, Xiangqi integration tests (mirroring `turn_loop_test`, `suggestion_card_test`): confirm path, override path, undo path, tier change.

## Out of Scope
- Game end texts and states (OB-047). Performance measurement (OB-010).
- Showing WXF or Chinese notation in the main line. Spoken suggestions.

## Dependencies
- OB-042 (seam, variant per game, card slot), OB-043 (rules), OB-044 (board, discs, suggested states), OB-045 (to reach Xiangqi from the UI).
- Shared: OB-007, OB-012, OB-022, OB-025, OB-041.
- XQ4 (decided, PO 2026-10-03).

## Decisions
- **XQ4 (= OB-001 Q10), PO 2026-10-03:** main line in absolute coordinates `A`–`I` / `1`–`10` (Red's frame) with the piece disc; WXF only in the expert line.

## Assumptions
- A-1: The Designer's example `[炮] B3 ➔ E3` paired with `C2.5` is inconsistent: from Red's side, B3→E3 is `C8.5`, and `C2.5` is H3→E3. This ticket uses the consistent pair `[炮] H3 ➔ E3` / `C2.5`.
- A-2: The Chess-calibrated WC slope is acceptable until OB-010 measures Xiangqi (OB-021 calibration note).

## Open Questions
None.

## Developer Handoff
- The only new code should be the Xiangqi move formatter, the WXF formatter, the card move widget and the seam implementation. If a shared advisor widget needs a Xiangqi branch, the OB-042 seam is missing something; fix it there.
- Put the formatters in `lib/features/xiangqi/domain/`, unit-tested from FENs. WXF needs the board to resolve tandems, so format from (position before the move, move).
- Reuse `EvalFormat` unchanged; only prefix the WXF string.
