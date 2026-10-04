# Tech Context

## Stack
- **Client / UI:** Flutter (Dart). Chosen for cross-platform state handling, predictable 60/120 FPS, isolates, and zero-overhead C interop through FFI.
- **Native interop:** Dart FFI talking directly to C/C++ dynamic libraries (`.so` on Android, `.dylib`/framework on iOS), no platform channels. Engines run **in-process** (no child processes; impossible on iOS). This is the provisional approach pending the license-boundary decision (OB-032; see `systemPatterns.md`).
- **No analytics / tracking / data-collecting SDKs** (PO 2026-10-02, OB-035 M-D2). No in-app purchase dependency while monetization is deferred.
- **Concurrency:** Dart isolates / background worker threads for engine I/O streams.
- **Engines:** Fairy-Stockfish (Chess, Xiangqi, Shogi), KataGo (Go, OpenCL/CPU), Edax 4.4 (Othello), Yixin or custom C++ (Gomoku/Caro).
- **Storage:** SQLite or key-value store for match history; app documents directory for downloaded assets.
- **Networking (assets only):** `Dio`, HTTP chunked transfer, MD5/SHA-256 integrity checks against a remote manifest. CDN: AWS S3 / Cloudflare R2.
- **State management:** Riverpod (`flutter_riverpod`). The proposal said 2.x; the current major is 3.x, which is used for this new project.

## Dependencies (by group)
| Group | Package | Purpose |
|-------|---------|---------|
| Native bridge | `ffi` | Bind Dart to the C/C++ engine libs (`.so`, `.dylib`) |
| Native bridge | Dart `Isolate` (plain; `flutter_isolate` only if plugins are needed inside the isolate) | Run engine and read/write UCI/GTP/USI streams off the UI thread |
| Native bridge | `path_provider`, `path` | `getApplicationDocumentsDirectory` for `.nnue` / `.bin.gz` / books |
| Dev | `ffigen` | Generate Dart FFI bindings from C headers |
| On-demand assets | `dio` | Chunked download, pause/resume, accurate progress |
| On-demand assets | `crypto` | MD5 / SHA-256 verification before mounting into an engine |
| On-demand assets | `archive` | Decompress assets (e.g. KataGo `.gz` weights) |
| Game rules | `chess` 0.8.1 (**decided 2026-10-02**, OB-002 Q3) | Chess rules, legal moves, FEN, undo. Wrapped by a rules adapter behind the OB-006 interface (see notes below) |
| Storage | `shared_preferences` ^2.5.5 (**decided 2026-10-03**, OB-008) | Small key-value settings (fair-play acknowledged version). Loaded once in `main()` and injected via `sharedPreferencesProvider` override; tests use `SharedPreferences.setMockInitialValues` |
| State | `flutter_riverpod` | Separate providers for Board State, Engine Search State, Download Progress State; clean caching/dispose when switching between the 6 games |
| UI | Bundled asset font (no `google_fonts`) | JetBrains Mono Regular/Bold in `assets/fonts/`, OFL registered in `LicenseRegistry` (OB-003) |
| UI | `flutter_svg` ^2.3.0 (OB-006) | Renders the bundled Cburnett piece pictograms (`assets/pieces/cburnett/`, Wikimedia Commons, triple-licensed GFDL/BSD/GPL, used under BSD; black outlines recolored; registered in `LicenseRegistry`; attribution also for OB-033) |
| UI | `flutter_animate` | Lightweight number/color transitions |
| Feedback | `services.HapticFeedback` (built-in) | `selectionClick` / `mediumImpact` / `heavyImpact` (no extra dependency; `flutter_vibrate` only if custom patterns are needed) |

### Rule checking for other games
- Chess: **`chess` 0.8.1** (PO decision 2026-10-02). Port of chess.js, single file (~1,735 lines), BSD-2-Clause/MIT, null-safe, min Dart 2.12, last release Oct 2023. Permissive license, not affected by OB-032; attribution on the licenses screen (OB-033).
  - Use: FIDE legal moves (verbose: from/to/flags/promotion), `in_checkmate`, `in_stalemate`, `insufficient_material`, `half_moves`, `undo()` (full state restore), `fen`, `load(fen)`.
  - **Do not use `in_draw` / `game_over`** (they treat the 50-move rule and threefold repetition as automatic draws). The game-end status is composed in our adapter: own repetition counter (en passant square counted only when an ep capture is legal), fivefold and 75-move rule (`half_moves >= 150`) automatic; threefold and 50-move as hints (OB-024).
  - The API is untyped/snake_case → no package types outside the rules module (OB-006). Implemented as `ChessPackageRules` (`lib/features/chess/data/`) behind `ChessRules` (`lib/features/chess/domain/`); it already keeps the repetition-key history and exposes `repetitionCount` / `halfmoveClock` for OB-024. Import the package with a prefix (`as lib`): its `Color` clashes with Flutter's.
  - Risks: unmaintained ~3 years; Dart 3.13.5 compatibility verified 2026-10-03; fallback if a future SDK breaks it = vendor the single file (license permits).
- Xiangqi and later games: rules modules still to be chosen in their phases.
- Xiangqi, Shogi, Gomoku, Othello: either a lightweight hand-written Dart rule module, or ask the engine through FFI. Note that UCI has no `islegal` command. With Fairy-Stockfish, legal moves can be listed with `go perft 1`; Edax needs its own approach. Prefer Dart rule modules so the tap board can dim illegal squares instantly without engine round-trips.

### Gotchas
- **`google_fonts` downloads fonts at runtime by default**, which breaks the 100% offline goal. Resolved in OB-003 by not using `google_fonts`: the font files are declared directly in `pubspec.yaml`.
- **iOS minimum is 15.0** with Flutter 3.47 (it migrates 13/14 targets to 15). The documented iOS 13.0+ cannot be met.

### Fairy-Stockfish native build (OB-004, 2026-10-03)
**Decision: Dart build hooks / native assets** (`hook/build.dart` + `native_toolchain_c` `CBuilder`), not hand-written Gradle CMake + Xcode targets.
- One Dart build script for Android and iOS; no Gradle/Xcode project edits; CMake not required on the dev machine.
- Bindings use `@Native` with `@DefaultAsset('package:spookymoove/fairy_stockfish')`, so no hard-coded `.so`/framework paths.
- iOS: bundled automatically as `fairy_stockfish.framework`. Android: `c++_static` so the `.so` is self-contained.
- Host builds (`flutter test` on macOS) skip the engine. Targets: Android arm64-v8a + x86_64, iOS arm64 (device + simulator). 32-bit Android is not built.
- `native_toolchain_c` is a labs.dart.dev (experimental) package; pin versions and expect API churn.

Setup:
- Source: git submodule `third_party/fairy-stockfish`, tag `fairy_sf_14_0_1_xq`, no upstream patches.
- Defines: `LARGEBOARDS`, `PRECOMPUTED_MAGICS`, `NNUE_EMBEDDING_OFF` (classical eval; no NNUE yet), `IS_64BIT`, `USE_POPCNT`, `USE_NEON` (arm64).
- C shim (`native/fairy_stockfish_shim/`): replaces `std::cin` / `std::cout` / `std::cerr` stream buffers with in-memory line queues; engine runs upstream `main` (renamed `fs_main`) on its own native thread.
- Dart (`lib/core/engine/fairy_stockfish/`): `FairyStockfishEngine` spawns one background isolate that owns all FFI calls; output lines arrive via `NativeCallable.listener` (no polling, no blocking reads).

Measured (2026-10-03):
- iOS release, arm64 `fairy_stockfish.framework`: **0.91 MB** uncompressed (913,840 bytes), ~0.39 MB gzip. Whole `Runner.app` 15 MB (Flutter.framework 10 MB, App.framework 3.8 MB).
- Android per-ABI sizes: **not yet measured**. Deferred to the final device pass (PO 2026-10-03: simulator-only until all tickets are done).
- OB-010 Xiangqi pass (2026-10-04): budget = store download size (PO). iOS `Runner.app` 19.5 MB, ≈ 9.7 MB zipped; Android arm64 APK 19.5 MB (native libs stored), ≈ 9.5 MB gzip (with the ghost app icon), `libfairy_stockfish.so` 1.6 MB. Both pass with ~20 MB headroom (estimates until App Store Connect / Play Console report). Benchmark harness: `integration_test/xiangqi_benchmark_test.dart`, `integration_test/xiangqi_input_cycle_test.dart`, `test_driver/perf_driver.dart` (commands in OB-010).
- iOS simulator: `uci`→`uciok`, `isready`→`readyok`; `go movetime 500` → `bestmove` in 500 ms; `stop` during `go infinite` → `bestmove` immediately; 61 frames during a 1 s search with 0 missed build/raster budgets.

Known limits:
- **One engine per process** (upstream globals). A second start returns `StateError`.
- **Restart after `quit` works**, but the upstream option counter is static, so a restarted engine's `uci` reply no longer lists `option` lines. `setoption` still works and values reset to defaults. OB-005 must not rely on the `option` list after a restart.
- **Native crashes are fatal**: C++ exceptions are surfaced as `FairyStockfishException` on the line stream, but a segfault or upstream `exit()` (e.g. hash allocation failure) terminates the app; in-process engines cannot isolate this.
- App backgrounding during a search is not handled yet (iOS may suspend the thread; the search resumes on foreground).

### Engine interface + UCI adapter (OB-005, 2026-10-03)
- `lib/core/engine/`: `GameEngine` (protocol-agnostic) → `UciEngine` (adapter) → `EngineTransport` (text lines; `FairyStockfishEngine` implements it, so an Android process transport can replace it per OB-032). Parser `uci/uci_parser.dart` is pure Dart and unit-tested.
- Defaults on start: `Threads 2`, `Hash 16` (`EngineConfig` rejects > 2 threads or hash outside 16–32 MB). `SearchLimits` rejects `movetime` > **900 ms**; optional depth cap; `multiPv` 1–500 (500 = score every legal move).
- Stale-result protection: a new search sends `stop` and cancels the old handle (`SearchCancelledException`); output is matched to searches by a FIFO of outstanding `go` commands, so a superseded search's output is never delivered.
- Multi-line result = deepest iteration complete for every line (OB-021 R3).
- Scores are from the **side to move**; conversion to the user's side is OB-022/OB-007.
- **UCCI not needed:** `UCI_Variant xiangqi` over plain UCI returns legal Xiangqi moves (verified against the engine's `go perft 1`; 44 legal moves at the start position). Moves use files `a`–`i`, ranks `1`–`10` (e.g. `b1c3`, `h10g8`).
- iOS simulator (2026-10-03): Chess startpos at the 900 ms cap → `e2e4`, depth 19, ~2.8M nps, 902 ms total; all-move search (MultiPV 500, depth 8) → 20/20 moves scored. Mid-range device timings pending (OB-010, final device pass).

### Package versions — verified on pub.dev (2026-10-02)
| Package | Proposed | Latest | Min Dart SDK | Notes |
|---------|----------|--------|--------------|-------|
| `flutter_riverpod` | ^2.5.1 | **3.4.3** | ^3.12.0 | Major bump (Riverpod 3). Use 3.x for a new project. |
| `ffi` | ^2.1.2 | 2.2.0 | 3.7 | |
| `path_provider` | ^2.1.3 | 2.1.6 | ^3.10.0 | |
| `path` | ^1.9.0 | 1.9.1 | ^3.4.0 | |
| `dio` | ^5.4.3+1 | 5.11.1 | 2.18 | |
| `crypto` | ^3.0.3 | 3.0.7 | ^3.4.0 | |
| `archive` | ^3.6.1 | **4.3.0** | 3.0 | Major bump; API changed from 3.x. |
| `chess` | ^0.8.1 | 0.8.1 | 2.12 | **Stale:** last release 2023-10. Works, but unmaintained. |
| `google_fonts` | ^6.2.1 | **9.0.0** | ^3.13.0 | Three majors ahead. |
| `flutter_animate` | ^4.5.0 | 4.5.2 | 2.17 | Last release 2024-11, stable. |
| `flutter_lints` | ^3.0.0 | **6.0.0** | ^3.8.0 | |
| `ffigen` | ^11.0.0 | **22.0.0** | 3.10 | Many majors ahead; config format changed. |
| `flutter_isolate` | — | 2.1.0 | 2.12 | Last release 2024-09. Optional. |
| `flutter_vibrate` | — | 1.4.0 | ^3.10.4 | Maintained (released 2026-01). Built-in `HapticFeedback` is still enough. |

Alternatives found while checking:
- **`dartchess` 0.14.0** (the Lichess team, released 2026-09): actively maintained chess rules with variants, but **GPL-3.0**. It has the same licensing question as Fairy-Stockfish. If the project goes GPL anyway, prefer it over the stale `chess` package.
- **Native assets / build hooks** (`hooks` 2.2.0, `code_assets` 2.1.0; `native_assets_cli` is discontinued): the current official way to compile and bundle C/C++ libs with a Flutter app. Evaluate it for building Fairy-Stockfish/KataGo/Edax instead of hand-written Gradle/Xcode setup.

Dev machine (2026-10-03): Flutter 3.47.6 stable, Dart 3.13.5, Android SDK 37, NDK 30.0.16248370, CMake 4.1.2, Xcode 27.0.

### Starter `pubspec.yaml` (reference)
The real `pubspec.yaml` was created in OB-003 (package `omni_board`, bundle/application ID `com.thuannguyen.omniboard`; renamed 2026-10-04 to package `cataland` / `com.cataland.app`, then to `ghost64` / `com.ghost64.app`, then to package `spookymoove`, ID `com.spookymoove.app`) with only `flutter_riverpod` + `flutter_lints`; add the packages below when their ticket starts. `google_fonts` is not used. Chess rules: `chess: ^0.8.1` (decided; the `dartchess` alternative in the comment is no longer considered for Chess).
```yaml
name: omnichess_advisor
description: Multi-board headless tactical game advisor.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.13.0

dependencies:
  flutter:
    sdk: flutter

  # --- Core & Architecture ---
  flutter_riverpod: ^3.4.3
  ffi: ^2.2.0
  path_provider: ^2.1.6
  path: ^1.9.1

  # --- Networking & File Transfer (Dynamic Download) ---
  dio: ^5.11.1
  crypto: ^3.0.7
  archive: ^4.3.0

  # --- Chess logic (headless board) ---
  chess: ^0.8.1          # or dartchess ^0.14.0 if GPL is acceptable

  # --- UI & Experience ---
  google_fonts: ^9.0.0
  flutter_animate: ^4.5.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  ffigen: ^22.0.0
```

## Non-functional requirements
### Performance and latency
- Engine response ≤ **1000 ms** in standard tactical positions on mid-range hardware (Snapdragon 7-series, Apple A12 Bionic or newer).
- Full user input cycle < **1.2 s** (binding working target; the UI consultation's 1.5 s still awaits PO sign-off).
- Every persona tier: suggestion ≤ 1000 ms, engine cap 900 ms, ≤ 2 threads, no extra download (OB-021 D14).
- UI thread stays at 60/120 FPS; all calculation, validation and stream parsing happens off the UI thread.

### Thermal and power
- Bounded searches: max **2 threads** per engine.
- Hash tables **16–32 MB** by default.

### Storage
- Base install ≤ **30 MB**.
- All 6 games plus models ≤ **140 MB**.

### Compatibility
- Android API 24+ (Android 7.0+).
- iOS 15.0+ (Flutter 3.47 minimum; originally specified 13.0+).

## Engine defaults to apply
- `Threads` ≤ 2, `Hash` 16–32 MB (or the equivalent option per engine).
- Use time/depth limits per move so the 1000 ms latency target is met.
