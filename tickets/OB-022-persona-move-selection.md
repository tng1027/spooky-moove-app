# Ticket Analysis

> **Status: Done on iOS simulator (2026-10-03), including the Chess screen wiring.** Gating until a tier is chosen, recompute on tier change, stale-result drop and card display are in OB-007's `SuggestionController` (`gameEngineProvider` + `personaSuggesterProvider`); OB-025 adds the turn status and covers the screen-level acceptance criteria (tier change on the opponent's turn applies to the next suggestion; switching back to a tier shows the same cached move; no search after the game ends). Xiangqi wiring comes with OB-009; reference-device latency with OB-010.
> - Pure Dart under `lib/features/persona/domain/`: `PersonaTier` (7 tiers, the single tier list), `PersonaConfig` (slope, bands, depths, 900 ms cap — REQ-015), `winChance()` (REQ-003), `selectMove()` (Baby band + mate tie-break, Gentle/Soft/Even bands + REQ-009 fallback, best move for tiers 5–7, single move for every tier).
> - `PersonaSuggester` (`lib/features/persona/application/`): tier search limits (tiers 1–4 MultiPV = legal-move count, depth 8; tiers 5–7 MultiPV 1, depth 12 / 18 / none; all 900 ms), engine lines → candidates (user-side scores), suggestion with score, WC, depth, nps (REQ-014). Cache per (position, tier) for stability (REQ-013, also covers OB-012's same suggestion after undo); `clearCache()` on new game. A superseded call fails with `SearchCancelledException`; a superseding cache hit stops the running search and its truncated result is not cached (REQ-012 engine side). 0 legal moves → null (REQ-011). No scored line → `EngineFailureException` (OB-007 error state).
> - Riverpod wiring: `personaSuggesterProvider` over `gameEngineProvider` (OB-007); "no tier → no request" (REQ-002) is enforced in `SuggestionController`, the single request path.
> - Tests: 29 unit tests (every tier acceptance case with seeded RNGs, WC conversion, suggester with a fake engine). Simulator integration test 3/3: Chess start position, all 7 tiers legal and ≤ 900 ms (tiers 1–4 depth 8 in ≤ 76 ms; Master/God hit the 900 ms cap at depth 17/18); Baby scores all 20 moves; Xiangqi Baby (44 moves, 311 ms) and God legal. Reference-device latency deferred to OB-010.

TICKET_TYPE: NEW_FEATURE
CONFIDENCE: HIGH

New capability: today the product only defines a best-move suggestion. Confidence is HIGH because every rule is now decided (OB-021 D1–D14, "Final tier definition"). The product purpose, default, mid-game behavior, per-tier bands, fallback, evaluation semantics, latency budget and milestone scope are all recorded. Only tunable constants remain (R7), which are validated in OB-010.

## Ticket Title
[Feature] Suggest the move chosen by the active persona tier (7 tiers, Milestone 1: Chess and Xiangqi)

## Summary
Every suggestion is chosen by the active persona tier — from 🥚 Baby (deliberately among the worst legal moves) to 👑 God (strongest move within the budget) — using one engine-agnostic metric: the user's win chance (WC). Suggestions are gated until a tier is chosen, and recomputed immediately when the tier changes.

## Business Context
- PO requirement "7-Tier Persona Engine" (2026-10-02); handicap advisor (OB-021 D1).
- Milestone 1 for Chess + Xiangqi; mandatory for every later game (OB-021 D13).
- Reuses the engine interface (OB-005) and suggestion card (OB-007).

## Current Behavior
Nothing implemented. Planned (OB-005/OB-007): best move under a ≤ 1000 ms bounded search.

## Expected Behavior
- No suggestion until a tier is chosen for the current game.
- Tiers 1–4 evaluate all legal moves in one search, then select by loss/WC band. Tiers 5–7 search the best line with increasing effort caps.
- The suggestion is always legal, always within the latency budget, and stable while position and tier are unchanged.
- A tier change recomputes the suggestion for the current position.

## User Story
As a parent playing a physical game against a young child
I want the app to suggest deliberately weaker moves at a level I choose
So that the child has real chances to win and enjoys the game.

As a club player
I want to choose how strong the suggested moves are
So that I can play anything from a balanced game to full-strength analysis.

## Functional Requirements
Definitions (OB-021): WC(m) = the user's win chance after move m (0–100 %, user's side). Best = the candidate with max WC. Loss(m) = WC(best) − WC(m) in pp. Random pick = uniform among qualifying moves (injectable RNG).

- REQ-001: Support 7 tiers, identical for every game: 🥚 Baby (1), 🐣 Gentle (2), 🐥 Soft (3), 🥉 Even (4), 🥈 Solid (5), 🥇 Master (6), 👑 God (7).
- REQ-002: No suggestion is computed or shown while no tier is selected for the current game.
- REQ-003: Convert Fairy-Stockfish scores to WC: WC = 100 / (1 + e^(−0.00368208 × cp)), cp from the user's side. Mate for the user = 100; mated = 0.
- REQ-004: Tiers 1–4 use all-move evaluation: every legal move is scored in one search (target depth 8, hard cap 900 ms). If the cap is hit, use the deepest iteration completed for all moves.
- REQ-005: 🥚 Baby: random pick among moves with Loss ≥ Lmax − 3 pp. Tie-break: if any qualifying move allows a forced mate against the user, pick the one with the shortest such mate.
- REQ-006: 🐣 Gentle: random pick among moves with 9 ≤ Loss ≤ 22 pp.
- REQ-007: 🐥 Soft: random pick among moves with 3 ≤ Loss < 9 pp.
- REQ-008: 🥉 Even: random pick among moves with resulting 47 ≤ WC ≤ 53 %.
- REQ-009: Fallback for tiers 2–4: if no move qualifies, pick the move closest to the band (smallest distance to the nearest edge). On a tie, pick the one with the smaller loss.
- REQ-010: 🥈 Solid / 🥇 Master / 👑 God: the best move of a single-line search with depth cap 12 / 18 / none, all within the 900 ms cap.
- REQ-011: Exactly one legal move → suggest it (all tiers). No legal moves → game-end state, no suggestion.
- REQ-012: Tier change mid-game → discard any running computation; recompute for the current position with the new tier.
- REQ-013: While the position and tier are unchanged, the displayed suggestion stays the same (no re-roll on redraw or resume).
- REQ-014: Expose the suggested move's evaluation (user's side) to the card (OB-007, OB-021 D12).
- REQ-015: Band edges, depth targets/caps and the WC slope are configurable constants in one place.

## Business Rules
- BR-001: The persona only changes the move suggested to the user (OB-021 D1).
- BR-002: No default tier; chosen at game start; changeable mid-game (OB-021 D5).
- BR-003: Suggestion shown ≤ 1000 ms after the move is accepted; engine ≤ 900 ms, ≤ 2 threads, 16–32 MB hash, no extra download (OB-021 D14).
- BR-004: Never suggest an illegal move.
- BR-005: Band edges change only with PO approval; depths may be tuned by engineering to meet BR-003 (OB-021 R7).

## User Flow
```text
Game started, tier chosen (OB-011 / OB-023)
↓
User enters the opponent's move
↓
Tier 1–4: all-move evaluation → WC per move → band selection (+ fallback)
Tier 5–7: single-line search with the tier's depth cap → best move
↓
Card shows the move and its evaluation from the user's side (OB-007)
```
Alternative flows:
- Tier changed while a suggestion is shown or computing → recompute for the same position.
- Tier changed while waiting for the opponent's move → the new tier applies to the next suggestion.
- One legal move → that move. No legal moves → game-end state.

## Acceptance Criteria
Tier-logic criteria use candidate lists with given WC values (unit-testable without an engine). "Seeded RNG" means the RNG is fixed for the test.

**General**
- Given a game has started and no tier is selected, When the user enters the opponent's move, Then no suggestion is computed or shown.
- Given any position and any tier, When a suggestion is computed, Then it is a legal move in that position.
- Given a position with exactly one legal move, When any tier computes a suggestion, Then that move is suggested.
- Given the user's side has no legal moves, When a suggestion is requested, Then the game-end state is shown and no move is suggested.
- Given a suggestion is shown for position P with 👑 God, When the user selects 🥚 Baby, Then a new suggestion for P, computed with Baby, replaces it, and the God suggestion is no longer displayed.
- Given a suggestion is being computed, When the user switches tiers, Then only the result for the new tier is displayed.
- Given a suggestion is shown, When the screen is redrawn or the app returns from the background with the same position and tier, Then the same move is still shown.
- Given cp = 0 / +100 / −250 from the user's side, When converted, Then WC ≈ 50.0 / 59.1 / 28.5 %. A mate for the user gives 100 %; being mated gives 0 %.

**🥚 Baby**
- Given candidates with WC {A 50, B 45, C 12, D 10, E 9} (Lmax = 41 pp), When Baby selects with a seeded RNG, Then the suggestion is one of {C, D, E} (Loss ≥ 38), never A or B.
- Given qualifying moves D (allows mate in 3 against the user) and E (allows mate in 1 against the user), When Baby selects, Then E is suggested.
- Given Chess positions where one legal move hangs the queen, When Baby selects, Then that move is in the candidate set even if it is not among the engine's top 5 lines.

**🐣 Gentle**
- Given candidates with WC {A 60, B 55, C 48, D 40, E 20} (losses 0, 5, 12, 20, 40), When Gentle selects, Then the suggestion is C or D.
- Given candidates with WC {A 60, B 57, C 54} (losses 0, 3, 6; none in 9–22), When Gentle selects, Then C is suggested (closest to the band).
- Given candidates with WC {A 60, B 30} (losses 0, 30), When Gentle selects, Then B is suggested (distance 8 vs. 9).

**🐥 Soft**
- Given candidates with WC {A 60, B 58, C 55, D 52, E 40} (losses 0, 2, 5, 8, 20), When Soft selects, Then the suggestion is C or D.
- Given candidates with WC {A 60, B 59, C 45} (losses 0, 1, 15; none in 3–9), When Soft selects, Then B is suggested (distance 2 vs. 6).
- Given a loss of exactly 9 pp, When Soft and Gentle evaluate it, Then it qualifies for Gentle, not Soft.

**🥉 Even**
- Given candidates with WC {A 80, B 65, C 52, D 49, E 30}, When Even selects, Then the suggestion is C or D.
- Given the user is behind: candidates with WC {A 40, B 35, C 20}, When Even selects, Then A (the best move) is suggested.
- Given the user is far ahead: candidates with WC {A 95, B 85, C 70}, When Even selects, Then C is suggested (closest to 53).
- Given candidates with WC {A 61, B 39} (both 8 pp from the band), When Even selects, Then A is suggested (smaller loss).

**🥈 Solid / 🥇 Master / 👑 God**
- Given Solid, When a suggestion is computed, Then it is the best move of a search capped at depth 12 (or the 900 ms cap, whichever comes first).
- Given Master, When a suggestion is computed, Then it is the best move of a search capped at depth 18 (or 900 ms).
- Given God, When a suggestion is computed, Then it is the best move of a search limited only by the 900 ms cap. In a position with a forced mate for the user, it is a move on the shortest mate found.

**Latency**
- Given standard Chess and Xiangqi test positions on reference devices (OB-010), When any tier computes a suggestion, Then it is shown ≤ 1000 ms after the move is accepted, using ≤ 2 engine threads.
- Given an all-move evaluation hits the 900 ms cap before depth 8, When the result is used, Then it comes from the deepest iteration completed for all moves, and the suggestion is still shown within budget.

## Edge Cases
- Very few legal moves (in check): bands may be empty → fallback (REQ-009).
- Many equal moves (Lmax small): Baby's band spans most moves; the result is still legal and random.
- Stalemate in Chess (draw, WC ≈ 50) vs. Xiangqi (loss, WC 0): handled through engine scores.
- Rapid tier switching: only the latest tier's result is shown.
- Engine error/timeout: error state per OB-007 (no tier-specific handling).

## In Scope
- Tier selection logic (pure Dart, unit-tested with the cases above).
- WC conversion for Fairy-Stockfish.
- All-move evaluation and depth-capped searches for Chess and Xiangqi (via OB-005).
- Gating until a tier is chosen; recompute on tier change; suggestion stability.

## Out of Scope
- Selector UI (OB-023) and tier choice in the game-start flow (OB-011).
- WC conversion and candidate sets for KataGo, Edax and Gomoku (OB-017–OB-020, per OB-021 "Engine mapping").
- Displaying the best move alongside weak suggestions (excluded by OB-021 D12).
- Opponent/bot mode.

## Dependencies
- OB-021 (resolved — source of all rules).
- OB-005 (engine interface: multi-line search covering all legal moves, depth caps, 900 ms cap, cancellation).
- OB-007 (card displays the suggested move and its evaluation).
- OB-011 / OB-023 (tier choice and changes).
- OB-010 (validates latency per tier; may tune depths).
- OB-001 (game end Q5).
- Note (per-game plan, 2026-10-02): the tier logic core (pure Dart, WC conversion) is in Phase 0 (shared). Wiring for Chess is completed in Phase 1 with OB-025 (turn loop) and OB-024 (game end); for Xiangqi in Phase 2 (OB-009).
- Note (PO compliance document, 2026-10-02): suggestion requests must also pass the access checks: tier access (Pro tiers, **OB-037**) and the free daily limit (**OB-038**). Gating is enforced in the request path, not only in the UI. Tier logic, bands and budgets are unchanged.
- Update (PO 2026-10-02): monetization deferred (OB-035 M-D1); the previous note is **parked**. No access checks or daily limit are built now; all tiers are allowed. Guardrail only: suggestion requests go through one request path (already the design), so a later check can be added there.

## Assumptions
- The Lichess win-chance slope (0.00368208) is adequate for Chess, Xiangqi and Shogi initially; it may be recalibrated per variant in OB-010 without PO approval.
- Depth 8 for all-move evaluation fits within 900 ms in typical positions; otherwise the 900 ms cap governs (REQ-004).

## Open Questions
None.

## Developer Handoff
- Pure function: `(candidates with WC, tier, rng) → move`, plus a tiny conversion layer per engine. Put the constants (bands, depths, slope, caps) in one config.
- Fairy-Stockfish: tiers 1–4 = MultiPV equal to the legal-move count, depth target 8, movetime cap 900 ms. Tiers 5–7 = MultiPV 1 with depth 12 / 18 / uncapped, movetime cap 900 ms.
- Cache the suggestion per (position, tier) for stability; cancel in-flight searches on tier or position change.
- Unit-test every acceptance case above with a seeded RNG; add device benchmarks to OB-010 for tiers 1–4 (worst case: positions with many legal moves).
