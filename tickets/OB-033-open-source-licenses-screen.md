# Ticket Analysis

TICKET_TYPE: NEW_FEATURE
CONFIDENCE: MEDIUM

No About / open-source licenses screen exists (no code), and none is documented in the memory bank. The PO's compliance document requires "Settings → About / Open Source Licenses" with links to the engines' source repositories (GPLv3). There is no Settings screen in scope, so the entry point must be defined. Confidence is MEDIUM because the exact notice content depends on counsel (OB-032 Q3).

## Ticket Title
[Feature] Show an About / Open Source Licenses screen with engine license texts and source links

## Summary
Provide an About screen, reachable from the new-game screen, listing the app version and every bundled engine and open-source package: name, version, license, license text (offline) and a link to the corresponding source repository/version.

## Business Context
- PO compliance document (2026-10-02), §1.2: "Settings → About / Open Source Licenses" must link to the engine's open-source repo per GPLv3.
- Engines: Fairy-Stockfish (GPLv3) in M1; later Edax (GPLv3), KataGo (MIT), Gomoku engine (TBD).
- Offline-first app (`projectbrief.md`): license texts must be readable offline; links need network.

## Current Behavior
Not implemented. There is no Settings screen; the new-game screen (OB-011) hosts a "FAIR PLAY" info key (OB-008).

## Expected Behavior
- An "ABOUT" key on the new-game screen, next to "FAIR PLAY", opens the About screen.
- The About screen shows: app name and version; a list of engines (name, exact version, license, "View license" (bundled text), "Source code" link to the exact version); then "Open-source packages" (Flutter's standard license list).
- Content and wording follow counsel's requirements (OB-032 Q3).

## User Story
As a user or rights holder
I want to see which open-source engines the app uses, under which licenses, and where their source code is
So that the app's license obligations are met and transparent.

## Functional Requirements
- REQ-001: "ABOUT" entry on the new-game screen (OB-011).
- REQ-002: Show app name and version/build.
- REQ-003: For each bundled engine: name, version, license name, full license text (bundled, offline), and a link to the source of that exact version.
- REQ-004: List all open-source packages used by the app, with licenses (offline). This explicitly includes the Chess rules library **`chess`** (Dart port of chess.js, BSD-2-Clause/MIT), with its copyright notice and full license text. That attribution is required even if the file is vendored (OB-006 REQ-016).
- REQ-005: External links open the system browser; offline → a clear "no connection" message, license texts still readable.
- REQ-006: If counsel requires a written source offer or additional notices, display them here (OB-032 Q3).
- REQ-007: Every external link is behind a parental gate (OB-040 A-D3, decided 2026-10-02). This ticket builds the reusable offline gate.

## Business Rules
- BR-001: Every bundled GPL engine is listed with its license and source location (PO document §1.2; counsel to confirm the exact form).
- BR-002: License texts are available offline.
- BR-003: Design language per `designSystem.md`.

## User Flow
```text
New-game screen → [ABOUT] → About screen
↓
Engine "Fairy-Stockfish <version> — GPLv3" → [VIEW LICENSE] (offline text) / [SOURCE CODE] (browser)
↓
"Open-source packages" → license list
```

## Acceptance Criteria
- Given the new-game screen, When the user taps "ABOUT", Then the About screen shows the app name and version.
- Given the M1 build, When the About screen is shown, Then Fairy-Stockfish is listed with its exact bundled version, "GPLv3", a "View license" action and a "Source code" link.
- Given the M1 build, When the package list is shown, Then `chess` appears with its license name and full license text, readable offline.
- Given airplane mode, When the user opens "View license", Then the full license text is displayed.
- Given airplane mode, When the user taps "Source code", Then a "no connection" message appears and the app doesn't crash.
- Given online, When the user taps "Source code", Then the system browser opens the repository at the bundled version.
- Given the About screen, When the user opens "Open-source packages", Then all Dart/Flutter packages and their licenses are listed.
- Given any user, When they tap an external link, Then a parental gate is shown first, and only a correct answer opens the link (OB-040 A-D3).
- Given the parental gate, When the user cancels or answers wrongly, Then nothing opens and the ABOUT screen stays visible.

## Edge Cases
- Engine modified for the app (e.g. C shim) → the link must point to the modified source if counsel requires it.
- Later games add engines (Edax, KataGo, Gomoku) → each game phase updates the list.

## In Scope
- About screen, engine list, offline license texts, package licenses, entry point.

## Out of Scope
- Hosting/publishing the engine source repository (release task; OB-034 checklist).
- Legal wording (counsel).

## Dependencies
- OB-011 (entry point), OB-032 (counsel: required notices), OB-040 (parental gate before external links — decided A-D3).
- Note (PO answers 2026-10-02): this ticket stays in the **release-readiness** track; it is **not** deferred with monetization. The final engine list depends on OB-032 (counsel, deferred); build against the current engine set (Fairy-Stockfish for M1).

## Assumptions
- The new-game screen is the right entry point (no Settings screen in scope). If the PO adds a Settings screen later, the entry point moves there.

## Open Questions
1. (Counsel, via OB-032 Q3) Exact notice content: link only, or also a written offer and build instructions?
2. (PO) Is a Settings screen wanted at all? Default: no; the About entry lives on the new-game screen.

## Developer Handoff
- Use Flutter's built-in license registry for packages; add engine entries with bundled license assets.
- Keep the engine list data-driven, so each game phase adds its engine entry.
