# Ticket Analysis

TICKET_TYPE: TECHNICAL_TASK
CONFIDENCE: MEDIUM

Release and compliance work, not new app behavior. The PO's compliance document §2 requires the product to be positioned as a "Family Companion & Training Assistant" and to avoid terms such as Cheat, Hack, Stealth, Bot, Auto-move, Undetected, to reduce store-review rejection risk. This ticket is a listing checklist plus an audit of in-app copy. Confidence is MEDIUM because the app name and the tier-7 label need PO decisions, and the store-policy citations need verification.

## Ticket Title
[Tech] Audit store listing and in-app copy for "Family Companion & Training Assistant" positioning before store submission

## Summary
Before the first store submission (M1), produce and verify a compliant listing (name, subtitle, description, keywords, screenshots, review notes) and remove risky terms from in-app copy, consistent with the handicap-advisor positioning (OB-021 D1) and the fair-play notice (OB-008).

## Business Context
- PO document §2.1: stores prohibit apps that enable cheating or an unfair advantage on other platforms (e.g. Lichess, Chess.com); risky terms can lead to rejection or account termination.
- PO document §2.2 — compliant positioning examples:
  - Name: "Board Companion", "Smart Chess Coach", "Tactical Assistant".
  - Description: "smart coach for real-world boards; helps parents play fun, level-balanced games with young kids".
  - Keywords: chess training, family board game, smart tutor, handicap assistant.
  - Screenshots: physical wooden board, family, kids practicing.
- Memory bank wording that may read as in-game assistance: "real-time tactical advisor" (`projectbrief.md`), working title "OmniChess **Advisor**".

## Current Behavior
No listing exists. In-app copy is defined in tickets: tier names (🥚 Baby … 👑 God) in OB-023 accessibility labels; PO spec caption "GOD MODE"; tier name "Hủy diệt tuyệt đối"; fair-play notice (OB-008).

## Expected Behavior
- A listing package per store (EN + VI) reviewed against a banned-terms list and the positioning rules.
- In-app strings audited; risky labels replaced per PO decision.
- Store review notes explain: physical-board use, offline, family/training purpose, fair-play notice.

## Business Rules
- BR-001: No listing or in-app text uses: cheat, hack, stealth, bot, auto-move, undetected, "win every online game", or similar (PO §2.1).
- BR-002: No screenshot shows an online/competitive board or another platform's UI (PO §2.2).
- BR-003: Positioning: family companion and training assistant for real-world boards (PO §2.2, OB-021 D1).
- BR-004: Paid features are described accurately; no claims beyond actual behavior (e.g. engine strength limited per OB-021 D14).

## User Flow
Not user-facing (release process).

## Acceptance Criteria
- Given the banned-terms list, When the listing (name, subtitle, description, keywords, what's-new, screenshots' text) is checked in EN and VI, Then none of the terms appear.
- Given the in-app string catalogue, When it is searched for the banned terms and for "GOD MODE", Then no matches remain (or each is approved by the PO).
- Given the screenshot set, When it is reviewed, Then every screenshot shows a physical-board or family/training context and no online platform.
- Given the store review notes, When submitted, Then they describe offline physical-board use, the fair-play notice and the family/training purpose.
- Given marketing claims about engine strength, When compared with OB-021 D14 (≤ 1000 ms, 2 threads), Then no claim overstates it (e.g. "maximum depth").

## Edge Cases
- Tier label "God" / "GOD MODE" / "Hủy diệt tuyệt đối" ("absolute destruction") may read as aggressive or unfair-advantage wording → PO decision.
- The app name containing "Advisor" combined with "real-time" → PO decision.
- The listing promotes the parent-child use case, but Baby/Gentle are Pro-only (OB-037) → the listing must make clear which features are paid.

## In Scope
- Checklist, banned-terms list, listing drafts (EN/VI), screenshot guidance, review notes, in-app copy audit.

## Out of Scope
- Legal opinions (OB-032, OB-040).
- Paywall copy itself (OB-037), except the banned-terms and accuracy checks.

## Dependencies
- OB-008 (fair-play notice), OB-023 (tier labels), OB-037 (paywall copy), OB-040 (audience declaration).
- PO decisions on app name and tier-7 label.
- Note (PO answers 2026-10-02): app name, tier-7 label and paywall copy are **deferred** ("tính sau"); needed before store submission, not for development. Recorded:
  - OB-040 A-D1/A-D2/A-D4/A-D5 apply to the listing: adult target audience (not Kids Category / Families); lowest content rating (4+ / Everyone); "no data collected" disclosures plus a short privacy policy; copy and screenshots addressed to parents.
  - **No analytics** (OB-035 M-D2), so no tracking SDKs to disclose.
  - Monetization is deferred, so the "paid features must be described" edge case (Baby/Gentle Pro-only) does not apply to the first listing; every tier is free.
  - Developers should still keep strings in one catalogue so the rename stays cheap.

## Assumptions
- The PO's store-policy citations are directionally right. **The specific citation "App Store Review Guidelines section 1.4 (safety & cheating)" could not be confirmed** — section 1.4 is understood to cover physical harm. The exact clauses should be verified by the release owner or counsel before relying on them.

## Open Questions
1. **App name:** keep "OmniChess Advisor" or adopt a compliant name (e.g. "Board Companion", "Smart Chess Coach")? The name is also needed for OB-003 (bundle ID).
2. **Tier 7 label:** keep "God" (👑) or rename (e.g. "Max", "Master+")? Also the Vietnamese "Hủy diệt tuyệt đối".
3. Who owns listing copy and screenshots (marketing vs. BA)?

## Developer Handoff
- Keep all user-facing strings in one catalogue so the audit can be automated (a simple banned-terms check in CI is recommended).
- No code change beyond string updates once the PO decides.
