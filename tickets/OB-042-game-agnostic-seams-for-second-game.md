# Ticket Analysis

> **Status: Done on iOS simulator (2026-10-03).** No visible change for Chess. The unit, widget and integration suites (318 + 24 tests) pass; tests changed only for renamed types.
> - Side model (REQ-001): `PlayerSide { first, second }` in `lib/core/game/`. `GameSession.userSide` is a `PlayerSide`. `GameKind` carries `engineVariant`, `files` / `ranks` and `sideLabel(side)`. Chess maps first to White through `PieceColor.of` / `.side`, and `ChessBoardState.userSide` stays a `PieceColor`. New-game side keys are `newGame.side.first|second`.
> - Active-game seam (REQ-002): `ActiveGameState` (side to move, position id, legal-move count, in check, can undo, entry blocked, result headline + hint) and `ActiveGameController` (`newGame`, `undo`, `commitEngineMove`, `showSuggestion(String?) → bool`, `enginePosition`). `ChessBoardController` implements the controller; `chessActiveGameState` maps the board.
> - Registry (REQ-008): `lib/features/new_game/presentation/game_registry.dart` is the only `switch` on `GameKind`. It holds `activeGameKindProvider`, `gameControllerProvider(game)`, `activeGameStateSourceProvider`, `activeGameControllerProvider`, `activeEngineVariantProvider`, and `GameWidgets` (board, suggested move, side pictogram). Note: the state source is a `select` on the game's own notifier, not a derived `Provider`, because Riverpod 3 notifies listeners of derived providers only on the next scheduler flush, which would delay the suggestion request after a board move.
> - Suggestion state (REQ-003, REQ-004): `SuggestionReady(suggestion)` exposes `engineMove`, and `SuggestionGameOver(headline)`. I PLAYED IT calls `commitEngineMove(ready.engineMove)`. The card's move area is `ChessSuggestedMove` (it finds the move in the board's legal moves); thinking / level / error / game-over stay shared. `GameResultFormat` became Chess-only `ChessResultFormat`, and `GameResultHeadline` / `ResultTone` moved to `lib/core/game/`.
> - Engine variant (REQ-005): `SuggestionController` starts the engine once and runs `setVariant` whenever the active variant differs, before the search. A failure resets both and reuses ENGINE ERROR + RETRY. `setVariant` cancels running searches, and the request counter drops stale results.
> - Board size (REQ-006): `AdvisorScreen.boardSizeFor(available, files:, ranks:)` returns a `Size`. 8 × 8 is unchanged (360 / 392 / 348); 9 × 10 gives 43.6 / 40.0 / 34.8 dp cells.
> - Smart entry (REQ-007): generic `SmartEntry` in `lib/core/board/smart_entry.dart` (`EntryMove<S>`, `ChoicePending` for several moves with the same from/to). Chess's `move_entry.dart` keeps its API through typedefs (`PromotionPending = ChoicePending<ChessSquare, ChessMove>`) and adds queen-first ordering and `choosePromotion`. The `MoveEntry` tests run unchanged.
> - New tests: `game_kind_test`, `board_size_test`, `chess_active_game_state_test`, `engine_variant_test` (a fake second game registered only in the test: `setVariant` runs before its first search, and the Chess search is cancelled).

TICKET_TYPE: TECHNICAL_TASK
CONFIDENCE: HIGH

Internal refactor with no user-facing change. Phase 1 kept the board and entry grid generic (`TapBoard`, `GameEngine`, `PersonaSuggester`). The advisor layer, the session and the new-game screen, however, read Chess types and providers directly (code review 2026-10-03, list below). Xiangqi (OB-009 epic) is a second concrete use case for each coupling point listed here, so these seams pass the workspace rule 09 test. Anything Xiangqi does not need stays Chess-specific.

## Ticket Title
[Tech] Add the game-agnostic seams a second game needs (side model, active-game seam, engine variant, aspect-aware board size)

## Summary
Decouple the advisor screen, the session and the new-game screen from Chess types, so a Xiangqi board controller and rules module (OB-043, OB-044) can plug in. Chess behaviour stays identical, and the existing Chess test suite is the acceptance gate.

## Business Context
- PO 2026-10-03: carry every decided Chess behaviour over to Xiangqi (OB-009). The shared behaviours (status line states, I PLAYED IT, undo, top bar win rate, persona gating, game-over handling) must not be copied per game, or the two games will drift.
- README design guardrail: "which games are offered" stays data in one place (`GameKind`).

## Current Behavior (chess coupling found in code, 2026-10-03)
| Area | File | Coupling |
|------|------|----------|
| Session side | `new_game/domain/game_session.dart` | `userSide` is `PieceColor` (Chess `white` / `black`) |
| Session start | `new_game/presentation/game_session_controller.dart` | `switch (game) { case GameKind.chess: chessBoardControllerProvider…newGame(side) }` |
| New-game screen | `new_game/presentation/new_game_screen.dart` | side keys built from `PieceColor.values`, label `'WHITE' / 'BLACK'`, `ChessPiecePictogram` king; `_selectedGame = GameKind.values.first` |
| Suggestion | `advisor/presentation/suggestion_controller.dart` | `_variant = 'chess'` constant; reads `chessBoardControllerProvider` (side to move, status, legal moves, checked king) and `chessRulesProvider` (`toEnginePosition`, `moveFromUci`); `SuggestionReady.move` is a `ChessMove`; `SuggestionGameOver.status` is a `ChessGameStatus` |
| Turn status | `advisor/presentation/turn_status.dart` | reads `chessBoardControllerProvider` (side to move, `status.isOver`) |
| Status line | `advisor/presentation/status_line_content.dart` | `PromotionPending` from Chess `MoveEntry` |
| Top bar / UNDO / I PLAYED IT | `widgets/top_bar.dart`, `undo_key.dart`, `confirm_played_key.dart` | read / call `chessBoardControllerProvider` (`isOver`, `canUndo`, `undo()`, `commit(ChessMove)`) |
| Card | `widgets/suggestion_card.dart` | renders `ChessMove` with `ChessMoveFormat` and `ChessPiecePictogram`; result via `GameResultFormat(ChessGameStatus, PieceColor)` |
| Result text | `advisor/domain/game_result_format.dart` | Chess statuses and draw reasons |
| Layout | `advisor/presentation/advisor_screen.dart` | `boardSizeFor` returns one square side; `ChessBoard` hard-wired |
| Entry logic | `chess/domain/move_entry.dart` | first-tap / candidate / auto-commit rules typed on `ChessSquare` / `ChessMove` (+ promotion) |

Already game-agnostic (keep as is): `GameEngine` / `UciEngine` (`setVariant`), `EnginePosition`, `SearchLimits`, `PersonaSuggester` (engine move strings, cache cleared per game), `winChance`, `EvalFormat`, `PersonaRow`, `AppKey`, `NewGameKey`.

## Expected Behavior
No visible change for Chess. After this ticket:
- The session's side means "moves first / moves second" and has per-game labels (Chess WHITE / BLACK; Xiangqi RED / BLACK from OB-045).
- The advisor layer reads the current game through one small seam. Adding Xiangqi means implementing that seam, not editing every advisor widget.
- The engine variant comes from the current game.
- The board area is sized for any files × ranks grid.

## Functional Requirements
- REQ-001 (side model): `GameSession.userSide` becomes a game-agnostic side (first mover / second mover). Chess maps first ↔ White. User-visible side labels and side-key pictograms come from the game entry (`GameKind`), never from an enum name. A Xiangqi first-mover side must never be shown as "WHITE", and Chess must never show "RED".
- REQ-002 (active-game seam): the advisor layer (suggestion, turn status, status line, top bar, UNDO, I PLAYED IT, card, advisor screen) gets everything it needs about the current game through one interface implemented per game. That covers: side to move, whether the game is over, whether undo is possible, whether entry blocks confirming (Chess promotion chooser open), whether the user's general/king is in check, the legal-move count, the engine position, a position identity for change detection, the result headline (lines + tone) and optional hint, and the actions `newGame(side)`, `undo()`, `commitEngineMove(String)` and `showSuggestion(String?)`. Only members both games need are added.
- REQ-003 (suggestion state): `SuggestionReady` and `SuggestionGameOver` no longer expose Chess types to shared code. The suggested move is kept as the engine move plus whatever the game needs to render and commit it. I PLAYED IT still commits exactly the move held in the ready state (OB-041 REQ-006).
- REQ-004 (card rendering): the suggestion card's move area is rendered by a per-game widget. The thinking / pick level / error + RETRY / game-over states stay shared.
- REQ-005 (engine variant): the variant (`chess`, `xiangqi`) comes from the game entry. When a session starts with a different game than the engine's current variant, `setVariant` runs before the first search, and no search for the old variant can deliver a result afterwards. The persona cache is still cleared on every new game.
- REQ-006 (board size): `boardSizeFor` returns a board size for a files × ranks grid: cell = min(W / files, (H − 252) / ranks), where H is the height inside the safe area and 252 dp = top bar 48 + persona row 52 + status line 56 + minimum card 96. For Chess (8 × 8) the result must equal today's value for every screen size.
- REQ-007 (smart entry): the 1–2-tap entry rules (first-tap rule, auto-commit, candidates, cancel) are shared by Chess and Xiangqi, not copied. Promotion handling stays Chess-only.
- REQ-008 (session start): `GameSessionController.start` resets the right game's board through the seam, with no per-game branches spread over the advisor layer. Branching on `GameKind` is allowed in one place, the game registry or provider.
- REQ-009: No new package, no global mutable state, no generic "game framework". Only Chess and Xiangqi need to fit (workspace rule 09).

## Business Rules
- BR-001: Chess behaviour, texts, haptics, timings (250 ms commit guard, 500 ms NEW GAME guard, 2 s engine timeout) and layout stay exactly the same.
- BR-002: `GameKind` stays the single list of offered games (README guardrail).

## User Flow
Not user-facing.

## Acceptance Criteria
- Given the full Chess unit, widget and integration test suite, When run after the refactor on the iOS simulator, Then every test passes. Tests may change only for renamed types or providers, never for behaviour.
- Given a Chess session with the user playing first, When any advisor screen renders, Then the side shows as WHITE wherever it appeared before, and no "RED" text exists anywhere in the Chess flow.
- Given the game entry for Chess, When the engine starts, Then `setVariant('chess')` is sent before the first search, as today.
- Given a fake second game registered only in a test, When a session for it starts after a Chess session, Then `setVariant` is called with its variant before its first search, and a Chess search still running cannot deliver a suggestion.
- Given `boardSizeFor` for 8 × 8, When called with 360×800, 392×800 and 360×600 safe-area sizes, Then the results equal the current square sizes (360, 392, 348).
- Given `boardSizeFor` for 9 × 10, When called with 392×800, 360×800 and 360×600 safe-area sizes, Then the cells are 43.6, 40.0 and 34.8 dp (board 392×436, 360×400, 313×348).
- Given the shared entry logic, When the Chess `MoveEntry` tests run against it, Then they pass unchanged, including promotion.
- Given the advisor-layer files listed under "Current Behavior", When inspected, Then none imports `chess_board_controller.dart`, `chess_models.dart`, `chess_game_status.dart` or `move_entry.dart`, except the per-game card widget and the Chess implementation of the seam.

## Edge Cases
- New game with the same game and side: still a fresh session (`updateShouldNotify` stays true).
- BACK from the new-game screen keeps the current game, tier and side (OB-011). The engine variant must not change on BACK.
- Engine failure during `setVariant`: same ENGINE ERROR + RETRY path as a failed start (OB-007 REQ-008).
- Game over: the active-game seam reports over before tier gating, as `SuggestionGameOver` does today (OB-024).

## In Scope
- The refactors in REQ-001–REQ-009, plus unit tests for side labels, variant switching and `boardSizeFor` (both grids).

## Out of Scope
- Any Xiangqi rules, board, assets or texts (OB-043–OB-047).
- Registering `GameKind.xiangqi` in the UI (OB-045). It may exist behind tests only if needed.
- Generalising for Shogi, Go or other later games.

## Dependencies
- Phase 1 tickets (done). No PO input needed.
- Consumed by OB-044, OB-045, OB-046, OB-047.

## Assumptions
- A-1: One active game at a time; two engines in parallel are not needed.
- A-2: The 252 dp fixed chrome matches the current tokens (`topBarHeight` 48, `personaRowHeight` 52, `statusLineHeight` 56, `minSuggestionCardHeight` 96).

## Open Questions
None.

## Developer Handoff
- Suggested shape (developer decides): a shared `PlayerSide { first, second }` (or move `PieceColor` to `lib/core/game/` with labels per game); `GameKind` gains `engineVariant`, `sideLabel(side)` and the side pictogram; one `ActiveGame`-style read model + notifier interface; a provider that resolves it from `gameSessionProvider.game`.
- Keep `ChessBoardController` as the Chess implementation. Don't merge Chess and Xiangqi controllers into one generic controller.
- Make `MoveEntry` generic over a minimal move shape (from, to), with promotion as a Chess extension. If that turns out heavier than ~1 day, raise it before copying.
- Change detection: `SuggestionController` listens to `legalMoves` identity today. Keep an equivalent position identity on the seam.
- Run the whole Chess suite (unit, widget, `integration_test/`) on the iPhone simulator before closing.
