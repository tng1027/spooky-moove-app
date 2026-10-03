# Ticket Analysis

> **Status: Done on iOS simulator (2026-10-03).** Not user-facing; consumed by OB-044, OB-046 and OB-047.
> - Model (REQ-001), in `lib/features/xiangqi/domain/xiangqi_models.dart`:
>   - sides use OB-042's `PlayerSide` (first = Red);
>   - `XiangqiPieceKind` with FEN letters;
>   - `XiangqiPoint` (file 0–8, rank 0–9; `name` `a1`–`i10`; `tryParse` accepts two-digit rank 10);
>   - `XiangqiPiece`;
>   - `XiangqiMove(from, to, captured)`, which implements `EntryMove`, so OB-044 can reuse `SmartEntry`.
> - Interface `XiangqiRules` (facts only, `ChessRules` style): `legalMoves`, `pieceAt`, `sideToMove`, `isCheck`, `hasNoLegalMoves`, `fen`, `moveCount`, `apply` / `undo` / `reset`, `toEnginePosition`, `moveFromUci`. It exposes no repetition or draw facts (XQ6, XQ9).
> - Implementation `DartXiangqiRules` (`lib/features/xiangqi/data/`): hand-written (XQ11), 9×10 `Int8List` mailbox.
>   - Legality: each pseudo-legal move is made, rejected if it leaves its own general attacked (chariot or cannon rays, horse with the reverse leg check, soldier) or facing the other general on an open file, then unmade.
>   - Legal moves are cached per position. A FEN can be loaded for tests only.
>   - `perft(depth)` runs make/unmake without allocating, for validation.
>   - Imports only `dart:typed_data` and plain-Dart `core/` types (`PlayerSide`, `EntryMove`, `EnginePosition`).
> - Perft:
>   - `integration_test/xiangqi_perft_oracle_test.dart` compares `go perft` from the bundled Fairy-Stockfish with the Dart module on the simulator. All 19 counts match: start 44 / 1,920 / 79,666 / 3,290,240, plus a midgame, cannon screens, flying general, horse legs + elephant eyes and crossed soldiers at depths 1–3.
>   - The counts and the commands used are recorded in `test/features/xiangqi/data/xiangqi_perft_positions.dart` and checked by the regular unit run. Start perft 4 takes ~0.4 s on the VM.
> - Performance (REQ-007): about 0.01 ms per position on the simulator (apply/undo with legal-move recomputation), far under the 2 ms target.
> - Rule tests (`dart_xiangqi_rules_test.dart`): horse leg; elephant eye and river; cannon with 0 / 1 / 2 screens (the screen itself is never captured); soldier before and after the river, on the last rank, and Black's direction; flying general (step, capture, piece between the generals); a pinned cannon second screen; checkmate and stalemate facts; FEN round trips over undo, including captures; reset; `ArgumentError` on an illegal move; uci round trip for every legal move; `a1a9` null; rank-10 parsing; engine position.

TICKET_TYPE: TECHNICAL_TASK
CONFIDENCE: HIGH

There are no Xiangqi rules in the app. The rules module itself is not user-facing: the board (OB-044), the advisor wiring (OB-046) and game end (OB-047) consume it. The legal-move rules are fully defined by the standard Asian/WXF rules, and Fairy-Stockfish (`UCI_Variant xiangqi`, already bundled) gives an independent oracle for perft validation. The library choice is decided: hand-written Dart, no new dependency (PO 2026-10-03, XQ11; as `techContext.md` prefers).

## Ticket Title
[Tech] Xiangqi rules module in pure Dart, validated by perft against Fairy-Stockfish

## Summary
Provide a Xiangqi rules module behind an interface, mirroring what `ChessRules` gives Chess: legal moves, apply, undo with full restore, reset, side to move, check, no-legal-move state, piece lookup, engine serialization and parsing of engine moves. It is validated with perft counts and rule-specific unit tests.

## Business Context
- The tap board must dim illegal points instantly, with no engine round-trip (`techContext.md`: "Prefer Dart rule modules"; UCI has no `islegal`).
- Licensing: GPL libraries are excluded until OB-032 is decided. A hand-written module adds no dependency and no attribution.

## Current Behavior
- No Xiangqi rules. OB-002 Q3 (rules library) is decided for Chess only (`chess` 0.8.1).
- The engine side already works: `setVariant('xiangqi')`, rank-10 moves (`h10g8`), 44 legal moves at the start position (OB-005, `techContext.md`).

## Expected Behavior
A pure-Dart, unit-tested module that is the single source of Xiangqi legality and state for the app. No Flutter imports and no engine calls.

## Functional Requirements
- REQ-001 (model): typed Xiangqi model: side (first = Red, second = Black, via the OB-042 side type), piece kinds (general, advisor, elephant, horse, chariot, cannon, soldier), point (file 0–8 = A–I from Red's left, rank 0–9 = 1–10 from Red's side), move (from, to, captured piece if any). No package types leave the module.
- REQ-002 (legal moves): generate the strictly legal moves of the side to move:
  - general and advisors stay in the palace; the general moves one point orthogonally, advisors one point diagonally;
  - elephants move exactly two points diagonally, are blocked by a piece on the "eye", and cannot cross the river;
  - horses move one orthogonal step then one diagonal step, blocked by a piece on the "leg";
  - chariots move like a rook;
  - cannons move like a rook without capturing, and capture by jumping exactly one screen piece;
  - soldiers move one point forward; after crossing the river they may also move one point sideways; they never move backwards;
  - a move is illegal if it leaves the mover's general in check, or leaves the two generals facing each other on a file with no piece between ("flying general").
- REQ-003 (state): side to move, `isCheck`, `hasNoLegalMoves`, `pieceAt(point)`, move count (undo depth).
- REQ-004 (apply / undo / reset): apply a legal move (throws `ArgumentError` otherwise); undo the last move with full state restore (captured piece back, side to move); reset to the standard initial position with an empty history.
- REQ-005 (engine): `toEnginePosition()` returns start position + move list in Fairy-Stockfish notation (files `a`–`i`, ranks `1`–`10`, e.g. `h3e3`, `h10g8`). `moveFromUci(String)` returns the matching legal move or null.
- REQ-006 (FEN): expose the position as Fairy-Stockfish Xiangqi FEN (start: `rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1`), for tests and debugging. Loading arbitrary FEN is allowed for tests only (initial position only in the product, OB-001 Q3).
- REQ-007 (performance): legal moves are computed once per position and cached until the next apply / undo / reset. Generation for any position takes well under one frame (< 2 ms on the simulator, measured in a test or benchmark).
- REQ-008 (library choice, PO 2026-10-03, XQ11): implement by hand in pure Dart, with no new dependency.

## Business Rules
- BR-001: Move rules follow the standard Asian/WXF rules for piece movement, check and flying general.
- BR-002: Repetition (perpetual check / chase) is **not** adjudicated (XQ6). The module doesn't need a repetition counter. The full move list is still sent to the engine, so its search sees the history.
- BR-003: No automatic draws (XQ9). The module exposes no draw facts.
- BR-004: A side with no legal moves has lost, whether or not it is in check. The module exposes the facts (`hasNoLegalMoves`, `isCheck`); OB-047 composes the result.

## User Flow
Not user-facing.

## Acceptance Criteria
- Given the initial position, When legal moves are counted through the module, Then perft depths 1–4 are 44 / 1,920 / 79,666 / 3,290,240.
- Given at least five further positions (a midgame, a position with a cannon screen capture, a position with flying-general constraints, a position with blocked horse legs and elephant eyes, an endgame with crossed soldiers), When perft depths 1–3 are counted, Then they equal Fairy-Stockfish `go perft` for the same FEN (values recorded in the test file with the command used).
- Given a horse whose leg point is occupied, When its moves are generated, Then the two destinations over that leg are absent.
- Given an elephant whose eye point is occupied, or whose target is across the river, When its moves are generated, Then those destinations are absent.
- Given a cannon with exactly one piece between it and an enemy piece on a line, When its moves are generated, Then the capture is present. With zero or two screens, the capture is absent.
- Given a soldier before the river, When its moves are generated, Then only the forward move exists. After crossing, sideways moves exist too, and backward moves never do.
- Given a move that would leave the generals facing each other with no piece between, When legal moves are generated, Then that move is absent.
- Given a pinned piece (moving it exposes the general to check or to the opposing general), When legal moves are generated, Then its exposing moves are absent.
- Given a checkmated side, When queried, Then `isCheck` and `hasNoLegalMoves` are both true. Given a side with no legal moves and no check, Then `hasNoLegalMoves` is true and `isCheck` is false.
- Given any sequence of applied moves including captures, When each is undone, Then the FEN equals the FEN before that move, and the move count goes back to 0 after undoing all.
- Given each legal move from several positions, When converted to engine notation and back with `moveFromUci`, Then the same move is returned. `moveFromUci('a1a9')` from the initial position returns null.
- Given the module's files, When inspected, Then they import no Flutter, no engine code and no third-party package (XQ11).

## Edge Cases
- Rank 10 parsing (`a10a9`, `i10i9`) vs. rank 1 (`a1a2`).
- Capturing the screen piece is not possible for a cannon, only the piece behind it.
- A general's capture that would face the other general.
- Soldier on the last rank (moves only sideways).
- Discovered check by moving the screen of a cannon.

## In Scope
- Model, legal-move generation, state, apply / undo / reset, engine serialization, FEN for tests, perft and rule unit tests.

## Out of Scope
- Board UI and entry (OB-044); WXF formatting (OB-046); game-end composition and texts (OB-047).
- Repetition rules, draw rules, custom start positions.

## Dependencies
- OB-042 for the shared side type. Can start in parallel and adopt the type when OB-042 lands.
- XQ11 (decided, PO 2026-10-03: hand-written).
- Fairy-Stockfish (bundled) as the perft oracle, run through the existing engine bridge or a desktop build to produce the reference numbers.

## Decisions
- **XQ11 (PO 2026-10-03):** hand-written pure-Dart module, no new dependency.
- **XQ6, XQ9 (PO 2026-10-03):** no repetition adjudication and no automatic draws, so the module exposes no repetition or draw facts (BR-002, BR-003).

## Assumptions
- A-1: Rules are the same in all regions for legal-move purposes. Region differences are in repetition adjudication, which is out of scope.

## Open Questions
None.

## Developer Handoff
- Mirror the `ChessRules` interface style (`lib/features/chess/domain/chess_rules.dart`): facts only, mutable via apply / undo / reset, no status composition.
- Suggested location: `lib/features/xiangqi/domain/` (model, interface) and `lib/features/xiangqi/data/` (implementation).
- A 9×10 mailbox array (with a padded border, or bounds checks) is enough. No bitboards needed at these sizes.
- Write the perft test first. Get the reference numbers from Fairy-Stockfish `position fen … ` + `go perft n` and record the commands in the test.
