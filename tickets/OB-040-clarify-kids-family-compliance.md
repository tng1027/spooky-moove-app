# Ticket Analysis

TICKET_TYPE: NEEDS_CLARIFICATION
CONFIDENCE: HIGH

**Status: PARTIALLY RESOLVED (2026-10-02).** The business decisions on target audience, parental gate, data and store copy are recorded below. Source: **"PO delegated to BA recommendation, 2026-10-02"** (PO answer #8, "BA đề xuất"). The **legal obligations** remain open and are **deferred with OB-032** until counsel is assigned (PO answer #9, "tính sau"). Nothing here is legal advice.

## Ticket Title
[Clarification] Target audience, parental gate and children's-policy obligations

## Summary
The PO positions the app as a "Family Companion" (parents playing with young children on a physical board). This ticket records the BA-recommended audience decision, consistent with the existing product constraints. These are: offline, no account, no server, no analytics (OB-035 M-D2), no ads. It also lists what counsel must still confirm.

## Business Context
- Positioning: "Family Companion & Training Assistant"; parents play with young children (PO compliance document §2.2, §3.3).
- The person operating the app is the adult/player. The child is the opponent on the **physical** board and does not need to touch the phone.
- Product constraints: 100% offline, no server dependency, full privacy (`projectbrief.md`); no analytics (OB-035 M-D2); no account or login anywhere in the memory bank; no ads.
- Monetization is deferred (OB-035 M-D1).

## Decisions (PO delegated to BA recommendation, 2026-10-02)
| # | Decision | Rationale |
|---|----------|-----------|
| A-D1 | **Target audience = adults (general audience, not directed to children).** Google Play: target age group 18+ only. Apple: do **not** join the Kids Category. | The app is operated by the parent/player; children play on the physical board. Declaring a child audience would bring the app into Google Play Families and Apple Kids Category requirements, which add constraints but no benefit, given that the child doesn't use the phone. |
| A-D2 | **Content age rating: the lowest available** (Apple 4+; IARC "Everyone"/PEGI 3 on Google Play). | Board games only: no violence, user-generated content, chat, ads, gambling or in-app web browsing. Age rating (content) is separate from target audience (A-D1). |
| A-D3 | **Parental gate before (a) any purchase flow (when monetization returns) and (b) any action that leaves the app** (external links, e.g. engine source links in OB-033, terms/privacy links). A simple offline check aimed at adults (e.g. a short arithmetic question). Not required for normal play. | A child sits next to the device during parent-child games, so it prevents accidental purchases and navigation. Cheap, fully offline, consistent with the family positioning. Applied even though the audience is adults. |
| A-D4 | **No personal data collected.** Store privacy disclosures: Apple "Data Not Collected"; Google Play Data safety "No data collected / shared". Publish a short privacy policy stating this (both stores ask for a privacy-policy link). | Follows from offline, no account, no analytics (M-D2), no ads. |
| A-D5 | **Store copy addresses parents, not children.** For example, "play balanced games with your child". Don't market the app as "for kids" and avoid child-directed styling (cartoon mascots, kid-targeted language) in the listing. Family/kids screenshots show the **parent** using the phone at a physical board. | Keeps the listing consistent with A-D1 while keeping the family-companion positioning (OB-034). |

## Impact on other tickets
- **OB-034 (store positioning):** apply A-D2 (age rating questionnaire answers), A-D4 (privacy disclosures) and A-D5 (copy and screenshots addressed to parents) in the listing checklist.
- **OB-033 (licenses screen):** external links (source code, license texts online) are behind the parental gate (A-D3). That is in M1 scope (needed for release), so the parental gate is built with OB-033.
- **OB-036 (purchases, deferred):** a parental gate before every purchase and before terms/privacy links (A-D3), unconditionally.
- **OB-008 (fair-play notice):** addressed to the device user (adult); no child version needed.
- **OB-035:** analytics conflict (C6) is moot. With no data collected, A-D4 holds.

## Current Behavior
Nothing implemented; no data collection, no purchases.

## Expected Behavior
- The listing declares an adult target audience with the lowest content rating and "no data collected" disclosures.
- Leaving the app (external links), and later purchasing, requires passing a parental gate.

## Business Rules
- BR-001: Target audience adults; not in Apple Kids Category; Google Play target age 18+ (A-D1).
- BR-002: Parental gate before purchases and external links (A-D3).
- BR-003: No personal data collection, no analytics, no ads (A-D4, OB-035 M-D2).
- BR-004: Store copy addresses parents (A-D5).

## User Flow
```text
ABOUT screen → user taps an external link (e.g. engine source)
↓
Parental gate (adult check, offline)
↓
Pass → external browser opens | Fail/cancel → stays in the app
```

## Acceptance Criteria
- Given the store submission, When the audience and content-rating questionnaires are completed, Then the target audience is adults (not the Kids Category / not Families) and the content rating is the lowest level (A-D1, A-D2).
- Given the store privacy forms, When completed, Then they state that no data is collected or shared, and a privacy-policy link stating this is provided (A-D4).
- Given any external link in the app, When the user taps it, Then a parental gate is shown, and only a correct answer opens the link (A-D3).
- Given the parental gate, When the user cancels or answers wrongly, Then the app stays on the current screen with nothing opened.
- Given the store listing, When reviewed, Then the text addresses parents and does not describe the app as "for kids" (A-D5).

## Edge Cases
- A child tapping around the screen during a game: no purchase or external link is reachable without the gate.
- Parental gate must work offline and with large text / screen readers.

## In Scope
- Audience and rating decision, parental-gate rule, privacy disclosures, store-copy rule.
- Legal obligations list (open, deferred).

## Out of Scope
- Implementing the parental gate (built with OB-033; reused by OB-036 later).
- Legal opinions (counsel, deferred with OB-032).

## Dependencies
- OB-034, OB-033, OB-036 (deferred), OB-008.
- **Legal counsel** for the open questions (deferred, together with OB-032).

## Assumptions
- No account, login, ads or analytics are added (if any are added later, A-D1/A-D4 must be revisited).
- The child does not operate the device as the main user; the parent/player does.

## Open Questions — counsel-dependent, **Deferred by PO 2026-10-02** (with OB-032)
1. **(Counsel)** Given family/kids marketing images and copy, could Google Play treat the app as "appealing to children" (mixed audience) despite an 18+ target declaration, and would the Families policy then apply?
2. **(Counsel)** COPPA (US), GDPR for minors (EU) and Vietnam's personal-data rules (Decree 13/2023): any obligations for an app that collects no data at all?
3. **(Counsel)** Privacy-policy content and wording requirements, and whether the parental gate design is adequate.

## Developer Handoff
- Build one small, reusable offline parental-gate component with OB-033 (first external link). OB-036 reuses it later.
- No SDKs that collect data (analytics, ads, crash reporting that sends data) without a new PO decision.
