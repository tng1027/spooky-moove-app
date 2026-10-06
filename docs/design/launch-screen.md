# Native Launch Screen — Design Spec (OB-055)

Status: **Final.** PO decisions recorded 2026-10-06. Ready for asset production (§9) and implementation.
Platforms: iOS 15+ (`LaunchScreen.storyboard`), Android minSdk 24 (legacy `launch_background.xml`) and Android 12+ (SplashScreen API, API 31+).

## PO decisions (2026-10-06)

| # | Decision |
|---|---|
| 1 | The lockup wordmark reads **"Spooky Moove"** (two words). This applies to the launch screen only. The app display name (`SpookyMoove`) is unchanged. |
| 2 | The slogan is **`ONE MOVE AHEAD`** / **`ĐI TRƯỚC MỘT NƯỚC`**. |
| 3 | The slogan follows the **device language**: Vietnamese on `vi` devices, English as the default and fallback for every other locale. |
| 4 | The reduced Android 12+ splash is accepted: game tiles as the center icon, the "Spooky Moove" branding image, and no slogan. |
| 5 | Scope is the bundled games only: **Chess and Xiangqi** (2 tiles). |

## 1. Concept

The launch screen is a solid `bgDark` canvas with one centered **lockup**. From top to bottom it contains:
- the two game-type tiles, the same accent blocks the Home screen uses;
- the "Spooky Moove" wordmark;
- the localized slogan.

The background matches the first Flutter frame, so the handoff never flashes.

**HIG tradeoff (accepted by the PO):** Apple's HIG says a launch screen should look like the first screen and avoid branding or text. This is a guideline, not a rejection reason. It is acceptable here for these reasons:
- The lockup is static and only appears until Flutter's first frame.
- The background and tiles match the Home screen.
- The slogan is localized for the device language.

To revert to pure HIG compliance later, remove the lockup image and keep the background.

## 2. Colors (light **and** dark mode identical)

The app forces `ThemeMode.dark`, so no system-adaptive colors are used. All values are **sRGB**. That includes the iOS storyboard background color, which defaults to Generic RGB.

| Element | Hex | Token | Contrast on bg |
|---|---|---|---|
| Background (all layers) | `#0F1015` | `bgDark` | — |
| Wordmark | `#FFFFFF` | `textPrimary` | 18.9:1 |
| Slogan | `#8E92A4` | `textSecondary` | 5.3:1 (AA) |
| Chess tile face / side | `#ED96D7` / `#A8508F` | `accentChess` / `accentChessSide` | — |
| Xiangqi tile face / side | `#578EF5` / `#2A56B3` | `accentXiangqi` / `accentXiangqiSide` | — |
| Tile pictograms | identical to the Home game-row `AppBlock` icon | — | — |

Do not use `#0A0B0D` (the adaptive-icon background) or `#000000`. Android `NormalTheme` and `postSplashScreenTheme` must also use `#0F1015`. Today they resolve to white in light mode.

## 3. Layout

### Lockup (logical pt/dp, phone): canvas 240 × 144

```
            ┌──────┐  16  ┌──────┐          ← tiles 48 × 48 (incl. 4 side depth), gap 16 → row 112 wide
            │  ♔   │      │  帥  │
            └──────┘      └──────┘
                     24                     ← gap
              SPOOKY MOOVE                  ← JetBrains Mono Bold 28, tracking +1, #FFFFFF, line box 34
                     8                      ← gap
             ONE MOVE AHEAD                 ← JetBrains Mono Regular 14, tracking +1.5, #8E92A4, line box 22
           ĐI TRƯỚC MỘT NƯỚC                  (vi variant; same position)
```

- **Hierarchy:** the wordmark comes first, the tiles second and the slogan third.
- **Case:** the wordmark is set in upper case, following the design-system rule for names. The PO's "Spooky Moove" spelling (two words, space) is kept.
- **Tiles:** these are exactly the Home game-row icon: a 48 dp `AppBlock` with a 32 dp pictogram, face and side colors, and a 4 dp depth. Order is Chess, then Xiangqi, following `GameKind.values`. Do not add labels.
- **Vertical budget:** 48 + 24 + 34 + 8 + 22 = 136 pt, which is within the 144 pt canvas. The 22 pt slogan line box leaves room for the stacked Vietnamese marks: Ộ has a circumflex above and a dot below, and Ớ has a horn plus an acute accent. Check that no diacritic is clipped in the export.

### Width check (JetBrains Mono advance = 0.6 em)

| Line | Characters | Width |
|---|---|---|
| `SPOOKY MOOVE` (Bold 28, +1) | 12 | 201.6 + 11 = **≈ 213 pt** ✓ |
| `ONE MOVE AHEAD` (Regular 14, +1.5) | 14 | 117.6 + 19.5 = **≈ 137 pt** ✓ |
| `ĐI TRƯỚC MỘT NƯỚC` (Regular 14, +1.5) | 17 | 142.8 + 24 = **≈ 167 pt** ✓ |

All lines are within the 240 pt canvas, so no font size change is needed for Vietnamese.

### Vietnamese glyph support (verified)

Both `assets/fonts/JetBrainsMono-Regular.ttf` and `JetBrainsMono-Bold.ttf` contain every precomposed character in the Vietnamese slogan, including **Ư (U+01AF), Ớ (U+1EDA), Ộ (U+1ED8)** and Đ. I checked this against each font's character map (cmap) with fontTools, and the full Vietnamese alphabet is covered too. **No fallback font is needed.** Export from precomposed (NFC) text so the font's own composed glyphs are used.

### Positioning and devices

- Center the lockup on the **full screen**, on both X and Y, and not on the safe area. The background is edge to edge. The lockup always stays inside the safe area.
- **Orientation:** portrait only, plus portrait upside-down on iPad. No landscape variant.

| Device | Lockup size | How |
|---|---|---|
| iPhone | 240 × 144 pt | fixed width and height constraints, centered, `scaleAspectFit` |
| iPad (regular × regular) | 360 × 216 pt | size-class constraint variation. The @3x asset (720 px) is exact at iPad @2x, so no extra export is needed. |
| Android phone | 240 × 144 dp | `launch_lockup` bitmap, `gravity="center"` |
| Android tablet (≥ sw600dp) | 360 × 216 dp | `sw600dp` bitmap variant |
| Android 12+ | system layout | see §5 |

The canvas has room for up to 4 tiles (4 × 48 + 3 × 16 = 240) if games are bundled later. That is out of scope now.

## 4. Localization (by device language)

All text is **baked into the lockup image**, with one image per language:
- An iOS storyboard label cannot use JetBrains Mono unless the font is registered natively.
- An Android `layer-list` cannot draw text at all.
- The localized variant is selected by the OS resource system. No code is involved.

| Platform | Default (EN, fallback for all non-`vi` locales) | Vietnamese |
|---|---|---|
| iOS | `LaunchLockup.imageset`, Universal / English | the same image set with a **Vietnamese** localization (Attributes inspector, Localization: tick Vietnamese and supply the `vi` images) |
| Android API 24–30, phone | `drawable-{m,h,xh,xxh,xxxh}dpi/launch_lockup.png` | `drawable-vi-{m,h,xh,xxh,xxxh}dpi/launch_lockup.png` |
| Android API 24–30, tablet | `drawable-sw600dp-{…}dpi/launch_lockup.png` | `drawable-vi-sw600dp-{…}dpi/launch_lockup.png` |
| Android 12+ | `splash_games`, `splash_branding` (no text to localize) | none needed |

Implementation notes:
- **iOS project must know `vi`.** `Info.plist` already lists `CFBundleLocalizations` = `en`, `vi`, but `project.pbxproj` `knownRegions` only has `en, Base`. Add `vi` to it. Otherwise iOS will not pick the Vietnamese asset.
- **iOS fallback**, if the localized asset catalog image does not resolve at launch on device: use a `vi.lproj/LaunchScreen.storyboard` copy that references a separate `LaunchLockupVI` image set, with `Base.lproj` keeping `LaunchLockup`. Verify on a `vi` device before choosing.
- **Android qualifier order** is language, then smallest width, then density, for example `drawable-vi-sw600dp-xxhdpi`. `launch_background.xml` in `drawable/` and `drawable-v21/` references `@drawable/launch_lockup` once, so no per-locale XML is needed.
- **No `-night` drawables or values are needed.** The light and dark values are identical, and `values-night/styles.xml` points at the same drawable.
- **No `-v31` localized assets are needed**, because Android 12+ has no slogan. Only `values-v31/` and `values-night-v31/` `LaunchTheme` styles are added (§5).
- **Known behavior (accepted):** the launch screen follows the device language, not the in-app language picker (OB-051/OB-053). A user on a `vi` device who chose English in the app sees the Vietnamese slogan during launch.
- **QA:** iOS caches launch screens. After changing the language or assets, reinstall or reboot before verifying.

## 5. Android 12+ (accepted reduced splash)

API 31+ ignores the layer-list on cold start. Set the following in `values-v31/styles.xml` and `values-night-v31/styles.xml`, `LaunchTheme`:

| Attribute | Value |
|---|---|
| `android:windowSplashScreenBackground` | `#0F1015` |
| `android:windowSplashScreenAnimatedIcon` | `@drawable/splash_games`: a 288 × 288 dp canvas with the 2 tiles at **64 dp, 16 dp gap** (144 × 64 dp), centered. Half-diagonal ≈ 79 dp, inside the 96 dp radius of the **192 dp safe circle** ✓ |
| `android:windowSplashScreenIconBackgroundColor` | unset (tiles carry their own color) |
| `android:windowSplashScreenBrandingImage` | `@drawable/splash_branding`: "SPOOKY MOOVE", JetBrains Mono Bold ~24 sp, `#FFFFFF`, centered on a 200 × 80 dp transparent canvas (text ≈ 183 dp incl. +1 tracking) |
| `postSplashScreenTheme` / `NormalTheme` `windowBackground` | `#0F1015` |

The difference from iOS and Android 7–11 is accepted by the PO:
- There is no slogan.
- The wordmark sits at the bottom edge, not under the tiles.
- The tiles are 64 dp instead of 48 dp.

`windowSplashScreenBrandingImage` is a framework attribute; AndroidX `core-splashscreen` does not support it, which is fine because API 24–30 use the legacy lockup.

## 6. Handoff to the first Flutter screen

- The first frame is `FairPlayScreen`, `HomeScreen` or `AdvisorScreen`, and all of them paint `#0F1015`. Only the lockup disappears.
- Use a **hard cut**. Do not add a Flutter recreation of the lockup, a fade, or a splash route.
- Keep the native launch screen until Flutter's first frame (the default). It also covers the `SharedPreferences` await in `main()`. Do not use `setKeepOnScreenCondition` or a delayed `runApp`.
- The window background behind Flutter is `#0F1015` on every API level.
- Use light status-bar and navigation-bar content on both sides of the handoff.

## 7. Game-type icon licensing

| Pictogram | Source | License | Usable |
|---|---|---|---|
| Chess king ♔ | `assets/pieces/cburnett/wK.svg` / `bK.svg` (Colin M.L. Burnett) | BSD (author offers GFDL/BSD/GPL). Notice in `assets/pieces/cburnett/LICENSE`, shown on the in-app license page. | ✅ |
| Xiangqi general 帥 / 將 | `assets/pieces/xiangqi/rK.svg` / `bK.svg` | Noto Serif TC glyph outlines, SIL OFL 1.1 (`OFL.txt`, `NOTICE.md`, in-app license page) | ✅ |
| Wordmark and slogan font | `assets/fonts/JetBrainsMono-*.ttf` | SIL OFL 1.1 (`OFL.txt`, in-app license page) | ✅ |
| Tile shape and colors | the app's own design system (OB-052) | first-party | ✅ |

- Export the tiles **from the app's own rendering** of the Home game-row icon at 3× and 4×, for example from a golden or `RepaintBoundary` capture. That guarantees the licensed sources above and an exact visual match.
- Compliance item Q32 concerns the **app icon** artwork (unclear origin), not these assets. The launch screen must not reuse the app icon, the ghost, or `ic_launcher_foreground.png`.

## 8. Do / Don't

**Do**
- Use exact sRGB `#0F1015` on every layer.
- Reuse the Home tiles and pictograms exactly.
- Keep the lockup static and centered.
- Test cold start with the device language set to EN and to VI, in system light and dark mode, on: iPhone SE, a notched iPhone, iPad, an Android 11 phone and tablet, and an Android 12+ phone.

**Don't**
- Don't use spinners, animation, version numbers, copyright lines or "Loading…".
- Don't use app-icon or ghost artwork (Q32).
- Don't use dynamic or system background colors, or other near-blacks.
- Don't hold the splash, and don't add a Flutter splash route.
- Don't put game names under the tiles.

## 9. Final export checklist

All files are PNG-24 with alpha, sRGB and a transparent background, exported from one layered master (Figma or SVG) with the text as NFC.

**Master**
- [ ] `launch_lockup` master, EN and VI variants (240 × 144 artboard, phone).
- [ ] `splash_games` master (288 × 288 artboard, 192 dp circle guide).
- [ ] `splash_branding` master (200 × 80 artboard).

**iOS:** `Runner/Assets.xcassets/LaunchLockup.imageset` (replaces 1×1 `LaunchImage`)
- [ ] EN (Universal): @1x 240×144, @2x 480×288, @3x 720×432.
- [ ] VI (Vietnamese localization): @1x 240×144, @2x 480×288, @3x 720×432.

**Android API 24–30 phone:** `launch_lockup.png`

| Density | EN `drawable-<dpi>/` | VI `drawable-vi-<dpi>/` |
|---|---|---|
| mdpi | [ ] 240×144 | [ ] 240×144 |
| hdpi | [ ] 360×216 | [ ] 360×216 |
| xhdpi | [ ] 480×288 | [ ] 480×288 |
| xxhdpi | [ ] 720×432 | [ ] 720×432 |
| xxxhdpi | [ ] 960×576 | [ ] 960×576 |

**Android API 24–30 tablet:** `launch_lockup.png`

| Density | EN `drawable-sw600dp-<dpi>/` | VI `drawable-vi-sw600dp-<dpi>/` |
|---|---|---|
| mdpi | [ ] 360×216 | [ ] 360×216 |
| hdpi | [ ] 540×324 | [ ] 540×324 |
| xhdpi | [ ] 720×432 | [ ] 720×432 |
| xxhdpi | [ ] 1080×648 | [ ] 1080×648 |
| xxxhdpi | [ ] 1440×864 | [ ] 1440×864 |

**Android 12+** (not localized): `drawable-<dpi>/`

| Density | `splash_games.png` | `splash_branding.png` |
|---|---|---|
| mdpi | [ ] 288×288 | [ ] 200×80 |
| hdpi | [ ] 432×432 | [ ] 300×120 |
| xhdpi | [ ] 576×576 | [ ] 400×160 |
| xxhdpi | [ ] 864×864 | [ ] 600×240 |
| xxxhdpi | [ ] 1152×1152 | [ ] 800×320 |

**Total:** 6 iOS images, 20 `launch_lockup` PNGs, 10 Android 12+ PNGs.

## 10. Remaining blocker

- **Artwork production.** No binary assets exist yet; the current `LaunchImage*.png` files are 1×1 placeholders. A designer, or a dev export from the app's tile rendering, must produce the masters and the checklist above. Everything else is decided.
