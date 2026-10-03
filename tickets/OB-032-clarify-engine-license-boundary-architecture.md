# Ticket Analysis

TICKET_TYPE: NEEDS_CLARIFICATION
CONFIDENCE: HIGH

The PO's "Legal, Architecture & Monetization Compliance Document" (2026-10-02) mandates an **IPC process separation** architecture: a closed-source Flutter app talking over stdin/stdout to a separate GPL engine process started with `Process.start`, and no embedding of engine C++ via Dart FFI. This conflicts with a platform constraint (iOS), with the current plan (OB-004 builds the engine as an in-process library over FFI), and with memory-bank notes. Whether process separation achieves the intended license boundary is a **legal question for counsel**, not a settled fact. This ticket collects the decisions needed. It is **blocked by counsel**. Nothing here is legal advice.

## Ticket Title
[Clarification] Decide the per-platform engine integration architecture and the GPL license boundary (requires legal counsel)

## Summary
Get counsel's opinion and a PO decision on (1) whether the app can stay proprietary while bundling GPLv3 engines, and under which architecture, (2) what to do on iOS, where separate engine processes are not available, and (3) whether GPLv3 distribution through the App Store is acceptable. Engineering then adjusts OB-004/OB-005.

## Business Context
- The PO wants the Flutter client (UI, state, persona decision engine, monetization/IAP logic) to stay **closed source**, and the engines (GPLv3) to be published separately.
- The PO wants to **sell** the app (subscriptions, lifetime; OB-035).
- Engines in scope: Fairy-Stockfish (GPLv3), Edax (GPLv3), KataGo (**MIT**, see below), Gomoku engine TBD (Yixin is not open source).

## Current Behavior
- Planned (OB-004): Fairy-Stockfish compiled **into the app as a library**, driven over **Dart FFI** from a background isolate, with in-process pipes. That is the only model that works on iOS (`activeContext.md`: "iOS cannot spawn child processes").
- `activeContext.md`: "Fairy-Stockfish and Edax are GPLv3. That requires publishing the app's source under GPL, and GPL is widely seen as conflicting with App Store terms. KataGo is MIT (no issue)."
- OB-002 (licensing strategy) is open.

## Expected Behavior
A recorded decision, per platform, covering the Open Questions below, after counsel review. OB-004/OB-005 are then confirmed or re-planned.

## Findings to verify (BA analysis, not legal advice)
| # | Claim in the requirement | BA finding | Needs |
|---|--------------------------|------------|-------|
| F1 | Engines run as a separate child process via `Process.start` with stdin/stdout pipes | **Not feasible on iOS.** iOS apps cannot spawn child processes or run bundled standalone executables, and Dart's `Process.start` is not available there. Apple also forbids executing downloaded code (`projectbrief.md`). On **Android** it is technically feasible: a bundled executable shipped in the app's native-library directory can be started as a process. | Engineering confirmation (spike); PO decision for iOS |
| F2 | Process separation keeps the Flutter app free of GPL obligations | **Unsettled legal question.** The engine binary would still be distributed inside the same app package, through the same store, by the same publisher. Whether that is "mere aggregation" or a combined work is for counsel. | **Counsel** |
| F3 | GPLv3 apps may be sold on the App Store and Google Play | Selling is permitted by GPLv3 itself. Compatibility of GPLv3 with **App Store** terms is **contested** (store usage rules add restrictions; GPL apps have been removed from the App Store in the past). Google Play is generally considered less problematic. | **Counsel** |
| F4 | Stockfish, Fairy-Stockfish, **KataGo** are GPLv3 | Stockfish and Fairy-Stockfish: GPLv3 ✔. **KataGo is MIT**, not GPL (`techContext.md`, `activeContext.md`). Edax: GPLv3. Yixin: not open source — needs permission (`activeContext.md`). | Correct the requirement |
| F5 | "Do not embed engine C++ via FFI if it blurs the license boundary" | OB-004 does exactly that, because it is the only iOS-viable option. If counsel requires process separation, iOS cannot ship these engines as planned. | PO + counsel |
| F6 | Closed-source monetization and persona logic | Depends on F2/F3. If counsel concludes the app must be GPL, the client code becomes open source. That does not forbid selling or IAP, but the code is public. | PO decision after counsel |

## Options for the PO and counsel (not recommendations of legal strategy)
- **O1 — Process separation on Android; iOS undecided.** Android: engine as a separate executable process. iOS: needs O2, O3 or O4.
- **O2 — App released under GPLv3 (source published) on both platforms.** In-process FFI stays (OB-004). Monetization still allowed; App Store compatibility per F3.
- **O3 — Replace GPL engines on iOS (or everywhere)** with permissively licensed or commercially licensed engines. Engine quality and availability to be assessed per game.
- **O4 — Android-only for GPL-engine games** until the iOS question is resolved.

## Business Rules
None decided. Constraint: Apple's rule against downloaded executable code (`projectbrief.md`).

## User Flow
Not user-facing.

## Acceptance Criteria
- Given F1–F6, When counsel reviews them, Then a written opinion is recorded covering: the license boundary (in-process vs. separate process when bundled), GPLv3 + App Store compatibility, and obligations (source offer, notices, Settings/About links).
- Given the opinion, When the PO chooses an option (O1–O4 or other) per platform, Then the decision is recorded in `activeContext.md`/`techContext.md` (by PO/BA) and OB-004/OB-005 are confirmed or re-planned.
- Given the decision, When OB-033 (licenses screen) is implemented, Then its content matches counsel's notice requirements.

## Edge Cases
- Different decisions per platform (Android process separation, iOS GPL or different engines).
- Mid-project change: OB-004 work done as an in-process library may need rework for Android process separation.
- Third-party Dart packages under GPL (e.g. `dartchess`, OB-002 Q3) inside the client would affect the client's license regardless of engine architecture.

## In Scope
- Legal questions, platform feasibility, architecture decision per platform.

## Out of Scope
- Implementation (OB-004/OB-005 follow the decision).
- Store listing copy (OB-034).

## Dependencies
- **Legal counsel (blocking).**
- OB-002 (licensing strategy; this ticket refines it for architecture).
- OB-004 (engineering spike: confirm Android process feasibility and iOS constraints).
- Note (PO answers 2026-10-02): **counsel assignment deferred** ("tính sau"). This ticket stays a **release blocker**: no store submission until it is decided. **Development continues with the current design**: Fairy-Stockfish in-process over FFI (OB-004), behind the transport-agnostic engine interface (OB-005). No other change to the engineering plan.
  - **Risk if counsel later mandates process separation:** feasible on **Android only**. Rework there is limited to a new line transport (child process) plus packaging, and the protocol adapters and UI are unchanged. On **iOS** no compliant path exists with GPL engines under process separation, so it would force O2 (app under GPLv3), O3 (different engines) or O4 (Android-only), possibly delaying the iOS release.
  - Monetization is deferred (OB-035 M-D1), so the "closed-source monetization logic" argument is less urgent for M1. The client-license question (F2/F3) still applies to the persona logic and UI.

## Assumptions
- The PO wants both iOS and Android (`projectbrief.md`).
- Engines are used unmodified, or with modifications that are published.

## Open Questions
1. **(Counsel)** Does running a bundled GPLv3 engine as a separate process, communicating over UCI/USI/GTP text pipes, keep the Flutter client outside the GPL when both ship in one app package?
2. **(Counsel)** Is distributing GPLv3 code through the Apple App Store acceptable under GPLv3 and Apple's terms? Through Google Play?
3. **(Counsel)** What exactly must be provided: source of the exact engine version, written offer, license texts, build scripts, notices in Settings/About?
4. **(PO)** iOS strategy given F1: O2, O3 or O4?
5. **(PO)** If the client must be GPL, is that acceptable for the business (monetization still allowed, code public)?
6. **(PO)** Correct the requirement: KataGo is MIT. Is the Gomoku engine choice (Yixin permission vs. open engine) part of this decision (OB-017)?

## Developer Handoff
- Until decided: continue OB-004 as a **spike**, and keep OB-005's engine interface **transport-agnostic** (text-protocol adapter over an abstract line transport: in-process pipe or child process). Then either architecture can be plugged in without touching the protocol adapters or the UI.
- Android spike option: verify that a bundled engine executable can be started as a separate process on API 24+ and current Android versions (packaging and execution restrictions).
- Do not adopt GPL Dart packages (e.g. `dartchess`) in the client until this and OB-002 are decided.
