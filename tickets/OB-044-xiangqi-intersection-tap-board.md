# Ticket Analysis

> **Status: Done on iOS simulator (2026-10-03).** Not reachable from the UI yet: OB-045 registers Xiangqi in `game_registry.dart`.
> - Glyphs (REQ-002): `tool/xiangqi_glyphs.py` extracts the 14 characters from OFL Noto Serif TC Bold into `assets/pieces/xiangqi/{r|b}{K,A,B,N,R,C,P}.svg` (56 KB). The font is not committed. The OFL text is in the same folder and registered in `LicenseRegistry` as "Noto Serif TC (Xiangqi glyphs)".
> - Token (REQ-003): `AppColors.pieceRed` `#FF8A80`. `designSystem.md` has a new "Xiangqi board" section.
> - Core: `IntersectionBoard` (`lib/core/board/intersection_board.dart`) with point keys `board.point.$file.$rank`, the pure `snapTap` (`snap.dart`), and `boardClockProvider` moved to `board_clock.dart` (re-exported for Chess). `BoardSquareState` is reused; whether a mark is a dot or a ring depends on whether a piece stands on the point. `TapBoard` and Chess are unchanged.
> - `XiangqiBoardController` implements `ActiveGameController` over `DartXiangqiRules` and `SmartEntry`, with the 250 ms guard and the same haptics as Chess. `xiangqiActiveGameState` leaves `headline` null until OB-047. `XiangqiBoard({required Size size})` draws the board, flipped when the user plays Black.
> - Decisions made during implementation:
>   - When two targets are within one cell at different distances, the nearest one wins. The ticket does not cover this case.
>   - The check fill takes precedence over the dimmed state, so a checked general with no legal moves still shows red.
> - Tests: snapping (8), controller (15), board widgets (13, including no overflow at text scale 2.0 at 392×800, 360×800 and 360×600), painter and contrast (2). Integration test `xiangqi_tap_board_test.dart` on the simulator covers H3 then E3, a one-tap destination, a snapping tap, undo, a suggestion, and Black at the bottom. The full suite (404 tests) and all 27 integration tests pass, including Chess.
> - Deferred: the full advisor layout check (top bar, card and status line around the Xiangqi board) moves to OB-045. 360×640 hit accuracy is checked in the device pass.

TICKET_TYPE: NEW_FEATURE
CONFIDENCE: HIGH

There is no Xiangqi board. The behaviour (legal-only, smart 1–2-tap entry, auto-commit, cancel, orientation, haptics, commit guard) is carried over unchanged from OB-006. The rendering is new: an intersection board with character pieces, from the Designer's review of 2026-10-03. The design choices were decided by the PO on 2026-10-03 (XQ1 characters, XQ2 `pieceRed` token, XQ3 40 dp cells with snapping). One risk remains: 35 dp cells on 360×640 screens can only be judged on a real device (final device pass, accepted by the PO under XQ3).

## Ticket Title
[Feature] Enter Xiangqi moves on a legal-only intersection tap board with character pieces, aspect-aware sizing and nearest-legal snapping

## Summary
Render the 9×10 Xiangqi board as one painted background (grid, river gap, palace diagonals) with a tappable cell centred on every point. Pieces are discs with Chinese characters. Entry, auto-commit, cancel, haptics and the commit guard work exactly as on the Chess board (OB-006, OB-041). Point states follow the Designer's spec. Taps near, but not on, a legal point snap to it within one cell. The board is sized by OB-042's aspect-aware `boardSizeFor`.

## Business Context
- Carry-over matrix rows 6, 8, 10, 11, 16, 20 (OB-009).
- PO principles: fewest taps and no notation knowledge (OB-001 Q7, Q8). The board mirrors the physical board.
- A 9×10 grid at 360 dp width gives 40 dp cells, below the 44 dp board exception of OB-006 BR-005. Snapping compensates (XQ3).

## Current Behavior
- `TapBoard` (`lib/core/board/tap_board.dart`) is a square-cell grid with a checkerboard fill, labels inside edge squares and Chess-oriented states (dimmed = `keyDisabled` fill, candidate = outline).
- No Xiangqi pieces, assets or board controller exist.

## Expected Behavior
### Geometry and painting
- 9 files × 10 ranks of square cells. Each cell is centred on one intersection point and is that point's hit area. Board size = 9 × cell by 10 × cell, with cell = min(W / 9, (H − 252) / 10) (OB-042 REQ-006).
- One background layer on `surfaceDark` paints the lines in 1 dp `textSecondary`: 10 horizontal lines, the 9 vertical lines (the 7 inner ones break at the river, the 2 edge ones run through), and the two palace X diagonals. No checkerboard and no 楚河漢界 text.
- Edge labels sit in the outer half-cell: files `A`–`I` along the bottom edge and ranks `1`–`10` along the left edge, in Red's frame. When the user plays Black, the board is flipped (Black at the bottom) and the labels read `I`–`A` and `10`–`1` (same rule as Chess, OB-006).

### Pieces (XQ1, XQ2)
- Disc with a Chinese character, from bundled vector assets (not system fonts). Red: 帥 仕 相 傌 俥 炮 兵. Black: 將 士 象 馬 車 砲 卒.
- Disc fill `keyNormal`. Red side: glyph and rim in the new board-only token `pieceRed` (≈ `#FF8A80`, ≈ 6:1 on `keyNormal`; distinct from `accentRed`, which keeps meaning "danger"). Black side: glyph `textPrimary`, rim `textSecondary`.
- The disc fits inside the cell with a visible gap to its neighbours.

### Point states
| State | Rendering |
|-------|-----------|
| normal | piece or empty point |
| selected | `accentActive` amber cell fill behind the piece |
| candidate, empty point | 12 dp amber dot on the point |
| candidate, capture | 3 dp amber ring around the target piece |
| suggested (from) | green (`accentGreen`) ring around the piece |
| suggested (to) | green dot on an empty point, or green ring around a captured piece |
| check | `accentRed` cell fill under the side-to-move's general |
| dimmed (not part of any legal move, or game over) | piece at ≈ 40 % opacity, no cell fill; taps ignored (subject to snapping) |

### Entry (unchanged from OB-006 / OB-041)
- First tap on a movable own piece = source; on any other active point = destination. A move auto-commits when unambiguous, otherwise the candidates are highlighted. Tapping the selected point again, or a non-target point, cancels.
- `selectionClick` on a selecting tap, `lightImpact` on commit; taps within 250 ms after a commit are ignored.

### Snapping (XQ3)
- A **target** is a point that would act in the current entry state. Idle: every active point. Selection pending: the candidates plus the selected point (cancel).
- If the tapped cell's point is a target, use it.
- Otherwise, if exactly one target centre lies within one cell width of the tap position, use that target.
- If two or more targets are equally near within one cell, ignore the tap (no change, no haptic).
- If no target lies within one cell, behave as today: idle → nothing; selection pending → cancel.

## User Story
As a Xiangqi player copying moves from a physical board, even without knowing notation
I want to tap where the piece moved, on a board that looks like my real board
So that every move takes one or two taps and I can't enter an illegal move.

## Functional Requirements
- REQ-001: Render the board per "Geometry and painting", sized by `boardSizeFor(9, 10)`.
- REQ-002: Render pieces per "Pieces". Assets are bundled vector files with a recorded, permissive or OFL license, registered in `LicenseRegistry` (like the Cburnett set) for OB-033.
- REQ-003: Add the board-only color token `pieceRed` to `AppColors` and `designSystem.md` (PO 2026-10-03, XQ2).
- REQ-004: Render every point state per the table. Rendering must not need Chess-only states.
- REQ-005: Entry through the shared smart-entry logic (OB-042 REQ-007) over the Xiangqi rules (OB-043).
- REQ-006: Snapping per "Snapping". Distance = Euclidean distance from the tap position to the point centre, in board pixels.
- REQ-007: A Xiangqi board controller implements the OB-042 active-game seam: tap, `commitEngineMove`, `undo` (one move, full restore, also from game over), `newGame(side)` (reset + orientation), `showSuggestion`, and the derived snapshot (pieces, legal moves, active points, side to move, checked general, can undo, game-over flag from OB-047).
- REQ-008: Orientation follows the user's side (user at the bottom).
- REQ-009: Legal moves are computed once per position, never in `build`. No dropped frames on entry.

## Business Rules
- BR-001: Only strictly legal moves can be entered (OB-043).
- BR-002: No notation in the input UI. Characters on pieces are allowed (they are on the physical pieces).
- BR-003: Cells ≥ 40 dp on 360 dp-wide screens with ≥ 652 dp of safe-area height. This is a documented exception to the 44 dp board rule (XQ3); smaller safe areas (e.g. 360×640 phones, ≈ 35 dp) are accepted with snapping and verified in the device pass. Update (OB-052 Open Question 7): after the restyle the default is ≈ 39.1 dp at 360 dp width; accepted.
- BR-004: Colors carry meaning only: amber = selected / candidate, green = suggestion, red = check, `pieceRed` = Red side only. No shadows, gradients or decorative motion.

## User Flow
```text
Opponent (Black) to move, user is Red
↓
User taps the destination point → only one Black piece can reach it → commits (lightImpact)
—— or ——
User taps a Black horse → its legal points show amber dots / rings → taps one → commits
—— or ——
User's tap lands between two points → snaps to the only legal point within one cell → commits
```

## Acceptance Criteria
- Given the initial position with Red to move, When the board renders, Then the grid, river gap and both palace diagonals are painted, pieces show their characters, and Red is at the bottom.
- Given the initial position, When the user taps the Red cannon on H3, Then H3 is filled amber and every legal destination shows an amber dot, including E3 and the capture ring on H10's horse.
- Given a selected cannon, When the user taps E3, Then the move H3→E3 commits with one `lightImpact` and the selection clears.
- Given a destination reachable by exactly one piece, When the user taps it first, Then that move commits in one tap.
- Given a destination reachable by two pieces (e.g. both Red chariots), When the user taps it, Then both sources are highlighted, and tapping one commits.
- Given a horse with a blocked leg, When it is selected, Then no dot appears on the blocked destinations, and taps there cancel the selection (or snap to a nearer target).
- Given a selection is pending, When the user taps the selected point again, Then the selection is cleared.
- Given a tap whose position is not on a target but exactly one target centre lies within one cell, When it lands, Then it acts as a tap on that target.
- Given a tap equidistant (within one cell) from two targets, When it lands, Then nothing changes and no haptic fires.
- Given the side to move is in check, When the board renders, Then that general's cell is filled `accentRed`.
- Given the user plays Black, When the board renders, Then Black is at the bottom and the labels read `I`–`A` left to right and `10`–`1` bottom to top.
- Given points that are not part of any legal move, When the board renders, Then their pieces are at ≈ 40 % opacity and the cells have no fill.
- Given a suggestion H3→E3 set via `showSuggestion`, When the board renders, Then the H3 cannon has a green ring and E3 a green dot. For a capture, the target piece has a green ring.
- Given a rapid double tap that commits a move, When the second tap lands within 250 ms, Then it is ignored.
- Given an undo, When the controller restores the previous position, Then selection and suggestion highlight are cleared and the board equals the earlier snapshot.
- Given safe areas of 392×800, 360×800 and 360×600 dp, When the board renders, Then cells are 43.6, 40 and 34.8 dp, all 90 points are fully visible, and nothing overflows with the top bar, persona row, card and status line at text scale 2.0.
- Given Red and Black discs on `keyNormal`, When contrast is measured, Then the Red glyph is ≥ 4.5:1 and the Black glyph ≥ 4.5:1.
- Given the input UI, When inspected, Then no notation letters (WXF, ICCS) appear.

## Edge Cases
- Two same pieces on the same file that can both reach the tapped destination.
- A tap at the very edge, outside the outermost points: snaps within one cell or does nothing.
- Snapping must never pick a dimmed point.
- Selection pending, and the tap is nearest to the selected point: cancel (it is a target).
- Game over: no point is a target, so no tap acts (OB-047).
- Very small safe areas (< 600 dp height): cells below 34.8 dp; out of the target range, noted in the device pass.

## In Scope
- Board painting, pieces and assets, point states, snapping, orientation, labels, Xiangqi board controller, `pieceRed` token, widget and unit tests, and a simulator integration test that enters moves on a Xiangqi session started programmatically (UI entry comes with OB-045).

## Out of Scope
- New-game registration (OB-045); suggestion text, engine and I PLAYED IT (OB-046); game-end texts (OB-047).
- Snapping on the Chess board.
- Piece animations or drag-and-drop.
- 楚河漢界 text, Chinese UI labels.

## Dependencies
- OB-042 (seam, shared entry logic, `boardSizeFor`), OB-043 (rules).
- XQ1, XQ2, XQ3 (decided, PO 2026-10-03).
- OB-033 (licenses screen lists the glyph asset source).

## Decisions
- **XQ1 (PO 2026-10-03):** Chinese characters on discs, not pictograms.
- **XQ2 (PO 2026-10-03):** New board-only token `pieceRed` ≈ `#FF8A80`.
- **XQ3 (PO 2026-10-03):** 40 dp cells at 360 dp width (≈ 35 dp at 360×640) are accepted, with nearest-legal snapping as the mitigation and a device check later.

## Assumptions
- A-1: Glyph SVGs can be derived from an OFL-licensed CJK font (for example Noto Serif TC). The 14 glyphs add < 100 KB.

## Open Questions
None. Device risk: 360×640 hit accuracy is checked in the final device pass (README testing policy).

## Developer Handoff
- Prefer a new widget in `lib/core/board/` (e.g. an intersection board) over bending `TapBoard`. The two share the tap-to-(file, rank) contract and the state enum where it fits. Add new state values (e.g. candidate capture) only if the Chess board ignores them safely.
- Paint the background with one `CustomPainter` that repaints only on size or orientation change. Points and pieces sit on top.
- Do snapping in one pure function: (tap offset, cell size, targets) → point | ignore | none. Unit-test ties, edges and orientation.
- Keep the 250 ms commit guard and the haptics in the controller, as in `ChessBoardController`.
