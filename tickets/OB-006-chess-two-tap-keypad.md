# Ticket Analysis

> **Status: Done on iOS simulator (2026-10-03).** Mid-range device input-cycle/frame timing deferred to OB-010 / the final device pass.
> - Rules interface `ChessRules` + typed model (`lib/features/chess/domain/`): legal moves with capture/castling/en passant/promotion flags, apply, undo, reset, check/mate/stalemate, insufficient material, repetition count, halfmove clock, FEN, `toEnginePosition()`, `moveFromUci()`.
> - Adapter `ChessPackageRules` (`lib/features/chess/data/`) over `chess` 0.8.1; no package types leave it; `in_draw` / `game_over` never used. Legal moves cached per position. Repetition keys count the en passant square only when an en passant capture is legal (the package always records it after a double push).
> - Entry state machine `MoveEntry` (pure): first-tap rule, auto-commit, candidates, cancel, promotion pending. Generic `TapBoard` grid (`lib/core/board/`) reusable by Xiangqi. `ChessBoard` + Riverpod `ChessBoardController` replace the placeholder; hooks for OB-011 (`setUserSide`, replaced by `newGame(userSide)` in OB-011: rules reset + orientation), OB-007 (`showSuggestion`, green squares incl. castling rook), OB-012 (`cancelEntry`, `undo`).
> - Pictograms: Cburnett SVG set (Wikimedia Commons, GFDL/BSD/GPL, used under BSD) via `flutter_svg`; black pieces' outline recolored to `#8E92A4` for contrast on the dark board (noted in `assets/pieces/cburnett/LICENSE`; registered in `LicenseRegistry`).
> - Haptics: `selectionClick` on a selecting tap; **`lightImpact` = "move accepted"**. Taps within 250 ms after a commit are ignored (rapid double tap = one commit).
> - Square states: selected = amber fill; candidate = amber outline; suggested = green outline; check = red fill; dimmed = `keyDisabled`.
> - Tests: 88 unit/widget tests pass (perft initial 20/400/8902, Kiwipete, positions 3 and 4; special moves and undo; entry flows; board states, Black orientation, promotion chooser, haptics, ≥ 44 dp squares). Simulator integration test `integration_test/chess_tap_board_test.dart` 2/2 on iPhone 17 Pro.
> - **Superseded in part by [OB-048](OB-048-always-two-tap-entry.md) (PO 2026-10-04):** the one-tap auto-commit (REQ-005 and the "1 tap" acceptance cases) is removed; the first tap always shows the options and the second tap commits (promotion still opens the chooser after it). Applies to Xiangqi too.
> - **Note on the castling AC:** tapping G1 alone is always ambiguous because the H1 rook can also reach G1 (likewise C1/A1), so castling destination-first takes 2 taps (G1, then the king). King-first is also 2 taps. Worst case is still 2 taps.

TICKET_TYPE: NEW_FEATURE
CONFIDENCE: HIGH

Move entry does not exist (no code). Revised on 2026-10-02 after the PO answers to OB-001 Q7 ("fewest taps possible", delegated to the BA) and Q8 (target users may have **no chess knowledge**). The input method changes from the column → row → destination keypad to a **legal-only tap board**. This is a **design change** to the memory bank ("No full graphical board diagram" / "No on-screen board is rendered"). **The PO confirmed it on 2026-10-02 ("đúng"), and the memory bank is updated** (`projectbrief.md`, `productContext.md`, `designSystem.md`, `systemPatterns.md`). The file name is kept for ID stability.

## Ticket Title
[Feature] Enter Chess moves on a legal-only tap board in 1–2 taps, with pictogram promotion

## Summary
Show a minimal 8×8 tap board that mirrors the physical board (user's side at the bottom, pieces as monochrome pictograms, coordinates on the edges). The user taps where a piece moved from and/or to; only legal options respond. A move commits automatically as soon as it is unambiguous. Promotion uses a 4-pictogram chooser (no letters). This ticket also delivers the Chess rules module behind an interface. The concrete module wraps the Dart package `chess` (PO decision 2026-10-02, OB-002 Q3).

## Business Context
- Value proposition #1: zero-distraction, fastest possible input (`productContext.md`); input cycle < 1.2 s (`techContext.md`).
- PO 2026-10-02: "suggest phương án ít bấm nhất có thể" (fewest taps) and "hướng tới người dùng k có kiến thức về cờ vua" (users may not know chess) → entry must not require reading coordinates or piece letters.
- Physical-board use case: the user copies what happened on the real board. A spatial mirror needs no translation into coordinates.

## Decision: input method (OB-001 Q7, PO delegated to BA recommendation, 2026-10-02)

| Option | Typical taps | Worst case | Needs chess knowledge? | Notes |
|--------|--------------|------------|------------------------|-------|
| A. Keypad file → rank → destination (memory bank) | 3 | 3 (+1 promotion) | **Yes**: reading coordinates off the physical board | Fixed key grid, 48–56 dp keys |
| B. Keypad, destination first (file + rank, then source if ambiguous) | 2–3 | 3 (+1) | Yes (coordinates) | |
| C. Keypad listing movable squares as buttons, then destinations | 2 | 2 (+1) | Yes (coordinates); up to ~20 source buttons | |
| **D. Tap board, smart entry (recommended)** | **1–2** | **2 (+1 promotion)** | **No**: tap the same spots as on the real board | 8×8 squares ≈ 44–45 dp on 360 dp width |

Option D:
- Typical cases:
  - `E2 ➔ E4` at move 1 takes **1 tap** (tap E4; only the E2 pawn can reach it).
  - `G1 ➔ F3` takes **2 taps** (F3 is reachable by the knight and the F2 pawn).
  - Castling takes 1–2 taps.
- Worst case: 2 taps, plus 1 for promotion.
- Two taps fit easily in the < 1.2 s target. It is also the only option usable without chess knowledge, and the board lets the user see at a glance that the app is in sync with the real board.

Trade-offs (accepted):
- Squares are ≈ 44 dp on 360 dp-wide phones: at the Apple minimum (44 pt), below the Material 48 dp guidance. They are ≥ 48 dp on screens ≥ 392 dp wide, which covers most current phones.
- Auto-commit makes a mis-tap commit a legal-but-wrong move. Mitigated by one-step undo, which the PO put in the Chess DoD on 2026-10-02 (OB-012).
- Layout change: the board needs a full-width square, so the 35/10/55 split in `designSystem.md` must be revised (see Business Rules BR-006).

## Current Behavior
Not implemented. Shell layout comes from OB-003.

## Expected Behavior
- An 8×8 board with the user's side at the bottom (OB-011 side choice), file letters `A`–`H` and rank numbers `1`–`8` on the edges, and pieces as monochrome pictograms (no letters).
- Squares not involved in any legal move of the side to move are dimmed and don't respond.
- **First tap on a square with a movable piece of the side to move** = source:
  - exactly one legal destination → the move commits immediately;
  - otherwise the source is selected (amber) and its legal destinations are highlighted; the second tap on a destination commits.
- **First tap on any other square** (empty, or opponent piece) = destination:
  - reachable by exactly one legal move → commits immediately;
  - reachable by several pieces → those source squares are highlighted; the second tap on one commits.
- Tapping the selected square again, or any non-highlighted square, cancels the selection.
- **Promotion:** when a pawn move reaches the last rank, a chooser shows 4 pictograms (queen, rook, bishop, knight) in the mover's color, queen first. One tap picks; tapping outside cancels the move.
- Every committed move plays the "move accepted" haptic.

## User Story
As someone mirroring a game from a physical board, even without knowing chess notation
I want to tap where the piece moved, like on the real board, and have the app finish the move as soon as it's clear
So that entering a move takes one or two taps and I can't enter an illegal move.

## Functional Requirements
- REQ-001: Render an 8×8 board oriented with the user's side at the bottom; edge labels `A`–`H` / `1`–`8`.
- REQ-002: Show pieces as monochrome pictograms; white and black pieces are distinguishable at a glance; no piece letters anywhere in the input.
- REQ-003: Only squares involved in a legal move of the side to move respond; others are dimmed.
- REQ-004: First-tap rule: own movable piece = source; any other square = destination (unambiguous because a destination can never hold a piece of the side to move).
- REQ-005: Auto-commit when the first tap identifies exactly one legal move (single destination for a source, or a single source for a destination).
- REQ-006: Otherwise highlight the candidate destinations (after a source) or candidate sources (after a destination); the second tap commits.
- REQ-007: Cancel the selection by tapping the selected square again or any non-highlighted square.
- REQ-008: Castling: a king move to its castling square (e.g. `E1` → `G1`) is a normal legal destination; the rook moves automatically in the game state.
- REQ-009: En passant: offered as a normal legal destination; the captured pawn is removed in the game state.
- REQ-010: Promotion: show the 4-pictogram chooser (queen first). If the move being entered matches the current suggestion, the suggested piece is pre-highlighted. One tap commits; tapping outside cancels.
- REQ-011: Haptics: `selectionClick` on a selecting tap, "move accepted" on commit (distinct from `mediumImpact`, which is reserved for "engine move ready").
- REQ-012: The board shows the current suggestion's from/to squares (and the rook squares for castling) highlighted in `accentGreen` (OB-007).
- REQ-013: Legal-move computation must not drop frames.
- REQ-014: The Chess rules module sits behind an interface (see "Rules module interface"); the UI and tests work against that interface.

### Rules module interface (behavior requirements; implemented with `chess`, see "Concrete rules module")
For any position, the module must provide:
- legal moves (from, to, promotion piece, flags: capture, castling, en passant, promotion);
- apply a move;
- side to move and check status;
- end-of-game data used by OB-024: checkmate, stalemate, insufficient material, repetition count, halfmove clock;
- serialization for the engine (FEN or start position + move list) and conversion from the engine's move format;
- standard initial position;
- undo of the last move with full state restore (OB-012).

### Concrete rules module (PO decision 2026-10-02: Dart package `chess` 0.8.1)
Evidence from reading the package source (pub.dev `chess` 0.8.1; port of chess.js; single file ~1,735 lines; min Dart SDK 2.12, null-safe; last release Oct 2023; BSD-2-Clause/MIT):
- **Provides:** FIDE legal move generation, including castling, en passant and promotion, as verbose moves (from/to/flags/promotion); `in_checkmate`; `in_stalemate`; `insufficient_material` (K v K, K v K+N, K v K+B, bishops all on one square color); `in_threefold_repetition` (FEN-based, O(n) per check); public `half_moves`; `undo()` with full state restore (castling rights, ep square, counters); `fen` getter; `load(fen)`.
- **Missing:** fivefold repetition and the 75-move rule → implemented in our adapter (OB-024).
- **Must not be used for game end:** `in_draw` / `game_over` (they treat the 50-move rule and threefold repetition as automatic draws, which contradicts OB-024 A1/A2).
- **Non-idiomatic API** (snake_case, untyped `Map`/`List`) → wrapped by an adapter; no package types leak beyond the rules module.
- **Risks:** unmaintained for ~3 years (2 open issues, PGN-related, not used); Dart 3 compatibility not yet verified (Flutter not installed). Fallback: vendor/fork the single file (license permits).

- REQ-015: Implement the rules interface with an adapter over `chess`. The adapter maps verbose moves to the app's typed move model (from, to, promotion piece, flags: capture, castling, en passant, promotion) and exposes no package types.
- REQ-016: **First step of the concrete module:** verify that `chess` 0.8.1 resolves and passes analysis/tests on the project's Dart 3 SDK (with OB-003). If it fails, vendor the single file into the project with its license notice and fix minimally.
- REQ-017: Perft and unit tests through the adapter: perft counts for standard positions (initial position depths 1–3; positions with castling, en passant and promotion), plus tests for castling both sides, en passant, every promotion piece, check evasion, and undo of each special move.

## Business Rules
- BR-001: Only strictly legal moves (FIDE) can be entered.
- BR-002: Entry requires no chess notation knowledge: no piece letters, no SAN, no `O-O`, no `e.p.` (PO 2026-10-02 principle).
- BR-003: Coordinates appear only as edge labels and in the suggestion text (OB-001 Q9 = coordinates).
- BR-004: Colors per `designSystem.md`: selected/candidate = `accentActive` amber; suggestion = `accentGreen`; check = `accentRed`; disabled = `keyDisabled`. No shadows, gradients, blur or decorative motion.
- BR-005: Board squares ≥ 44 dp (exception to the 48 dp key guidance for the 8×8 board only; ≥ 48 dp on screens ≥ 392 dp wide). Promotion chooser keys follow the normal ≥ 48 dp rule.
- BR-006 (layout, design change): portrait layout = suggestion card (top, ~25%) → persona row (52 dp) → full-width square board → status line. Replaces the keypad's 55% region from `designSystem.md`.

## User Flow
```text
Position awaiting input
↓
User taps E4 (destination first) → only the E2 pawn can reach it → move commits, haptic
—— or ——
User taps F3 → candidates G1 (knight) and F2 (pawn) highlighted → user taps G1 → commits
—— or ——
User taps the G1 knight (source first) → F3/H3 highlighted → taps F3 → commits
```
Alternative flows:
- Pawn reaches the last rank → pictogram chooser → tap the queen → commits.
- Tap a dimmed square → nothing happens.
- Tap the selected square again → selection cleared.

## Acceptance Criteria
- Given the initial position with White to move, When the user taps E4, Then `E2 ➔ E4` is committed with one tap and the "move accepted" haptic fires.
- Given the initial position, When the user taps F3, Then G1 and F2 are highlighted as candidates, and tapping G1 commits `G1 ➔ F3`.
- Given the initial position, When the user taps the G1 knight, Then exactly F3 and H3 are highlighted, and tapping H3 commits `G1 ➔ H3`.
- Given a piece with exactly one legal destination, When the user taps that piece, Then that move commits immediately.
- Given any position, When the board renders, Then every square not involved in a legal move of the side to move is dimmed and ignores taps.
- Given a pinned piece with no legal moves, When the user taps it, Then nothing is selected.
- Given the side to move is in check, When the board renders, Then only moves that resolve the check are possible.
- Given kingside castling is legal, When the user taps G1 (or taps the king, then G1), Then castling commits and the game state shows the rook on F1.
- Given en passant is legal, When the user taps the en passant destination (or the pawn, then the destination), Then the move commits and the captured pawn is removed.
- Given a pawn move to the last rank, When it is entered, Then a chooser with 4 piece pictograms (queen first, no letters) appears; tapping the knight commits a knight promotion; tapping outside cancels and the position is unchanged.
- Given the user plays Black, When the board renders, Then Black's pieces are at the bottom and the labels read `H`–`A` left to right and `8`–`1` bottom to top.
- Given a source is selected, When the user taps the same square again, Then the selection is cleared and the position is unchanged.
- Given a 360 dp-wide portrait screen, When the board renders, Then all 64 squares are fully visible and each is at least 44 dp × 44 dp.
- Given a mid-range device, When a move is entered at a normal pace, Then the input cycle is under 1.2 s and no frames are dropped.
- Given the input screens, When they are inspected, Then no piece letters, SAN or `O-O` appear anywhere in the input UI.
- Given the project's Dart 3 SDK, When `chess` 0.8.1 is added (or vendored), Then the project builds and analyzes without errors (REQ-016).
- Given the standard perft positions, When legal moves are counted through the adapter, Then the counts match the published perft values (e.g. initial position: 20 / 400 / 8,902 at depths 1–3).
- Given castling, en passant or a promotion was applied, When undo is called through the adapter, Then the FEN equals the FEN before the move.
- Given the UI and game-state code, When inspected, Then no `chess` package type or untyped `Map`/`List` from the package is referenced outside the rules module.

## Edge Cases
- Double check (only king moves possible).
- A destination reachable by two pieces of the same kind (e.g. two rooks) → candidate highlight.
- Destination-first promotion where two pawns can reach the same promotion square by capture.
- Rapid double tap (one commit).
- Mis-tap auto-commit → requires undo (OB-012).
- Very small screens (< 360 dp width): squares fall below 44 dp; out of target range (Android API 24 phones are typically ≥ 360 dp).

## In Scope
- Tap board widget (game-agnostic grid with per-square state), Chess orientation/labels/pictograms.
- Smart entry (first-tap rule, auto-commit, candidates, cancel), promotion chooser.
- Rules module **interface** + a test fake; the concrete Chess rules module as an adapter over `chess` (Dart 3 check, typed move mapping, perft/unit tests).
- Unit tests for entry logic against the interface; widget tests for board states.

## Out of Scope
- Suggestion text (OB-007); turn alternation (OB-025); end detection display (OB-024); undo UI and history (OB-012).
- Custom start positions (OB-001 Q3).
- Drag-and-drop or animations of pieces (no decorative motion).

## Dependencies
- OB-003 (shell, tokens; layout revised per BR-006).
- OB-011 (user side → orientation), OB-025 (whose move is entered), OB-007 (suggestion highlight).
- OB-002 Q3 (rules library) — **resolved 2026-10-02: `chess` 0.8.1** (PO decision). New dependency, permissive license; attribution in OB-033.
- OB-012 (undo): the rules interface must support restoring the previous state (undo of castling, en passant, promotion), and UNDO clears a pending selection or closes the promotion chooser (OB-012 REQ-005/REQ-006).
- Bundled monochrome piece pictograms (offline asset; license to be checked with OB-002).

## Assumptions
- Physical-board coordinates are not needed for entry; edge labels help users whose boards are labelled.
- Promotion is rare (≈ 0–1 per game), so one extra tap is acceptable.

## Open Questions
None. (Undo is decided: in the Chess DoD, OB-012. Rules library decided: `chess`.)

## Developer Handoff
- Build a generic board grid (N×M, per-square state: normal/dimmed/selected/candidate/suggested/check) reused by Xiangqi and later games.
- Entry logic as a pure state machine over the rules interface: (position, tap) → (selection | candidates | committed move | promotion prompt).
- Start with a fake rules implementation for UI/tests; the concrete module is a thin adapter over `chess` (typed moves in/out; game-end status composed per OB-024, not from `in_draw`/`game_over`).
- Render pictograms from bundled vector assets (not Unicode glyphs; system font coverage varies).
