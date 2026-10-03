# Ticket Analysis

> **Status: DEFERRED by PO (2026-10-02)** — full-feature build first. All games are available to everyone (OB-035 M-D1). Recorded: **Shogi and Othello will be Pro** (OB-035 M-D3), so the target access map is Chess/Caro = free; Xiangqi, Go, Shogi, Othello = Pro. Download gating and expiry are deferred (OB-035 Open Questions 2–3). References below to "OB-035 Q7/Q8" map to those questions.

TICKET_TYPE: NEW_FEATURE
CONFIDENCE: MEDIUM

Gating games by entitlement does not exist and isn't in the memory bank. The PO's document §3.3 (Paywall 3): Chess and Caro free; Xiangqi and Go Pro-only. Shogi and Othello are unspecified, and gating of on-demand packs isn't defined (OB-035 Q8). This ticket covers the mechanism. Each game's access value comes from OB-035, and it is delivered phase by phase: Xiangqi in Phase 2 (M1), the rest later.

## Ticket Title
[Feature] Lock Pro-only games in the new-game flow and show the game paywall (Xiangqi in M1)

## Summary
In the new-game flow (OB-011), Pro-only games are listed with a lock. Selecting one opens the game paywall (OB-036) instead of starting the game. Free games start normally. For on-demand games, download access follows OB-035 Q8.

## Business Context
- PO document §3.3: "Chess and Caro free to download; Xiangqi/Go require Pro."
- Milestones: M1 = Chess + Xiangqi (bundled) → in M1, only Xiangqi is gated. Caro and Go are post-M1 (on-demand packs, OB-014/015). Shogi and Othello are unspecified.

## Current Behavior
Not implemented. OB-011 lists available games without access rules.

## Expected Behavior
- Game access map (configurable): Chess = free; Xiangqi = Pro; Caro = free; Go = Pro; Shogi = TBD; Othello = TBD (OB-035 Q8).
- Free user: locked games show a lock marker; tapping one opens Paywall 3 (copy TBD); no game starts.
- After purchase, the tapped game starts (side selection follows).
- Pro user: all available games start normally.

## User Story
As a free user
I want to see which games are included and which need Pro
So that I can play Chess for free and upgrade for other games.

## Functional Requirements
- REQ-001: A configurable game access map (free/Pro per game).
- REQ-002: Locked games in the new-game list show a lock marker (design tokens only).
- REQ-003: Tapping a locked game opens the game paywall (OB-036) and does not start a game.
- REQ-004: After a successful purchase, continue the new-game flow for that game.
- REQ-005: On-demand games: download is allowed or blocked for free users per OB-035 Q8.
- REQ-006: If Pro lapses during a game of a Pro-only game, behavior per OB-035 Q7.

## Business Rules
- BR-001: Access per PO document §3.3; Shogi/Othello per OB-035 Q8.

## User Flow
```text
New game → [CHESS] [XIANGQI 🔒]
↓
Free user taps XIANGQI → game paywall → purchase → side selection → game
```

## Acceptance Criteria
- Given a free user in M1, When the new-game list renders, Then Chess is unlocked and Xiangqi shows a lock.
- Given a free user taps Xiangqi, When the paywall closes without purchase, Then no game starts and the list is shown again.
- Given a free user taps Xiangqi and purchases Pro, When the purchase completes, Then the side selection for Xiangqi is shown.
- Given a Pro user, When the list renders, Then no game shows a lock.
- Given the access map marks a game as free, When a free user taps it, Then the game starts normally.

## Edge Cases
- Pro expires mid-game in Xiangqi (OB-035 Q7).
- On-demand pack downloaded while Pro, then Pro lapses (keep the pack, lock play?).

## In Scope
- Access map, lock state in the game list, game paywall trigger. Xiangqi in Phase 2; Caro/Go/Shogi/Othello entries added in their phases.

## Out of Scope
- Purchase flow (OB-036); pack downloads (OB-015).

## Dependencies
- OB-011, OB-036, OB-035 (Q7, Q8), OB-015 (on-demand games).

## Assumptions
- In M1 the only gated game is Xiangqi.

## Open Questions
1. Shogi and Othello access; download gating for on-demand packs (OB-035 Q8).
2. Paywall 3 copy.

## Developer Handoff
- Store access rules as data next to the game registry used by OB-011.
- Enforce access at game start, not only in the list UI.
