# Ticket Analysis

TICKET_TYPE: NEEDS_CLARIFICATION
STATUS: RESOLVED (2026-10-02) — no longer blocking
CONFIDENCE: HIGH

All open questions are answered. Product-level decisions came from the PO (D1–D6). The PO delegated the remaining persona questions to the BA recommendation (D7–D14). The 7 tiers are now defined precisely in the "Final tier definition" section below. OB-022 and OB-023 are unblocked. This ticket is kept as the decision record.

## Ticket Title
[Clarification] Define the purpose and per-tier move-selection rules of the 7-tier persona system

## Summary
Decision record for the "7-Tier Persona Engine" (🥚 Baby, 🐣 Gentle, 🐥 Soft, 🥉 Even, 🥈 Solid, 🥇 Master, 👑 God). It covers the product purpose, milestone, default/mid-game behavior, design language, and an engine-agnostic definition of every tier.

## Business Context
- PO requirement (2026-10-02): cover everything from letting a 3–4-year-old win to beating an international master.
- Confirmed as a **handicap advisor**: the persona changes the move suggested to the user. This fits the allowed uses "handicap analysis" and "offline recreational games" (`productContext.md`, OB-008).

## Decisions

### Source: PO answer 2026-10-02
| # | Decision |
|---|----------|
| D1 | **Interpretation A.** The persona changes only the move **suggested to the user**. The app never plays as an opponent. A "resign" suggestion is not applicable: when the user's side has no legal moves, the game-end state (OB-001 Q5) is shown. |
| D2 | The persona system is part of Milestone 1 and applies to all games (scoped by D13). |
| D3 | Every game has the same 7 tiers. |
| D4 | Strong tiers think "as fast as possible" (made concrete by D14). |
| D5 | ~~**No default tier.** The user must pick a tier when starting a game.~~ **Revised by the PO on 2026-10-03: the default tier is Even** (OB-011 revision). The tier **can be changed mid-game**. |
| D6 | The selector follows the existing design language (`designSystem.md`). |

### Source: PO delegated to BA recommendation, 2026-10-02
| # | Question | Decision |
|---|----------|----------|
| D7 | Q2 — Evaluation semantics | Tiers are defined on **win chance (WC)**: the user's estimated chance of winning, 0–100 %, always **from the user's side** (the side the suggestion is for). **Loss** = WC(best move) − WC(candidate move), in percentage points (pp). 🥚, 🐣 and 🐥 use **loss vs. best**. 🥉 Even uses the **absolute WC** of the resulting position, because its intent is balance. |
| D8 | Q1/Q8 — Gentle, Soft, Even rules | **Neither the spec table nor the sample code** is used literally. Each tier is a WC/loss band (see the tier table) calibrated from the spec's pawn values: Gentle −1.0…−2.5 pawns ≈ 9–22 pp; Even ±0.3 pawn ≈ 47–53 % WC. Stockfish-only "Skill Level" and "always 2nd-best" are dropped. Skill Level doesn't exist in KataGo or Edax. "2nd-best" can be as good as the best move or a blunder depending on the position. "Skip all captures" is dropped: it is not engine-agnostic (Othello flips on every move), and the loss band already produces quiet concessions. |
| D9 | Q3 — Fallback | If no candidate falls in a tier's band, suggest the candidate **closest to the band** (smallest distance to the nearest band edge). On a tie, choose the one with the **smaller loss** (the stronger move). |
| D10 | Even when the user is behind | Follows from D9: if every move leaves WC < 47 %, the closest one to the band is the best move, so Even plays **full strength** until the game is balanced again. If every move leaves WC > 53 %, Even suggests the move that gives back the most advantage while staying closest to 53 %. |
| D11 | Q4 — Non-centipawn engines | The same WC-based rules for every game. Each engine only needs a **WC conversion** and a **candidate set** (see "Engine mapping"). No tier logic is engine-specific. |
| D12 | Q5 — Card evaluation for weak tiers | The card shows the evaluation of the **suggested move only**, from the **user's side** (+ = good for the user), in the engine's native unit (pawns / mate for Fairy-Stockfish; native units for later engines per their tickets). The best move and its evaluation are not shown in weak tiers. |
| D13 | Q6 — Assumption A1 confirmed | Milestone 1 delivers the persona for **Chess and Xiangqi**. Supporting all 7 tiers per this ticket is a **mandatory acceptance requirement for every later game** (OB-016 Shogi, OB-017 Gomoku/Caro, OB-018 Othello, OB-019 Go). Milestone 1 is not expanded to the on-demand games. |
| D14 | Q7 — Assumption A2 confirmed | Every tier stays within the existing budget: suggestion shown ≤ 1000 ms after the move is accepted (engine search time cap **900 ms**, leaving margin), ≤ 2 threads, 16–32 MB hash, **no extra network/NNUE download**. Strength differences come from move selection and search-effort caps, not from longer thinking. |

## Final tier definition

Terms:
- **Candidate set:** the moves evaluated for selection (see "Engine mapping"). For Chess and Xiangqi: **all legal moves**.
- **WC(m):** the user's win chance after move m. **Best** = the candidate with the highest WC. **Loss(m)** = WC(best) − WC(m).
- **Random pick:** uniform random choice among the qualifying moves. The RNG is injectable/seedable for tests.
- **Stability:** while the position and tier are unchanged, the same suggestion stays displayed. No re-roll on redraw or resume.

| Tier | Search (Fairy-Stockfish, M1) | Selection rule | Fallback / tie-break |
|------|------------------------------|----------------|----------------------|
| 🥚 1 Baby | All-move evaluation | Random pick among moves with Loss ≥ Lmax − 3 pp (Lmax = the largest loss among candidates) | Tie-break: if any qualifying move allows a forced mate against the user, pick the one with the **shortest** mate |
| 🐣 2 Gentle | All-move evaluation | Random pick among moves with **9 ≤ Loss ≤ 22 pp** | D9 |
| 🐥 3 Soft | All-move evaluation | Random pick among moves with **3 ≤ Loss < 9 pp** | D9 |
| 🥉 4 Even | All-move evaluation | Random pick among moves with resulting **47 ≤ WC ≤ 53 %** | D9 (→ best move when the user is behind; D10) |
| 🥈 5 Solid | Single best line, depth cap **12** | Best move | — |
| 🥇 6 Master | Single best line, depth cap **18** | Best move | — |
| 👑 7 God | Single best line, no depth cap (full 900 ms) | Best move (engine prefers the shortest mate) | — |

Common rules (all tiers):
- R1: Exactly one legal move → suggest it.
- R2: No legal moves → game-end state, no suggestion (D1).
- R3: **All-move evaluation** (tiers 1–4) = one search that scores every candidate. Target depth **8**, hard time cap 900 ms. If the cap is hit, use the deepest iteration completed for all candidates. WC(best) comes from the same search, so losses are consistent.
- R4: Every tier's engine time ≤ 900 ms; ≤ 2 threads; hash 16–32 MB (D14).
- R5: Mate scores map to WC = 100 % (user mates) or 0 % (user is mated). Ordering among mates: a shorter mate for the user is better; a shorter mate against the user is worse.
- R6: Tier changed mid-game → discard any running computation and recompute for the current position with the new tier (D5).
- R7: Depth targets/caps (8, 12, 18) and band edges are **tunable constants**. OB-010 may adjust the depths so that R4 holds on reference devices; band edges change only with PO approval.

## Engine mapping (WC conversion and candidate set)
| Game / engine | WC conversion | Candidate set | Effort cap (Solid / Master / God) |
|---------------|---------------|---------------|------------------------------------|
| Chess, Xiangqi, Shogi — Fairy-Stockfish | WC = 100 / (1 + e^(−0.00368208 × cp)), cp from the user's side (Lichess win-chance model) | All legal moves | Depth 12 / 18 / uncapped |
| Go — KataGo | Engine root winrate × 100 (user's side) | Candidate set defined in OB-019/OB-020. It must include the engine's top candidates **and** enough other legal moves to populate every band within the 900 ms cap | Visit caps defined in OB-020 (Solid < Master < God = full budget) |
| Othello — Edax | WC = 100 / (1 + e^(−d / s)), d = predicted disc difference (user's side), s calibrated in OB-018 | All legal moves | Depth caps defined in OB-018 |
| Gomoku/Caro — engine per OB-017 | Engine winrate if provided, else a logistic of its score calibrated in OB-017 | All legal moves if feasible within 900 ms, else as for Go | Defined in OB-017 |

Note on calibration: the 0.00368208 constant is calibrated for Chess. It is used initially for Xiangqi and Shogi as well; OB-010 may recalibrate it per variant (engineering tuning, no PO decision needed).

## Current Behavior
Nothing implemented. Planned (OB-005/OB-007): the best move under a bounded search.

## Expected Behavior
OB-022 implements the tier definition above; OB-023 provides the selector; OB-007 displays per D12.

## Business Rules
- BR-001: The persona affects only the move suggested to the user (D1).
- BR-002: The same 7 tiers, same rules, for every game (D3, D11).
- BR-003: No default tier; chosen at game start; changeable mid-game with immediate recompute (D5, R6).
- BR-004: All tiers within ≤ 1000 ms / ≤ 2 threads / no extra download (D14).
- BR-005: Selection rules exactly as in "Final tier definition".

## User Flow
```text
User picks a game → picks a tier (required)
↓
Opponent moves on the board → user enters it
↓
Engine evaluates (all moves for tiers 1–4, best line for tiers 5–7) → tier rule picks one legal move
↓
Card shows the move and its evaluation from the user's side (D12)
↓
User changes tier → recompute for the same position (R6)
```

## Acceptance Criteria
- Given this ticket, When OB-022 is reviewed, Then every tier has one testable rule, band, fallback and search limit, with no table vs. code conflict.
- Given D13, When later game tickets (OB-016–OB-019) are written, Then each includes "supports all 7 tiers per OB-021" in its acceptance criteria, with its WC conversion and candidate set.
- Given the decisions, When the PO reviews this ticket, Then each decision is traceable to its source (PO answer, or PO delegated to BA recommendation).

## Edge Cases
Covered by the rules: one legal move (R1), no legal moves (R2), lopsided positions (D9/D10), mates (R5, Baby tie-break), tier change during a search (R6), latency cap hit (R3).

## In Scope
- Decision record and tier definition.

## Out of Scope
- Implementation (OB-022, OB-023).
- Opponent/bot mode (excluded by D1).

## Dependencies
- OB-022, OB-023, OB-007, OB-010 consume these decisions.
- Revision (2026-10-02, PO principle "usable without chess knowledge"): D12's display unit is revised. The card's primary evaluation is the user's **win chance** (`WIN 62%`; mates as `YOU MATE IN n` / `OPPONENT MATES IN n`). The native evaluation (`EVAL +1.4`) moves to the small secondary line. D12's core rule (evaluation of the suggested move, from the user's side) is unchanged. See OB-007.
- OB-016–OB-020: engine-specific mapping per the table above.
- Note (PO compliance document, 2026-10-02): tier **semantics are unchanged**. The PO adds commercial access: Soft/Even/Solid free; Baby/Gentle/Master/God Pro-only (**OB-037**). D5 (no default tier) still holds: free users must pick a free tier. Paywall copy for God must respect D14 (≤ 1000 ms, 2 threads): "maximum depth" claims are inaccurate (OB-035 Q14). The tier name "God"/"Hủy diệt tuyệt đối" is reviewed in **OB-034**.
- Update (PO 2026-10-02): monetization deferred (OB-035 M-D1). **All 7 tiers are free and available** in the full-feature build; tier gating (OB-037) is deferred. Tier names unchanged until OB-034 is resumed.

## Assumptions
- The Lichess win-chance model is an adequate initial WC conversion for Fairy-Stockfish centipawns (tunable, R7).
- A target depth of 8 for all-move evaluation is achievable for typical Chess/Xiangqi positions within 900 ms on reference devices with 2 threads (validated in OB-010; if not, the depth is lowered per R3/R7).

## Open Questions
None blocking. Non-blocking:
1. After playtesting, the PO may want to tune band edges (e.g. make Gentle gentler). Changes require PO approval (R7).

## Developer Handoff
- Implement the tier logic once, against "candidates with WC" — never against engine-specific scores.
- Fairy-Stockfish: tiers 1–4 = one multi-line search covering every legal move (depth target 8, 900 ms cap); tiers 5–7 = single-line search with depth caps 12 / 18 / none.
- Keep constants (bands, depths, conversion slope) in one place; inject the RNG.
