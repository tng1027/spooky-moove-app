# Ticket Analysis

> **Status: Phase 1 Implemented, pending device QA (2026-10-06); display name changed to "Spooky Moove" (D1 revised). Phase 2 blocked only on the Designer's artwork exports. Priority P1 (M1 release polish, not a submission blocker).** All PO questions answered (Decisions D1–D6). **Phase 1** (`#0F1015` background, white-flash fix) ships on its own. **Phase 2** (name "Spooky Moove" + slogan EN/VI by device language + Chess/Xiangqi icons) starts when the exports listed in "Design spec" land. Technical approach decided: **hand-edited native files, no `flutter_native_splash`** (D3).
>
> Revision 2 (2026-10-06): concept changed to name + slogan + game icons; Q1–Q5 open. Revision 1 (2026-10-06, superseded): ghost mark only, no text.

TICKET_TYPE: ENHANCEMENT
CONFIDENCE: HIGH

A launch screen already exists on both platforms: the untouched Flutter template (`LaunchScreen.storyboard`, `launch_background.xml`, `LaunchTheme`). The request changes how it looks, so it is an enhancement, not a new feature. It is not a bug: no requirement defines the launch screen (OB-003 put "App icon, splash screen" out of scope; OB-052 Open Question 2 deferred splash to a follow-up). The white flash described below is a real defect of the template against our dark-only app, but it has no prior acceptance criterion, so it is fixed here (Phase 1). Not a duplicate: no ticket covers the launch screen. The revised content (name, slogan, game icons) is still a static native launch screen, so the type does not change.

## Ticket Title
[Enhancement] Branded dark native launch screen with app name, slogan and game icons on iOS and Android (incl. Android 12+ splash), with no white flash before the first frame

## Summary
- **Phase 1 (independently shippable):** every native launch and window background becomes `#0F1015` (`AppColors.bgDark`) in light and dark mode, and the placeholder image is removed. This removes the white flash and the black-to-dark jump.
- **Phase 2:** the launch screen shows (1) the app name "Spooky Moove", (2) a short slogan describing the app and (3) icons of the supported games (Chess and Xiangqi today, more later), on iOS and Android 7–11. Android 12+ shows a reduced version because its SplashScreen API allows only a centered icon and an optional bottom branding image (REQ-011).
- Both phases hand off to the first Flutter frame with no flash and add no startup time.

## Business Context
- PO request 2026-10-06 (verbatim): "Launch screen: it's still Flutter's placeholder. Apple usually doesn't reject for this, but it looks unfinished."
- PO direction 2026-10-06 (revision 2): the launch screen shows the app name "Spooky Moove", a short slogan describing the app, and icons of the supported game types (Chess, Xiangqi; extensible later).
- First impression on every cold start, and the first thing App Review sees. The only store requirement is an iOS launch storyboard (already set: `UILaunchStoryboardName = LaunchScreen`).
- Apple HIG (Launch screens) recommends a launch screen that looks like the first screen and avoids text, because it is not localized at runtime and is not a branding surface. This is guidance, not a review rule; many approved apps show a name and slogan. **Non-blocking risk, accepted by the PO direction.**
- The app is **dark-only**: `ThemeMode.dark`, `theme` and `darkTheme` both `AppTheme.dark()`, scaffold `#0F1015` (`lib/app.dart`, `lib/core/theme/`). Any light launch background therefore produces a white-to-dark flash.
- Display name: changed from `SpookyMoove` to "Spooky Moove" (two words, D1 revised) in `Info.plist`, `AndroidManifest.xml`, `MaterialApp.title` and `OpenSourceInfo.appName`; matches the launch artwork.

## Current Behavior
Source: files listed per row; verified 2026-10-06.

| Platform | File | Current |
|---|---|---|
| iOS | `ios/Runner/Base.lproj/LaunchScreen.storyboard` | White background (`#FFFFFF`), one centered `LaunchImage` image view. |
| iOS | `ios/Runner/Assets.xcassets/LaunchImage.imageset/` | 1 × 1 px transparent PNGs (Flutter placeholder) + Flutter's `README.md`. Result: **a plain white screen**. |
| iOS | `ios/Runner/Base.lproj/Main.storyboard` | Root view background white (behind `FlutterViewController`). |
| Android | `res/drawable-v21/launch_background.xml` (used, `minSdk = 24`) | `?android:colorBackground` only; bitmap commented out. |
| Android | `res/drawable/launch_background.xml` | `@android:color/white` (pre-API 21; unused at `minSdk 24`). |
| Android | `res/values/styles.xml` | `LaunchTheme` / `NormalTheme` on `Theme.Light.NoTitleBar` → **light/white** window in system light mode. `NormalTheme` window background `?android:colorBackground` stays visible until the first Flutter frame. |
| Android | `res/values-night/styles.xml` | Same on `Theme.Black.NoTitleBar` → **black** (`#000000`), not `#0F1015`. |
| Android 12+ | no `values-v31` / `values-night-v31` | System splash (mandatory on API 31+) shows the **launcher icon** (adaptive icon, background `#0A0B0D`, ghost + piece-pattern foreground) masked in a circle on the default theme background. The Flutter `launch_background` drawable is not shown on API 31+. |
| Flutter | `lib/main.dart` | Before `runApp`: license registration, `setPreferredOrientations`, `await SharedPreferences.getInstance()`. The native launch screen covers this time; first route is the fair-play gate or Home (`_HomeGate`). |
| Game icons in app | `home_screen.dart` `_GameIconBlock` → `GameWidgets.sidePictogram` | Home rows already show one pictogram per game on its accent block (`accentChess #ED96D7`, `accentXiangqi #578EF5`): Cburnett chess piece (`assets/pieces/cburnett/`, BSD, attributed) and Xiangqi glyph (`assets/pieces/xiangqi/`, Noto Serif TC, OFL 1.1, attributed). Both are registered in the licenses screen (`main.dart`). |
| Game taglines | `app_strings*.dart` | Per-game taglines exist (e.g. VI `CHIẾN THUẬT KINH ĐIỂN`); **no app-level slogan** exists in the app or docs. |
| Deps | `pubspec.yaml` | No `flutter_native_splash`, no `flutter_launcher_icons`. |

Observed result today:
- **iOS:** white screen → dark first frame (white flash on every cold start).
- **Android 7–11, light mode:** white window → dark first frame. **Dark mode:** black → `#0F1015` (small color jump).
- **Android 12+:** app icon on a white (light mode) or default dark background → dark first frame.

## Expected Behavior
- **Phase 1:** from the tap on the app icon to the first Flutter frame, one calm `#0F1015` screen in light and dark mode; no white or black frame at any point.
- **Phase 2, iOS and Android 7–11:** the same background with the name "Spooky Moove", the slogan in the **device language** (`ONE MOVE AHEAD` / `ĐI TRƯỚC MỘT NƯỚC`, English fallback) and the Chess + Xiangqi icons, laid out per the design spec, static, same in light and dark mode.
- **Phase 2, Android 12+:** the system splash with `#0F1015` background, the game tiles as centered icon and the "Spooky Moove" wordmark as bottom branding image (REQ-011); **no slogan** (platform limit, accepted D4).
- The in-app language picker (OB-051 / OB-053) never changes the launch screen.
- The first Flutter frame (fair-play notice or Home) appears on the same `#0F1015` background with no color change; the launch content disappears on a hard cut.

## User Story
As a player opening SpookyMoove
I want the app to start on a polished dark screen that tells me its name, what it does and which games it supports
So that the app feels finished and I immediately know I am in the right place, without a white flash.

## Functional Requirements

### Phase 1 — background and flash fix (ships independently)
- REQ-001 (iOS): `LaunchScreen.storyboard` background `#0F1015` (sRGB), placeholder `LaunchImage` view removed or empty; `Main.storyboard` root view uses the same color so no white shows during handoff.
- REQ-002 (Android API 24–30): `LaunchTheme` and `NormalTheme` window backgrounds `#0F1015` in `values` and `values-night`; `launch_background.xml` = that color.
- REQ-003 (Android API 31+): `values-v31` / `values-night-v31` set the splash background `#0F1015`. Icon stays the launcher icon in Phase 1 (accepted interim, design spec §3).
- REQ-004: the native color value equals `AppColors.bgDark`; keep one native color resource per platform and note the link next to it.
- REQ-005: no white system bars during launch (light content on dark background) on either platform.

### Phase 2 — name, slogan and game icons
- REQ-006 (iOS, Android 7–11): the launch screen shows the name **"Spooky Moove"** (two words, D1), the slogan (REQ-010) and one icon per bundled game (Chess, Xiangqi), centered per the design spec, fully inside the safe area on the smallest supported screens (iPhone SE, 360 × 640 dp) and not stretched on the largest.
- REQ-007: text (name, slogan) is rendered so it looks the same as the design on every device; whether as image assets or native text is the developer's choice within the design spec, but launch screens cannot use Flutter fonts, so the result must not fall back to a system font if the design specifies a brand font.
- REQ-008: game icons are the approved artwork from the design spec, with documented provenance and licence (BR-004). Reusing the in-app pictograms (Cburnett chess piece, Noto Serif TC Xiangqi glyph), already attributed in the licenses screen, satisfies BR-004; any new artwork needs its source recorded in the design spec.
- REQ-009: the set of game icons matches the games bundled in the release (Chess, Xiangqi for M1). Adding a game later = updating the native assets in that game's release; no runtime-dynamic launch content (native launch screens are static).
- REQ-010 (slogan, D2 + D3): approved slogan `ONE MOVE AHEAD` (EN) / `ĐI TRƯỚC MỘT NƯỚC` (VI), chosen by the **device language**: Vietnamese device → VI; English or any other language → EN (fallback). iOS: localized launch assets (Base/en + vi); Android 7–11: `drawable` (EN) + `drawable-vi` density variants. The in-app language choice (OB-053) has no effect on the launch screen; this mismatch is accepted. Copy must not change without updating this ticket.
- REQ-011 (Android 12+, accepted D4): system splash with background `#0F1015`; centered icon = the Chess + Xiangqi game tiles composed inside the 192 dp visible circle of a 288 dp canvas (no icon background); branding image = the "Spooky Moove" wordmark (max 200 × 80 dp) at the bottom. **No slogan on Android 12+.** The wordmark is the same in every language, so no per-locale `-v31` variant is needed unless the design spec adds language-specific branding.
- REQ-012: static only: no animation, progress indicator, version or legal text.

### Both phases
- REQ-013: startup time does not grow: no artificial delay, no minimum display time, no `setKeepOnScreenCondition`, no Flutter-side intro screen (BR-003, D6). The launch screen disappears when Flutter draws its first frame, as today.
- REQ-014: no new dependency, runtime or dev (hand-edited native files, D3).

## Design spec
**Source of truth: `docs/design/launch-screen.md` (revision 2, final, 2026-10-06).** It covers the layout (§3), localization (§4), Android 12+ (§5), icon licensing (§7) and the export checklist (§9).

- **Phase 1:** done. `#0F1015` everywhere, placeholder image removed, and Android 12+ keeps the launcher icon until Phase 2.
- **Phase 2:** blocked only on the artwork. The Designer produces it per the brief below.

### Designer Brief: Phase 2 assets

**Goal:** three masters and 36 PNG exports that the developer can copy straight into the project.

**Inputs (all in the repo, all licensed for this use):**
- Background `#0F1015` (`AppColors.bgDark`). Use it only as an artboard preview; every export has a **transparent** background.
- Font: `assets/fonts/JetBrainsMono-Bold.ttf` and `JetBrainsMono-Regular.ttf` (OFL). Vietnamese glyphs are verified, so no fallback font is needed.
- Pictograms: chess king `assets/pieces/cburnett/wK.svg` (BSD) and xiangqi general `assets/pieces/xiangqi/rK.svg` (OFL). Use the exact pictogram from the Home game row.
- Tile colors: Chess face `#ED96D7` with side `#A8508F`; Xiangqi face `#578EF5` with side `#2A56B3`. Text: wordmark `#FFFFFF`, slogan `#8E92A4`.
- Tile reference: the Home game-row `AppBlock` (48 dp, 32 dp pictogram, 4 dp side depth). For a pixel-exact reference, the developer can supply a 4× `RepaintBoundary` capture of both tiles on request.
- **Do not use** the app icon, the ghost or `ic_launcher_foreground.png` (compliance Q32), and no other piece art.

**Master 1: `launch_lockup` (EN and VI variants, 240 × 144 pt artboard)**, top to bottom, horizontally centered:
1. Tiles: Chess, then Xiangqi, each 48 × 48 including the 4 pt depth, with a 16 pt gap (row is 112 wide).
2. A 24 pt gap.
3. `SPOOKY MOOVE`: Bold 28, tracking +1, upper case, line box 34.
4. An 8 pt gap.
5. Slogan: Regular 14, tracking +1.5, line box 22. EN is `ONE MOVE AHEAD`; VI is `ĐI TRƯỚC MỘT NƯỚC`, typed as precomposed (NFC) text.
- Vertical total is 136 pt, centered in the 144 pt artboard. Check that the Vietnamese marks on Ộ, Ớ and Ư are not clipped.
- No labels under the tiles, no other text, no shadows beyond the tile depth, no gradients.

**Master 2: `splash_games` (Android 12+, 288 × 288 dp artboard)**
- The same two tiles at **64 dp** with a 16 dp gap (144 × 64), centered. Everything must stay inside the **192 dp circle** guide, which the system masks. No background fill.

**Master 3: `splash_branding` (Android 12+, 200 × 80 dp artboard)**
- `SPOOKY MOOVE`, Bold ~24 sp, `#FFFFFF`, centered. No slogan and no tiles. This image is the same for all languages.

**Exports:** PNG-24 with alpha, sRGB, transparent background, no compression artefacts. Name and organize the files exactly as below, so the folders can be dropped into `android/app/src/main/res/` and the iOS asset catalog:

| Asset | Folder / file | Sizes (px) |
|---|---|---|
| iOS EN | `ios/LaunchLockup.imageset/launch_lockup{,@2x,@3x}.png` | 240×144, 480×288, 720×432 |
| iOS VI | `ios/LaunchLockup.imageset/vi/launch_lockup{,@2x,@3x}.png` | same |
| Android phone EN | `drawable-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/launch_lockup.png` | 240×144, 360×216, 480×288, 720×432, 960×576 |
| Android phone VI | `drawable-vi-{…dpi}/launch_lockup.png` | same |
| Android tablet EN | `drawable-sw600dp-{…dpi}/launch_lockup.png` | 360×216, 540×324, 720×432, 1080×648, 1440×864 |
| Android tablet VI | `drawable-vi-sw600dp-{…dpi}/launch_lockup.png` | same as tablet EN |
| Android 12+ icon | `drawable-{…dpi}/splash_games.png` | 288, 432, 576, 864, 1152 (square) |
| Android 12+ branding | `drawable-{…dpi}/splash_branding.png` | 200×80, 300×120, 400×160, 600×240, 800×320 |

**Delivery:** commit or hand over to `docs/design/launch-screen/`:
- `masters/`: the three layered sources (Figma link or SVG), with text kept live in the source.
- `exports/`: the folder tree above.
- A preview PNG of each variant on `#0F1015` at phone size: EN, VI, Android 12+ (icon plus branding at the bottom).

**Designer self-check before handover:**
- [ ] 36 PNGs, exact pixel sizes, transparent, sRGB.
- [ ] The EN and VI lockups differ only in the slogan line; the tiles and wordmark are pixel-identical.
- [ ] `splash_games` content stays inside the 192 dp circle at every density.
- [ ] Tiles match the Home game row (colors, pictogram, depth).
- [ ] Copy matches D1/D2 exactly; Vietnamese diacritics are complete.
- [ ] Only the sources listed under Inputs are used (BR-004).

## Business Rules
- BR-001: The launch screen background equals the app background `#0F1015` on every platform and system theme.
- BR-002 (revised): Text on the launch screen is limited to the app name and the approved slogan. No other text (version, "Loading…", copyright, legal, per-game taglines). No animation or progress indicator.
- BR-003: Startup is never slowed down to show the launch screen. No extra Flutter intro screen (PO confirmed, D6).
- BR-004 (now applies directly): Game icons and any other artwork must have a documented source and a licence compatible with the app (GPLv3, OB-002) and be attributed in the licenses screen (OB-033) where required. Artwork with unclear provenance, including the piece art baked into the current app icon (compliance Q32, `docs/fairy-stockfish-app-store-compliance-qa.md`), must not be used.
- BR-005: Only games bundled in the release are shown. Games that are not available (future on-demand packs, Phase 3+) are not shown (D5).
- BR-007: The slogan follows the device language (VI → Vietnamese, anything else → English), never the in-app language choice (D3).
- BR-006: Slogan copy follows the store positioning rules (OB-034: "Family Companion & Training Assistant"; no "cheat", "bot", "engine", "unbeatable", rating or absolute-strength claims), in every language shown.

## User Flow
```text
Tap app icon (cold start)
↓
iOS / Android 7–11: native launch screen
  Phase 1: #0F1015 only
  Phase 2: #0F1015 + "Spooky Moove" + slogan (device language) + Chess / Xiangqi icons
Android 12+: system splash
  Phase 1: #0F1015 + launcher icon
  Phase 2: #0F1015 + game-tiles icon + "Spooky Moove" wordmark at the bottom, no slogan
↓ Flutter engine starts, main() loads SharedPreferences
↓ first Flutter frame drawn (hard cut, no fade)
Fair-play notice (first launch) or Home on #0F1015 — no flash in between
```
Alternatives: warm start / resume → no launch screen (OS behavior, unchanged). Android 12+ start from recents after process death may briefly show the system splash; same theme. Device language decides the slogan (VI → `ĐI TRƯỚC MỘT NƯỚC`, otherwise `ONE MOVE AHEAD`), not the in-app language choice (OB-053), because the launch screen shows before the app reads its settings.

## Acceptance Criteria

### Phase 1
- Given an iPhone in light or dark mode, When the app is cold-started, Then the launch screen is `#0F1015` and no white frame appears before the first Flutter screen.
- Given an Android 7–11 device in light or dark mode, When the app is cold-started, Then the window is `#0F1015` and switches to the first Flutter screen without a white or black frame.
- Given an Android 12+ device in light or dark mode, When the app is cold-started, Then the system splash background is `#0F1015` and the switch to the first Flutter screen has no white or black frame.
- Given first launch (fair-play notice) and a later launch (Home), When the launch screen hands over, Then the first Flutter screen appears on the same background with no color change.
- Given a 60 fps screen recording of a cold start on each platform, When stepped frame by frame, Then no frame between tap and first Flutter frame has a background other than `#0F1015` (system icon-zoom animation excepted).
- Given the status and navigation bars during launch, When the launch screen shows, Then no white bar is visible.

### Phase 2
- Given an iPhone or an Android 7–11 device in light or dark mode, When the app is cold-started, Then the launch screen shows "Spooky Moove", the slogan for the device language and the Chess and Xiangqi icons as in the design spec, identical in both modes.
- Given iPhone SE and 360 × 640 dp, When the launch screen shows, Then name, slogan and icons are fully visible inside the safe area, not clipped or overlapping; on Pro Max / tablets they are centered and not stretched.
- Given an Android 12+ device in any language, When the app is cold-started, Then the splash shows `#0F1015`, the game-tiles icon fully inside the circular mask and the "Spooky Moove" wordmark at the bottom; no slogan is shown.
- Given the device language is Vietnamese, When the app is cold-started on iOS or Android 7–11, Then the slogan reads `ĐI TRƯỚC MỘT NƯỚC`.
- Given the device language is English, When the app is cold-started on iOS or Android 7–11, Then the slogan reads `ONE MOVE AHEAD`.
- Given the device language is neither English nor Vietnamese (e.g. French, Japanese), When the app is cold-started, Then the slogan reads `ONE MOVE AHEAD` (fallback).
- Given the device language is English and the in-app language is set to Vietnamese (or the reverse), When the app is cold-started, Then the launch screen follows the device language; the in-app choice applies only from the first Flutter screen.
- Given the game icons on the launch screen, When their source is checked, Then each has a recorded source and licence in the design spec and, where required, an entry in the licenses screen; no art from the current app icon is used.
- Given the slogans and name, When compared with the approved copy (D1, D2), Then they match exactly: "Spooky Moove", `ONE MOVE AHEAD`, `ĐI TRƯỚC MỘT NƯỚC` (Vietnamese diacritics complete and unclipped).
- Given the launch screen, When the shown games are compared with the games on Home, Then both list exactly Chess and Xiangqi.
- Given the launch screen, When shown, Then it contains no text other than name and slogan, and no animation.

### Both phases
- Given a release build on the same device, When cold-start time to the first Flutter frame is measured before and after, Then it is not longer (±10 %), and no Flutter intro screen appears between the native launch screen and the first app screen.
- Given `pubspec.yaml`, When compared before and after, Then no dependency (runtime or dev) was added.
- Given the installed app, When its home-screen name is checked, Then it is unchanged (`SpookyMoove`).

## Edge Cases
- iOS launch-screen cache: an updated launch screen may only appear after deleting the app and restarting the device / simulator (QA note, not a defect).
- Text size: launch screens do not follow Dynamic Type / font scale; text must be legible at the fixed design size (image text) and must not overflow if native text is used.
- Device language Vietnamese with app language English (or the reverse, OB-053 saved choice): slogan follows the device — accepted mismatch (D3).
- Device language changed while the app is installed: the next cold start shows the new language's slogan (iOS may need the launch-screen cache cleared, see above).
- Regional variants (`vi-VN`, `en-GB`, `en-AU`) resolve to VI / EN as expected; unsupported languages fall back to EN.
- VI slogan is longer than EN: must fit iPhone SE width without truncation; diacritics not clipped.
- Android 12+ OEM skins (Samsung One UI, Xiaomi) that resize or tint the splash icon or hide the branding image.
- Android 13+ themed (monochrome) launcher icons: do not affect the splash.
- Slow first start (first install, low-end device): launch screen stays longer; no timeout behavior.
- A new game added in a later release: launch icons must be updated in that release (REQ-009); missing update = launch screen and Home disagree.
- iPad: not a target; layout must still be centered and unbroken in compatibility mode.

## In Scope
- Phase 1: iOS `LaunchScreen.storyboard`, `Main.storyboard` background; Android `launch_background.xml`, `values` / `values-night` `styles.xml`, new `values-v31` / `values-night-v31`, a shared `#0F1015` color resource.
- Phase 2: launch assets (name, slogan, Chess + Xiangqi icons) for iOS and Android 7–11, in EN and VI by device language; Android 12+ game-tiles icon and "Spooky Moove" branding wordmark.
- Light and dark system mode on both platforms.
- QA on iOS simulator now; Android and physical devices in the final device pass (testing policy 2026-10-04).

## Out of Scope
- App icon redesign or replacement (compliance Q32; separate decision with OB-034).
- Slogan anywhere else in the app (Home, store listing); store listing copy stays in OB-034.
- Slogan on Android 12+ (platform limit, D4).
- Animated splash (Android 12+ animated vector icon, Lottie, iOS animation) and any Flutter-side intro screen (D6).
- Following the in-app language choice (OB-053) on the native launch screen (not technically possible before the app runs).
- Runtime-dynamic game list on the launch screen (on-demand packs, Phase 3+).
- Startup-time optimization (deferring `SharedPreferences`, engine warm-up); only "no regression" is required.
- A light app theme; store screenshots.
- `androidx.core:core-splashscreen` compat library (API 24–30 keep the window-background approach; API 31+ use platform attributes).

## Technical Approach (decided, D3 + D6)
**Native launch screen only (Option A), hand-edited native files, no `flutter_native_splash`.** The device-language slogan needs per-locale assets (iOS Base/en + vi, Android `drawable` + `drawable-vi`), which the plugin cannot generate and would overwrite on regenerate. No Flutter intro screen (Option B rejected, D6). The analysis below is kept for the record.

### Constraints that shape the choice
- **Android 12+ SplashScreen API:** only a background color, one centered icon (visible circle 192 dp of a 288 dp canvas, or 160 dp with icon background) and an optional bottom branding image (≤ 200 × 80 dp). No free layout, so **the slogan cannot appear** and name + icons must fit into icon + branding (REQ-011).
- **Text on native launch screens:** iOS launch storyboards and Android layer-list drawables cannot use Flutter fonts; a layer-list cannot draw text at all. Brand-styled text is therefore delivered as images (iOS can use native labels with system fonts only, unless the font is also registered natively).
- **Localization:** possible but per platform and per device language only: iOS `vi.lproj` localized storyboard / localized image assets; Android `drawable-vi-*` bitmaps (API 24–30) — and not for the Android 12+ branding image if it contains text in a different language per locale (`values-vi-v31` can point to a different drawable, adding more assets). Every language doubles the text assets.

### Option A (chosen): native launch screen only
Name, slogan and icons drawn natively (Phase 2 assets). Zero startup cost, HIG-tolerable, matches BR-003. Android 12+ gets the reduced version.

### Option B (rejected by PO, D6): native splash + Flutter intro screen
Keep Phase 1 natively, then a Flutter screen shows name, slogan (in the **in-app** language), game icons from the game registry (automatically extensible), identical on every Android version.
- Cost: a second "splash" after the native one (double splash on Android 12+), extra startup time if shown for any minimum duration (violates BR-003 unless it only covers real loading), HIG discourages it, plus a new route, state and tests.
- Rejected by the PO (D6).

### Hand-edited native files vs. `flutter_native_splash` (re-evaluated)
| | Hand-edited native files | `flutter_native_splash` (dev dependency only) |
|---|---|---|
| Dependency | None | Generator in `dev_dependencies`; no runtime code if `preserve()` / `remove()` are not used |
| Phase 1 (color only) | ~6–8 small files | Overkill |
| Phase 2 center image + branding | Manual exports per density (5 Android + 3 iOS per image), storyboard constraints | Generates densities, storyboard with bottom branding, `values-v31` (`android_12: image, color, branding`) from one config |
| Localized slogan (chosen, D3) | Possible (`vi.lproj`, `drawable-vi`, `values-vi-v31`) | **Not supported**; per-locale assets must be hand-edited on top and are overwritten on regenerate |
| Free layout (name + slogan + icons) | Any native layout on iOS; layer-list on Android 7–11 | One center image + one branding image; the whole block must be pre-composed into those images anyway |
| Maintenance | Explicit, reviewable diffs | Regenerates storyboard, styles, `Info.plist`; generator-version churn |

**Outcome:** with the slogan localized by device language (D3), **hand-edit both phases**. The Designer delivers composed EN and VI launch images (or layers per spec), the Android 12+ game-tiles icon and one wordmark branding image.

## Dependencies
- Designer artwork exports per "Design spec" (`docs/design/launch-screen.md`) — the only blocker for Phase 2.
- Game icon artwork with licence notes (BR-004); OB-033 licenses screen if new artwork needs attribution.
- OB-034 (app name, deferred): if the brand name changes again, the launch artwork and display name follow (D1).
- Game registry / bundled games (OB-042, OB-049): defines which icons appear (REQ-009, D5).
- OB-053: in-app language vs. device language mismatch on the launch screen (accepted, D3).
- `AppColors.bgDark` (`lib/core/theme/app_colors.dart`) as the color source.
- Testing policy (README, 2026-10-04): Android verification in the final device pass.

## Assumptions
- A-1: The launch screen is dark (`#0F1015`) in system light and dark mode (design spec §2; former Q1, no PO objection recorded).
- A-2: `#0F1015` is the background, not the icon's `#0A0B0D`.
- A-3: Portrait iPhone and Android phones are the targets; iPad / tablets are not designed separately.
- A-4: The ghost-only mark of revision 1 is no longer the concept; the ghost may still appear only if the updated design spec includes it.
- A-5: Reusing the in-app game pictograms (Cburnett, Noto Serif TC) is licence-safe because they are already attributed (BSD / OFL 1.1); final choice is the Designer's.

## Decisions
PO, 2026-10-06:
- D0 (rev. 2 concept, former Q2): the launch screen shows app name + slogan + supported game icons; ghost-only mark dropped.
- D1 (Q1, name): launch artwork reads **"Spooky Moove"** (two words). Revised 2026-10-06: the app display name (`CFBundleDisplayName`, `android:label`, `MaterialApp.title`, `OpenSourceInfo.appName`) is also changed to "Spooky Moove" in this ticket. Bundle id, package name and Dart class names are unchanged.
- D2 (Q1, slogan): **`ONE MOVE AHEAD`** (EN) / **`ĐI TRƯỚC MỘT NƯỚC`** (VI), approved.
- D3 (Q2, language): slogan by **device language** (VI → Vietnamese; English and all other languages → English). The in-app language picker does not affect the launch screen. Overrides the BA recommendation (English-only); consequence: hand-edited native files, no `flutter_native_splash`.
- D4 (Q3, Android 12+): reduced splash accepted: game-tiles center icon + "Spooky Moove" branding wordmark, no slogan.
- D5 (Q4, games): only games bundled in the release (currently Chess + Xiangqi).
- D6 (Q5): no extra Flutter intro screen (BR-003).

Former Q3 (ghost icon dependency) → obsolete with the new concept; artwork provenance is BR-004.

## Open Questions
None open.

## QA Checklist

### Phase 1
- [ ] iOS simulator, light and dark mode: delete app, reset simulator (launch-screen cache), cold start → `#0F1015`, no white frame (screen recording, step frames).
- [ ] iOS: first launch (fair-play notice) and later launch (Home): no color change at handoff.
- [ ] Android API 24–30, light and dark: `#0F1015`, no white or black frame (final device pass).
- [ ] Android API 31+ (incl. 34/35), light and dark: splash background `#0F1015`, launcher icon, handoff without flash.
- [ ] Status and navigation bars: no white bar during launch on either platform.

### Phase 2
- [ ] iOS (SE and Pro Max size), light and dark: name, slogan, Chess + Xiangqi icons match the design spec; nothing clipped or stretched.
- [ ] Android API 24–30 (360 × 640 dp and a large phone): same content as iOS, centered, crisp at every density.
- [ ] Android API 31+ (EN and VI device): game-tiles icon inside the circle, "Spooky Moove" wordmark at the bottom, no slogan; Samsung One UI check.
- [ ] Device language **Vietnamese** (iOS and Android 7–11): slogan `ĐI TRƯỚC MỘT NƯỚC`, diacritics complete, fits iPhone SE / 360 dp.
- [ ] Device language **English** (incl. `en-GB`): slogan `ONE MOVE AHEAD`.
- [ ] Device language **other** (e.g. French, Japanese): slogan `ONE MOVE AHEAD` (fallback).
- [ ] Device English + in-app Vietnamese, and device Vietnamese + in-app English: launch screen follows the device; first Flutter screen follows the in-app choice.
- [ ] Device language switched between runs: next cold start shows the new slogan (iOS: delete app / reset if cached).
- [ ] Name reads "Spooky Moove" (two words) on the launch screen and under the home-screen icon.
- [ ] Games shown = Chess + Xiangqi, same as Home.
- [ ] Icon sources and licences recorded; licenses screen updated if new artwork.
- [ ] No text other than name and slogan; no animation.

### Both phases
- [ ] Release build cold start to first frame: no regression (same device, ±10 %); no Flutter intro screen.
- [ ] `pubspec.yaml`: no new dependency (runtime or dev); `flutter analyze` and `flutter test` green.
- [ ] Physical iPhone + physical Android in the final device pass.

## Developer Handoff
- **Phase 1 now (hand-edit):** `#0F1015` sRGB in `LaunchScreen.storyboard` and `Main.storyboard`; remove the placeholder image view; Android color resource used by `launch_background.xml`, `LaunchTheme` and `NormalTheme` (`values`, `values-night`); add `values-v31` / `values-night-v31` with `android:windowSplashScreenBackground`. No Dart changes. Can be merged and released before Phase 2.
- **Phase 2 once the Designer's exports land:** iOS: launch image centered on the full screen, localized Base/en + vi (localized asset or `vi.lproj` storyboard, developer's choice; unsupported languages must fall back to EN; add `vi` to `knownRegions` in `ios/Runner.xcodeproj/project.pbxproj` or iOS never picks the VI asset); Android 7–11: centered bitmap in `launch_background.xml`, EN in `drawable-*`, VI in `drawable-vi-*`; Android 12+: `windowSplashScreenAnimatedIcon` = game tiles (288 dp canvas, content within 192 dp) and `windowSplashScreenBrandingImage` = wordmark in `values-v31` / `values-night-v31` (same for all languages).
- Hand-edited native files only; no `flutter_native_splash` (D3).
- **Phase 1 done (2026-10-06):** both storyboards use sRGB `#0F1015` (placeholder `LaunchImage` view removed; the imageset stays until Phase 2); Android `@color/launch_background` in `values/colors.xml` used by both `launch_background.xml`, `NormalTheme` (`values`, `values-night`) and new `values-v31` / `values-night-v31` (`windowSplashScreenBackground`).
- Keep `main.dart` startup unchanged; no `setKeepOnScreenCondition`, no intro route.
- Verify per the QA checklist on the iOS simulator (delete app + reset to beat the launch-screen cache); Android in the final device pass.
