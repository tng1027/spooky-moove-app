# Ticket Analysis

> **Status: Done on iOS simulator (2026-10-04).** `SmartEntry._firstTap` never commits: a tapped piece always becomes the source with its destinations highlighted, and a tapped target always offers its candidate pieces, even when there is only one. The second tap commits through `_resolve`, so Chess promotion still opens the chooser. Chess and Xiangqi share this code.
> - Tests: move-entry, board, controller and session tests now enter every move in two taps. There are new cases for a single destination, a single source, en passant and both promotion orders. The rapid double-tap case taps four squares and checks that only the first move commits.
> - The integration helpers lost their `isSingleTap` shortcut, and the tap-board tests show the single-option highlight (Chess E4 → E2, Xiangqi A6 → A7). The full suite has 493 tests, and all 33 integration tests pass.

TICKET_TYPE: ENHANCEMENT
CONFIDENCE: HIGH

Board entry exists and works as specified. The one-tap auto-commit is a decided behaviour (OB-006 REQ-005, PO-confirmed 2026-10-02), reused for Xiangqi by OB-042 REQ-007 and OB-044. The PO now wants different behaviour (never commit on the first tap), so this is a change to a decided rule, not a bug. Source: PO request of 2026-10-04 after simulator testing: "For some opponent moves the app applies the move automatically with one tap. Don't do it. We keep showing the possible moves, then the user taps to pick."

## Ticket Title
[Enhancement] Never commit a move on the first tap: always show the options, commit on the second tap (Chess and Xiangqi)

## Summary
Remove the one-tap shortcut from the shared smart entry. The first tap always selects: a tapped movable piece shows its legal destinations, and a tapped target shows the pieces that can reach it, even when there is only one option. The second tap on a highlighted option commits the move (Chess promotion still opens the chooser). Everything else about entry stays as it is: cancel rules, haptics, commit guard, promotion chooser, Xiangqi snapping, UNDO and I PLAYED IT.

## Business Context
- On the simulator the PO saw moves applied by a single tap. The user had no chance to check what was about to happen, which is surprising and erodes trust that the app mirrors the physical board.
- OB-006 accepted the risk "a mis-tap commits a legal-but-wrong move, mitigated by undo". The PO now prefers prevention (a visible confirmation step) over recovery (UNDO).
- Cost: moves that took 1 tap now take 2. OB-006's worst case was already 2 taps (+1 for promotion), so the worst case doesn't change and the < 1.2 s input-cycle target still holds (OB-010 measures it).
- The user's own move normally goes in via ✓ I PLAYED IT (OB-041), so the extra tap mostly affects entering the opponent's move and overrides.

## Current Behavior
Shared by Chess and Xiangqi (`lib/core/board/smart_entry.dart`, `SmartEntry._firstTap`):
- First tap on a movable piece of the side to move:
  - exactly one legal destination → the move commits immediately (Chess promotion: the chooser opens immediately);
  - several destinations → `SourceSelected` (piece amber, destinations highlighted).
- First tap on any other active square/point (empty or opponent piece):
  - reachable by exactly one piece → the move commits immediately (e.g. Chess `E4` at move 1 commits `E2 ➔ E4`; Xiangqi `A6` commits `A7 ➔ A6`; en passant destination; promotion destination opens the chooser);
  - reachable by several pieces → `DestinationSelected` (target amber, candidate sources highlighted).
- With a selection: tapping a highlighted option commits via `_resolve` (or opens the Chess promotion chooser); tapping the selected square again, or any other active non-highlighted square, cancels to idle (it does not reselect); taps on inactive squares are ignored and keep the selection.
- 250 ms commit guard after a commit; `selectionClick` on a selecting tap, `lightImpact` on commit; UNDO clears a selection or closes the chooser (OB-012).

## Expected Behavior
- The first tap never commits and never opens the promotion chooser. It always produces a selection:
  - tapped movable piece → that piece is selected and **all** its legal destinations are highlighted (also when there is just one);
  - tapped target → that target is selected and **all** pieces that can reach it are highlighted (also when there is just one).
- The second tap on a highlighted option commits the move, or opens the promotion chooser when the move is a Chess promotion (as today).
- All other rules are unchanged (see Business Rules).

## User Story
As someone mirroring a game from a physical board
I want the app to show me what a tap would do before it applies a move
So that a move is never applied by surprise and I always confirm it with a second tap.

## Functional Requirements
- REQ-001: The first tap on a movable piece of the side to move selects it and highlights all its legal destinations, regardless of how many there are (1 or more).
- REQ-002: The first tap on any other active square/point selects it as the target and highlights all pieces that can reach it, regardless of how many there are (1 or more).
- REQ-003: No move is committed and no promotion chooser is opened by a first tap from idle.
- REQ-004: The second tap on a highlighted option commits the move; if several legal moves share that from/to pair (Chess promotion), the promotion chooser opens instead (unchanged).
- REQ-005: Cancel and ignore rules stay as today: tapping the selected square/point again cancels; tapping another active, non-highlighted square/point cancels to idle; tapping an inactive square/point is ignored and keeps the selection; a board tap while the promotion chooser is open cancels it.
- REQ-006: The change lives in the shared smart entry, so Chess and Xiangqi behave the same with no per-game branch.
- REQ-007: Haptics stay as today: `selectionClick` on the first (selecting) tap, "move accepted" (`lightImpact`) on commit.
- REQ-008: Product docs that describe "1–2 taps" / "auto-commit when unambiguous" are updated to "2 taps (+1 for Chess promotion)": `memory-bank/productContext.md`, `memory-bank/projectbrief.md`, and the Chess DoD line in `tickets/README.md`.

## Business Rules
- BR-001: Entering a move on the board always takes exactly 2 taps (+1 for the Chess promotion piece). This supersedes OB-006 REQ-005 ("auto-commit when the first tap identifies exactly one legal move") and the matching auto-commit wording in OB-042 REQ-007 and OB-044.
- BR-002: Only legal moves can be entered; inactive squares/points stay dimmed and ignore taps (OB-006 BR-001, REQ-003, unchanged).
- BR-003: The first-tap rule is unchanged: own movable piece = source, any other active square/point = target (OB-006 REQ-004).
- BR-004: Unchanged: 250 ms commit guard, UNDO (clears a selection / closes the chooser), ✓ I PLAYED IT (one tap, not board entry), suggestion highlight, Xiangqi nearest-legal snapping (OB-044), game-over board lock (OB-024, OB-047).
- BR-005: Highlight colours unchanged: selected = amber fill, candidate = amber outline (OB-006 BR-004 / OB-044 point states).

## User Flow
```text
Position awaiting input
↓
Tap 1: a piece  → piece selected, its destinations highlighted (even if only one)
       a target → target selected, the pieces that can reach it highlighted (even if only one)
↓
Tap 2: a highlighted option → move commits, "move accepted" haptic
                               (Chess promotion → chooser → tap a piece → commits)
```
Alternative flows:
- Tap 2 on the selected square/point → selection cleared, position unchanged.
- Tap 2 on another active, non-highlighted square/point → selection cleared (no reselect); the next tap starts a new selection.
- Tap 2 on an inactive square/point → ignored, selection kept.
- UNDO while a selection is shown → selection cleared, no move taken back (OB-012, unchanged).

## Acceptance Criteria
Chess:
- AC-1: Given the initial position with White to move, When the user taps E4, Then nothing is committed, E4 is selected and E2 is highlighted as the only candidate; When the user then taps E2, Then `E2 ➔ E4` is committed with the "move accepted" haptic.
- AC-2: Given a piece with exactly one legal destination (e.g. a lone pawn on A3), When the user taps that piece, Then nothing is committed and only A4 is highlighted; When the user then taps A4, Then `A3 ➔ A4` is committed.
- AC-3: Given the initial position, When the user taps F3, Then G1 and F2 are highlighted, and tapping G1 commits `G1 ➔ F3` (unchanged); When the user taps the G1 knight, Then F3 and H3 are highlighted, and tapping H3 commits `G1 ➔ H3` (unchanged).
- AC-4: Given en passant is legal and only one pawn can capture, When the user taps the en passant destination, Then nothing is committed and the capturing pawn is highlighted; tapping it commits the en passant capture and removes the captured pawn.
- AC-5: Given a pawn on the 7th rank that can only advance to promote, When the user taps the pawn, Then no chooser opens and only the promotion square is highlighted; When the user then taps the promotion square, Then the 4-pictogram chooser opens (queen first), and tapping the knight commits a knight promotion.
- AC-6: Given the same promotion position, When the user taps the promotion square first, Then no chooser opens and the pawn is highlighted; When the user then taps the pawn, Then the chooser opens; tapping outside it cancels and the position is unchanged.
- AC-7: Given kingside castling is legal, When the user taps the king and then G1 (or G1 and then the king), Then castling commits with the rook on F1 (unchanged).

Xiangqi:
- AC-8: Given the initial position with Red to move, When the user taps A6, Then nothing is committed and the A7 soldier is highlighted as the only candidate; When the user then taps A7, Then `A7 ➔ A6` is committed.
- AC-9: Given a Red piece with exactly one legal destination, When the user taps it, Then nothing is committed and only that destination is highlighted; tapping the destination commits the move.
- AC-10: Given a piece is selected on the Xiangqi board, When the user taps inside a cell near a highlighted destination, Then the tap snaps to it and the move commits (OB-044 snapping unchanged).

Both games:
- AC-11: Given any position and an idle board, When the user taps any active square/point, Then no move is committed and no promotion chooser opens.
- AC-12: Given a selection (source or target), When the user taps the selected square/point again, Then the selection is cleared and the position is unchanged.
- AC-13: Given a selection, When the user taps another active square/point that is not highlighted, Then the selection is cleared and no move is committed (as today); When the user then taps a square/point, Then it starts a new selection.
- AC-14: Given a selection, When the user taps an inactive (dimmed) square/point, Then nothing changes and the selection stays.
- AC-15: Given a first tap, When it selects, Then the `selectionClick` haptic fires; When the second tap commits, Then the "move accepted" haptic fires.
- AC-16: Given a selection is shown, When the user taps UNDO, Then the selection is cleared and no move is taken back (OB-012, unchanged).
- AC-17: Given the user's turn with a suggestion, When the user taps ✓ I PLAYED IT, Then the suggested move is applied in one tap (OB-041, unchanged).
- AC-18: Given a finished game, When the user taps the board, Then nothing happens (unchanged).
- AC-19: Given the unit, widget and simulator integration suites, When they run, Then they pass with every board-entered move made in two taps (no test relies on a one-tap commit).

## Edge Cases
- Rapid double tap on the same square/point: the first tap selects, the second cancels; nothing is committed. (Previously this could commit a one-destination piece once.) The commit guard is unaffected because there's no commit.
- Pinned piece / piece with no legal move: still inactive, a tap does nothing (unchanged).
- In check: only check-resolving squares/points are active; a single legal reply still takes 2 taps.
- Two pawns capturing onto the same promotion square: target first shows both pawns, then the chooser after picking one (unchanged).
- Xiangqi: a target reachable by one piece near the board edge with snapping: the snapped first tap selects, it never commits.
- A selection left open when the opponent's move arrives via another path (UNDO, I PLAYED IT, NEW GAME): existing clearing behaviour applies (unchanged).

## In Scope
- Shared smart entry change for Chess and Xiangqi (first tap always selects).
- Updating unit, widget and integration tests that assume a one-tap commit, including their tap helpers.
- Doc wording updates (REQ-008).

## Out of Scope
- Reselecting on a tap at another own piece while a selection is shown (today it cancels; unchanged unless the PO asks).
- A setting to turn the one-tap shortcut back on.
- Any change to ✓ I PLAYED IT, UNDO, the promotion chooser UI, highlight colours, haptic types, the commit guard or Xiangqi snapping.
- Re-measuring the input cycle (OB-010 Chess/Xiangqi passes cover it with the new 2-tap flow).

## Dependencies
- OB-006 (Chess entry, superseded in REQ-005), OB-042 (shared `SmartEntry`), OB-044 (Xiangqi board and snapping), OB-012 (UNDO clears selection), OB-041 (I PLAYED IT).
- Should land before the OB-010 Xiangqi pass so the input-cycle measurement uses the 2-tap flow.

## Decisions
- **PO 2026-10-04:** Never commit on the first tap; always show the possible moves and let the user pick with a second tap. Applies to both Chess and Xiangqi (shared entry). Supersedes OB-006 REQ-005 / its "1 tap" acceptance cases and the auto-commit wording in OB-042 REQ-007 and OB-044.
- **BA:** Keep today's cancel rule (another active non-highlighted tap cancels, no reselect); the request doesn't ask to change it.

## Assumptions
- The change applies to both sides' moves entered on the board (opponent moves and user overrides); there is only one entry path.

## Open Questions
None.

## Developer Handoff
- `lib/core/board/smart_entry.dart`: in `SmartEntry._firstTap`, return `SourceSelected` whenever a tapped piece has ≥ 1 destination and `DestinationSelected` whenever a target has ≥ 1 source; drop the `length == 1 → _resolve` shortcuts. `_resolve` (second tap) and `ChoicePending` stay as they are. Update the class doc ("Smart 1–2-tap") accordingly. No change expected in `ChessBoardController` / `XiangqiBoardController` (`_handle` already plays `selectionClick` for a selection), `MoveEntry`, or the boards.
- Unit tests to change: `test/features/chess/domain/move_entry_test.dart` ("E4 commits E2-E4 with one tap", "a piece with a single destination commits on the first tap", "en passant destination commits with one tap", promotion "destination first opens the chooser" / "source first opens the chooser" now need the second tap); `test/features/xiangqi/presentation/xiangqi_board_controller_test.dart` ("a destination reachable by one piece commits in one tap"). Add tests for single-option `SourceSelected` / `DestinationSelected`.
- Integration helpers with an `isSingleTap` shortcut that must always tap from then to: `integration_test/turn_loop_test.dart` (`play`; keep the stopwatch starting before the committing second tap), `integration_test/suggestion_card_test.dart` (`play`), `integration_test/xiangqi_turn_loop_test.dart` (`play`). Also `integration_test/xiangqi_tap_board_test.dart` ("Only the A7 soldier reaches A6: one tap").
- Then run the whole suite and fix any other test that enters a move with one tap (likely candidates: `chess_board_controller_test.dart`, `chess_board_test.dart`, advisor / undo / confirm / game-over widget tests, `chess_tap_board_test.dart`, `new_game_test.dart`, `xiangqi_game_end_test.dart`).
- Docs per REQ-008.
