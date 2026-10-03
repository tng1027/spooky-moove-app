# Ticket Analysis

> **Status: Done on iOS simulator (2026-10-03).** Physical iPhone run, Android build/test and Android per-ABI sizes deferred to the final device pass (PO testing policy 2026-10-03).
> - Build: Dart build hooks / native assets (`hook/build.dart`, `native_toolchain_c`), no Gradle/Xcode edits. Decision record in `techContext.md`.
> - Source: git submodule `third_party/fairy-stockfish` at tag `fairy_sf_14_0_1_xq`, unpatched. Defines `LARGEBOARDS`, `PRECOMPUTED_MAGICS`, `NNUE_EMBEDDING_OFF` (classical eval).
> - C shim `native/fairy_stockfish_shim/` (`fs_start` / `fs_send` / `fs_free` / `fs_join`): in-memory `cin`/`cout`/`cerr` line queues; engine on its own native thread; no process spawning (BR-001).
> - Dart `lib/core/engine/fairy_stockfish/`: `FairyStockfishEngine` with one background isolate owning all FFI calls; output via `NativeCallable.listener` (BR-002).
> - Verified on iPhone 17 Pro simulator (`integration_test/fairy_stockfish_engine_test.dart`, 6/6 pass): `uciok` / `readyok`; `go movetime 500` → valid `bestmove` in ~500 ms; `stop` → `bestmove` immediately, engine still usable; double start rejected; dispose during search + restart works; 0 missed frames during a 1 s search.
> - Size: iOS arm64 `fairy_stockfish.framework` 0.91 MB (≈0.39 MB gzip). Android per-ABI: pending.
> - Open Question 1 answered: Android ABIs **arm64-v8a + x86_64** (x86_64 for the emulator); 32-bit not built.
> - Known limits: one engine per process; after a restart `uci` no longer lists `option` lines (upstream static counter; `setoption` still works); native segfault / upstream `exit()` kills the app; backgrounding during a search not handled.
> - Follow-up for PO/BA: update the `systemPatterns.md` diagram to the confirmed in-process design.

TICKET_TYPE: TECHNICAL_TASK
CONFIDENCE: HIGH

All Milestone 1 games run on Fairy-Stockfish. The engine must be compiled for Android and iOS and driven from Dart through FFI on a background isolate. The memory bank itself flags that the documented "executables over stdin/stdout pipes" design does not work on iOS (no child processes), so the engine must be linked in as a library. This is high-risk technical foundation work with no direct user-facing behavior.

## Ticket Title
[Tech] Build Fairy-Stockfish as an in-process library and drive it over FFI from a background isolate (Android + iOS)

## Summary
Compile Fairy-Stockfish for Android (per ABI) and iOS as a linked library, expose a minimal C send/receive interface, and prove from Dart that a background isolate can send UCI commands and receive engine output on both platforms without blocking the UI.

## Business Context
- `activeContext.md` Next step 2; risk "Executables vs. libraries on iOS".
- `projectbrief.md`: Apple forbids downloaded executable code; engine binaries must ship in the app.
- `techContext.md`: FFI (no platform channels), background isolates, evaluate native assets / build hooks (`hooks`, `code_assets`) vs. hand-written Gradle/Xcode.
- Base install budget ≤ 30 MB (`techContext.md`) — engine size must be measured early.

## Current Behavior
No native code, no build integration. `systemPatterns.md` diagram describes "Native C/C++ Engine Executables" communicating over "Standard I/O / Pipe", which contradicts the iOS constraint noted in `activeContext.md`.

## Expected Behavior
- Fairy-Stockfish is compiled into the Android and iOS builds as a library (no process spawning).
- A minimal C interface lets Dart send a line of text to the engine and read output lines.
- From a background isolate, Dart can send `uci` and receive `uciok`, send `isready` and receive `readyok`, and run `position startpos` + `go movetime <ms>` and receive a `bestmove` line.
- The UI isolate is never blocked while the engine runs.
- Release build size contribution of the engine is measured and recorded per ABI.

## Business Rules
- BR-001: No engine executable or machine code is downloaded at runtime (Apple rule).
- BR-002: Engine work never runs on the UI isolate.

## User Flow
Not user-facing. Developer verification flow:

```text
Debug screen / test triggers engine start
↓
Background isolate loads the native library
↓
UCI handshake (uci → uciok, isready → readyok)
↓
position startpos; go movetime 500
↓
bestmove line received and logged
```

## Acceptance Criteria
- Given an Android API 24+ device (arm64-v8a), When the engine is started from Dart, Then `uci` returns `uciok` and `isready` returns `readyok`.
- Given an iOS 13+ device, When the engine is started from Dart, Then the same handshake succeeds without spawning a child process.
- Given the engine is running a search, When the user interacts with the UI, Then frames are not dropped because of engine work (engine runs off the UI isolate).
- Given `position startpos` and `go movetime 500`, When the search completes, Then a syntactically valid `bestmove` line is received within ~600 ms on mid-range hardware.
- Given a `stop` command during a search, When it is sent, Then the engine returns `bestmove` promptly and remains usable.
- Given release builds, When sizes are measured, Then the engine's size contribution per Android ABI and for iOS is recorded in `techContext.md`.

## Edge Cases
- Engine crash / native exception — must not crash silently; surfaced as an error to the caller.
- Engine started twice / disposed while searching.
- App backgrounded during a search (iOS may suspend).
- 32-bit Android ABIs (armeabi-v7a) — decide if supported (see Open Questions).

## In Scope
- Native build of Fairy-Stockfish for Android ABIs and iOS (device + simulator as needed for development).
- Minimal C shim (send line / read line, or redirected in-process pipes).
- Dart FFI bindings (hand-written or `ffigen`).
- Background isolate that owns the engine and exchanges text lines with the UI isolate.
- Size measurement of the engine in release builds.
- Decision record: native assets/build hooks vs. Gradle/CMake + Xcode setup.

## Out of Scope
- Protocol abstraction, UCI parsing, engine options (OB-005).
- NNUE loading for Shogi.
- KataGo, Edax, Gomoku engines.
- Any user-facing screen.

## Dependencies
- OB-003 (Flutter project exists).
- OB-002 (licensing) — must be resolved before any store release, not before this spike.
- Note (PO compliance document, 2026-10-02): the PO mandates running GPL engines in a separate process (IPC) and forbids static/dynamic linking. That conflicts with this in-process FFI design and is **not feasible on iOS** (no child processes; no downloaded executables). Until **OB-032** is decided (counsel), this ticket stays a technical spike: nothing ships, and the engine sits behind the transport-agnostic interface of OB-005, so an Android process-based transport can be swapped in if chosen.
- Update (PO answers 2026-10-02): counsel is deferred; **development continues with this in-process FFI design** as the working architecture for the Chess slice and M1 builds. OB-032 remains a release blocker only. Risk: if counsel later mandates process separation, Android needs a new transport; iOS would need a strategy change (see OB-032 note).

## Assumptions
- Fairy-Stockfish's embedded NNUE (if any) for Chess/Xiangqi fits within the bundle budget; to be verified by the size measurement.
- Android App Bundle per-ABI splitting will be used (`activeContext.md` 30 MB risk).

## Open Questions
1. Must 32-bit Android (armeabi-v7a) and x86_64 be supported, or arm64 only? (Affects size and build matrix; API 24 devices may be 32-bit.)
2. If the measured size makes the 30 MB base budget infeasible, is the budget negotiable, or should features be cut? (PO decision; raise with OB-010 results.)

## Developer Handoff
- Treat this as a spike with a production-quality outcome: the C shim and isolate runner will be reused by every engine.
- Recommended: one long-lived isolate per active engine, communicating by `SendPort`/`ReceivePort` with text lines; keep native calls blocking only inside that isolate.
- Update the `systemPatterns.md` diagram (via PO/BA) once the in-process design is confirmed — the "executables/stdin" description is inaccurate for iOS.
- Add an integration test (device) for the handshake; unit tests aren't possible for native linking.
