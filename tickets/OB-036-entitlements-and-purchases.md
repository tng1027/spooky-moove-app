# Ticket Analysis

> **Status: DEFERRED by PO (2026-10-02)** — monetization is not in the current scope (OB-035 M-D1). Draft kept for later. Recorded since: no analytics (OB-035 M-D2), and a parental gate is required before any purchase regardless of audience (OB-040 A-D3). Not ready for development. References below to "OB-035 Q9–Q12" use the pre-deferral numbering and map to OB-035 Open Questions 4 (trial, lifetime), 5 (validation, grace) and 6 (pricing).

TICKET_TYPE: NEW_FEATURE
CONFIDENCE: LOW

New capability: no purchases exist and the memory bank has no monetization. The plans and prices come from the PO's document §3.1. Confidence is LOW because validation, offline grace, trial scope and lifetime rules are pending OB-035, and kids-policy requirements (parental gate) are pending OB-040.

## Ticket Title
[Feature] Sell Pro (monthly, yearly with trial, lifetime), restore purchases, and keep entitlements working offline

## Summary
Add store in-app purchases for Pro — $2.99/month, $19.99/year with a 3-day free trial, $39.99 lifetime — a generic paywall screen, restore purchases, and a locally cached entitlement so Pro works offline. Other features ask "is Pro active?" through one entitlement interface.

## Business Context
- PO document §3.1 (freemium, subscription + lifetime).
- Offline-first product (`projectbrief.md`): entitlements must not require a connection for daily use.

## Current Behavior
Nothing implemented.

## Expected Behavior
- A paywall (reused by OB-037/OB-039 and any future limit prompt) shows the three options with store-localized prices, trial info where eligible, "Restore purchases", and the required subscription terms/links.
- A successful purchase unlocks Pro immediately; restore unlocks it on a new device/reinstall.
- Entitlement is cached locally and honored offline within the grace policy (OB-035 Q11).
- Expiry, refund or revocation removes Pro at the next validation.

## User Story
As a free user
I want to upgrade to Pro (monthly, yearly with a free trial, or once for life) and keep it working offline
So that I can use all tiers, games and unlimited suggestions at the board.

## Functional Requirements
- REQ-001: Products: Pro monthly ($2.99), Pro yearly ($19.99, 3-day trial — plan per OB-035 Q9), Pro lifetime ($39.99). Prices displayed from the store, localized.
- REQ-002: One entitlement "Pro" = active subscription OR lifetime ownership.
- REQ-003: Generic paywall screen with a configurable headline/subtitle (used by Paywalls 1–3 and the limit paywall), the plans, restore, terms/privacy links, and close.
- REQ-004: Restore purchases.
- REQ-005: Local entitlement cache; offline use honored within the grace period (OB-035 Q11).
- REQ-006: Handle pending, cancelled, failed and deferred ("ask to buy") purchases with clear messages.
- REQ-007: A parental gate precedes any purchase and any external link (terms/privacy) (OB-040 A-D3, decided 2026-10-02).
- REQ-008: No purchase UI text uses banned terms (OB-034).

## Business Rules
- BR-001: Pro unlocks all features gated in OB-037 and OB-039 (and any daily limit, if kept — OB-035 Open Question 1).
- BR-002: Prices and trial per PO document §3.1; trial eligibility per store rules.
- BR-003: Validation approach per OB-035 Q11 (default proposal: no own backend).

## User Flow
```text
Locked feature tapped → paywall (headline per trigger)
↓
User picks a plan → store purchase sheet → success → Pro active → returns to the feature
↓
(new device) paywall → [Restore purchases] → Pro active
```

## Acceptance Criteria
- Given a free user, When the paywall opens, Then monthly, yearly (with "3-day free trial" if eligible) and lifetime are shown with store-localized prices, plus "Restore purchases" and the terms links.
- Given the user completes a purchase, When the store confirms it, Then Pro is active immediately and the triggering feature unlocks.
- Given a Pro user reinstalls the app, When they tap "Restore purchases", Then Pro is active again.
- Given Pro is active and the device is offline, When the app is used within the grace period, Then Pro features remain unlocked.
- Given a subscription has expired or been refunded, When the entitlement is next validated, Then Pro features lock again.
- Given the user cancels the purchase sheet, When it closes, Then nothing changes and no error is shown.
- Given any user, When they start a purchase, Then a parental gate is shown first (OB-040 A-D3).

## Edge Cases
- Trial already used on the account; lifetime owner shown subscription options (should not be shown); purchase pending (ask to buy); store unavailable; clock changes.

## In Scope
- Products, paywall screen, purchase/restore, entitlement interface and offline cache.

## Out of Scope
- Where paywalls are triggered (OB-037, OB-039; daily limit parked in OB-035); own backend (unless decided).
- Analytics of any kind, including purchase/paywall event tracking (excluded by PO decision OB-035 M-D2).

## Dependencies
- OB-035 (Q9 trial, Q10 lifetime, Q11 validation/grace, Q12 pricing), OB-040 (parental gate), OB-034 (copy), OB-032 (license of client code).
- Store setup: App Store Connect / Play Console products (release task).
- New dependency: an in-app purchase plugin (not in `techContext.md` yet).

## Assumptions
- Store-native in-app purchases on both platforms.

## Open Questions
See OB-035 Open Questions 4–6 (deferred by PO 2026-10-02).

## Developer Handoff
- Expose a single entitlement stream (`isPro`) to the rest of the app; gating tickets depend only on it.
- Keep the paywall headline/subtitle configurable per trigger.
- Test with sandbox/test accounts; cover expiry and restore paths.
