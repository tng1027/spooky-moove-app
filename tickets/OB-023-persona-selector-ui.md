# Ticket Analysis

> **Revision (PO, 2026-10-03):** a game now starts with the Even tier selected (default on the new-game screen, OB-011 revision). REQ-002 and BR-001 ("no tier at game start") are superseded; the advisor's persona row still changes the tier at any time.

> **Status: Done on iOS simulator (2026-10-03).** Recompute on tier change (REQ-007) is delivered by the provider; the turn loop (OB-025) listens to it and calls `PersonaSuggester`. The "no suggestion on opponent move without a tier" criterion is enforced there.
> - `personaTierProvider` (`lib/features/persona/presentation/persona_tier_controller.dart`): nullable, game-scoped; `select()` fires `selectionClick` (no-op for the selected tier); `clear()` for a new game (OB-011).
> - `PersonaRow` (`lib/features/persona/presentation/widgets/persona_row.dart`) replaces the placeholder and is built from `PersonaTier.values` (no per-button logic). 52 dp row, 48 dp tall keys, ≈ 46 dp wide on 360 dp; `accentActive` selected / `keyNormal` unselected, 4 px radius; no shadow, gradient, ripple or animation; emoji 21 sp (`AppTypography.tierEmoji`), scale-down for large text. Semantics: button, tier name, selected state, tap action.
> - Prompt: the suggestion card placeholder shows `PICK A LEVEL` only while no tier is selected; no caption for the selected tier (assumption kept). Emoji kept (Open Question 1 default).
> - Open Question 2 still open: below 360 dp the keys shrink proportionally (≈ 40 dp wide at 320 dp, under the 44 dp target) without overflow.
> - Tests: 14 new unit/widget tests (controller, order, selection color, flat tokens, semantics, sizes at 360 dp, no overflow at 360/320 dp with text scale 2.0, card prompt). Simulator integration test 1/1 (no tier → Soft → Baby) with screenshots.

TICKET_TYPE: NEW_FEATURE
CONFIDENCE: MEDIUM

New UI: no persona selector exists. Confidence raised from LOW to MEDIUM after the PO answer of 2026-10-02 (OB-021 D5, D6): no default tier, the tier must be chosen when a game starts, it can be changed mid-game, and the selector must follow the existing design language (`designSystem.md`). The remaining uncertainty is about layout details (placement on short screens, emoji vs. monochrome style), handled as assumptions below.

## Ticket Title
[Feature] Let the user choose one of 7 persona tiers from a selector row that follows the design system

## Summary
Add a row of 7 tier buttons (🥚 🐣 🐥 🥉 🥈 🥇 👑) to the advisor screen. When a game starts, no tier is selected and the user must pick one before getting suggestions. The tier can be changed at any time with one tap; the selected state uses the existing `accentActive` token and the `selectionClick` haptic.

## Business Context
- PO requirement "Tối ưu Giao diện UI cho 7 Nút Bấm" (2026-10-02), refined by the PO answer of 2026-10-02: "tuân theo ngôn ngữ thiết kế hiện có" (follow the existing design language).
- Keeps the product's zero-distraction, glanceable UI (`productContext.md`, `designSystem.md`).
- Part of Milestone 1 (OB-021 D2 / A1).

## Current Behavior
Nothing implemented. The documented layout (`designSystem.md`) is: hero/suggestion card ~35% (top), status/spacing ~10%, keypad ~55%. There is no persona row.

## Expected Behavior
- A persona row shows 7 tier buttons in tier order.
- When a game starts, **no tier is selected**, and suggestions are not shown until the user selects one.
- Tapping a tier selects it (selected state in `accentActive` amber), clears the previous selection and fires `selectionClick`.
- Changing the tier mid-game triggers a recomputed suggestion for the current position (OB-022).
- Only existing design tokens are used; no decorative motion.

## User Story
As a player at a physical board
I want to set and change the suggestion strength with a single thumb tap
So that I can adapt to my opponent instantly without menus.

## Functional Requirements
- REQ-001: Show 7 buttons in order 🥚 🐣 🐥 🥉 🥈 🥇 👑.
- REQ-002: At game start, no tier is selected; the row signals that a choice is required, and suggestions are gated until one is chosen.
- REQ-003: At most one tier is selected at any time; after the first choice, exactly one.
- REQ-004: Tapping a non-selected tier selects it and fires `HapticFeedback.selectionClick()`.
- REQ-005: The selected state uses `accentActive` (`#FFD600`); unselected buttons use `keyNormal`; corner radius 4–6 px; no shadows, gradients, blur or scale animation.
- REQ-006: Each button has an accessible label with the tier name (Baby, Gentle, Soft, Even, Solid, Master, God), since the buttons have no visible text.
- REQ-007: Changing the tier mid-game notifies move selection (OB-022) so the current suggestion is recomputed.
- REQ-008: All 7 buttons fit on a 360 dp-wide portrait screen, meeting the touch-target rules below.

## Business Rules
- BR-001: No default tier; a tier must be chosen when a game starts (OB-021 D5).
- BR-002: The tier can be changed mid-game (OB-021 D5).
- BR-003: Existing design language only (OB-021 D6): selected = `accentActive`; green stays reserved for the recommended move/advantage; no `#10B981`; no decorative motion (`designSystem.md` → "Motion and haptics").
- BR-004: Row height 52 dp (PO spec; within the 48–56 dp key height in `designSystem.md`); emoji 20–22 sp.
- BR-005: Touch targets: height ≥ 48 dp (`designSystem.md`), width ≥ 44 dp (platform minimum). On 360 dp, 7 equal-width buttons with minimal outer padding and small gaps give ≈ 46–48 dp each, which satisfies this. 7 × 48 dp with standard 16 dp side padding does not fit.

## User Flow
```text
User picks a game (OB-011)
↓
Advisor screen: persona row with no tier selected, prompt to choose a tier
↓
User taps 🐥 → 🐥 shown in amber, selectionClick haptic → suggestions enabled
↓
Mid-game: user taps 🥚 → 🥚 selected, suggestion for the current position recomputed (OB-022)
```
Alternative flows:
- User enters the opponent's move before choosing a tier → no suggestion; the tier prompt stays visible.
- User taps the already selected tier → no change.

## Acceptance Criteria
- Given a new game has just started, When the advisor screen appears, Then 7 tier buttons are shown in order 🥚 🐣 🐥 🥉 🥈 🥇 👑, none is selected, and a prompt to choose a tier is visible.
- Given no tier is selected, When the user enters the opponent's move, Then no suggestion is shown until a tier is chosen.
- Given a non-selected tier, When the user taps it, Then it becomes the only selected tier, is shown in `accentActive`, and a `selectionClick` haptic fires.
- Given a suggestion is shown, When the user selects a different tier, Then the suggestion for the current position is recomputed with the new tier (OB-022).
- Given a 360 dp-wide portrait screen, When the row renders, Then all 7 buttons are fully visible, none overlap, and each is at least 44 dp wide and 48 dp tall.
- Given the row in any state, When it is inspected, Then it uses only design-system tokens, with no `#10B981`, shadows, gradients, blur or scale animation.
- Given a screen reader is on, When focus moves over a tier button, Then the tier name and its selected/unselected state are announced.

## Edge Cases
- Narrow screens (< 360 dp, e.g. 320 dp): fallback per Open Question 2.
- Short screens where the 10% status region is less than 52 dp.
- Large font/display scaling.
- Emoji rendering differs by Android version/OEM and iOS.
- Rapid repeated taps across tiers (only the last selection counts).

## In Scope
- Persona row widget, unselected-at-start state, selected state, haptic, accessibility labels, notifying move selection on change.

## Out of Scope
- Move selection logic (OB-022).
- Game selection screen and the "choose tier when starting a game" step if it lives there (OB-011).
- Top bar with back `[<]`, game title and undo `[↶]` shown in the PO sketch — OB-011 / OB-012.
- Suggestion notation in the sketch (`Qd1 ➔ h5`, `[ #M2 ]`) — OB-001 Q9 / OB-007.

## Dependencies
- OB-021 (decisions D5, D6 recorded; resolved 2026-10-02, tier semantics final — no impact on this UI beyond labels).
- OB-022 (consumes the selected tier).
- OB-011 (game start flow; where the required tier choice happens).
- OB-003 (theme tokens, layout regions).
- OB-007 (suggestion card placement relative to the row).
- Note (2026-10-02): with the tap board (OB-006 BR-006), the row sits between the suggestion card (~25%) and the full-width board, instead of in the 10% status region. The first assumption below is superseded on placement; the row height (52 dp) and width rules are unchanged.
- Note (PO compliance document, 2026-10-02): free users see 🥚, 🐣, 🥇, 👑 with a **lock state** (lock glyph, design tokens only, no new accent). Tapping a locked tier opens a paywall without selecting it (**OB-037**). The lock state is a new key state to add to this ticket's design once OB-035 Q6 is confirmed.
- Update (PO 2026-10-02): monetization deferred (OB-035 M-D1). **No lock state now**; all 7 tiers are selectable as originally specified. Guardrail: render the row from the tier list (one source), not 7 hard-coded buttons with per-button logic.

## Assumptions
- The row sits in the existing ~10% status region between the suggestion card and the keypad, so the 35/10/55 layout from `designSystem.md` is kept. The PO sketch's placement under a top bar is not adopted (the top bar belongs to OB-011/OB-012).
- No caption such as "Đang bật: 👑 GOD MODE": the selected state is shown by color only, matching "Không có chữ thừa thãi" and the design system.
- The emoji from the PO spec are kept (system emoji font, offline), even though the design system is monochrome-leaning; the selected state is carried by the amber key background/border, not the emoji color.
- Persisting the tier across app restarts is only needed as part of resuming an interrupted game (OB-001 Q6).

## Open Questions
1. **Emoji vs. style (design, non-blocking):** Keep colored emoji, or use monochrome glyphs/numbers 1–7 to match "Industrial Utility"? Default: keep emoji (see Assumptions).
2. **Very narrow/short screens (design, non-blocking):** Below 360 dp width, or when the status region is under 52 dp, may the row use slightly smaller targets (≥ 44 dp) or take space from the keypad region?

## Developer Handoff
- Small widget driven by a persona-tier state provider scoped to the current game (nullable at game start); no logic in the widget beyond selection.
- Theme tokens only (`accentActive`, `keyNormal`, `surfaceDark`); state change without animation.
- `Semantics` labels with selected state; verify on 360 dp and 320 dp devices and with large text.
