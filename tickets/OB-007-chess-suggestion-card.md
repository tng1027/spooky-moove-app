# Ticket Analysis

> **Status: Done on iOS simulator (2026-10-03).** Mid-range device latency deferred to OB-010 / the final device pass.
> - Scope (dev decision with the PO, 2026-10-03): end to end, including the minimal suggestion trigger that OB-025 / OB-022 row 1.5 would otherwise own. `gameEngineProvider` (UciEngine + Fairy-Stockfish, started lazily, restarted after a failure) and `personaSuggesterProvider` live in `lib/features/advisor/presentation/suggestion_providers.dart`.
> - `SuggestionController` (`suggestion_controller.dart`) has a sealed state: no tier / waiting / thinking / ready / failed / no moves. It requests a suggestion when it is the user's turn with a tier, reacts to tier, position (`legalMoves` identity) and new game, and drops stale results with a request counter plus the new `PersonaSuggester.cancel()` (REQ-009). Timeout is 2 s (900 ms engine cap + margin); errors are logged and show `ENGINE ERROR` + RETRY (REQ-008).
> - The tier prompt has priority over "opponent's turn", so a user playing Black sees PICK A LEVEL right after the new game.
> - Pure formatters: `ChessMoveFormat` (coordinates, `✕`, castling rook line, en passant `✕ D5`) and `EvalFormat` (`WIN nn%` green from 50 %, `YOU MATE IN n` / `OPPONENT MATES IN n`, `EVAL +1.4 | DEPTH 16 | 850k nps`, mates `M4` / `-M4`).
> - `SuggestionCard` replaces the placeholder. The promotion piece and the castling rook are Cburnett pictograms in the user's color. The board highlights from/to (+ rook squares) in green; the pawn taken en passant gets the new `BoardSquareState.suggestedCapture` (green outline + `✕`).
> - Haptics: `mediumImpact` when a suggestion is shown; `heavyImpact` when the opponent's move puts the user in check (the king square was already red, OB-006).
> - `gameSessionProvider` now notifies on every start, even with the same game and side, so the suggestion cache is cleared per game.
> - Verified on iPhone 17 Pro simulator (`integration_test/suggestion_card_test.dart`, real engine): first suggestion including engine start 276–388 ms; after the opponent's reply 339 ms; tier change (Solid → Baby) 71–96 ms. All 20 integration tests and 192 unit/widget tests pass.
> - Left for others: status line text (OB-025), game-over content (OB-024), streaming search info on the card (not required).
> - Follow-up (2026-10-03): OB-041 adds a "✓ I PLAYED IT" key in the status line that commits the ready suggestion from this card's state. Revision 3 of OB-041 moved the win-rate line from the card to the top bar, reworded `WIN nn%` to `WIN RATE nn%`; the card keeps the move, instruction line and expert line.

TICKET_TYPE: NEW_FEATURE
CONFIDENCE: HIGH

The suggestion output does not exist. Revised 2026-10-02 after the PO decided coordinate notation (OB-001 Q9) and set the principle that the app must be usable by people **without chess knowledge** (OB-001 Q8). Notation, the special-move display and the evaluation display are now fully defined.

## Ticket Title
[Feature] Show the tier-based Chess suggestion in plain coordinates, with special-move instructions, win chance and board highlight

## Summary
On the user's turn, show the persona-chosen move in large coordinates (`E7 ➔ E5`), with a short instruction line for moves that need extra physical actions (castling rook, en passant capture, promotion piece). Show the user's win chance in plain language, plus the expert detail line, and highlight the move on the tap board. Haptics as before.

## Business Context
- Core loop: enter the opponent's move → get the suggestion (`projectbrief.md`), shown in the persona's tier (OB-021, OB-022).
- PO 2026-10-02: coordinates for move display (Q9); target users may not know chess, so no SAN, piece letters, `O-O` or `e.p.`.
- Output spec: centered, 40–48 sp, high contrast (`productContext.md`, `designSystem.md`).

## Decision: notation (OB-001 Q9 = coordinates; special-move format per BA recommendation, 2026-10-02)
| Move type | Main line (48 sp, `accentGreen`) | Instruction line (pictogram + coordinates, `textPrimary`) |
|-----------|-----------------------------------|------------------------------------------------------------|
| Normal | `E2 ➔ E4` | — |
| Capture | `E4 ➔ D5 ✕` (✕ = a piece is captured on the destination) | — |
| Castling | `E1 ➔ G1` (the king's move) | `[rook pictogram] H1 ➔ F1` (the rook also moves) |
| En passant | `E5 ➔ D6 ✕` | `✕ D5` (remove the pawn on D5) |
| Promotion | `E7 ➔ E8 [queen pictogram]` | — (the pictogram shows the new piece) |

Coordinates are uppercase file + rank, absolute (White's frame, `A1` bottom-left from White's side), and match the board edge labels. Castling and en passant flags come from the rules module (OB-006 interface). No piece letters, SAN, `O-O` or `e.p.` anywhere.

## Decision: evaluation display (revises OB-021 D12 for the non-chess-user principle)
- Primary line: user's win chance, from the user's side, rounded to a whole percent: `WIN 62%`. The value is the WC computed in OB-022. Green if ≥ 50 %, red if < 50 %.
- Forced mate: `YOU MATE IN 4` (green) / `OPPONENT MATES IN 4` (red), replacing `M4`.
- Secondary expert line (small, `textSecondary`): `EVAL +1.4 | DEPTH 16 | 850k nps` (pawns from the user's side). Kept for advanced users, de-emphasized.
- The evaluation always describes the **suggested** move (OB-021 D12 unchanged on that point).

## Current Behavior
Not implemented. Hero region placeholder from OB-003.

## Expected Behavior
- On the user's turn with a tier selected (OB-025, OB-022): show a "thinking" state, then the suggestion per the tables above, within ≤ 1000 ms.
- The tap board highlights the suggestion's from/to squares (and the rook's squares for castling) in `accentGreen` (OB-006 REQ-012).
- Haptics: `mediumImpact` when the suggestion is ready; `heavyImpact` plus a red highlight of the user's king square when the user is in check.
- The suggestion is cleared when the user's move is entered (OB-025). The game-over content comes from OB-024. On engine error: error state with Retry.

## User Story
As a player at a physical board, even without chess knowledge
I want the suggested move shown as clear coordinates and highlighted squares, with any extra action spelled out
So that I can play it on the real board correctly at a glance.

## Functional Requirements
- REQ-001: Request a suggestion when it becomes the user's turn and a tier is selected (OB-025, OB-022).
- REQ-002: Show a non-blocking "thinking" state.
- REQ-003: Format the main line and instruction line exactly per the notation table.
- REQ-004: Show `WIN nn%` or the mate wording, then the expert line, both with tabular figures.
- REQ-005: Highlight the suggestion on the tap board (from/to; plus rook from/to for castling; ✕ marker on the en passant captured square).
- REQ-006: `mediumImpact` when the suggestion is ready; `heavyImpact` + red king-square highlight when the user is in check.
- REQ-007: The game-over state replaces the suggestion (content per OB-024).
- REQ-008: Error state with Retry if the engine fails or exceeds the timeout.
- REQ-009: Never show a suggestion for a position other than the current one, or for a tier other than the active one.

## Business Rules
- BR-001: Green = suggested move/advantage; red = threat/check/disadvantage; amber = selection (`designSystem.md`).
- BR-002: Suggestion shown ≤ 1000 ms after the move is accepted (OB-021 D14).
- BR-003: The evaluation is from the user's side and describes the suggested move.
- BR-004: No chess notation beyond coordinates (PO principle 2026-10-02).
- BR-005: Only number/color transitions; no decorative motion.

## User Flow
```text
Opponent's move entered → user's turn (OB-025)
↓
Card: thinking
↓
Card: "E1 ➔ G1" / "[rook] H1 ➔ F1" / "WIN 58%" / "EVAL +0.6 | DEPTH 14 | 900k nps"
Board: E1, G1, H1, F1 highlighted green; mediumImpact
```

## Acceptance Criteria
- Given the engine suggests `e2e4`, When the card renders, Then the main line reads `E2 ➔ E4` and there is no instruction line.
- Given a suggested capture `e4d5`, When the card renders, Then the main line reads `E4 ➔ D5 ✕`.
- Given the suggestion is White kingside castling, When the card renders, Then the main line reads `E1 ➔ G1`, the instruction line shows the rook pictogram with `H1 ➔ F1`, and E1, G1, H1, F1 are highlighted green on the board.
- Given the suggestion is en passant `e5d6`, When the card renders, Then the main line reads `E5 ➔ D6 ✕` and the instruction line reads `✕ D5`.
- Given the suggestion is a promotion `e7e8q`, When the card renders, Then the main line reads `E7 ➔ E8` followed by the queen pictogram, with no letter `Q`.
- Given the suggested move's WC is 62 %, When the card renders, Then the primary eval reads `WIN 62%` in green; at 38 % it reads `WIN 38%` in red.
- Given the suggested move leads to a forced mate for the user in 4, When the card renders, Then it reads `YOU MATE IN 4`; for a forced mate against the user, `OPPONENT MATES IN 4` in red.
- Given search info updates, When digits change, Then the layout does not shift (tabular figures).
- Given the suggestion is ready, When it is displayed, Then `mediumImpact` fires once.
- Given the opponent's move puts the user in check, When the position is shown, Then `heavyImpact` fires and the user's king square is highlighted red.
- Given the engine fails or times out, When the timeout elapses, Then an error state with Retry is shown; Retry re-requests the suggestion.
- Given the card and board in any state, When they are inspected, Then no SAN, piece letters, `O-O` or `e.p.` appear.

## Edge Cases
- Queenside castling: `E1 ➔ C1` + `[rook] A1 ➔ D1`; for Black, `E8 ➔ G8` + `[rook] H8 ➔ F8`.
- Capture with promotion: `D7 ➔ E8 ✕ [queen]`.
- Tier change while thinking (OB-022 R6) — only the new tier's result is shown.
- Large font scale — the 48 sp main line must not overflow (the instruction line may wrap).

## In Scope
- Card states (thinking, result, check, error); formatting per the tables; board highlight; haptics.
- Unit tests for formatters (each move type, WC/mate wording, nps abbreviations); widget tests per state.

## Out of Scope
- Game-over content (OB-024); turn timing (OB-025); move selection (OB-022).
- Showing the best move alongside weak suggestions (excluded, OB-021 D12).

## Dependencies
- OB-005 (engine), OB-006 (board, rules flags, highlight API), OB-022 (move + WC), OB-025 (turn timing), OB-024 (game-over content).
- OB-001 Q9 — resolved (coordinates).

## Assumptions
- `WIN nn%` uses the same WC as persona selection (Lichess model, OB-021); it is an estimate, not a guarantee.
- English UI strings (localization not documented); see README open questions.

## Open Questions
None blocking.

## Developer Handoff
- Formatting is pure Dart over (move + flags from the rules interface, WC, mate distance, engine info) → view model.
- The board highlight is driven by the same view model (squares to highlight + markers).
- Use bundled pictogram assets for the rook/promotion icons, the same set as OB-006.
