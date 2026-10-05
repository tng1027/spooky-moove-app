# Ticket Analysis

> **Status: Implemented (2026-10-05), awaiting PO sign-off of the Vietnamese copy below (D2) and simulator verification.** Previous: Ready for development (2026-10-05). Priority P1, part of the M1 store release (D1).** All open questions answered by the PO (see Decisions D1–D4); R5, R6 and the technical approach R4 stand as BA recommendations. Done requires PO sign-off of the Vietnamese copy (D2).
>
> Previous status: Draft (2026-10-05), Q1–Q4 open.

TICKET_TYPE: ENHANCEMENT
CONFIDENCE: HIGH

The language capability already exists in a minimal form: the Home `LANGUAGE` key and `LanguageDialog` (OB-051) offer `ENGLISH` only, and the fair-play notice is already bilingual EN/VI (OB-008). The request expands the existing picker to a second language and translates the rest of the UI, so it is an enhancement, not a new feature. It is not a bug (English-only is the decided current behavior, OB-051 REQ-005) and not a duplicate (OB-051 explicitly put translation and localization infrastructure out of scope).

## Ticket Title
[Enhancement] Add Vietnamese as an app language: translate all in-app UI and offer it in the Language dialog

## Summary
Add `TIẾNG VIỆT` next to `ENGLISH` in the Home Language dialog. Every in-app screen, dialog, card line and screen-reader label is shown in the chosen language. On first launch the app follows the device language (Vietnamese device → Vietnamese, anything else → English); a choice made in the dialog is saved and wins from then on. The fair-play notice switches from the device language to the app language (OB-051 D2).

## Business Context
- PO request 2026-10-05: "need to support Vietnamese".
- Closes README Open Question 9 ("App language") and Gap 7 ("Localization/accessibility are not mentioned"). OB-051 D2 already decided what happens to the fair-play notice "once a second app language ships".
- The store listing is already planned in EN + VI (OB-034), and target users may not know chess (or English); plain Vietnamese wording lowers the entry barrier for Vietnamese players, the first non-English market.

## Current Behavior
Source: `settings/domain/app_language.dart`, `settings/presentation/language_dialog.dart`, `new_game/presentation/home_screen.dart`, `fair_play/domain/fair_play_notice.dart`, `fair_play/presentation/fair_play_screen.dart`, `app.dart`, `pubspec.yaml`.
- `AppLanguage` enum has one value (`english`, label `ENGLISH`, spoken `English`); `AppLanguage.current` is a constant. The dialog returns the picked language, but nothing applies or persists it.
- All UI text is English string literals spread across widgets and domain formatters (e.g. `chess_result_format.dart`, `xiangqi_result_format.dart`, `eval_format.dart`, `GameCopy` in `game_registry.dart`, `PersonaTier.label`), with separate English `semanticsLabel` / `spoken*` strings for screen readers (upper-case labels would be spelled out).
- Fair-play notice: bundled EN and VI text (`FairPlayNoticeText`, `fairPlayNoticeVersion` = 4), chosen by the device's first preferred language (`platformDispatcher.locale.languageCode == 'vi'`).
- `MaterialApp` sets no `locale`, `supportedLocales` or `localizationsDelegates`; `flutter_localizations` / `intl` are not dependencies. Persistence uses `shared_preferences` via `sharedPreferencesProvider` (Riverpod), as for the fair-play acknowledgement.
- iOS `Info.plist` has `CFBundleDevelopmentRegion` but no `CFBundleLocalizations`.
- Font: bundled JetBrains Mono covers the full Vietnamese set (checked 2026-10-05: Ệ Ế Ề Ể Ễ Ậ Ộ Ư Ơ Đ … all present), so no new font is needed.

## Expected Behavior
- Language dialog lists `ENGLISH` and `TIẾNG VIỆT`, each written in its own language (OB-051 BR-002), current one selected.
- Picking a language closes the dialog and the whole app switches immediately (no restart), and the choice survives app restarts.
- Without a saved choice, the app language is Vietnamese when the device's preferred language is Vietnamese, otherwise English.
- The fair-play notice (first-launch gate and the FAIR PLAY re-view) uses the app language.

## User Story
As a Vietnamese player who may not read English or know chess terms
I want the whole app in plain Vietnamese
So that I can set up a game and follow the suggestions without guessing what the screens mean.

## Functional Requirements
- REQ-001: Supported languages are English and Vietnamese, kept as data in one place (`AppLanguage`, OB-051 BR-001). Dialog labels: `ENGLISH`, `TIẾNG VIỆT`; spoken: "English", "Tiếng Việt".
- REQ-002: Default language with no saved choice: Vietnamese if the device's first preferred language is Vietnamese (`vi`, any region), English otherwise (R1).
- REQ-003: Picking a language in the dialog applies it at once to every screen and dialog, and saves it locally. Picking the already-selected language just closes the dialog.
- REQ-004: A saved choice wins over the device language on every later launch, including after the device language changes. Without a saved choice, the app follows the device language as read at launch.
- REQ-005: Every user-visible in-app string has an English and a Vietnamese version: Home (header, rows, taglines, hero copy), Settings / Language / About dialogs (headings and keys; license texts themselves stay as published), new-game screen (headings, side cards, helper text, START GAME), advisor screen (top bar, status line states, I PLAYED IT, UNDO / NEW GAME and the discard dialog, suggestion card prompts, timeout / RETRY, game-over results and hints, promotion chooser), and persona tier names (R3).
- REQ-006: Screen-reader labels (`semanticsLabel`, spoken variants, headers, selected states) are translated together with the visible text, and the app reports the chosen locale to the platform so VoiceOver / TalkBack read Vietnamese with a Vietnamese voice.
- REQ-007: Platform-provided strings (e.g. the dialog barrier's "Dismiss" announcement, system back semantics) follow the app language for both supported languages.
- REQ-008: Not translated, in both languages: the app name `SpookyMoove`; move coordinates (`E2 ➔ E4`, `H3 ➔ E3`) and their arrow / capture marks; Xiangqi character discs; the WXF / engine expert line (`EVAL +1.4 | DEPTH 16 | 850k nps`); open-source license texts and engine names.
- REQ-009: Fair-play notice: shown in the app language (OB-051 D2). Text and `fairPlayNoticeVersion` stay unchanged, so switching language never asks for a new acknowledgement. On first launch (no saved choice yet) the notice follows REQ-002, which equals today's behavior.
- REQ-010: Game names: `CHESS` / `XIANGQI` in English; `CỜ VUA` / `CỜ TƯỚNG` in Vietnamese (R2). Side names follow the language (`WHITE` / `BLACK` → `TRẮNG` / `ĐEN`; `RED` / `BLACK` → `ĐỎ` / `ĐEN`).
- REQ-011: Numbers and percentages keep the current format in both languages (`nn%` integer win rate, `.` decimal in the engine line); no dates or currency exist in the app (R5).
- REQ-012: iOS declares English and Vietnamese as supported localizations so the system and App Store recognise Vietnamese.

## Business Rules
- BR-001: No string is shown half-translated: if a Vietnamese string is missing, the build must fail (or a test must fail), never silently show English mid-screen.
- BR-002: Vietnamese copy follows the same rules as English: plain words for people who do not know chess (`productContext.md`), OB-034 positioning / banned-terms rules (in Vietnamese too, e.g. no "gian lận" / "cheating", no "God mode"), upper-case labels as in the design system.
- BR-003: Chess / Xiangqi terms use the standard Vietnamese words (e.g. checkmate `CHIẾU HẾT`, draw `HÒA`), with the plain-wording rule taking priority; the PO approves the final list (D2).
- BR-004: Design system unchanged: tokens only, keys ≥ 48 dp, 360 dp × text scale 2.0 without overflow or clipped diacritics; labels scale down rather than wrap where the English label does today.
- BR-005: The language setting is stored on the device only (no data collection, OB-035 M-D2).

## User Flow
```text
First launch
↓ device language vi? → app language Vietnamese, else English (nothing saved yet)
Fair-play notice in that language → I UNDERSTAND / TÔI ĐÃ HIỂU
↓
Home: [SETTINGS] PICK A GAME [LANGUAGE]   (VI: [CÀI ĐẶT] CHỌN TRÒ CHƠI [NGÔN NGỮ])
↓ tap LANGUAGE
Dialog: LANGUAGE / [ENGLISH] [TIẾNG VIỆT] / [CLOSE]
↓ tap the other language
Dialog closes → whole app re-renders in that language → choice saved
↓ later launches
Saved language used, whatever the device language is
```
Alternative: tap the selected language, CLOSE, barrier or system back → dialog closes, nothing changes, nothing saved.

## Acceptance Criteria
- Given a fresh install on a device set to Vietnamese, When the app starts, Then the fair-play notice and, after acknowledging, Home are in Vietnamese.
- Given a fresh install on a device set to English (or any non-Vietnamese language), When the app starts, Then everything is in English, as today.
- Given Home in English, When the user opens LANGUAGE, Then the dialog lists `ENGLISH` (selected) and `TIẾNG VIỆT`.
- Given the Language dialog, When the user taps `TIẾNG VIỆT`, Then the dialog closes and Home, the new-game screen, the advisor screen and every dialog show Vietnamese text without restarting the app.
- Given the user chose Vietnamese, When the app is killed and relaunched, Then it opens in Vietnamese, even if the device language is English.
- Given the user chose English on a Vietnamese device, When the app is relaunched, Then it stays English, and the fair-play notice opened from FAIR PLAY is English.
- Given the user already acknowledged the fair-play notice, When they switch language, Then they are not asked to acknowledge it again, and the FAIR PLAY re-view shows it in the new language.
- Given Vietnamese, When a Chess game reaches checkmate, stalemate or an automatic draw, and a Xiangqi game reaches CHECKMATE / NO MOVES, Then the result, the winner line and any draw hint are in Vietnamese.
- Given Vietnamese, When a suggestion is shown, Then the move stays in coordinates (`E7 ➔ E5`), the win rate keeps the `nn%` format, and all surrounding labels are Vietnamese.
- Given Vietnamese and VoiceOver / TalkBack on, When focus moves over Home, the new-game screen, the advisor screen and the dialogs, Then every key, header and state is announced in Vietnamese with a Vietnamese voice.
- Given 360 × 640 at text scale 2.0 in Vietnamese, When every screen and dialog renders (incl. the 7-tier row and side cards), Then nothing overflows, no diacritic is clipped, and every key stays ≥ 48 dp tall.
- Given the in-app string catalogue in both languages, When it is checked against the OB-034 banned-terms list, Then no match remains.
- Given a developer adds an English string without its Vietnamese version, When the project is analysed / tested, Then it fails.

## Edge Cases
- Saved value unreadable or unknown (e.g. a removed language): fall back to REQ-002 default; never crash.
- Device preferred list `[en, vi]`: English (first preferred language decides, same as the fair-play rule today).
- Device language changed while the app runs, with no saved choice: picked up on the next launch; no mid-session switch (R1).
- Double tap on a language: one switch, one save.
- Language switched while the Language dialog is the only route above Home: no game is running (the picker exists only on Home), so no in-progress game text needs to re-render.
- Engine timeout / RETRY and "thinking" states shown in Vietnamese too.

## In Scope
- Vietnamese as a second app language; Language dialog with two entries; immediate switch; local persistence; device-language default.
- Translation of all in-app UI strings and screen-reader labels (REQ-005, REQ-006), incl. platform strings (REQ-007).
- Fair-play notice driven by the app language (OB-051 D2), no wording or version change.
- iOS supported-localizations declaration (REQ-012).
- Unit / widget tests: default resolution, persistence, switching, a Vietnamese smoke pass of each screen, missing-string guard, 360 dp × 2.0 checks in Vietnamese. Existing widget tests keep running in English. Integration tests updated (run by the PO, testing policy 2026-10-04).

## Out of Scope
- Store listing / metadata in Vietnamese (name, subtitle, description, keywords, screenshots): owned by OB-034, already planned EN + VI there.
- Languages other than English and Vietnamese.
- A "follow device language" entry in the dialog (R1; can be added later).
- Language key on screens other than Home, or on the fair-play gate (R6).
- Android 13+ per-app language in system settings (`localeConfig`) and iOS per-app language in system Settings beyond REQ-012.
- Changing the fair-play wording or its version; translating license texts.
- Translating move notation, the engine / WXF expert line or Xiangqi characters (REQ-008).
- Right-to-left support, new fonts.

## Dependencies
- OB-051 (Done): Language dialog, `AppLanguage`, decision D2. This ticket revises OB-051 REQ-005 / REQ-006 and its "no localization framework" out-of-scope line.
- OB-008 (Done): fair-play texts EN/VI; only the language source changes.
- OB-034: banned-terms list and positioning rules applied to Vietnamese copy; store listing VI stays there. The tier-7 label is still pending in OB-034, so its Vietnamese name follows that decision.
- OB-052 (implemented, PO verifying): Home rows, taglines, hero copy and new-game screen strings to translate; best started after OB-052 is accepted to avoid translating copy that is still moving.
- OB-033: About / licenses dialog headings translated; license texts not.
- PO sign-off of the Vietnamese copy (D2).

## Decisions
PO, 2026-10-05 (all recommendations accepted):
- D1 (Q1): Vietnamese ships in the **M1 store release** (P1, M1 release readiness). M1 is not releasable without it.
- D2 (Q2): the BA / developer draft the Vietnamese copy (incl. chess / xiangqi terms, BR-003); the **PO signs it off** in one review pass before Done.
- D3 (Q3): persona tier names are translated using the R3 draft (`EM BÉ`, `NHẸ NHÀNG`, `DỄ`, `CÂN BẰNG`, `VỮNG`, `CAO THỦ`); the tier-7 Vietnamese name follows the OB-034 naming decision and is an open item in the PO copy sign-off until then.
- D4 (Q4): default language = device language (R1).
- D5: the app name stays **SpookyMoove** in Vietnamese too (in-app copy, home-screen display name, fair-play notice); no localized display name (REQ-008).

BA recommendations (stand unless the PO objects):
- R1 (accepted, D4): Default = device language (Vietnamese device → Vietnamese, else English); a manual choice is saved and overrides it. No "device default" entry in the dialog.
- R2: Game names translated in Vietnamese UI: `CỜ VUA`, `CỜ TƯỚNG` (what Vietnamese players call them; "Xiangqi" means nothing to them).
- R3 (accepted, D3): Persona tier names translated in Vietnamese (plain-wording rule; users may not read English). Names: Baby `EM BÉ`, Gentle `NHẸ NHÀNG`, Soft `DỄ`, Even `CÂN BẰNG`, Solid `VỮNG`, Master `CAO THỦ`, God → follows the OB-034 tier-7 decision. Emojis unchanged. Must fit the 7-tier row at 360 dp × 2.0.
- R4: Technical approach: in-house typed string catalogue (one Dart interface with an English and a Vietnamese implementation, selected by the app-language provider) plus the SDK's `flutter_localizations` only for Material / Cupertino built-in strings (REQ-007). No `intl` / gen-l10n / ARB: ~150 strings, two languages, no plurals, dates or currency; the compiler enforces completeness (BR-001); matches the existing `FairPlayNoticeText` pattern. Revisit gen-l10n if a third language or external translators arrive.
- R5: No locale-specific number formatting (only integer percentages and a technical engine line).
- R6: No language switch on the fair-play gate: the device-language default already covers first launch.

## Assumptions
- A-1: "Support Vietnamese" means full in-app UI translation, not just the fair-play notice (which already exists).
- A-2: The language picker stays Home-only (OB-051 BR-003).
- A-3: ~~Vietnamese text is drafted by the BA/developer and approved by a native reviewer~~ → decided (D2): BA/developer draft, PO signs off.
- A-4: English copy does not change as part of this ticket.

## Open Questions
None. Q1–Q4 answered by the PO on 2026-10-05 (see Decisions D1–D4). The tier-7 Vietnamese name stays tied to OB-034.

## Developer Handoff
- Extend `AppLanguage` with `vietnamese('TIẾNG VIỆT', spoken: 'Tiếng Việt')` plus a language code; replace the constant `AppLanguage.current` with a Riverpod notifier that resolves saved choice → device language → English and saves through `sharedPreferencesProvider` (same pattern as `fairPlayAcknowledgedProvider`).
- Feed the resolved locale into `MaterialApp.locale` with `supportedLocales` en / vi and `flutter_localizations` delegates (SDK package, add to `pubspec.yaml`), so platform strings and screen-reader voice follow (REQ-006, REQ-007).
- Move UI literals (visible and spoken) into a typed catalogue with EN and VI implementations; domain formatters that return text today (`*_result_format.dart`, `eval_format.dart`, `GameCopy`, `PersonaTier.label`, `GameKind` labels) take the catalogue or return values the UI maps; developer decides. Keep coordinates / expert line untouched.
- `FairPlayNoticeBody.textOf` reads the app language instead of `platformDispatcher.locale`; keep `fairPlayNoticeVersion` = 4.
- Add `CFBundleLocalizations` (en, vi) to iOS `Info.plist`.
- Tests: existing English widget tests stay; add resolution / persistence / switch tests and a Vietnamese 360 × 640 × 2.0 pass. Verify on the iOS simulator in both languages (testing policy 2026-10-03).

## Implementation notes (2026-10-05)
- `AppLanguage` gained `vietnamese` and a `code`; `appLanguageProvider` (`lib/features/settings/application/app_language_controller.dart`) resolves saved choice (`settings.app_language`) → device language → English and saves on pick.
- Catalogue: `AppStrings` (`lib/core/l10n/`), one const instance per language; every field is required, so a missing Vietnamese string does not compile (BR-001). Widgets read `AppStrings.of(context)` through a `LocalizationsDelegate`; game state reads `appStringsProvider`. `GameKind` labels and `GameCopy` moved into it.
- `MaterialApp` gets the app locale, en / vi `supportedLocales` and the `flutter_localizations` delegates (REQ-006/007); iOS `CFBundleLocalizations` = en, vi.
- Fair-play notice follows the app language; `fairPlayNoticeVersion` stays 4.
- Tests: resolution / persistence / switching, a Vietnamese pass of Home, every dialog, both new-game screens, the advisor and the discard dialog at 360 × 640 × 2.0, and a banned-terms scan of all copy sources. Integration tests pin English via the saved setting.

## Vietnamese copy for PO sign-off (D2)
Draft by the developer; PO 2026-10-05 set ĐI LẠI, TÔI NGHE THEO RỒI, TỚI LƯỢT BẠN, CAM KẾT CÔNG BẰNG, MẤT KẾT NỐI, CỜ TRUYỀN THỐNG TRUNG QUỐC. Tier names and descriptions come from OB-054 (approved); the fair-play notice from OB-008 (unchanged). `{…}` are untranslated names (REQ-008). Two-part results keep ` — ` (shown on two lines).

| Key | English | Vietnamese (draft) |
|---|---|---|
| `close` | CLOSE (spoken: Close) | ĐÓNG (spoken: Đóng) |
| `settingsTitle` | SETTINGS (spoken: Settings) | CÀI ĐẶT (spoken: Cài đặt) |
| `settingsEmpty` | NO SETTINGS YET (spoken: No settings yet) | CHƯA CÓ CÀI ĐẶT (spoken: Chưa có cài đặt) |
| `languageTitle` | LANGUAGE (spoken: Language) | NGÔN NGỮ (spoken: Ngôn ngữ) |
| `aboutTitle` | ABOUT & LICENSES (spoken: About and licenses) | THÔNG TIN & GIẤY PHÉP (spoken: Thông tin và giấy phép) |
| `aboutFreeSoftware` | {appName} is free software under {appLicense}. | {appName} là phần mềm tự do theo giấy phép {appLicense}. |
| `aboutEngine` | Chess & Xiangqi engine: {engineName} {engineTag} ({engineLicense}), modified for {appName}. | Bộ máy cờ vua & cờ tướng: {engineName} {engineTag} ({engineLicense}), đã chỉnh sửa cho {appName}. |
| `aboutSourceHeading` | SOURCE CODE | MÃ NGUỒN |
| `aboutReleaseTags` | Each release is tagged v<version>. Engine commit {engineCommit}. | Mỗi bản phát hành được gắn thẻ v<phiên bản>. Commit bộ máy {engineCommit}. |
| `aboutCopySource` | COPY SOURCE URL (spoken: Copy source URL) | SAO CHÉP LINK MÃ NGUỒN (spoken: Sao chép link mã nguồn) |
| `aboutCopied` | COPIED (spoken: Copied) | ĐÃ SAO CHÉP (spoken: Đã sao chép) |
| `aboutViewLicenses` | VIEW LICENSES (spoken: View licenses) | XEM GIẤY PHÉP (spoken: Xem giấy phép) |
| `aboutLegalese` | {appLicense}. Source: {appSourceUrl} | {appLicense}. Mã nguồn: {appSourceUrl} |
| `homeTitle` | PICK A GAME (spoken: Pick a game) | CHỌN TRÒ CHƠI (spoken: Chọn trò chơi) |
| `chessName` | CHESS (spoken: Chess) | CỜ VUA (spoken: Cờ vua) |
| `chessTagline` | CLASSIC STRATEGY (spoken: classic strategy) | CHIẾN THUẬT KINH ĐIỂN (spoken: chiến thuật kinh điển) |
| `xiangqiName` | XIANGQI (spoken: Xiangqi) | CỜ TƯỚNG (spoken: Cờ tướng) |
| `xiangqiTagline` | CHINESE CHESS (spoken: Chinese chess) | CỜ TRUYỀN THỐNG TRUNG QUỐC (spoken: cờ truyền thống Trung Quốc) |
| `white` | WHITE (spoken: White) | TRẮNG (spoken: Trắng) |
| `black` | BLACK (spoken: Black) | ĐEN (spoken: Đen) |
| `red` | RED (spoken: Red) | ĐỎ (spoken: Đỏ) |
| `back` | ‹ BACK (spoken: Back) | ‹ QUAY LẠI (spoken: Quay lại) |
| `fairPlay` | FAIR PLAY (spoken: Fair play) | CAM KẾT CÔNG BẰNG (spoken: Cam kết công bằng) |
| `newGameTitleSpokenPrefix` | New game | Ván mới |
| `playing` | PLAYING | BẠN ĐANG CHƠI |
| `yourSide` | YOUR SIDE (spoken: Your side) | PHE CỦA BẠN (spoken: Phe của bạn) |
| `firstMove` | FIRST MOVE (spoken: first move) | ĐI TRƯỚC (spoken: đi trước) |
| `secondMove` | SECOND MOVE (spoken: second move) | ĐI SAU (spoken: đi sau) |
| `startGame` | START GAME (spoken: Start game) | BẮT ĐẦU (spoken: Bắt đầu) |
| `levelHelper` | YOU CAN CHANGE THE LEVEL WHILE PLAYING | CÓ THỂ ĐỔI CẤP ĐỘ KHI ĐANG CHƠI |
| `newGame` | NEW GAME (spoken: New game) | VÁN MỚI (spoken: Ván mới) |
| `discardTitle` | DISCARD THIS GAME? (spoken: Discard this game?) | BỎ VÁN NÀY? (spoken: Bỏ ván này?) |
| `cancel` | CANCEL | HỦY |
| `gameOver` | GAME OVER | HẾT VÁN |
| `waitingForOpponent` | WAITING FOR OPPONENT (spoken: Waiting for the opponent) | CHỜ ĐỐI THỦ (spoken: Chờ đối thủ) |
| `pickLevelAbove` | PICK A LEVEL ABOVE (spoken: Pick a level above) | CHỌN CẤP ĐỘ Ở TRÊN (spoken: Chọn cấp độ ở trên) |
| `confirmPlayed` | I PLAYED IT (spoken: I played the suggested move) | ĐÃ CHƠI THEO GỢI Ý (spoken: Đã chơi theo gợi ý) |
| `undo` | UNDO (spoken: Undo) | ĐI LẠI (spoken: Đi lại) |
| `pickLevel` | PICK A LEVEL | CHỌN CẤP ĐỘ |
| `thinking` | THINKING... | ĐANG NGHĨ... |
| `suggestionCaption` | SUGGESTION | GỢI Ý |
| `engineError` | AN ERROR OCCURRED | LỖI XẢY RA |
| `retry` | RETRY (spoken: Retry) | THỬ LẠI (spoken: Thử lại) |
| `winRate` | WIN RATE | TỶ LỆ THẮNG |
| `youMateIn` | YOU MATE IN | BẠN CHIẾU TƯỚNG SAU |
| `opponentMatesIn` | OPPONENT MATES IN | ĐỐI THỦ CHIẾU TƯỚNG SAU |
| `percentSpoken` | percent | phần trăm |
| `queenSpoken` … `knightSpoken` | (spoken) Queen, Rook, Bishop, Knight | (spoken) Hậu, Xe, Tượng, Mã |
| `checkmate` | CHECKMATE | CHIẾU TƯỚNG |
| `noMoves` | NO MOVES | HẾT CỜ |
| `youWin` | YOU WIN | BẠN THẮNG |
| `youLose` | YOU LOSE | BẠN THUA |
| `stalemateDraw` | STALEMATE — DRAW | HẾT CỜ — HÒA |
| `drawInsufficientMaterial` | DRAW — NOT ENOUGH PIECES TO WIN | HÒA — KHÔNG ĐỦ CỜ ĐỂ THẮNG |
| `drawFivefold` | DRAW — SAME POSITION 5 TIMES | HÒA — LẶP THẾ CỜ 5 LẦN |
| `drawSeventyFiveMoves` | DRAW — 75 MOVES WITHOUT CAPTURE OR PAWN MOVE | HÒA — 75 NƯỚC KHÔNG ĂN QUÂN HAY ĐI TỐT |
| `hintThreefold` | DRAW POSSIBLE — SAME POSITION 3 TIMES | CÓ THỂ XIN HÒA — LẶP THẾ CỜ 3 LẦN |
| `hintFiftyMoves` | DRAW POSSIBLE — 50 MOVES WITHOUT CAPTURE OR PAWN MOVE | CÓ THỂ XIN HÒA — 50 NƯỚC KHÔNG ĂN QUÂN HAY ĐI TỐT |
