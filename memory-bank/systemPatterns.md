# System Patterns / Architecture

## Layered architecture
```text
┌────────────────────────────────────────────────────────────┐
│                    Flutter UI Layer                        │
│ (Legal-only Tap Board / Suggestion Card / Persona Row)     │
└──────────────┬──────────────────────────────▲──────────────┘
               │ (1) User Input               │ (6) Evaluation & Move
               ▼                              │
┌─────────────────────────────────────────────┴──────────────┐
│     Game Session, Rule Validation & Persona Selection      │
│ (Turn loop, legality, FEN/SGF/USI, history & undo, tiers)  │
└──────────────┬──────────────────────────────▲──────────────┘
               │ (2) Position String          │ (5) Search result(s)
               ▼                              │
┌─────────────────────────────────────────────┴──────────────┐
│                    Dart FFI Bridge                         │
│     (Background Isolate - UCI/GTP/USI text protocol)       │
└──────────────┬──────────────────────────────▲──────────────┘
               │ (3) Text lines in            │ (4) Text lines out
               ▼                              │
┌────────────────────────────────────────────────────────────┐
│      Native C/C++ Engines (in-process libraries, provisional)│
│  [ Fairy-Stockfish ]     [ KataGo ]      [ Edax / Yixin ]  │
└────────────────────────────────────────────────────────────┘
```

Data flow: tap on the board → rules module validates and updates the game state → on the user's turn, serialize the position (FEN / SGF / USI string) → FFI bridge on a background isolate sends text-protocol commands → native engine searches (multi-line for tiers 1–4, depth-capped for 5–7) → results parsed → persona tier picks the move (OB-022) → suggestion card + board highlight + haptics.

### Engine execution model (open decision — OB-032, counsel deferred)
- **Current development approach (provisional):** engines compiled **into the app as libraries**, driven over Dart FFI on a background isolate. Their stdin/stdout are replaced by in-process pipes or a small C shim (send/receive lines) (OB-004).
- **Separate executables over stdin/stdout pipes are infeasible on iOS:** iOS apps cannot spawn child processes, and `Process.start` is unavailable there. This replaces the original SAD's "executables / Standard I/O" description.
- The PO's compliance document asks for GPL engines to run as separate processes (IPC) for license separation. That is **feasible on Android only**; whether it is legally sufficient is for counsel (OB-032). Until decided, the engine interface stays **transport-agnostic** (OB-005), so an Android process transport could be swapped in.

### Layer responsibilities
- **UI layer:** tap board, suggestion card, persona row, status line with UNDO, haptics. Never does heavy work on the UI thread.
- **Game session & rules:** turn loop (OB-025), move legality, legal moves for the tap board, serialization (FEN, SGF, USI), move history and undo (OB-012), game-end detection (OB-024). One rules module per game, behind a rules interface. **Rules adapter pattern:** third-party rules code (Chess: `chess` package) is wrapped by an adapter that exposes typed moves and composes the game-end status itself (OB-006, OB-024). The session keeps its own position history, in sync with the library's `undo()`, for repetition counting and undo (OB-012).
- **Persona selection:** pure Dart; converts engine scores to the user's win chance and picks the move by tier (OB-021, OB-022). Suggestions are cached per (position, tier), so undo shows the same suggestion.
- **FFI bridge:** loads native libs (`.so` on Android, `.dylib`/framework on iOS), runs the engine text protocol (UCI / UCCI if needed / USI / GTP / Gomoku protocol / Edax text) on a dedicated isolate, streams and parses output.
- **Native engines:** C/C++ cores, bounded search (see NFRs in `techContext.md`).
- **Offline, no analytics:** no network calls except on-demand data packs (ODDAS); no tracking SDKs (OB-035 M-D2).

## Game → engine matrix
| Game | Distribution | Engine | Protocol | Footprint |
|------|--------------|--------|----------|-----------|
| Chess | Bundled | Fairy-Stockfish | UCI | Shared C++ binary (~12 MB) |
| Xiangqi | Bundled | Fairy-Stockfish | UCI (`UCI_Variant xiangqi`; UCCI not needed, OB-005) | Reuses binary (0 MB delta) |
| Shogi | On-demand | Fairy-Stockfish | USI | Shared binary + `shogi.nnue` (~20 MB) |
| Gomoku / Caro | On-demand | Yixin / custom C++ | Gomoku protocol | Binary + opening DB (~2 MB) |
| Othello | On-demand | Edax 4.4 | GGS / custom text | Binary + book (~3 MB) |
| Go / Weiqi | On-demand | KataGo (OpenCL/CPU) | GTP | Binary (~10 MB) + weights (~40 MB) |

Pattern: a shared engine abstraction (start, set options, set position, go with limits incl. multi-line and depth caps, stop, parse result) with one protocol adapter per protocol family, so the UI and state layers stay game-agnostic (OB-005). Games and tiers offered are listed as data in one place, with no scattered hard-coded checks, so future gating stays cheap (OB-035 guardrail).

Licenses: Fairy-Stockfish and Edax are GPLv3; KataGo is MIT; Yixin is not open source (needs permission). See OB-002 / OB-032.

## On-Demand Dynamic Asset Subsystem (ODDAS)
**Asset splitting strategy:**
- **Binaries ship in the app.** Apple forbids running downloaded machine code, so KataGo, Edax, Yixin etc. are compiled into the app (or as conditional sub-frameworks) at build time.
- Monetization is deferred, so there is no download gating; every pack is available (OB-035).
- **Only data is downloaded:** NN weights (`.bin.gz`), NNUE files (`.nnue`), opening books (`.dat`), hosted on a CDN (AWS S3 / Cloudflare R2).
- Downloaded with `Dio` (HTTP chunked/segmented, pause/resume) into `getApplicationDocumentsDirectory`, then verified against a remote config manifest.

**Asset lifecycle state machine:**
```text
UNINSTALLED → FETCHING → VERIFYING → MOUNTED → PURGEABLE
                 ↑ (pause/resume)      │ (checksum fail → retry / UNINSTALLED)
```
- `UNINSTALLED`: no asset index in local document storage.
- `FETCHING`: segmented download with pause/resume; emits percent done and ETA.
- `VERIFYING`: MD5/SHA-256 checked against the remote manifest.
- `MOUNTED`: validated; file path is passed to the engine's launch parameters.
- `PURGEABLE`: the user can delete the pack from storage settings at any time.

## Concurrency pattern
- Engine I/O, move validation and output parsing all run on background isolates / worker threads.
- The UI thread only renders and handles input; it must hold 60/120 FPS.
