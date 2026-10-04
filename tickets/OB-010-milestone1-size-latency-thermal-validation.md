# Ticket Analysis

> **Xiangqi pass: harness done, simulator baseline in progress (2026-10-04).** Device numbers come in the final device pass with the same harness.
>
> **Decisions:** Q1 → the 30 MB budget is the **store download size** (App Store thinned size, Play per-ABI download) (PO 2026-10-04). Q2 → engineering-proposed position set below; PO confirms.
>
> **Harness (re-run each milestone):**
> - Positions: `integration_test/benchmark/xiangqi_bench_positions.dart`. 9 FENs: start (44 legal moves), central cannon (35), developed with rooks out (48, worst case for the all-move tiers), midgame (29), cannon screens (26), horse and elephant endgame (21), crossed soldiers (9), mate in one (36), in check (4).
> - Per-tier latency + win-chance band check: `flutter test integration_test/xiangqi_benchmark_test.dart -d <device>` (add `--profile` on a real device; the simulator supports debug only, the engine is always built optimized). 9 positions × 7 tiers × 3 cold runs (hash cleared, no cache). Prints `BENCH|…` per run, `SUMMARY|tier|median|p95|max|min depth|over 1000ms` per tier, `SPREAD|…` per position and one `BANDS|…` line.
> - Input cycle with snapping + frames: `flutter test integration_test/xiangqi_input_cycle_test.dart -d <device>`; for frame data on a device: `flutter drive --profile --driver=test_driver/perf_driver.dart --target=integration_test/xiangqi_input_cycle_test.dart -d <device>` (writes `build/xiangqi_frames.json`). 10 Red moves entered as BLACK (second tap off the point so it snaps), timed from the first tap to the suggestion on screen. Prints `CYCLE|…`, `SUMMARY|input cycle|…` and `FRAMES|…`.
> - Size: `flutter build ios --release --no-codesign --analyze-size`; `flutter build apk --release --target-platform android-arm64 --analyze-size`. Store sizes: App Store Connect (TestFlight build, "App Store file size") and Play Console (App bundle explorer, download size per device).
>
> **Results so far (2026-10-04):**
>
> | Item | Measured | NFR | Result |
> |------|----------|-----|--------|
> | iOS arm64 `Runner.app` | 19.5 MB uncompressed, **≈ 9.7 MB zipped** (estimate of the download; Flutter 10 MB, App 5.3 MB, engine 0.9 MB, Assets.car 2.3 MB with the new app icon, 2026-10-04) | ≤ 30 MB download | Pass (estimate; confirm thinned size on the next TestFlight upload) |
> | Android arm64 APK | 19.5 MB file (native libs stored uncompressed), **≈ 9.5 MB gzip** (with the new app icon) (estimate of the Play download; `libflutter` 11.7 MB, `libapp` 4.3 MB, `libfairy_stockfish` 1.6 MB) | ≤ 30 MB download | Pass (estimate; confirm in Play Console) |
> | Xiangqi glyph assets (item a) | 64 KB (`assets/pieces/xiangqi`) | < 100 KB | Pass |
> | Per-tier latency, simulator | Pending: simulator run | ≤ 1000 ms | — |
> | Input cycle with snapping (item b), simulator | Pending: simulator run | < 1.2 s | — |
> | Win-chance band check (item c) | Pending: simulator run | Bands reachable | — |
> | Frames during search, thermal 30 min, tap accuracy at 360×640 (item d) | Device pass | 60 FPS, no throttling | — |
>
> Size notes: both platforms have ~20 MB headroom, so arm64-only Android and NNUE stay optional. The app icon is the largest asset: `Assets.car` 2.3 MB on iOS (1024 px marketing icon included) and an 830 KB adaptive-icon foreground on Android; could be recompressed before release, not blocking.

TICKET_TYPE: TECHNICAL_TASK
CONFIDENCE: HIGH

The NFRs (≤ 30 MB base install, ≤ 1000 ms engine response, < 1.2 s input cycle, 60/120 FPS, ≤ 2 threads) are explicit in `techContext.md`, and `activeContext.md` warns the 30 MB budget is tight and must be measured early. This is measurement and reporting work, not user-facing behavior.

## Ticket Title
[Tech] Measure Milestone 1 against size, latency, frame-rate and thermal NFRs

## Summary
Establish repeatable measurements for the Chess + Xiangqi build: install size per platform/ABI, engine response time, full input cycle time, UI frame rate during search, and thermal/battery behavior over a simulated game, and report gaps against the NFRs.

## Business Context
- `techContext.md` NFRs: base install ≤ 30 MB; engine ≤ 1000 ms on mid-range (Snapdragon 7-series, Apple A12+); input cycle < 1.2 s; 60/120 FPS; max 2 threads; 16–32 MB hash.
- `activeContext.md` risk: "30 MB base budget … measure early".
- `progress.md`: "Size / latency / thermal validation against NFRs" — not started.

## Current Behavior
No build exists; no measurements.

## Expected Behavior
A short report (added to `techContext.md` or the ticket) with measured values and pass/fail against each NFR, plus a repeatable procedure so measurements can be re-run each milestone.

## Business Rules
- BR-001: Base install ≤ 30 MB (Chess + Xiangqi).
- BR-002: Engine response ≤ 1000 ms in standard tactical positions on mid-range hardware.
- BR-003: Full input cycle < 1.2 s (binding over the 1.5 s figure, per `activeContext.md`).
- BR-004: UI holds 60/120 FPS during engine search.
- BR-005: Engine uses ≤ 2 threads.

## User Flow
Not user-facing.

## Acceptance Criteria
- Given a release Android App Bundle, When per-ABI download/install sizes are measured, Then values are recorded and compared with the 30 MB budget.
- Given a release iOS build, When the App Store thinned size is measured, Then it is recorded and compared with the 30 MB budget.
- Given a fixed set of standard tactical positions (Chess and Xiangqi), When the engine is queried on a Snapdragon 7-series and an A12-class device, Then the median and p95 response times are recorded against 1000 ms.
- Given a scripted or manual sequence of move entries, When the input cycle is timed, Then median and p95 are recorded against 1.2 s.
- Given an engine search is running, When the UI is profiled, Then no jank frames attributable to engine work are observed.
- Given a 30-minute simulated game, When device temperature/battery are observed, Then results are recorded and any throttling is noted.
- Given any NFR fails, When the report is written, Then the gap and options (e.g. arm64-only, smaller NNUE, shorter movetime) are listed for a PO decision.

## Edge Cases
- Low-end devices below the reference hardware (out of NFR scope, but note results).
- Debug vs. release builds (only release/profile counts).

## In Scope
- Measurement procedure and report for Milestone 1 (Chess + Xiangqi).
- Definition of the "standard tactical positions" test set (engineering may propose; PO confirms).

## Out of Scope
- Optimizations themselves (separate tickets if gaps are found).
- On-demand games' size (≤ 140 MB total) — measured when those games land.

## Dependencies
- OB-004 (engine in build) for size; OB-007 and OB-009 for latency and input cycle.
- Note (added 2026-10-02): if OB-021/OB-022 are adopted, also measure (a) the depth reachable in ≤ 1000 ms with 2 threads (input to the Solid/Master/God depth targets 12–14 / 18–20 / 24+), (b) the time to evaluate all legal moves for the Baby tier, and (c) the size impact of any "Full NNUE" network.
- Update (PO answer 2026-10-02): the persona is in Milestone 1; strong tiers should be "as fast as possible". Working assumption (OB-021 A2, to be confirmed): every tier must meet the same ≤ 1000 ms / 2-thread budget, so measure per tier.
- Update (OB-021 D14, confirmed 2026-10-02): budget per tier = suggestion ≤ 1000 ms, engine cap 900 ms, ≤ 2 threads, no extra download. Measure separately: (a) all-move evaluation for tiers 1–4 at target depth 8, including worst-case positions with many legal moves; (b) depth-capped searches for Solid (12) and Master (18), and God at the full 900 ms. OB-010 may lower depth targets/caps and recalibrate the win-chance slope per variant (OB-021 R7); band edges are not changed here.
- Note (per-game plan, 2026-10-02): run this ticket in **two passes**, without splitting it. **Chess pass** (part of the Chess Definition of Done): size after OB-004; Chess latency, input cycle, frame rate and thermal per tier. **Xiangqi pass** (Phase 2): the same measurements for Xiangqi. Report results per pass.
- Note (PO compliance document, 2026-10-02): if OB-032 chooses a separate-process engine on Android, measure the process start time and IPC overhead against the 1000 ms budget. The in-app purchase plugin (OB-036) adds to the 30 MB base size; include it in the size pass.
- Note (Phase 2 tickets, 2026-10-03): the **Xiangqi pass** runs after OB-043–OB-047 (epic OB-009). Besides the per-tier latency (all-move evaluation over up to ~44+ legal moves, `UCI_Variant xiangqi`), input cycle, FPS and thermal: (a) measure the size delta of the Xiangqi piece glyph assets (OB-044, expected < 100 KB); (b) time the input cycle on the intersection board including snapping; (c) check the Chess-calibrated WC slope against Xiangqi scores and recalibrate if the tier bands misbehave (OB-021 calibration note); (d) in the final device pass, check tap accuracy on a 360×640 phone (≈ 35 dp cells, OB-044 XQ3 risk).
- Update (PO 2026-10-02): monetization deferred, so **no purchase plugin** in the M1 size pass. Engine stays in-process FFI (OB-004) for now; the IPC measurement applies only if OB-032 later requires it.

## Assumptions
- Reference devices (Snapdragon 7-series Android, A12 iPhone) are available to the team.

## Open Questions
1. Is "base install ≤ 30 MB" measured as store download size, installed size, or per-ABI APK size?
2. What counts as "standard tactical positions"? Is an engineering-proposed test set acceptable?
3. If 30 MB is not achievable with Fairy-Stockfish + Flutter runtime, which is negotiable: the budget, or 32-bit Android support?

## Developer Handoff
- Size: start measuring right after OB-004 with an otherwise empty app, so the budget risk surfaces before features are built.
- Latency: instrument engine request → bestmove timing in profile builds; avoid adding production telemetry (app is offline/private).
- Frames: Flutter DevTools performance overlay/timeline during searches.
