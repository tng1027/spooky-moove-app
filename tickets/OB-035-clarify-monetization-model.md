# Ticket Analysis

TICKET_TYPE: NEEDS_CLARIFICATION
CONFIDENCE: HIGH

**Status: DEFERRED by PO (2026-10-02).** This is the **single log ticket** for monetization. It records the decisions taken and parks every open monetization question, including the daily free limit (merged from OB-038, per PO answer #2: "log tạm vào 1 ticket, sẽ consider sau"). OB-036, OB-037 and OB-039 are kept as deferred drafts; OB-038 is superseded by this ticket.

## Ticket Title
[Clarification] Monetization model (freemium) — decisions log and deferred questions

## Summary
The PO's compliance document §3 proposes a freemium model: subscription, lifetime purchase, persona-tier gating, a 25/day free limit, and game gating. The PO has decided to **build the full-feature version first**. Monetization is not in the Chess DoD and not in the M1 build scope for now. This ticket keeps the proposal, the recorded decisions, the known conflicts and the open questions in one place until the PO resumes it.

## Business Context
PO document §3 (2026-10-02), kept for reference:
- **Pricing:** $2.99/month or $19.99/year (3-day free trial); lifetime $39.99.
- **Tier gating:** free = 🐥 Soft, 🥉 Even, 🥈 Solid; Pro = 🥚 Baby, 🐣 Gentle, 🥇 Master, 👑 God.
- **Daily limit:** `freeDailyMoveLimit = 25`; after 25 → paywall.
- **Paywall 1** (🥚/🐣): "Mở khóa Chế độ Rèn luyện Nhẹ nhàng — Giúp bé luôn tự tin và hứng thú khi chơi cờ cùng bố mẹ."
- **Paywall 2** (👑): "Mở khóa Sức mạnh Động cơ Tối đa — Khai thác trọn vẹn trí tuệ nhân tạo ở độ sâu cao nhất."
- **Paywall 3:** Chess and Caro free; Xiangqi and Go Pro.

## Decisions (PO, 2026-10-02)
| # | Decision | Source |
|---|----------|--------|
| M-D1 | **Monetization deferred.** Build the full-feature version first: every game and every tier is available to every user. Monetization is out of the Chess DoD and out of the current M1 build scope. | PO answer #1 ("tập trung vào phiên bản full feature trước") |
| M-D2 | **No analytics.** No usage tracking, no conversion-funnel measurement, no analytics SDK. The offline/privacy commitment ("no server dependency, full privacy", `projectbrief.md`) stands. | PO answer #6 ("không analytics") |
| M-D3 | **Shogi and Othello will be Pro** when monetization is introduced (details later). With the PO document: Pro = Xiangqi, Go, Shogi, Othello; free = Chess, Caro. | PO answer #4 ("sẽ PRO nhưng tính sau") |
| M-D4 | Daily-limit question logged here (merged from OB-038), to be considered later. | PO answer #2 |
| M-D5 | Audience and parental gate decided by BA recommendation → OB-040. Parental gate before any future purchase flow. | PO answer #8 (delegated) |

**Out of scope as a result of M-D2:** conversion-funnel measurement, paywall view/purchase event tracking, A/B testing of prices or copy. Any future monetization must work without analytics.

## Current Behavior
No monetization anywhere; nothing implemented.

## Expected Behavior
Nothing to build now. When the PO resumes monetization, the deferred questions below are answered and OB-036, OB-037 and OB-039 are re-reviewed (plus a new or revived limit ticket if a limit is kept).

## Known conflicts (kept for when the topic resumes)
| # | Conflict | Detail |
|---|----------|--------|
| C1 | 25/day vs. game length | ~40 user moves per chess game → a free user cannot finish one game per day if 1 unit = 1 suggestion. |
| C2 | Counting rules undefined | Recomputes (tier change, OB-021 R6; undo; retry), behavior at the limit, reset time/timezone, offline clock changes. |
| C3 | Tier gating vs. "no default tier" | OB-021 D5; locked-tier UX not designed (OB-023). |
| C4 | Game gating vs. milestones | Xiangqi in M1 but Pro; Caro free but post-M1. |
| C5 | Offline-first vs. purchases | Store needed for purchase/restore; offline grace policy needed; an own backend would add a server dependency. |
| C7 | Paywall 2 copy vs. engine limits | "Độ sâu cao nhất" contradicts OB-021 D14 (≤ 1000 ms, 2 threads). |
| C8 | Paywall 1 vs. positioning | The marketed family use case (Baby/Gentle) would be paid; the listing must say so (OB-034). |
| C10 | Lifetime + subscriptions | Family sharing, refunds, upgrade paths undefined. |
(C6 analytics and C9 audience are resolved by M-D2 and OB-040.)

## Business Rules
- BR-001: No analytics or tracking of any kind (M-D2).
- BR-002: Until monetization resumes, every game and every tier is available to every user (M-D1).

## User Flow
Not applicable.

## Acceptance Criteria
- Given the full-feature build, When any game or tier is chosen, Then it is available without purchase, limit or lock (M-D1).
- Given any build, When network traffic and dependencies are reviewed, Then no analytics or tracking SDK or event is present (M-D2).
- Given the PO resumes monetization, When the deferred questions are answered, Then OB-036/OB-037/OB-039 are updated to testable acceptance criteria.

## Edge Cases
Parked until resumed: trial already used, Pro expiry mid-game, lifetime + subscription, refunds, family sharing, offline for days, reinstall, clock changes.

## In Scope
- Decisions log and deferred questions for monetization.

## Out of Scope
- Any implementation now (M-D1); analytics of any kind (M-D2); legal opinions (OB-032, OB-040).

## Dependencies
- OB-021 (tiers), OB-011 (game list), OB-034 (copy), OB-040 (parental gate), OB-032 (client license affects "closed-source monetization logic").

## Assumptions
- Store-native purchases only, if and when monetization is built.

## Open Questions — all **Deferred by PO 2026-10-02**
1. **Daily limit (merged from OB-038):** unit (suggestions per new user turn vs. games per day), value 25 vs. ~40 user moves per game, whether recomputes count, behavior at the limit (BA proposal: move entry keeps working, suggestions replaced by an upgrade prompt), reset at local midnight, acceptance of clock/reinstall bypass.
2. **Locked tiers:** visible with a lock (BA proposal) vs. hidden; behavior when Pro expires mid-game.
3. **Game gating details:** Shogi/Othello Pro confirmed (M-D3); gate pack downloads or only play?
4. **Trial plan(s), lifetime scope (future games?), family sharing.**
5. **Validation:** store-only on device (BA proposal: no own backend) and offline grace length.
6. **Pricing localization** (store price tiers, e.g. VND).
7. **Copy:** Paywall 2 accurate wording; 🥇 Master and Paywall 3 copy (with OB-034).

## Developer Handoff
- **Nothing to build now.** Do not add an in-app purchase plugin, entitlement layer or paywall.
- **Design guardrail (non-functional, lightweight):** keep "which games and tiers are offered" as data in one place (the game list used by OB-011 and the tier list used by OB-023/OB-022), not as scattered hard-coded checks in widgets. In the full-feature build everything is simply available. This keeps a later gating step cheap; it is **not** a mandate to build an entitlement abstraction now.
- No analytics SDKs, crash reporters that send usage data, or remote config (M-D2). Any crash-reporting idea needs a separate PO decision.
