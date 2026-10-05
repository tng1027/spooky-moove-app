# Ticket Analysis

> **Status: Done (PO accepted 2026-10-05).** One-time EN/VI notice gate with a versioned acknowledgment in `shared_preferences` (`lib/features/fair_play`); `FairPlayScreen.readOnly()` opens from the new-game screen's FAIR PLAY key (header since OB-050). Wording v4 applied and accepted 2026-10-05.

TICKET_TYPE: NEW_FEATURE
CONFIDENCE: HIGH

No fair-play notice exists (no code). The requirement is in `projectbrief.md` / `productContext.md`. On 2026-10-02 the PO delegated format and wording to the BA ("BA suggest"), so the format, behavior and draft text below are decided. The text is subject to a final legal review before store release; that review does not block development.

## Ticket Title
[Feature] Show a one-time fair-play notice that must be acknowledged before first use

## Summary
On first launch, show a full-screen fair-play notice in plain language (English or Vietnamese by device language). It states that the app is for training, study, handicap and friendly offline games, and must not be used in rated/sanctioned/tournament play without arbiter permission. The user taps "I UNDERSTAND" to continue. The notice can be re-read from the new-game screen, and is shown again when its wording version changes.

## Business Context
- Hard constraint (`projectbrief.md`); "Fair-play and ethics" (`productContext.md`).
- Handicap advisor positioning (OB-021 D1): the app suggests moves to the user, which is acceptable only in non-competitive play.
- Target users may not know chess (PO 2026-10-02), so the wording must be plain, not legalistic.

## Decision: format (PO delegated to BA recommendation, 2026-10-02)
- **Blocking first-launch screen** with a single "I UNDERSTAND" / "TÔI ĐÃ HIỂU" button. Explicit acknowledgment, no checkbox (one tap).
- Shown **once per install**, and again when the notice **wording version** changes.
- **Re-viewable** from an info key ("FAIR PLAY") on the new-game screen (OB-011). There is no settings screen in scope.
- Language: Vietnamese if the device language is Vietnamese, otherwise English.
- Design language: dark background, JetBrains Mono, high contrast, no imagery or motion; the button is a design-system key (≥ 48 dp).

## Current wording (version 4, 2026-10-05)
History: v1 initial draft; v2/v3 app renames (Ghost64, SpookyMoove); v4 PO-approved designer feedback from the compliance QA (Q33): Go federations (EGF, Nihon Ki-in) replaced by chess/xiangqi federations, since M1 ships Chess + Xiangqi only; "cheating" softened to "breaks fair-play rules".

**English**
> **FAIR PLAY**
>
> SpookyMoove is for training, casual study, handicap games and friendly offline play.
>
> Do NOT use it during rated, sanctioned or tournament games (FIDE, national chess or xiangqi federations, or any other organisation) unless the arbiter has allowed it.
>
> Using move suggestions in competitive play breaks fair-play rules and can get you disqualified. You are responsible for how you use this app.
>
> **[ I UNDERSTAND ]**

**Tiếng Việt**
> **CHƠI CỜ CÔNG BẰNG**
>
> SpookyMoove dành cho luyện tập, học cờ, chơi chấp quân và các ván giao hữu ngoài đời.
>
> KHÔNG sử dụng trong các ván đấu tính điểm, giải đấu chính thức hoặc thi đấu (FIDE, các liên đoàn cờ vua hoặc cờ tướng quốc gia, hay bất kỳ tổ chức nào khác) nếu chưa được trọng tài cho phép.
>
> Dùng gợi ý nước đi khi thi đấu là vi phạm luật chơi công bằng và có thể bị truất quyền thi đấu. Bạn chịu trách nhiệm về cách sử dụng ứng dụng này.
>
> **[ TÔI ĐÃ HIỂU ]**

## Current Behavior
Not implemented.

## Expected Behavior
As described in the format decision and the draft wording above.

## User Story
As the product owner
I want every user to acknowledge, in plain language, that the app must not be used in rated or tournament play
So that the product is positioned as a training and handicap tool, not a cheating aid.

## Functional Requirements
- REQ-001: On first launch, show the fair-play screen before anything else; the advisor is unreachable until "I UNDERSTAND" is tapped.
- REQ-002: Show the current wording (v4, `fairPlayNoticeVersion`) in the app language (OB-053; was the device language).
- REQ-003: Persist locally the acknowledged wording version; skip the screen while it matches the current version.
- REQ-004: When the current wording version is higher than the acknowledged one, show the screen again on next launch.
- REQ-005: A "FAIR PLAY" info key on the new-game screen (OB-011) opens the notice read-only (with a close action, no re-acknowledgment).
- REQ-006: Works fully offline; text is bundled.
- REQ-007: Text is scrollable at large font scales; the button stays reachable.

## Business Rules
- BR-001: Use in rated, sanctioned or tournament play without arbiter permission is forbidden (`projectbrief.md`).
- BR-002: Allowed uses: training, casual study, handicap games, friendly offline play (`productContext.md`, OB-021 D1).
- BR-003: The notice must be acknowledged before first use and after each wording-version change.

## User Flow
```text
First launch → FAIR PLAY screen → tap [I UNDERSTAND] → new-game screen (OB-011)
Later launches → straight to the app (until the wording version changes)
New-game screen → [FAIR PLAY] info key → read-only notice → close
```

## Acceptance Criteria
- Given a fresh install, When the app launches, Then the fair-play screen is shown first and no other screen is reachable (system back on Android doesn't bypass it).
- Given the device language is Vietnamese, When the notice is shown, Then the Vietnamese version-1 text and the "TÔI ĐÃ HIỂU" button are displayed; for any other language, the English text and "I UNDERSTAND".
- Given the notice is shown, When the user taps "I UNDERSTAND", Then the new-game screen opens.
- Given the user acknowledged version 1, When the app is relaunched, Then the notice is not shown.
- Given the user acknowledged version 1 and the app now ships version 2 of the wording, When the app launches, Then the notice is shown again and must be acknowledged.
- Given the app is killed while the notice is displayed, When it is relaunched, Then the notice is shown again.
- Given the new-game screen, When the user taps "FAIR PLAY", Then the notice opens read-only and closing returns to the new-game screen.
- Given airplane mode, When the notice is displayed, Then it renders fully.
- Given the largest system font scale, When the notice is displayed, Then all text is reachable by scrolling and the button is tappable.

## Edge Cases
- Reinstall / cleared app data → shown again.
- Device language changes after acknowledgment → no re-acknowledgment needed (same version).
- Very small screens → scrolling.

## In Scope
- Notice screen, acknowledgment persistence with wording version, read-only re-view, EN/VI text.

## Out of Scope
- Full Terms of Service / privacy policy documents.
- Localization of the rest of the app (not documented).
- Enforcement or detection of tournament use.

## Dependencies
- OB-003 (shell), OB-011 (info key on the new-game screen).
- Local key-value persistence (smallest option; storage choice open in `techContext.md`).
- Legal review of the text before store release (non-blocking for development).
- Note (PO compliance document, 2026-10-02): the notice text must follow the store-positioning rules in **OB-034** (no "real-time advisor/assistant", "tournament", "live game"). The current draft frames the app as "for practice, learning and casual games only" and is compatible; recheck wording during the OB-034 copy audit. If the audience includes children (OB-040), the notice may need a version aimed at parents.
- Update (OB-040 A-D1, 2026-10-02): target audience = adults. The notice addresses the device user; **no child version needed**. Text unchanged.

## Assumptions
- Plain-language wording is acceptable to legal; legal may edit it before release (→ wording version 2 if changed after shipping).
- Organisations named (v4): FIDE and national chess/xiangqi federations, matching M1 games; "any other organisation" covers federations of games added later (Go, Shogi, Gomoku, Othello). Revisit the list when a new game ships.

## Open Questions
None blocking. Non-blocking: legal review of the draft text before store release.

## Developer Handoff
- A gate before the main navigation, driven by `acknowledgedVersion < currentVersion`.
- Keep both texts and `currentVersion` in one place.
- Widget tests: fresh state shows the gate; acknowledged state skips it; a version bump re-shows it; the locale picks the language.
