# Active Context

## Current focus
- 2026-10-02: Project kicked off. BRD + SAD captured in the memory bank. No code yet (repo empty).

- 2026-10-02: Design system (Industrial Utility / Terminal Neo-Brutalism, see `designSystem.md`) and the Flutter dependency list (see `techContext.md`) captured.

- 2026-10-02: Package versions verified on pub.dev; a starter `pubspec.yaml` snippet is in `techContext.md`.
- 2026-10-03: Flutter 3.47.6 / Dart 3.13.5 installed. OB-003 done: git repo, app shell `omni_board` (`com.thuannguyen.omniboard`), dark theme tokens, bundled JetBrains Mono, revised placeholder layout, widget tests. iOS minimum is 15.0 (Flutter requirement).
- 2026-10-04: App renamed to **Cataland**: Dart package `cataland`, bundle/application ID `com.cataland.app`, display name "Cataland", root widget `CatalandApp`. Repo folder is still `omni-board`.

- 2026-10-02: Backlog created in `tickets/` (index and per-game plan: `tickets/README.md`). PO decisions recorded:
  - Tap board replaces the keypad (OB-006).
  - No-chess-knowledge principle and coordinate notation (OB-006, OB-007).
  - 7-tier persona (OB-021).
  - Fair-play notice format (OB-008).
  - Session flow, with undo in the Chess DoD (OB-001, OB-012).
  - Monetization deferred, no analytics (OB-035).
  - Adult audience (OB-040).
- 2026-10-02: Chess rules library decided: Dart package `chess` 0.8.1 (OB-002 Q3, Chess only; see `techContext.md`).
- 2026-10-03: OB-004 implemented and verified on the iOS simulator (Fairy-Stockfish via build hooks + C shim + background isolate; details in `techContext.md`). Android build/test deferred.
- 2026-10-03: OB-006 implemented and verified on the iOS simulator: `ChessRules` interface + `ChessPackageRules` adapter, pure `MoveEntry` state machine, generic `TapBoard`, `ChessBoard` with Riverpod `ChessBoardController`, Cburnett SVG pictograms (`flutter_svg`, BSD), promotion chooser, haptics (`lightImpact` = move accepted). Castling always takes 2 taps (the rook also reaches the king's target square).
- 2026-10-03: OB-022 core implemented and verified on the iOS simulator: `lib/features/persona/` (pure tier selection + WC conversion + `PersonaConfig`; `PersonaSuggester` over `GameEngine` with per-(position, tier) cache and superseded-result discard). Screen wiring and the "no tier → no request" gate come with OB-025/OB-023/OB-007.
- 2026-10-03: OB-023 implemented and verified on the iOS simulator: `PersonaRow` (built from `PersonaTier.values`) + nullable `personaTierProvider` (`select` with `selectionClick`, `clear` for OB-011); the card placeholder shows `PICK A LEVEL` until a tier is chosen. OB-025 listens to the provider to call `PersonaSuggester`. Open: OB-023 Q2 (keys ≈ 40 dp wide below 360 dp).
- 2026-10-03: OB-011 implemented and verified on the iOS simulator: `lib/features/new_game/` (`GameKind` enum = the offered-games list, `GameSession`, `gameSessionProvider.start()` → `ChessBoardController.newGame(side)` + tier clear), `NewGameScreen` (root after the fair-play notice; pushed with BACK from the advisor's NEW GAME key after confirmation; the old game is reset only when a side is tapped), shared `AppKey` widget in `lib/core/widgets/`. OB-025 should listen to `gameSessionProvider` for REQ-006 and search cancellation.
- 2026-10-03: OB-007 implemented end to end and verified on the iOS simulator (also completes the OB-022 Chess wiring): `gameEngineProvider` + `personaSuggesterProvider`, `SuggestionController` (sealed states, request on the user's turn with a tier, stale-drop via request counter + `PersonaSuggester.cancel()`, 2 s timeout, Retry restarts the engine), pure `ChessMoveFormat` / `EvalFormat`, `SuggestionCard`, `BoardSquareState.suggestedCapture` for en passant. ~340 ms from the opponent's move to the suggestion on the simulator. OB-025 now only needs the status line and the game-end stop.
- 2026-10-03: OB-025 implemented and verified on the iOS simulator (closes OB-022's Chess wiring too): derived `turnStatusProvider` (session user side vs. board side to move; null with no game or no legal move) and `StatusLine` (turn label left in `textSecondary`, NEW GAME right; replaces `StatusLinePlaceholder`). Game end is a minimal stop (no label, no search, even on a tier change); OB-024 owns results and draw rules. Integration test `turn_loop_test.dart`: 573 ms first suggestion incl. engine start, 346 ms next.
- 2026-10-03: OB-024 implemented and verified on the iOS simulator: pure `ChessGameStatus.of(rules)` (sealed: in progress with optional claimable draw / checkmate / draw with reason), carried in `ChessBoardState.status` (derived per snapshot, so undo restores it); game over → all squares dimmed, taps ignored, `SuggestionGameOver` (replaces `SuggestionNoMoves`, checked before the tier), no turn label. Card shows the result on two lines via `GameResultFormat`; claimable-draw hint at the card's bottom; NEW GAME key reused.
- 2026-10-03: OB-012 implemented and verified on the iOS simulator: `ChessBoardController.undo()` (promotion chooser closes first, else `ChessRules.undo()` + new snapshot) and `ChessBoardState.canUndo`; `UndoKey` in the status line left of NEW GAME; `AppKey` now has a disabled state (`onTap: null`). Everything downstream (game status, turn label, suggestion via the (position, tier) cache) follows from the restored snapshot; the adapter's history is the only history.
- **Testing policy (PO 2026-10-03):** every ticket is implemented and verified on the **iOS simulator**. Revised 2026-10-04: the agent runs `flutter analyze` + `flutter test` and updates integration tests but does not run them; the PO runs the integration tests himself. Physical-device testing (iPhone and Android) happens in one pass after all tickets are finished. Android work (builds, emulator/device runs, per-ABI sizes) is deferred until then.
- **Ticket status (PO 2026-10-03):** when a ticket's implementation is finished, add a `> **Status: ...**` block at the top of the ticket file (format as in OB-003/OB-004) and update `tickets/README.md`.
- 2026-10-03: PO: "For chess, it is all good now" → move every decided Chess behaviour to Xiangqi. BA + Designer review done; **Phase 2 tickets prepared**: OB-009 rewritten as the epic (carry-over matrix + Xiangqi DoD), OB-042 seams refactor, OB-043 rules module, OB-044 intersection board, OB-045 new-game GAME row + RED/BLACK, OB-046 advisor wiring (card `[炮] H3 ➔ E3`, WXF in the expert line), OB-047 game end, OB-010 Xiangqi pass. 
- 2026-10-03: **PO accepted all Phase 2 defaults XQ1–XQ11**: characters on discs, `pieceRed` token, 40 dp + snapping (device check later), absolute `A`–`I` / `1`–`10` + piece disc with WXF only in the expert line, default RED, no perpetual check/chase adjudication, `NO MOVES` / `YOU WIN|YOU LOSE`, preselect current game else CHESS, no automatic draws, OB-009 rewrite acknowledged, hand-written Dart rules module. OB-001 Q10 resolved. Recorded in the tickets and `productContext.md`.
- 2026-10-03: OB-042 implemented and verified on the iOS simulator (no visible Chess change). Xiangqi plugs in by:
  - implementing `ActiveGameController` plus a state mapping to `ActiveGameState` (`lib/core/game/`);
  - adding a `GameKind` value (label, `engineVariant`, files / ranks, side labels);
  - adding one case per `switch` in `lib/features/new_game/presentation/game_registry.dart` (state source, controller, board / suggested-move / side-pictogram widgets).

  Board entry uses the shared `SmartEntry` (`lib/core/board/smart_entry.dart`). Shared advisor code sees moves only in engine notation. Riverpod 3 caveat: listeners of a derived `Provider` are notified on the next scheduler flush, so the active-game state is exposed as a `select` on the game's own notifier.
- 2026-10-03: OB-043 implemented and verified on the iOS simulator.
  - Pure-Dart Xiangqi rules in `lib/features/xiangqi/`: model, `XiangqiRules` interface and the `DartXiangqiRules` mailbox implementation. `XiangqiMove` implements `EntryMove` for OB-044.
  - Perft matches the bundled Fairy-Stockfish on 6 positions (oracle integration test `xiangqi_perft_oracle_test.dart`; counts recorded in `test/features/xiangqi/data/xiangqi_perft_positions.dart`). About 0.01 ms per position.
  - Next: OB-044 (intersection board + Xiangqi board controller implementing `ActiveGameController`).
- 2026-10-03: OB-044 implemented and verified on the iOS simulator.
  - Core: `IntersectionBoard` plus the pure `snapTap` in `lib/core/board/`; `boardClockProvider` now lives in `board_clock.dart`.
  - Xiangqi: `XiangqiBoardController` / `XiangqiBoard` / `xiangqiActiveGameState` in `lib/features/xiangqi/presentation/`, with glyph SVGs from OFL Noto Serif TC (rebuild with `tool/xiangqi_glyphs.py`) and the `pieceRed` token.
  - Not registered yet. Next: OB-045 adds `GameKind.xiangqi` to `game_registry.dart` and the new-game screen, plus the full advisor layout check.
- 2026-10-03: OB-045 implemented and verified on the iOS simulator. Xiangqi is selectable (`GameKind.xiangqi`); `NewGameScreen(initialGame:)` preselects the session's game; real Fairy-Stockfish suggestions appear in the `xiangqi` variant. The card shows an interim `H3 ➔ E3`. Next: OB-046 (Xiangqi card with disc, capture mark and WXF line), then OB-047 (game end).
- 2026-10-03: OB-046 implemented and verified on the iOS simulator. Xiangqi card: moving-piece disc + `H3 ➔ E3` (` ✕` on capture); expert line `C2.5 · EVAL …` via `XiangqiWxf` (Fairy-Stockfish WXF port, `.` instead of `=`). New seam slot `GameWidgets.expertLine`. `SuggestionController` now defers the session-change refresh by a microtask (derived providers are stale inside the session listener), which fixed the first search after a game switch running in the old variant. Next: OB-047 (Xiangqi game end).
- 2026-10-04: OB-047 implemented and verified on the iOS simulator. `XiangqiGameStatus` (no legal move = loss: checkmate / no moves) and `XiangqiResultFormat` feed `ActiveGameState.headline`; the shared game-over path needed no change. Next: OB-010 Xiangqi device pass.
- 2026-10-04: OB-048 (PO request after simulator testing). Board entry never commits on the first tap, even with a single option; the first tap shows the options and the second picks. Shared `SmartEntry`, so Chess and Xiangqi both change. Verified on the iOS simulator.
  - The dev Mac ran out of disk space (Xcode DerivedData was 22 GB), so Xcode builds failed with "No space left on device". DerivedData was cleared with PO approval. If integration files fail to "load", check free space first.
- **Now: Phase 2 Xiangqi, no PO blockers.** Start with OB-042 ∥ OB-043. Phase 1 Chess is done on the simulator; the Chess pass of OB-010 and the device pass are still open.

## Next steps (per-game plan, `tickets/README.md`)
0. Install Flutter (with Dart ≥ 3.13).
1. Phase 0: ~~scaffold (OB-003)~~, ~~Fairy-Stockfish over FFI (OB-004)~~, ~~engine interface (OB-005)~~, ~~persona core (OB-022)~~, ~~persona row (OB-023)~~ done (simulator); next fair-play notice (OB-008).
2. Phase 1 Chess: ~~tap board (OB-006)~~ done (simulator), ~~suggestion card (OB-007)~~ done (simulator), ~~new game (OB-011)~~ done (simulator), ~~turn loop (OB-025)~~ done (simulator), ~~game end (OB-024)~~ done (simulator), ~~undo (OB-012)~~ done (simulator), Chess performance pass (OB-010).
3. Phase 2 Xiangqi (epic OB-009) completes Milestone 1: OB-042 ∥ OB-043 → OB-044 → OB-045 → OB-046 → OB-047 → OB-010 Xiangqi pass.
4. Release readiness in parallel: licenses screen (OB-033), store positioning (OB-034), counsel on OB-032/OB-040.
5. Post-M1: ODDAS (OB-014/015), then Shogi, Gomoku/Caro, Othello, Go.

## Open questions and risks
- **Licensing (decided PO 2026-10-04, OB-002):** the app is **GPLv3 open source** (source published); engines stay in-process over FFI on both platforms; IPC dropped. Every dependency and asset must be GPL-compatible. Still a release blocker: counsel confirms GPLv3 store distribution and the compliance checklist (OB-032).
- **`chess` package on Dart 3:** verified on Dart 3.13.5 (2026-10-03). Game end is composed in our adapter, not with `in_draw`/`game_over` (OB-024).
- **30 MB base budget:** since Apple requires all engine binaries to ship in the app (Fairy-Stockfish ~12 MB, KataGo ~10 MB, Edax, Yixin) plus Flutter's runtime, the 30 MB target is tight. Need per-ABI splitting (Android App Bundle) and to measure early (OB-010).
- **KataGo on mid-range CPU:** the 1000 ms target with ~40 MB weights and 2 threads may require a smaller network or visit caps (OB-020).
- **Xiangqi:** notation and 9×10 sizing decided (PO 2026-10-03, XQ3/XQ4). Remaining risk: tap accuracy with ≈ 35 dp cells on 360×640 phones, checked in the final device pass. UCCI not needed (OB-005).
- **Go input:** quadrant zoom vs. coordinate grid (OB-019).
- **Gomoku engine:** Yixin vs. a custom C++ engine. Yixin is not open source, so bundling it needs permission (or use an open engine such as Rapfi or a custom one) (OB-017).
- **Input latency target mismatch:** the BRD says the input cycle is < 1.2 s; the UI consultation says < 1.5 s. 1.2 s is the working target until the PO decides.
- **Color token mismatch:** the disabled key color is `#1A1B20` in the palette but `#16171E` in the sample code; `bgDark` vs. true black. Provisionally `#1A1B20` / `#0F1015` in `lib/core/theme/app_colors.dart` (PO 2026-10-03); final values open (OB-003 Q1).
- **Decided 2026-10-04:** no resume after app kill in M1 (OB-001 Q6).
- **Not decided:** app name and tier-7 label (OB-034); app language beyond the EN/VI fair-play notice; match history (OB-013).
