# Ticket Analysis

> **Status: SUPERSEDED — merged into [OB-035](OB-035-clarify-monetization-model.md) (Open Question 1) on 2026-10-02.** The PO asked to log the daily-limit question in one ticket and consider it later ("log tạm vào 1 ticket, sẽ consider sau"). Do not work from this file. It is kept only so the ID stays stable and the BA's proposed defaults below remain available for reference.

TICKET_TYPE: NEEDS_CLARIFICATION
CONFIDENCE: HIGH

The PO's document §3.2 sets `freeDailyMoveLimit = 25` ("after 25 moves → paywall"). The unit ("move"), the counting rules, the reset time and the behavior at the limit are undefined. A literal reading conflicts with game length (~40 moves per side in chess), so a free user cannot finish one game per day. It cannot be specified without business decisions (OB-035 Q2–Q5). A full feature ticket will replace this once decided.

## Ticket Title
[Clarification] Define and then enforce the free daily suggestion limit (25/day)

## Summary
Free users get a limited number of suggestions per day; beyond it, a paywall replaces suggestions. This ticket fixes the counting rules and records BA-proposed defaults so the feature can be built as soon as the PO confirms.

## Business Context
- PO document §3.2 (`freeDailyMoveLimit = 25`) and §3.3 (paywall after the limit).
- Advisor loop: the user enters every move; suggestions appear only on the user's turn (OB-025).

## Current Behavior
Not implemented. No limits exist.

## Expected Behavior (BA-proposed defaults, to confirm in OB-035)
- **Counted unit:** a suggestion shown for a **new user turn**. Recomputations for the same position (tier change, retry after error, undo then the same position) do not count. Move entry never counts.
- **At the limit:** move entry keeps working (board stays in sync). On the user's turn the card shows "Free limit reached — upgrade to Pro for unlimited suggestions" with a button that opens the paywall (OB-036). The counter shows remaining suggestions.
- **Reset:** local midnight, device time zone.
- **Pro:** unlimited.

## Business Rules
- BR-001: Limit value 25 per day for free users (PO document); unit and reset per OB-035.
- BR-002: Board sync is never blocked by the limit (proposed).

## User Flow
```text
Free user, user's turn, suggestions used < 25 → suggestion shown, counter decremented
Used = 25 → card shows limit message + [UPGRADE] → paywall
Next day (local midnight) → counter reset
```

## Acceptance Criteria
To be finalized after OB-035. Proposed:
- Given a free user with 0 suggestions used today, When 25 user turns have received a suggestion, Then on the 26th user turn the card shows the limit message instead of a suggestion.
- Given a free user changes tier mid-turn, When the suggestion is recomputed for the same position, Then the counter does not change.
- Given the limit is reached, When the user enters moves, Then moves are accepted and the board stays in sync.
- Given local midnight passes, When the next user turn arrives, Then a suggestion is shown and the counter restarts at 24 remaining.
- Given a Pro user, When any number of suggestions is shown, Then no limit applies.

## Edge Cases
- Device clock moved back/forward offline (accepted risk?).
- Reinstall resets the local counter (accepted risk?).
- Game ends exactly at the limit.

## In Scope
- Counting rules, limit state on the card, reset, paywall trigger.

## Out of Scope
- Purchase flow (OB-036).

## Dependencies
- OB-035 (Q2–Q5), OB-036, OB-025, OB-007, OB-022.

## Assumptions
- Counting is local (no server), consistent with offline-first.

## Open Questions
1. Unit of the limit and whether 25 is intended given ~40 moves per side (OB-035 Q2, Q3).
2. Behavior at the limit (OB-035 Q4).
3. Reset time and acceptance of clock/reinstall bypass (OB-035 Q5).

## Developer Handoff
- A local daily counter keyed by local date; increments only on the first suggestion for a (game, position) on a user turn.
- Gate in the suggestion request path (same place as tier gating, OB-037).
