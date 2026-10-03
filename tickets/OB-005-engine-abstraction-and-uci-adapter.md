# Ticket Analysis

> **Status: Done on iOS simulator (2026-10-03).** Mid-range device timing (BR-003) deferred to the final device pass / OB-010.
> - Interface `GameEngine` + `SearchHandle` (`lib/core/engine/game_engine.dart`), typed models (`engine_models.dart`: `CentipawnScore` / `MateScore`, `ScoreBound`, `SearchLine`, `EngineMove` / `NoLegalMove`, `SearchResult`, `SearchLimits`, `EngineConfig`).
> - Transport-agnostic per OB-032: `EngineTransport` (text lines); `FairyStockfishEngine` implements it.
> - `UciEngine` (`uci/uci_engine.dart`): applies `Threads 2` / `Hash 16` on start; `setVariant` via `UCI_Variant`; `go movetime N [depth D]` with a hard 900 ms cap; MultiPV for OB-022's all-move search; new search cancels the old one (`SearchCancelledException`) and stale output is never delivered; engine errors fail searches with `EngineFailureException`; `start()` works again after dispose or failure.
> - Pure parser (`uci/uci_parser.dart`): cp, mate (signed), lower/upper bounds, multipv, `info string` / `currmove` / malformed lines ignored, `bestmove (none)` → `NoLegalMove`.
> - Tests: 38 unit tests pass (parser + adapter with a fake transport). Simulator integration test 6/6: defaults accepted; Chess best move legal and delivered in 902 ms; Xiangqi best move legal; A→B delivers only B; all-move search scores 20/20 moves at depth 8; depth cap 12 respected; restart works.
> - Assumption confirmed: **UCCI not needed** — `UCI_Variant xiangqi` over UCI returns legal Xiangqi moves (recorded in `techContext.md`).
> - Scores stay from the side to move; user-side conversion belongs to OB-022/OB-007. The Riverpod "Engine Search State" provider is deferred to OB-007/OB-025.
> - Open Question 2 (streaming updates on the card) remains for OB-007; the adapter supports both.

TICKET_TYPE: TECHNICAL_TASK
CONFIDENCE: HIGH

`systemPatterns.md` prescribes a shared engine abstraction (start, set options, set position, go with limits, stop, parse result) with one adapter per protocol family, so the UI stays game-agnostic. Milestone 1 needs only the UCI adapter (Chess and Xiangqi via `UCI_Variant`). This is internal work that the suggestion card (OB-007) consumes.

## Ticket Title
[Tech] Add a game-agnostic engine interface with a UCI adapter and bounded-search defaults

## Summary
On top of the FFI bridge (OB-004), implement the engine interface and a UCI adapter that applies the NFR defaults (Threads ≤ 2, Hash 16–32 MB, per-move time limit), sends positions, streams search info (eval, mate, depth, nps), returns the best move, and supports stop/cancel and variant selection.

## Business Context
- `systemPatterns.md`: "shared engine abstraction … one protocol adapter per protocol family".
- `techContext.md` NFRs: engine response ≤ 1000 ms on mid-range hardware; max 2 threads; 16–32 MB hash; time/depth limits per move.
- The suggestion card shows best move, evaluation (centipawns or mate) and search info (`Depth: 18 | 1.2M nps`) (`productContext.md`).

## Current Behavior
Nothing implemented. OB-004 provides raw line I/O only.

## Expected Behavior
- A caller can: start the engine, set the variant (`chess`, `xiangqi`), send a position (start position + move list, or FEN), request a search with a time limit, receive streaming search updates, receive the final best move, stop a search, and dispose the engine.
- Defaults applied on start: `Threads` ≤ 2, `Hash` within 16–32 MB, per-move time limit that keeps total response ≤ 1000 ms.
- Search updates expose: score in centipawns or mate-in-N, depth, nodes per second, principal variation's first move.
- A new position request cancels any running search; stale results are never delivered for a newer position.

## Business Rules
- BR-001: Max 2 engine threads (thermal/power NFR).
- BR-002: Hash table 16–32 MB by default.
- BR-003: Final engine response ≤ 1000 ms in standard tactical positions on mid-range hardware.
- BR-004: Results always correspond to the latest submitted position.

## User Flow
Not user-facing. Consumer flow:

```text
Rules layer submits position (variant + moves)
↓
Adapter: stop running search (if any) → position … → go movetime N
↓
Stream of info updates (depth, score, nps)
↓
bestmove → final result delivered to state layer
```

## Acceptance Criteria
- Given the engine is started, When the defaults are applied, Then the engine reports `Threads` ≤ 2 and `Hash` between 16 and 32 MB.
- Given the variant is set to `xiangqi` and the Xiangqi start position is submitted, When a search runs, Then a legal Xiangqi best move is returned.
- Given a standard Chess position, When a search is requested on a mid-range device, Then the final best move is delivered within 1000 ms.
- Given a search for position A is running, When position B is submitted, Then no result for position A is delivered and the result for B is delivered.
- Given an engine `info` line with `score mate 4`, When it is parsed, Then the result is represented as mate-in-4 (not centipawns).
- Given an engine `info` line with `score cp 140`, When it is parsed, Then the evaluation is +1.40 pawns from the engine side-to-move perspective, with perspective conversion handled per OB-001's decision.
- Given malformed or unexpected engine output, When it is parsed, Then it is ignored or reported without crashing.
- Given the engine is disposed, When it is started again, Then it works normally.

## Edge Cases
- Position with no legal moves (mate/stalemate): engine returns `bestmove (none)` or equivalent — must be represented explicitly.
- Rapid successive submissions (user taps fast).
- Engine crash mid-search — error surfaced to state layer, engine restartable.
- `info` lines with `lowerbound`/`upperbound`, `multipv`, `string` — handled or ignored safely.

## In Scope
- Engine interface (protocol-agnostic) + UCI adapter.
- Variant selection via `UCI_Variant`.
- Output parsing (info, bestmove) as pure Dart, unit-tested.
- Default options and per-move time limit configuration.
- Stop/cancel and stale-result protection.

## Out of Scope
- USI, GTP, Gomoku protocol, Edax text adapters.
- User-configurable strength/time settings (not documented).
- Multi-PV / showing alternative moves (not documented).
- UCCI (see Open Questions).

## Dependencies
- OB-004 (FFI bridge).
- OB-001 (evaluation perspective — affects only the presentation mapping, not the parser).
- Note (added 2026-10-02): OB-022 (persona move selection) may later require evaluating all legal moves (multi-line search) and per-tier strength/limits. Not in this ticket's scope, but keep the interface open to it. Open Question 1 below may be answered by OB-021.
- Update (OB-021 resolved 2026-10-02): Open Question 1 is answered — no user-adjustable time; strength comes from persona tiers. OB-022 needs from this adapter: (a) a multi-line search covering every legal move with per-move scores (depth target + time cap); (b) single-line search with a depth cap; (c) a hard 900 ms time cap and cancellation for both.
- Note (OB-032, 2026-10-02): keep the engine interface **transport-agnostic** (text lines in/out, start/stop/dispose). The transport (in-process FFI vs. separate process on Android) depends on the licensing decision in OB-032; the UCI parser and the rest of the app must not depend on it.

## Assumptions
- UCI with `UCI_Variant xiangqi` is sufficient for Xiangqi; UCCI is not needed (`activeContext.md` lists this as a question to confirm).
- A fixed per-move time limit (`movetime`) is an acceptable way to meet the 1000 ms target; exact value to be tuned with OB-010.

## Open Questions
1. Is there any requirement for user-adjustable engine strength or thinking time? (Not documented — treated as out of scope.)
2. Should streaming (intermediate) search updates be shown on the card while searching, or only the final result? (Affects OB-007 only; adapter supports both.)

## Developer Handoff
- Keep parsing pure and isolated (no FFI) so it can be unit-tested with recorded engine output.
- Model results with explicit types (e.g. centipawn vs. mate score, "no move") rather than strings.
- Expose engine state to Riverpod as an "Engine Search State" provider per `techContext.md`, disposed when the game changes.
- Confirm the UCCI question by testing `UCI_Variant xiangqi` and record the result in `techContext.md` via BA/PO.
