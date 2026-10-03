# Ticket Analysis

> **Status: Done (2026-10-03).**
> - Project `omni_board`; Android `applicationId` / iOS bundle ID `com.thuannguyen.omniboard` (PO, answers Q3; display name "Omni Board" is a working title until OB-034).
> - Colors provisional per palette: `bgDark #0F1015`, `keyDisabled #1A1B20` (PO, Q1).
> - Layout implemented per the revised design (suggestion card / persona row 52 dp / square board / status line 48 dp), replacing the 35/10/55 criterion.
> - Fonts: JetBrains Mono bundled as asset fonts (no `google_fonts` dependency); OFL registered in `LicenseRegistry`.
> - Portrait-only on both platforms (Q4 assumption kept).
> - **Deviation:** iOS deployment target is **15.0**, Flutter 3.47's minimum (it auto-migrates 13/14 to 15). "iOS 13.0+" in the docs cannot be met with current Flutter. Android `minSdk 24` as specified.
> - `chess` 0.8.1 verified on Dart 3.13.5 (scratch test, 2026-10-03).

TICKET_TYPE: TECHNICAL_TASK
CONFIDENCE: HIGH

The repository has no Flutter project, no `pubspec.yaml`, and is not a git repository; Flutter is not installed on the dev machine. Every feature ticket needs a running app shell with the agreed design tokens, offline fonts and screen layout. This is foundation work with no new user-facing behavior beyond an empty, themed screen.

## Ticket Title
[Tech] Scaffold the Flutter app shell with design tokens, bundled fonts and hero/keypad layout

## Summary
Create the Flutter project (Android API 24+, iOS 13+) using the verified starter `pubspec.yaml`, set up the dark theme from `designSystem.md`, bundle JetBrains Mono for offline use, and render the empty portrait layout (hero ~35% / status ~10% / keypad ~55%).

## Business Context
- `activeContext.md` Next steps 0–1.
- `progress.md`: "Flutter project scaffold (pubspec.yaml, theme tokens, bundled fonts)" — not started.
- 100% offline is a core goal; `google_fonts` fetches fonts at runtime by default, which would break it (`techContext.md` → Gotchas).

## Current Behavior
- No source code, no `pubspec.yaml` file (the starter pubspec exists only as a snippet inside `techContext.md`).
- No git repository.
- Flutter SDK not installed (verified 2026-10-02).

## Expected Behavior
- A Flutter app that builds and launches on Android (API 24+) and iOS (13.0+).
- Launching shows a dark screen with three regions in portrait: hero/suggestion placeholder (~35%), status/spacing (~10%), keypad placeholder (~55%).
- All text uses bundled JetBrains Mono with tabular figures; the app makes no network request for fonts.
- Theme tokens from `designSystem.md` are defined in one place.

## Business Rules
- BR-001: The app must not perform any network request at startup or for fonts (offline goal).
- BR-002: Dark theme by default; color tokens carry meaning (green = good, red = danger, amber = selected) and are not used decoratively.
- BR-003: Corner radius 4–6 px; no shadows, gradients or blur.

## User Flow
```text
User launches app
↓
App starts without network access
↓
Dark themed screen with hero / status / keypad regions is shown
```

## Acceptance Criteria
- Given a device on Android 7.0 (API 24), When the app is installed and launched, Then it starts and shows the three-region layout.
- Given a device on iOS 13.0, When the app is installed and launched, Then it starts and shows the three-region layout.
- Given the device is in airplane mode on first launch, When the app starts, Then all text renders in JetBrains Mono (no fallback font) and no network request is attempted.
- Given a portrait phone screen, When the main screen renders, Then the hero region is ~35%, the status region ~10% and the keypad region ~55% of the available height.
- Given any numeric text in the shell, When it is rendered, Then it uses tabular (fixed-width) figures.
- Given the project, When static analysis runs with `flutter_lints`, Then there are no errors or warnings.

## Edge Cases
- Small screens (e.g. 4.7") — keypad region must still allow 48 dp minimum key height in later tickets; flag if it cannot.
- System light mode enabled — app still shows the dark theme (see Open Questions).
- Large system font scale — text must not overflow the hero region.

## In Scope
- Install Flutter (Dart ≥ 3.13) — environment prerequisite.
- Initialize git repository with a Flutter `.gitignore`.
- `flutter create` with Android `minSdk 24`, iOS deployment target 13.0.
- `pubspec.yaml` with the verified versions from `techContext.md` (only packages needed now may be added; others when their ticket starts).
- `AppColors` tokens, typography (JetBrains Mono, tabular figures), shape tokens, `ThemeData`.
- Bundled font assets + `GoogleFonts.config.allowRuntimeFetching = false` (or direct asset font usage).
- Riverpod `ProviderScope` at the root.
- Empty main screen layout with the three regions.
- Portrait orientation (see Open Questions).

## Out of Scope
- Keypad logic, suggestion logic, engine integration.
- Game selection screen.
- App icon, splash screen, store metadata.
- CI pipeline.

## Dependencies
- Flutter SDK installation on the dev machine.
- `designSystem.md`, `techContext.md`.
- Note (2026-10-02, OB-006 BR-006): the input region is now a full-width square tap board, not a 55% keypad. Shell layout regions: suggestion card (top, ~25%) → persona row (52 dp) → square board → status line. The three-region 35/10/55 acceptance criterion is superseded by this layout (memory bank `designSystem.md` update pending).
- Note (PO compliance document, 2026-10-02): Open Question 3 (app name) is affected by **OB-034**. The working title "OmniChess Advisor" contains "Advisor", close to the banned "real-time advisor/assistant" positioning; the final name should come from OB-034 before store setup.

## Assumptions
- Package name `omnichess_advisor` from the starter pubspec is acceptable (working title — see Open Questions).
- The app is portrait-only, based on `designSystem.md` describing only a portrait layout.

## Open Questions
1. **Color tokens (design):** `keyDisabled` is `#1A1B20` in the palette but `#16171E` in the sample code. Which is final? (Also: `bgDark` `#0F1015` or true black `#000000`?) Non-blocking: developers may use the palette table values provisionally and swap later.
2. **Light mode:** `productContext.md` says "dark mode by default"; `designSystem.md` says "dark mode only by default". Is a light theme ever in scope?
3. **App name / bundle ID:** "OmniChess Advisor" is a working title; repo is `omni-board`. What are the final display name and application ID / bundle identifier?
4. **Orientation:** Portrait-only confirmed? Tablets?

## Developer Handoff
- Follow `techContext.md` starter pubspec (Riverpod 3, archive 4, google_fonts 9, ffigen 22). Consider loading JetBrains Mono directly as an asset font rather than via `google_fonts` if that removes a dependency; either way it must be offline.
- Put tokens in a single theme module; widgets must reference tokens, not hex literals.
- Leave hero and keypad regions as placeholder widgets that OB-006/OB-007 will replace.
- Add a widget test that pumps the main screen and asserts the three regions exist.
