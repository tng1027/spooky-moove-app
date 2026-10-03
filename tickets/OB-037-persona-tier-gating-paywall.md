# Ticket Analysis

> **Status: DEFERRED by PO (2026-10-02)** — full-feature build first. All 7 tiers are available to everyone (OB-035 M-D1). Locked-tier UX and expiry behavior are deferred (OB-035 Open Question 2). References below to "OB-035 Qn" point to the pre-deferral numbering and map to OB-035 Open Questions 2 (Q6/Q7) and 7 (Q14). The daily limit (OB-038) is merged into OB-035.

TICKET_TYPE: ENHANCEMENT
CONFIDENCE: MEDIUM

Enhances the planned persona selector (OB-023) and tier logic (OB-022), which are specified but not built, with Pro gating per the PO's document §3.2/§3.3. Which tiers are free is clear; the locked-tier UX and expiry behavior are pending OB-035 Q6/Q7, and the Paywall 2 copy has an accuracy issue (OB-035 Q14).

## Ticket Title
[Enhancement] Lock 🥚 Baby, 🐣 Gentle, 🥇 Master and 👑 God behind Pro, with tier paywalls

## Summary
Free users can choose 🐥 Soft, 🥉 Even or 🥈 Solid. The Pro tiers are visible with a lock. Tapping a locked tier opens the matching paywall (Paywall 1 for 🥚/🐣, Paywall 2 for 👑; 🥇 uses the generic Pro paywall) instead of selecting it.

## Business Context
- PO document §3.2: baby = Pro, gentle = Pro, soft = free, even = free, solid = free, master = Pro, god = Pro.
- PO document §3.3: Paywall 1 (🥚/🐣) and Paywall 2 (👑) copy.
- OB-021 D5: no default tier; the user must pick one.

## Current Behavior
Not implemented. OB-023 specifies 7 equally selectable tiers; OB-022 computes suggestions for any selected tier.

## Expected Behavior
- Free user: 🐥, 🥉, 🥈 selectable; 🥚, 🐣, 🥇, 👑 shown with a lock marker (design-system tokens only).
- Tapping a locked tier opens a paywall (OB-036) and does **not** change the selected tier.
  - 🥚/🐣 → Paywall 1: "Mở khóa Chế độ Rèn luyện Nhẹ nhàng — Giúp bé luôn tự tin và hứng thú khi chơi cờ cùng bố mẹ."
  - 👑 → Paywall 2 (copy per OB-035 Q14).
  - 🥇 → generic Pro paywall (copy TBD).
- After a purchase from a tier paywall, the tapped tier becomes selected.
- Pro user: all 7 tiers selectable, no locks.

## User Story
As a free user
I want to see all tiers, with the premium ones clearly marked
So that I can play with the free tiers and upgrade when I need the gentlest or strongest levels.

## Functional Requirements
- REQ-001: Tier access map: free = {Soft, Even, Solid}; Pro = {Baby, Gentle, Master, God}.
- REQ-002: Locked tiers show a lock marker without color misuse (no new accent; e.g. lock glyph + `textSecondary`).
- REQ-003: Tapping a locked tier opens the corresponding paywall and doesn't select the tier.
- REQ-004: After a successful purchase from that paywall, select the tapped tier and compute the suggestion (OB-022 R6).
- REQ-005: Accessibility label announces "locked, Pro" for locked tiers.
- REQ-006: When Pro lapses mid-game while a Pro tier is active → behavior per OB-035 Q7.
- REQ-007: Gating is enforced in the suggestion logic too (OB-022), not only in the UI.

## Business Rules
- BR-001: Access map per PO document §3.2.
- BR-002: No default tier (OB-021 D5); free users must pick a free tier to get suggestions.
- BR-003: Paywall copy must be accurate (OB-021 D14) and free of banned terms (OB-034).

## User Flow
```text
Free user, new game → persona row: 🥚🔒 🐣🔒 🐥 🥉 🥈 🥇🔒 👑🔒
↓
Taps 🥚 → Paywall 1 → closes → still no tier selected
↓
Taps 🐥 → Soft selected → suggestions start
```

## Acceptance Criteria
- Given a free user, When the persona row renders, Then 🥚, 🐣, 🥇 and 👑 show a lock marker and 🐥, 🥉, 🥈 do not.
- Given a free user, When they tap 🥚 or 🐣, Then Paywall 1 opens with the PO's text, and the selected tier is unchanged.
- Given a free user, When they tap 👑, Then Paywall 2 opens with the approved text, and the selected tier is unchanged.
- Given a free user taps 🐣 and completes a purchase, When the paywall closes, Then 🐣 is selected and a suggestion for the current position is computed.
- Given a Pro user, When the persona row renders, Then no tier shows a lock and all are selectable.
- Given a free user somehow has a Pro tier stored (e.g. expired subscription), When a suggestion is requested, Then the rule from OB-035 Q7 applies and no Pro-tier suggestion is shown without an active entitlement.
- Given a screen reader, When focus is on 🥚 for a free user, Then it announces "Baby, locked, Pro".

## Edge Cases
- Pro expires during a game (OB-035 Q7).
- Purchase pending ("ask to buy") → tier stays locked until confirmed.
- Offline Pro within grace → unlocked (OB-036).

## In Scope
- Lock state in the persona row, tier paywall triggers, enforcement in suggestion requests.

## Out of Scope
- Purchase flow itself (OB-036); daily limit (OB-038); game gating (OB-039).

## Dependencies
- OB-023, OB-022, OB-036, OB-035 (Q6, Q7, Q14), OB-034 (copy).

## Assumptions
- Locked tiers stay visible (PO document describes tapping 🥚/🐣/👑 to open paywalls).

## Open Questions
1. Expiry mid-game behavior (OB-035 Q7).
2. Paywall 2 wording (OB-035 Q14) and the 🥇 Master paywall copy.

## Developer Handoff
- Tier access is a pure function of (tier, isPro); the persona row and the suggestion request both use it.
- Paywall triggers pass a headline key to the OB-036 paywall.
