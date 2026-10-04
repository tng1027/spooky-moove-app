# Project Brief — SpookyMoove (formerly OmniChess Advisor)

Source: BRD + SAD v1 (provided 2026-10-02), updated with PO decisions of 2026-10-02 (tickets in `tickets/`, index `tickets/README.md`). This file is the foundation; all other memory-bank files derive from it.

## What it is
An **offline tactical training companion** mobile app for people playing on a **physical board**. The user mirrors each move on a minimal **legal-only tap board** (2 taps: options, then pick; OB-006, OB-048), and on their turn receives a suggested move plus an evaluation. The suggestion is shaped by a chosen **7-tier persona** (from deliberately weak to full strength; OB-021). Store positioning: "Family Companion & Training Assistant" (OB-034); final app name pending.

## Supported games
| # | Game | Distribution |
|---|------|--------------|
| 1 | Chess | Bundled (default) |
| 2 | Xiangqi / Chinese Chess | Bundled (default) |
| 3 | Gomoku / Caro | On-demand download |
| 4 | Shogi / Japanese Chess | On-demand download |
| 5 | Othello / Reversi | On-demand download |
| 6 | Go / Weiqi | On-demand download |

## Milestones
- **Milestone 1 = Chess + Xiangqi** (bundled) + fair-play notice + persona tiers. Delivered per game: Phase 0 shared foundation → Phase 1 Chess → Phase 2 Xiangqi (`tickets/README.md`).
- Post-M1: ODDAS, then Shogi, Gomoku/Caro, Othello, Go. **The 7-tier persona is mandatory for every game** (OB-021 D13).

## Core goals
- Sub-second move entry (full input cycle < 1.2 s) with minimal eye contact away from the board.
- 100% offline gameplay: no server dependency, no network latency, full privacy. **No analytics or tracking** (OB-035 M-D2).
- Lean install: base app ≤ 30 MB (Chess + Xiangqi); everything fully downloaded ≤ 140 MB.
- Grandmaster-grade analysis via proven C/C++ engines: Fairy-Stockfish, KataGo, Edax, Yixin.
- One unified app instead of several per-game apps.
- Usable **without chess-notation knowledge** (no piece letters, SAN, `O-O`, `e.p.`; OB-006/OB-007).

## Business model
- **Full-feature version first; monetization deferred** (PO 2026-10-02, OB-035 M-D1): every game and tier is available to everyone.
- Planned for later (not decided in detail): freemium with Pro; Xiangqi, Go, Shogi and Othello as Pro (OB-035 M-D3).

## Audience
- Target audience: **adults** (parents/players operate the phone; children play on the physical board). Not Apple Kids Category / not Google Play Families. Lowest content rating (4+ / Everyone). Parental gate before purchases and external links. **No personal data collected** (OB-040, PO delegated to BA recommendation). Legal obligations still to be confirmed by counsel (deferred).

## Hard constraints
- Flutter (Dart) client, engines on background isolates. Current development approach: engines **in-process over Dart FFI** (OB-004), final under the GPLv3 decision (OB-002, 2026-10-04).
- Android API 24+ (7.0+), iOS 13.0+.
- Apple rule: no downloaded executable code. Only **data** (NNUE, NN weights, opening books) is downloaded; engine binaries ship in the app. iOS apps cannot spawn child processes.
- Fair-play: a one-time notice forbidding use in rated/sanctioned/tournament play without arbiter permission (FIDE, EGF, Nihon Ki-in, etc.) (OB-008).
- **Licensing:** the app is GPLv3 open source (PO 2026-10-04, OB-002). Release blocker until counsel confirms GPLv3 store distribution and compliance (OB-032).
