# Ticket Analysis

> **Status: RESOLVED for Chess (2026-10-02).** Every Chess question is answered (explicit decisions or accepted assumptions; see "Resolution summary" under Dependencies). Still open, neither blocks the Chess slice: **Q6** (resume after app kill; not in the Chess DoD) and **Q10** (Xiangqi notation; needed for Phase 2).
>
> **Q10 — RESOLVED (PO 2026-10-03, XQ4; proposed by BA + Designer):** input needs no notation (intersection tap board, OB-044). Output main line in **absolute coordinates** in Red's frame, files `A`–`I`, ranks `1`–`10`, with the moving piece's disc and `✕` for captures (e.g. `[炮] H3 ➔ E3`). **WXF only in the expert line**, from the mover's side (e.g. `C2.5 · EVAL +0.3 | …`). Recorded as a decision in OB-046. Only Q6 (resume after app kill) remains open.
>
> **Status: RESOLVED (PO 2026-10-04).** Q6 → **no resume in M1**: after the app is killed, it always opens at Home. Q3 (standard initial position only) and Q5 (automatic draws, draw hint, no resign / draw-offer buttons) confirmed by the PO as decisions. No open questions remain.

TICKET_TYPE: NEEDS_CLARIFICATION
CONFIDENCE: HIGH

The memory bank describes how a *single* move is entered (two-tap keypad) and how a *single* suggestion is shown (suggestion card), but not the game session around them: which side the user plays, whether the user's own move must also be entered, where a game starts from, how mistakes are corrected, and what happens at game end. These decisions directly determine the keypad, the rules module, and the acceptance criteria of OB-006, OB-007, OB-009 and OB-011/OB-012. They cannot be derived from the codebase (there is none) and must not be invented.

## Ticket Title
[Clarification] Define the core advisor session flow and move notation for Chess and Xiangqi

## Summary
Get product decisions on the end-to-end session loop (setup → opponent move → suggestion → user's own move → … → game end) and on the move notation shown/entered for Chess and Xiangqi, so that the Milestone 1 feature tickets can be finalized.

## Business Context
The core value is "enter the opponent's move, instantly get the best reply" while playing on a physical board (`projectbrief.md`, `productContext.md`). The physical board and the app state must stay in sync for every suggestion to be correct. Any desync (the user played a different move than suggested, a mis-tap, a takeback on the board) silently produces wrong advice. The session rules are therefore business-critical, not a UI detail.

## Current Behavior
Nothing is implemented (repository contains only `memory-bank/` and `.cursor/`).

Documented today:
- The user enters the **opponent's** move and receives the engine's best move (`projectbrief.md`).
- Two-tap entry: Tap 1 = source column + row, Tap 2 = legal destination (`productContext.md`).
- The rules layer owns "History Undo" (`systemPatterns.md`), but no undo UX is described.
- Suggestion examples: Chess `E7 ➔ E5`, Xiangqi `P2 ➔ 5` (`productContext.md`).

## Expected Behavior
A documented, PO-approved session flow and notation decision (answers to the Open Questions below), added to the memory bank (`productContext.md`) by the PO/BA, after which OB-006, OB-007, OB-009, OB-011 and OB-012 can be marked ready.

## Business Rules
No new business rules are defined by this ticket. Rules will be derived from the answers.

## User Flow
Partially known flow (gaps marked `?`):

```text
Open app → (? choose game) → (? choose side / who moves first) → (? start position)
↓
[If user moves first ?] → app shows suggestion immediately ?
↓
Opponent moves on physical board → user enters opponent's move (two-tap) → suggestion shown
↓
User plays a move on the physical board → (? user must enter own move / app assumes suggestion was played)
↓
Repeat → (? game end detection and display)
```

## Acceptance Criteria
- Given the open questions in this ticket, When the PO reviews them, Then each question has a written decision (or an explicit "out of Milestone 1") recorded in `productContext.md`.
- Given the decisions are recorded, When OB-006, OB-007, OB-009, OB-011 and OB-012 are re-reviewed, Then none of them still contains a blocking open question about session flow or notation.

## Edge Cases
Edge cases the decisions must cover:
- The user plays a move different from the suggestion.
- The user mis-taps and enters a wrong opponent move.
- A takeback happens on the physical board.
- The user starts the app mid-game (position is not the initial position).
- The user plays the side that moves first (no opponent move to enter yet).
- Checkmate, stalemate, draw (repetition, 50-move rule, insufficient material), Xiangqi perpetual check/chase rules.
- Chess pawn promotion (two-tap flow doesn't cover piece choice; only Shogi promotion is described).
- App backgrounded/killed mid-game.

## In Scope
- Decisions on the questions listed below for Chess and Xiangqi (Milestone 1).

## Out of Scope
- Session flow for Shogi, Gomoku/Caro, Othello and Go (they will need their own clarification; see OB-017 and OB-019).
- UI visual design (covered by `designSystem.md`).
- Implementation.

## Dependencies
- PO availability.
- None technical.
- Related (added 2026-10-02): OB-021 (persona system). Its Q1 — whether the persona shapes the move suggested to the user or the app plays as the opponent — directly affects Q1 (side selection) and Q2 (user's own move) here; answer them together.
- Update (PO answer 2026-10-02, recorded in OB-021): the persona changes only the move **suggested to the user** — the app never plays as an opponent, so the core loop here is unchanged. Starting a game now also requires choosing a persona tier (no default), and the tier can change mid-game. Q11 (evaluation perspective) is shared with OB-021 Q2.
- Update (OB-021 resolved 2026-10-02): Q11 is answered. Evaluations are shown from the **user's side** (+ = good for the user) (OB-021 D7/D12). The remaining questions here are unaffected.
- Note (per-game plan, 2026-10-02): Chess-phase tickets carry labelled proposed assumptions for the open questions, so the PO can simply confirm them: Q1/Q3 → OB-011 A1/A2 (user picks the side; initial position only); Q2 → OB-025 A1 (user enters every move); Q5 → OB-024 A1–A3 (automatic FIDE draws; claimable draws as a hint; no resign buttons); Q8 → OB-006 note (`[Q] [R] [B] [N]` prompt).
- **Resolved (PO answer 2026-10-02):**
  - **Q7 → resolved** (PO: "fewest taps possible", delegated to the BA): legal-only **tap board** with smart 1–2-tap entry (OB-006). Design change to the memory bank (on-screen board).
  - **Q8 → resolved** (PO: users may have no chess knowledge; letter keys not acceptable): promotion via a **4-pictogram chooser**, queen first (OB-006). **New product principle:** input and output must be usable without chess-notation knowledge — no piece letters, SAN, `O-O`, `e.p.`.
  - **Q9 → resolved** (PO: "toạ độ"): coordinate display `E7 ➔ E5`, with the special-move format in OB-007.
  - Q11 resolved earlier (user's side).
  - ~~Still open: Q1/Q3, Q2, Q4, Q5, Q6, Q10~~ → superseded by the summary below.
- **Resolution summary (PO answers 2026-10-02):**

  | Q | Outcome | Kind | Where |
  |---|---------|------|-------|
  | Q1 | The user picks **exactly one side** per game (White/Black); suggestions only for that side | **Decision** (PO: "ng dùng chỉ chọn 1 phe") | OB-011 |
  | Q2 | ~~The user enters **every** move, including their own~~ → **Option b** (2026-10-03): one-tap "✓ I PLAYED IT" confirms the suggestion; any other move is entered on the board as an override | **Decision** (PO 2026-10-03, replaces the accepted assumption) | OB-041 (revises OB-025 A1) |
  | Q3 | Standard initial position only | **Decision** (PO confirmed 2026-10-04) | OB-011 A2 |
  | Q4 | **One-step undo is in the Chess DoD** (one move per tap) | **Decision** (PO: "đúng") | OB-012 |
  | Q5 | Automatic FIDE draws, plain-language claimable-draw hint, no resign/draw-offer buttons | **Decision** (PO confirmed 2026-10-04) | OB-024 A1–A3 |
  | Q6 | No resume after app kill in M1; the app always opens at Home | **Decision** (PO 2026-10-04) | — |
  | Q7 | Legal-only tap board, smart 1–2-tap entry; replaces "no on-screen board" | **Decision** (memory bank updated) | OB-006 |
  | Q8 | Pictogram promotion; no-chess-knowledge principle | **Decision** | OB-006 |
  | Q9 | Coordinate notation `E7 ➔ E5` | **Decision** | OB-007 |
  | Q10 | Xiangqi notation: absolute `A`–`I` / `1`–`10` + piece disc; WXF only in the expert line | **Decision** (PO 2026-10-03, XQ4) | OB-046 (epic OB-009) |
  | Q11 | Evaluation from the user's side | **Decision** | OB-021 D12 |

  "Accepted assumptions" are not explicit PO decisions; they stand unless the PO revisits them.

## Assumptions
- Milestone 1 = Chess + Xiangqi (bundled) + fair-play notice, per `activeContext.md` "Next steps" 0–4 and 6.

## Open Questions
**Session**
1. **Side selection:** Does the user tell the app which side they play (White/Black, Red/Black)? If the user plays first, should a suggestion be shown before any input?
2. **User's own move:** After a suggestion, does the user (a) always enter their own move, (b) confirm "played suggestion" with one tap, or (c) the app assumes the suggestion was played? This changes the input count per turn significantly.
3. **Starting position:** Initial position only for Milestone 1, or also set-up from an arbitrary position (e.g. FEN paste or piece-by-piece entry)?
4. **Undo:** Is undo of the last entered move required in Milestone 1? One step or unlimited? (Rules layer mentions "History Undo".)
5. **Game end:** What should the app display on checkmate / stalemate / draw? Should it detect draw by repetition and the 50-move rule, or only mate/stalemate?
6. **Session persistence:** If the app is killed mid-game, must the game resume on relaunch?
7. **Two-tap wording:** Tap 1 is described as "source column + row" (e.g. `E`, `2`) — that is two key presses, plus one for the destination. Is a 3-press flow acceptable, or must source selection be a single press (e.g. a list of movable pieces/squares)?
8. **Chess promotion:** How is the promotion piece chosen (prompt with Q/R/B/N, or auto-queen with an override)?

**Notation**
9. **Chess output notation:** Coordinate (`E7 ➔ E5`) as shown in the docs, or SAN (`e5`, `Nf3`)? Uppercase files as in the example?
10. **Xiangqi notation:** Input uses column + row coordinates, but the output example `P2 ➔ 5` is WXF-style (and incomplete — WXF would be `P2+5` / `P2.5`). Which notation is used for input and for output? Are files numbered from each player's own side (traditional, 1–9 right-to-left) or absolute (`a`–`i`, rows `0`–`9`)?
11. **Evaluation perspective:** Is `+1.4` from White's/Red's perspective or from the user's perspective?

## Developer Handoff
No implementation work. Developers can start OB-003, OB-004 and OB-005 in parallel because they do not depend on these answers. OB-006 onward should not be finalized until this ticket is resolved.
