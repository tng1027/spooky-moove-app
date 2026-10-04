# Ticket Analysis

> **Status: Done on iOS simulator (2026-10-04).** Home header `[SETTINGS] PICK A GAME [LANGUAGE]`; `SettingsDialog` (`NO SETTINGS YET`) and `LanguageDialog` (`AppLanguage.english` only) on the shared `AppDialog`. Release gate D1 still applies before submission.
>
> Previous status: Ready for development (2026-10-04). All open questions are answered by the PO (see Decisions). No separate design pass needed: the header reuses the OB-050 pattern and both dialogs follow `NewGameConfirmDialog`. Settings content is still "decided later" by the PO; this ticket ships the entry points and dialog shells, with a release gate (D1).

TICKET_TYPE: NEW_FEATURE
CONFIDENCE: HIGH

Neither a Settings entry nor a language choice exists. The app has no settings, and only the fair-play notice is bilingual, picked by the device language (OB-008 REQ-002, `FairPlayNoticeText.forLanguage`). README Gap 10 ("No Settings screen") and Open Question 9 (app language) were open, and OB-033 assumed "no Settings screen". So this is a new user-facing capability, not an enhancement or duplicate.

## Ticket Title
[Feature] Home header: SETTINGS key (top-left) and LANGUAGE key (top-right), each opening a small dialog

## Summary
Home's header becomes `[SETTINGS]  PICK A GAME  [LANGUAGE]`. SETTINGS opens a small dialog for on/off settings; it ships with `NO SETTINGS YET` until content is decided. LANGUAGE opens a small dialog to pick the app language; English is the only option for now.

## Business Context
- PO request 2026-10-04, items 1 and 2:
  - "in Home screen, at the top left corner is a Setting toggle. Click on it will open a small modal to turn on/turn off settings. The content of setting modal will be decided later"
  - "in Home screen, at the top right corner is a Language toggle. Click on it will open a small modal to pick Language. Currently, we support English only"
- Gives future settings and the "Settings → About / Open Source Licenses" entry from the PO compliance document (OB-033, D3) a home, and prepares for localization (README Open Question 9).

## Current Behavior
Source: `home_screen.dart`, `fair_play_screen.dart`, `fair_play_notice.dart`, `new_game_key.dart` (dialog pattern), OB-049 Design.
- Home header (48 dp row): conditional `BACK` key top-left (removed by OB-050), title `PICK A GAME` left-aligned; trailing corner empty, reserved by OB-049 for a future ABOUT key (OB-033).
- No settings exist and nothing besides the fair-play acknowledgement is persisted (`shared_preferences`).
- Language: all UI is English. The fair-play notice shows Vietnamese on a Vietnamese device, English otherwise. No in-app language choice.
- Small-dialog precedent: `NewGameConfirmDialog` (`Dialog`, `surfaceDark`, radius token, `AppKey` buttons).

## Expected Behavior
- Home header, three-slot layout (OB-050 BR-001): `SETTINGS` key left, `PICK A GAME` centred, `LANGUAGE` key right. No BACK key in any state (OB-050 D1).
- SETTINGS → small dialog titled `SETTINGS`, a list area for on/off rows (empty for now, shows `NO SETTINGS YET`), and a `CLOSE` key.
- LANGUAGE → small dialog titled `LANGUAGE` listing `ENGLISH` (selected) and a `CLOSE` key. Picking the selected language just closes it.

## User Story
As a player
I want Settings and Language within reach from Home
So that I can adjust the app once options exist and pick my language when more are offered.

## Functional Requirements
- REQ-001: Home header shows `SETTINGS` in the leading corner and `LANGUAGE` in the trailing corner, `PICK A GAME` centred. Text labels, no icons (D4). Corner keys ≥ 48 dp, ≤ 30 % of the width, labels scale down (OB-050 header pattern).
- REQ-002: Tapping `SETTINGS` opens a small dialog titled `SETTINGS` with a `CLOSE` key. Barrier tap and system back also close it. A double tap opens one dialog.
- REQ-003: The Settings dialog renders its entries from one data list. With an empty list it shows the line `NO SETTINGS YET` (D1).
- REQ-004: Tapping `LANGUAGE` opens a small dialog titled `LANGUAGE` listing every supported language from one data list (today: `ENGLISH`), the current one shown selected, plus `CLOSE`. Barrier tap and system back close it.
- REQ-005: Choosing a language closes the dialog and applies it. With English as the only option, nothing changes and nothing is persisted.
- REQ-006: The fair-play notice keeps following the device language (OB-008 REQ-002) until a second app language ships (D2).
- REQ-007: Semantics: keys announced "Settings" and "Language" as buttons; dialog titles as headers; the selected language announced as selected.

## Business Rules
- BR-001: Supported languages and the Settings entries are each data in one place (README guardrail style); no hard-coded checks in widgets.
- BR-002: Language names are shown in their own language (`ENGLISH`; later e.g. `TIẾNG VIỆT`) so users can find their language.
- BR-003: Opening or closing either dialog never changes app state, and both are available only on Home (PO scope).
- BR-004: Design system: tokens only, Latin labels, text labels on keys, dark theme, no decorative motion, keys ≥ 48 dp, 360 dp × text scale 2.0 without overflow. No haptic on opening dialogs (matches navigation keys).
- BR-005 (release gate, D1): before store submission the Settings dialog has at least one real entry (a setting, or the ABOUT row from OB-033), or the SETTINGS key is hidden.

## User Flow
```text
Home: [SETTINGS]  PICK A GAME  [LANGUAGE]
↓ tap SETTINGS
Dialog: SETTINGS / NO SETTINGS YET / [CLOSE]
↓ CLOSE (or barrier tap / back) → Home

↓ tap LANGUAGE
Dialog: LANGUAGE / [ENGLISH (selected)] / [CLOSE]
↓ ENGLISH or CLOSE → Home (unchanged)
```

## Acceptance Criteria
- Given the Home screen, When it renders, Then `SETTINGS` is in the top-left corner, `PICK A GAME` in the centre and `LANGUAGE` in the top-right corner, there is no BACK key, and the CHESS / XIANGQI keys are unchanged.
- Given Home reached after discarding a game (OB-050), When it renders, Then the header is the same: `SETTINGS`, `PICK A GAME`, `LANGUAGE`, no BACK key.
- Given the Home screen, When the user taps `SETTINGS`, Then a small dialog titled `SETTINGS` opens over Home showing `NO SETTINGS YET` and a `CLOSE` key.
- Given the Settings dialog, When the user taps `CLOSE`, taps outside it, or uses system back, Then the dialog closes and Home is unchanged.
- Given the Home screen, When the user taps `LANGUAGE`, Then a small dialog titled `LANGUAGE` lists exactly one option, `ENGLISH`, shown as selected, plus `CLOSE`.
- Given the Language dialog, When the user taps `ENGLISH`, Then the dialog closes and all text stays English.
- Given a device set to Vietnamese, When the fair-play notice is shown (first launch or FAIR PLAY re-view), Then it is still in Vietnamese (OB-008 unchanged, D2).
- Given the Home screen, When the user double-taps `SETTINGS` or `LANGUAGE`, Then exactly one dialog opens.
- Given a screen reader, When focus moves over the Home header, Then it announces "Settings, button", "Pick a game, header", "Language, button".
- Given 360 × 640 at text scale 2.0, When Home and both dialogs render, Then nothing overflows, every key stays ≥ 48 dp tall, and corner labels scale down instead of wrapping.

## Edge Cases
- Device language changes while the app runs: the app stays English; the fair-play notice follows the device on its next display (unchanged).
- Dialog open when the app is backgrounded and resumed: dialog still shown, no state lost.
- Barrier tap and CLOSE in quick succession: the dialog closes once, Home stays.

## In Scope
- Home header layout with the two corner keys (title centred).
- Settings dialog shell (title, `NO SETTINGS YET` empty state, CLOSE, data-driven entry list).
- Language dialog with English only (data-driven list).
- Widget tests for both dialogs and the header; update `home_screen_test`.

## Out of Scope
- Any actual setting (content "decided later", PO).
- The ABOUT row itself (built with OB-033, D3).
- Any translation or a second language; localization infrastructure (`flutter_localizations`, ARB files) — README Open Question 9.
- Persisting a language choice (one option → nothing to store).
- Moving FAIR PLAY off the new-game screen (stays in its header, OB-050).
- Settings / Language on screens other than Home.

## Dependencies
- **OB-050** (blocking): removes Home's BACK key (D1 there) and provides the three-slot header pattern. Ship after or with OB-050.
- OB-049 (Home screen; trailing corner was reserved for ABOUT — now LANGUAGE).
- OB-008 (fair-play notice language rule, unchanged).
- OB-033: its entry point moves from the new-game screen to a row in this Settings dialog (D3); its Open Question 2 ("Settings wanted?") is answered yes by the PO.
- OB-034 / store submission: release gate BR-005.
- README Open Question 9 (localization; partly answered: English only for now).

## Decisions
PO, 2026-10-04 (recommended defaults accepted):
- D1 (Q1): the Settings dialog ships now with `NO SETTINGS YET`. Release gate: before store submission it has at least one real entry, or the SETTINGS key is hidden.
- D2 (Q2): the fair-play notice keeps following the device language (OB-008 unchanged) until a second app language ships; then the app language drives it.
- D3 (Q3): ABOUT (OB-033) becomes a row in the Settings dialog when OB-033 is built.
- D4 (Q4 + OB-050 D3): header key labels are text, `SETTINGS` and `LANGUAGE`; no icons.

## Assumptions
- A-1: "Toggle" means a header key that opens a dialog, not an on/off switch in the header.
- A-2: "Small modal" means a centred dialog like `NewGameConfirmDialog`.
- A-3: Settings rows, when they come, are on/off switches persisted locally (`shared_preferences`, already a dependency).

## Open Questions
None. Q1–Q4 answered (see Decisions). Settings content remains a future PO decision and is tracked by the release gate (BR-005).

## Developer Handoff
- Home header: switch to the three-slot header from OB-050 (leading `SETTINGS`, middle `PICK A GAME`, trailing `LANGUAGE`); remove the left-aligned title row.
- Two small dialogs following `NewGameConfirmDialog` styling. Settings entries and languages each come from one list; empty-state line when the settings list is empty.
- No new dependency and no localization framework in this ticket. Fair-play locale logic untouched.
- Verify on the iOS simulator (testing policy 2026-10-03).
