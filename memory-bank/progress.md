# Progress

Plan and ticket statuses: `tickets/README.md` (per game: Phase 0 shared → Phase 1 Chess → Phase 2 Xiangqi = Milestone 1 → ODDAS and later games).

## Done
- [x] BRD and SAD documented in the memory bank (2026-10-02).
- [x] Design system and Flutter dependency list documented (2026-10-02).
- [x] Backlog and per-game plan created; Chess requirements decided (OB-001 resolved for Chess) (2026-10-02).
- [x] Chess rules library chosen: `chess` 0.8.1 (2026-10-02).

## Not started
- [x] Flutter project scaffold (`pubspec.yaml`, theme tokens, bundled fonts, revised layout) — OB-003 (2026-10-03)
- [x] FFI bridge + background isolate engine runner — OB-004 (provisional, OB-032); verified on iOS simulator 2026-10-03. Deferred to the final device pass: physical iPhone run, Android build/test, Android per-ABI sizes.
- [x] Fairy-Stockfish integration (Chess, Xiangqi): engine interface + UCI adapter — OB-005; verified on iOS simulator 2026-10-03 (UCCI not needed). Device timing deferred to the final device pass.
- [x] Persona tier logic core + engine-facing `PersonaSuggester` — OB-022; verified on iOS simulator 2026-10-03. Screen wiring with OB-025/OB-007.
- [x] Persona selector row — OB-023; verified on iOS simulator 2026-10-03.
- [x] Rules module Chess: `ChessRules` + adapter over `chess` 0.8.1 — OB-006 (2026-10-03); game-end composition — OB-024; Xiangqi — OB-009 (library TBD)
- [x] Legal-only tap board — OB-006; verified on iOS simulator 2026-10-03. Device timing deferred to OB-010.
- [ ] Suggestion card + haptics — OB-007
- [ ] New game, turn loop, game end, undo — OB-011, OB-025, OB-024, OB-012
- [x] Fair-play notice gate (EN/VI, versioned acknowledgment in `shared_preferences`) — OB-008 (2026-10-03). Remaining: place the "FAIR PLAY" key opening `FairPlayScreen.readOnly()` on the new-game screen in OB-011 (REQ-005).
- [ ] Size / latency / thermal validation against NFRs — OB-010
- [ ] Licenses (ABOUT) screen + parental gate — OB-033
- [ ] Match history storage (SQLite / KV) — requirements undefined (OB-013)
- [ ] ODDAS: manifest, downloader, verification, lifecycle, storage settings — OB-014/015
- [ ] Shogi (USI, `shogi.nnue`, drop tray, promotion prompt)
- [ ] Gomoku / Caro (Yixin or custom)
- [ ] Othello (Edax 4.4)
- [ ] Go (KataGo, GTP, 19×19 input, Pass/Resign)

## Deferred
- Monetization (OB-035–OB-039), by PO decision 2026-10-02.
- Physical-device testing (iPhone + Android) and all Android verification: one pass after all tickets are finished (PO 2026-10-03). Until then, tickets are verified on the iOS simulator.

## Known issues
- None yet (see open risks in `activeContext.md`).
