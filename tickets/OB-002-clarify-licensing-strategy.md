# Ticket Analysis

TICKET_TYPE: NEEDS_CLARIFICATION
CONFIDENCE: HIGH

The core engine (Fairy-Stockfish) and the Othello engine (Edax) are GPLv3. The recommended maintained chess rules package (`dartchess`) is also GPL-3.0. The memory bank flags that GPL may require publishing the app source and is widely seen as conflicting with App Store terms, and that Yixin (Gomoku) is not open source. This is a business/legal decision that affects engine choice, dependency choice, and whether the product can ship on iOS at all. It cannot be decided by engineering.

## Ticket Title
[Clarification] Decide the licensing strategy for GPL engines and proprietary Gomoku engine

## Summary
Get a PO/legal decision on how the app is licensed and distributed given GPLv3 engines (Fairy-Stockfish, Edax), a GPL rules library option (`dartchess`), and a closed-source Gomoku engine (Yixin).

## Business Context
- Fairy-Stockfish powers Chess, Xiangqi and Shogi — three of six games and the entire Milestone 1 (`systemPatterns.md`).
- The app targets both App Store and Play Store (`projectbrief.md`).
- `activeContext.md` → "Licensing: decide the licensing strategy before shipping."
- `techContext.md` → `chess` package is stale (last release 2023-10); `dartchess` is maintained but GPL-3.0.

## Current Behavior
No decision recorded. No code exists.

## Expected Behavior
A recorded decision in the memory bank covering the open questions below, so that OB-004 (engine build), OB-006 (rules library choice), OB-017 (Gomoku engine) and OB-018 (Othello) can proceed on a known basis.

## Business Rules
None defined until decided.

## User Flow
Not applicable (business/legal decision).

## Acceptance Criteria
- Given the licensing questions below, When the PO (with legal input if needed) decides, Then the decision is recorded in `activeContext.md` / `techContext.md`.
- Given the decision, When a developer picks between `chess` and `dartchess`, Then the choice follows the recorded decision without further PO input.
- Given the decision, When the Gomoku engine is chosen (OB-017), Then the choice is consistent with it (Yixin with permission, or an open engine such as Rapfi, or custom).

## Edge Cases
- GPL accepted on Android but not iOS → platform-specific distribution or engine strategy.
- Licensing changes after Milestone 1 ships → would force engine replacement late.

## In Scope
- Licensing model of the app (proprietary vs. GPL open source).
- Acceptability of GPL engines/libraries on each store.
- Gomoku engine licensing (Yixin permission vs. alternative).
- Required attributions / license screen (whether it is needed in the app).

## Out of Scope
- Engineering of any engine.
- Store listing and pricing.

## Dependencies
- PO and legal counsel.
- Note (PO answer 2026-10-02): Q3 (rules library) is **deferred** ("sẽ quyết định sau"). OB-006 proceeds against a rules-module interface; the decision is needed before the concrete Chess rules module is implemented. Bundled piece pictograms (OB-006/OB-007) also need a license-compatible asset set.
- **Q3 resolved for Chess (PO decision 2026-10-02):** Chess rules library = Dart package **`chess` 0.8.1** (pub.dev; port of chess.js; BSD-2-Clause/MIT as stated by the PO; permissive, so not affected by the GPL question in OB-032). Attribution goes on the licenses screen (OB-033). Evidence and risks: OB-006 "Concrete rules module". **Still open:** rules modules/libraries for Xiangqi, Shogi, Gomoku/Caro, Othello and Go (decided in their phases).
- Note (Phase 2, 2026-10-03): **Q3 resolved for Xiangqi (PO 2026-10-03, XQ11):** hand-written pure-Dart rules module, no new dependency (OB-043). Xiangqi piece glyph assets must be OFL or permissive and attributed in OB-033 (OB-044).
- Note (PO compliance document, 2026-10-02): the PO proposes keeping the client closed by running GPL engines as separate processes (IPC). Feasibility and legal effect are analysed in **OB-032** (blocked by counsel); Q1/Q2 here are now tracked there. Q5 (license screen) → **OB-033** (required by the PO). Q6 (business model) is answered: freemium with subscription and lifetime (**OB-035**). Store positioning → **OB-034**.
- Update (PO 2026-10-02): monetization deferred (OB-035 M-D1); counsel assignment deferred (OB-032 remains a release blocker). Development continues with the FFI design (OB-004).

## Assumptions
- The product intends to ship on both iOS App Store and Google Play.

## Open Questions
1. Is the app willing to be released as GPLv3 open source (source published)? If not, which engine replaces Fairy-Stockfish for Chess/Xiangqi/Shogi?
2. Is App Store distribution of a GPLv3 app acceptable to the business given the known conflict, or is iOS GPL-free / out of scope?
3. Rules library: `dartchess` (GPL, maintained) or `chess` (stale, permissive) or a hand-written module?
4. Gomoku: seek Yixin permission, use an open engine (e.g. Rapfi — license to be verified), or build a custom engine?
5. Is an in-app "open source licenses / attributions" screen required?
6. Does the business model (free, paid, ads, IAP) affect the answer? (Not documented anywhere.)

## Developer Handoff
No implementation. Until decided, OB-004 can proceed as a technical spike with Fairy-Stockfish (it is the documented engine), but nothing should be published to a store. Keep the rules library behind the rules module boundary so it can be swapped.
