# Fairy-Stockfish & App Store Compliance — Q&A

Ngày: 2026-10-05 · Người trả lời: Developer, BA, Designer · Phạm vi ban đầu: bản iOS `1.0.0+1` (app commit `64cee59`, chưa có tag release).

**Recheck 2026-10-05 22:45:** bản `1.0.0+2`, tag `v1.0.0+2` @ `4550df9` (đã push), IPA `build/ios/ipa/spookymoove.ipa` (export `app-store-connect`, team `Z9ZLKTXDX5`). Các câu có thay đổi được đánh dấu **Recheck**.

> Không phải tư vấn pháp lý. Các câu liên quan GPLv3 §6/§10 và Apple EULA cần counsel xác nhận (`tickets/OB-032`).

## Tóm tắt

**Trạng thái (recheck 2026-10-05): phần GPLv3 kỹ thuật đã đủ; CHƯA sẵn sàng submit App Store** vì còn counsel (OB-032), test trên iPhone thật/TestFlight và store metadata.

Đã ổn:
- Engine build từ source, pin tại commit `433d4115a31ebcf0d9c0e4238b12915b70a0b7c1` (tag `fairy_sf_14_0_1_xq`), không sửa upstream; fork public `tng1027/Fairy-Stockfish`.
- Engine chạy in-process qua Dart FFI, offline, không NNUE, không network/analytics, không tải code động (Guideline 2.5.2 OK).
- Source public: `github.com/tng1027/spooky-moove-app` trả 200 ẩn danh; tag `v1.0.0` và `v1.0.0+2` đã push; `LICENSE`, `NOTICE.md` (modification notice có ngày), `BUILDING.md` (toolchain + cách tự cài).
- App: Settings → ABOUT & LICENSES (GPLv3, tag/commit engine, source URL + COPY, VIEW LICENSES); license Fairy-Stockfish có trong IPA.
- IPA `1.0.0+2` đã kiểm tra: `fairy_stockfish.framework`, 0 file `.nnue`, 2 license asset, `CFBundleLocalizations` en/vi.
- Fair-play notice EN/VI đã sửa (chỉ FIDE/liên đoàn cờ vua, cờ tướng; không còn EGF/Nihon Ki-in, không "cheating"; version 4) và theo ngôn ngữ app (OB-053).
- Cấp "God" đã đổi thành BIG BRAIN / CAO THỦ, mô tả định tính (OB-054); Settings không còn rỗng; Language có ENGLISH + TIẾNG VIỆT.

Blockers còn lại:
1. Counsel chưa xác nhận GPLv3 vs Apple Usage Rules/EULA (OB-032 Q7–Q10; tiền lệ VLC 2011).
2. Chưa test trên iPhone thật, chưa TestFlight (IPA có rồi nhưng chưa upload/chạy).
3. Chưa có store metadata, Review Notes, privacy policy URL, App Privacy answers. (`PrivacyInfo.xcprivacy` + `ITSAppUsesNonExemptEncryption = false` đã thêm sau IPA `1.0.0+2`, có trong release build; vào build upload kế tiếp.)
4. App icon vẫn vẽ Shogi/Go/Gomoku + mặt nạ, nguồn artwork chưa rõ (Q32).
5. License inventory đầy đủ cho mọi dependency chưa lập thành file (Q30).

Quyết định cần PO: chấp nhận rủi ro bị gỡ khi copyright holder khiếu nại; giữ TestFlight internal tới khi OB-032 đóng; "game packs" chỉ chứa dữ liệu; thay app icon.

---

## GPLv3 checklist (recheck 2026-10-05, bản `1.0.0+2`)

| Question | SpookyMoove | Evidence / việc còn lại |
|---|---|---|
| GPL source available? | ✅ | `github.com/tng1027/spooky-moove-app` trả 200 ẩn danh; tag `v1.0.0`, `v1.0.0+2` đã push. |
| Exact version identified? | ✅ | Tag `fairy_sf_14_0_1_xq` (`NOTICE.md`, `lib/core/legal/open_source_info.dart`). |
| Exact commit identified? | ✅ | `433d4115a31ebcf0d9c0e4238b12915b70a0b7c1`. |
| Modifications disclosed? | ✅ | `NOTICE.md` §Modifications (có ngày) + SPDX header trên 3 file shim. |
| Complete corresponding source? | ✅ | App repo public + tag theo từng build; engine fork public `tng1027/Fairy-Stockfish` (nhánh `xq`, tag `fairy_sf_14_0_1_xq` @ `433d411`, trả 200); `.gitmodules` trỏ sang fork; `BUILDING.md` ghi toolchain. |
| GPL license included? | ✅ | Repo: `LICENSE`. IPA: `assets/licenses/fairy_stockfish_copying.txt` (đã kiểm tra trong `spookymoove.ipa`). |
| Copyright notices included? | ✅ | `NOTICE.md`; app đăng ký AUTHORS + GPLv3 qua `registerEngineLicense()`; `fairy_stockfish_authors.txt` có trong IPA. |
| Source link in app? | ✅ | Settings → ABOUT & LICENSES (EN/VI): URL selectable + COPY SOURCE URL; VIEW LICENSES mở `showLicensePage`. |
| User can obtain source? | ✅ | Repo + fork public, tag `v1.0.0+2` trùng commit build IPA. |
| App imposes proprietary restrictions? | ⚠️ | App công bố GPL-3.0-or-later (`LICENSE`, README, About). Còn Apple Standard EULA — OB-032 Q8. |
| Apple EULA conflict? | ❓ counsel | OB-032 Q7–Q9. |
| Dynamic executable download? | ✅ không | |
| Engine network dependency? | ✅ không | |
| DRM preventing GPL rights? | ❓ counsel | App không thêm DRM, nhưng App Store áp FairPlay + Usage Rules (OB-032 Q7). `BUILDING.md` hướng dẫn tự cài bản sửa đổi qua Xcode. |

Release build check (`flutter build ipa`, 2026-10-05 22:44, tag `v1.0.0+2`): `Frameworks/` gồm `App`, `Flutter`, `fairy_stockfish`; 0 file `.nnue`; hai license asset có trong `flutter_assets`; `CFBundleShortVersionString` 1.0.0, `CFBundleVersion` 2; `CFBundleLocalizations` en, vi; ký team `Z9ZLKTXDX5`. IPA này chưa có `PrivacyInfo.xcprivacy` / `ITSAppUsesNonExemptEncryption`; đã thêm vào source sau đó (release build kiểm tra: có cả hai). Chưa làm: kiểm tra About trên iPhone thật.

Kiểm tra trước đó (bản `1.0.0+1`, `flutter build ios --release --no-codesign`): `Frameworks/` gồm `App`, `Flutter`, `fairy_stockfish` (export `fs_start/fs_send/fs_join/fs_free`, chỉ phụ thuộc libc++/Foundation/libSystem); 0 file `.nnue`; hai license asset có trong `flutter_assets`. Chưa làm: build IPA đã ký, kiểm tra About trên iPhone thật.

---

## Q&A

### 1. Fairy-Stockfish đang được tích hợp vào iOS app theo cách nào: source trực tiếp, static library, dynamic library/XCFramework, hay process/module riêng?
- **Developer:** Biên dịch từ source (submodule `third_party/fairy-stockfish`) qua Dart native-assets build hook `hook/build.dart` (`CBuilder.library`, dòng 80–110) cùng shim `native/fairy_stockfish_shim/*`. Kết quả là dynamic framework `fairy_stockfish.framework` trong `Runner.app/Frameworks/` (thấy trong build simulator). Chạy in-process, không phải process riêng.
- **BA:** Đồng ý: source → dynamic library in-process gọi qua Dart FFI. Dạng đóng gói trong archive release cần Developer xác nhận trên `Runner.xcarchive`.
- **Designer:** Ngoài phạm vi. Copy nên ghi "chạy trên máy, offline".

### 2. Fairy-Stockfish có được link trực tiếp vào application binary của SpookyMoove không?
- **Developer:** Không link tĩnh vào `Runner` (`linkModePreference: dynamic`, `hook/build.dart:85`). Dart gọi trực tiếp C qua FFI `@DefaultAsset('package:spookymoove/fairy_stockfish')` (`fairy_stockfish_bindings.dart:4`) — framework nạp vào cùng address space (in-process dynamic linking).
- **BA:** Theo cách hiểu phổ biến của FSF, đây vẫn là combined work. OB-002/OB-032 chốt in-process FFI là kiến trúc cuối cùng.
- **Designer:** Ngoài phạm vi. About nên ghi app "có chứa" Fairy-Stockfish, không ghi "sử dụng dịch vụ".

### 3. Chính xác version/tag/commit nào của Fairy-Stockfish sẽ được đưa vào bản App Store?
- **Developer:** Commit `433d4115a31ebcf0d9c0e4238b12915b70a0b7c1`, tag upstream `fairy_sf_14_0_1_xq` (branch `xq`, 2021-11-19). Ghi trong gitlink và `.gitmodules`. App repo ở `64cee59` ("release v1.0.0"), chưa có git tag.
- **BA:** Chưa thể chứng minh bản submit dùng đúng commit này khi chưa có tag release — Developer cần tag.
- **Designer:** About cần hiển thị version/commit này; Dev cấp hằng số/asset để UI đọc (OB-033 REQ-003).
- **Recheck:** App repo có tag `v1.0.0` và `v1.0.0+2` (đã push); mỗi build upload có tag riêng `v<version>+<build>` (`BUILDING.md`). IPA `1.0.0+2` build từ `4550df9` = tag `v1.0.0+2`.

### 4. Chúng ta có sửa đổi source code của Fairy-Stockfish không? Nếu có, toàn bộ modification đã được xác định và lưu lại chưa?
- **Developer:** Không sửa file upstream (submodule sạch). Thay đổi bên ngoài: `fairy_stockfish_main.cpp` đổi `main` → `fs_main`; `fairy_stockfish_shim.cpp` redirect `cin/cout/cerr` và cung cấp C API `fs_start/fs_send/fs_join`; build defines riêng (`hook/build.dart:92–101`). Tất cả có trong git nhưng chưa có modification notice (GPLv3 §5a).
- **BA:** Đồng ý. Shim + build flags (`LARGEBOARDS`, `NNUE_EMBEDDING_OFF`…) thuộc Corresponding Source; cần notice sửa đổi kèm ngày.
- **Designer:** Nếu coi là modified, About thêm dòng "Modified for SpookyMoove" + link source.
- **Recheck:** Modification notice có ngày trong `NOTICE.md` §Modifications + SPDX header trên shim. ✅

### 5. Có thành phần nào khác của Fairy-Stockfish được bundle không, ngoài engine source/binary?
- **Developer:** Không. Không có NNUE, `variants.ini`, opening book, Syzygy. `pubspec.yaml` chỉ khai báo font và quân cờ.
- **BA:** Đồng nghĩa `Copying.txt`/`AUTHORS` cũng không được bundle → app không mang theo bản GPLv3 (xem Q12).
- **Designer:** Ngoài phạm vi.

### 6. Các NNUE files / evaluation data / embedded assets đi kèm Fairy-Stockfish có license riêng không, và license đó có cho phép App Store distribution không?
- **Developer:** Không bundle NNUE: `NNUE_EMBEDDING_OFF` (`hook/build.dart:98`), `EvalFile` mặc định `<empty>` (`src/ucioption.cpp:206`) → `useNNUE=false`, dùng classical eval (`src/evaluate.cpp:94–106`). Không phát sinh câu hỏi license NNUE.
- **BA:** Đồng ý. Nếu sau này thêm net, Developer + Legal phải kiểm tra license từng net trước.
- **Designer:** Nếu thêm NNUE/data, cần mục riêng trong danh sách license.

### 7. Với đúng binary mà chúng ta submit lên App Store, chúng ta có thể cung cấp Corresponding Source theo yêu cầu GPLv3 không?
- **Developer:** Về kỹ thuật có (submodule pin + `hook/build.dart` + shim + `pubspec.lock`). Chưa sẵn sàng: chưa tag build submit, chưa xác minh repo public, chưa có archive để đối chiếu.
- **BA:** Hiện chưa: repo origin trả 404 ẩn danh, không tag, không LICENSE. Cần public repo + tag đúng commit build (Developer/PO).
- **Designer:** Ngoài phạm vi.
- **Recheck:** Có — repo public, tag `v1.0.0+2` trùng commit IPA, engine fork public. ✅

### 8. Source được cung cấp có thể build lại đúng Fairy-Stockfish binary mà chúng ta phân phối không?
- **Developer:** Tương đương về chức năng: cùng source/defines, `native_toolchain_c` theo `pubspec.lock`, Flutter revision `5fc34683…` (`.metadata`). Xcode/clang không được ghi lại → không đảm bảo bit-identical. Cần build-info cho release.
- **BA:** GPL không đòi bit-identical nhưng cần build được binary tương đương. Thiếu pin toolchain (không `.fvmrc`), `native_toolchain_c` còn experimental.
- **Designer:** Ngoài phạm vi.
- **Recheck:** `BUILDING.md` ghi Flutter 3.47.6 (rev `5fc34683…`), Xcode 27.0, macOS 26.6.2; vẫn không bit-identical (GPL không yêu cầu).

### 9. Chúng ta sẽ cung cấp source code bằng URL nào cho người dùng?
- **Developer:** Chưa xác định; app không chứa URL nào. Ứng viên: `https://github.com/tng1027/spooky-moove-app` — PO/dev cần chốt.
- **BA:** Unknown — PO/Developer chọn URL public, ví dụ GitHub repo + tag `v1.0.0`.
- **Designer:** Đặt nút "SOURCE CODE" dưới mục Fairy-Stockfish trên About, link thẳng tới tag/commit, kèm URL dạng text để chép khi offline.
- **Recheck:** Đã chốt `https://github.com/tng1027/spooky-moove-app` (`OpenSourceInfo.appSourceUrl`), hiển thị trong ABOUT & LICENSES dạng text + nút COPY (không link ngoài → không cần parental gate).

### 10. URL đó có tồn tại và truy cập được trước thời điểm App Store release không?
- **Developer:** Không xác minh được từ repo (không có `gh`). Release owner cần xác nhận.
- **BA:** Hiện **không** — origin trả 404 công khai. Phải là điều kiện bắt buộc trong release checklist (cả TestFlight external). Owner: PO.
- **Designer:** Không release About/screenshot chứa link khi URL chưa hoạt động.
- **Recheck:** Có — trả 200 ẩn danh (cả fork engine và tag `v1.0.0`). ✅

### 11. Source repository có chứa đầy đủ Fairy-Stockfish source, modification, build configuration và các thành phần cần thiết để reproduce binary không?
- **Developer:** Chỉ có gitlink submodule, phụ thuộc upstream GitHub; có build config và shim. Nên fork/mirror hoặc vendor source vào repo/release archive.
- **BA:** Chưa đầy đủ. Đề xuất mirror source engine vào repo public + thêm `BUILDING.md` hướng dẫn build iOS release.
- **Designer:** Ngoài phạm vi.
- **Recheck:** Engine qua submodule trỏ fork public `tng1027/Fairy-Stockfish` (nhánh `xq`, tag giữ nguyên); `BUILDING.md` hướng dẫn build. ✅

### 12. App có hiển thị GPLv3 license và copyright notices phù hợp không?
- **Developer:** Không. `LicenseRegistry` chỉ đăng ký OFL font, Cburnett, Noto Serif TC (`lib/main.dart:26–48`); không có `Copying.txt` của Fairy-Stockfish; không có `showLicensePage`.
- **BA:** Không — release blocker (OB-033).
- **Designer:** Chưa đạt. Thêm entry "Fairy-Stockfish — GPLv3" với toàn văn license + copyright (từ `AUTHORS`), đọc được offline.
- **Recheck:** Có — `registerEngineLicense()` đăng ký GPLv3 + AUTHORS; asset có trong IPA; ABOUT & LICENSES hiển thị tên engine, tag, GPLv3. ✅

### 13. App có một Open Source / Licenses / About screen để người dùng truy cập các thông tin license và source code không?
- **Developer:** Không. `SettingsDialog` chỉ hiện "NO SETTINGS YET" (`settings_dialog.dart:15`); About/Licenses ở trạng thái Planned (OB-033).
- **BA:** Không. OB-033 đã có spec (engine, GPLv3, link source, parental gate) nhưng chưa làm.
- **Designer:** Chưa có. Đề xuất "ABOUT & LICENSES" trong Settings (thay "NO SETTINGS YET"): tên app + version; "Chess & Xiangqi engine: Fairy-Stockfish <version> — GPLv3" với [VIEW LICENSE] [SOURCE CODE]; [OPEN-SOURCE PACKAGES] mở `showLicensePage`. Link ngoài qua parental gate (OB-040).
- **Recheck:** Có — Settings → ABOUT & LICENSES (OB-033): GPLv3, engine tag/commit, source URL + COPY, VIEW LICENSES (`showLicensePage`). Không hiển thị version app (lấy từ `pubspec.yaml`, chưa đưa lên UI). ✅

### 14. App Store Description, Screenshots, Keywords và Promotional Text có mô tả Fairy-Stockfish hoặc open-source components một cách chính xác không?
- **Developer:** Unknown — metadata không có trong repo; chỉ có hướng dẫn ở `docs/marketing-feature-list.md` §5 và OB-034.
- **BA:** Unknown. Marketing doc không nhắc Fairy-Stockfish/open source. Designer/PO soạn listing, không dùng "Stockfish" như thương hiệu app.
- **Designer:** Chưa có metadata. Thêm cuối Description: "Move analysis is powered by the open-source Fairy-Stockfish engine (GPLv3). Source: <URL>." Không dùng "Stockfish" trong tên/subtitle/keywords.

### 15. Chúng ta có đang tuyên bố hoặc ngụ ý rằng SpookyMoove là proprietary/closed-source trong khi GPLv3 obligations có thể áp dụng cho phần mềm kết hợp không?
- **Developer:** Không có LICENSE ở root, README không ghi license, `publish_to: 'none'`. Trên thực tế chưa công bố GPLv3 dù PO đã quyết (`tickets/OB-002:3–5`).
- **BA:** Không có tuyên bố "proprietary", nhưng repo private + không LICENSE + Apple Standard EULA mặc định → thực tế đang "đóng", mâu thuẫn quyết định GPLv3 (OB-002, 2026-10-04). Cần LICENSE GPLv3; Legal xét custom EULA.
- **Designer:** Tránh "proprietary AI"/"our own engine"; dùng "powered by open-source Fairy-Stockfish".
- **Recheck:** `LICENSE` GPLv3 ở root, README có mục License, About ghi "free software under GPL-3.0-or-later". Còn Apple Standard EULA (OB-032 Q8).

### 16. Chúng ta đã xác định chính xác phần nào của SpookyMoove được GPLv3 bao phủ và phần nào độc lập chưa?
- **Developer:** PO quyết định toàn bộ app GPLv3 (OB-002:4). Asset bên thứ ba giữ license riêng (Cburnett BSD, fonts OFL). Chưa phản ánh trong repo; counsel chưa xác nhận.
- **BA:** Đồng ý; không cần vạch ranh giới vì toàn bộ app GPLv3. Thiếu LICENSE/header và xác nhận Legal.
- **Designer:** Ngoài phạm vi.

### 17. Nếu Fairy-Stockfish được sửa đổi hoặc link với application, chúng ta có đáp ứng các yêu cầu GPLv3 đối với combined work không?
- **Developer:** Là combined work (Dart/shim gọi engine in-process). Hướng tuân thủ đã chọn nhưng chưa thực hiện: thiếu LICENSE, URL source public, notice trong app, modification notice.
- **BA:** Chưa. Dependencies đều tương thích GPL (OB-002).
- **Designer:** Ngoài phạm vi.

### 18. Cơ chế iOS code-signing của Apple có ảnh hưởng thế nào đến nghĩa vụ GPLv3 Section 6 / Installation Information trong trường hợp cụ thể của SpookyMoove?
- **Developer:** Người dùng có thể tự build và cài bằng Xcode + Apple ID (`docs/ios-testflight-release.md` §5–6), nhưng cần certificate Apple và không ký được bằng identity app gốc. Áp dụng §6 hay không là câu hỏi cho counsel (OB-032 F3).
- **BA:** Installation Information áp dụng khi object code đi kèm "User Product" trong giao dịch chuyển giao thiết bị; SpookyMoove không bán thiết bị và user có thể tự cài qua Xcode → nhiều ý kiến cho rằng §6 không phải điểm xung đột chính. Điểm thực sự là §10 vs App Store Usage Rules. Legal xác nhận.
- **Designer:** Ngoài phạm vi.

### 19. Người dùng có thể thực hiện các quyền GPLv3 đối với Fairy-Stockfish sau khi tải app từ App Store mà không gặp restriction trái với GPLv3 không?
- **Developer:** Unknown — xung đột tiềm ẩn giữa Apple Usage Rules và GPLv3 §10; ticket ghi "contested" (OB-032:34). Counsel kết luận.
- **BA:** Chưa chắc. FSF coi Usage Rules (giới hạn thiết bị, DRM, cấm phân phối lại) là "further restrictions" — lý do VLC bị gỡ 2011. PO chỉ có thể cấp ngoại lệ §7 cho code mình sở hữu, không thay tác giả Fairy-Stockfish/Stockfish.
- **Designer:** About không được chứa câu hạn chế quyền GPL (vd. "không được sửa đổi/phân phối lại").

### 20. SpookyMoove có tải thêm executable/code từ Internet sau khi App Review hoàn tất không?
- **Developer:** Không. `lib/` không có code mạng (`http` chỉ là transitive, không import); không có ATS/entitlement; không có cơ chế tải code.
- **BA:** Không. "Downloadable game packs" (Planned) chỉ được chứa dữ liệu, không code (2.5.2).
- **Designer:** Copy "Works offline" chỉ đúng khi không tải code.

### 21. Fairy-Stockfish có được download/update dynamically sau khi app được review không, hay toàn bộ engine đã nằm trong app bundle?
- **Developer:** Toàn bộ trong bundle (`Runner.app/Frameworks/fairy_stockfish.framework`), build lúc compile. Không có update động.
- **BA:** Đồng ý.
- **Designer:** "Downloadable game packs" là Planned — không nhắc trong listing.

### 22. App có thực thi code ngoài những executable/code đã được Apple review không?
- **Developer:** Không. Chỉ Flutter AOT, `App.framework`, `fairy_stockfish.framework` (đã ký). Engine chỉ nhận lệnh UCI text (`uci_engine.dart:70–99`).
- **BA:** Không thấy dấu hiệu; cần xác nhận lại trên archive (Q41).
- **Designer:** Ngoài phạm vi.

### 23. App có sử dụng private API, undocumented API, dynamic code loading hoặc JIT để chạy Fairy-Stockfish không?
- **Developer:** Không private API/JIT (release AOT). Framework nạp qua native assets chuẩn của Dart FFI, nhúng và ký trong bundle. Engine dùng pthreads/`std::thread` (`USE_PTHREADS`).
- **BA:** Không. `dart:ffi` là API công khai; shim chỉ dùng thread/stream chuẩn C++.
- **Designer:** Ngoài phạm vi.

### 24. Fairy-Stockfish có chạy hoàn toàn trong app sandbox và sử dụng public iOS APIs không?
- **Developer:** Có. Thread trong process app (`fairy_stockfish_shim.cpp:148`), libc++/pthreads; không entitlements, không truy cập file ngoài sandbox (NNUE tắt).
- **BA:** Có; giới hạn 2 thread (`memory-bank/techContext.md`, OB-010).
- **Designer:** Ngoài phạm vi.

### 25. App có tạo/spawn process riêng cho Fairy-Stockfish trên iOS không?
- **Developer:** Không. `std::thread` + Dart `Isolate.spawn` (`fairy_stockfish_engine.dart:59`); không `Process.start`. Phương án process đã loại vì iOS không cho phép (OB-032:32, OB-002:4).
- **BA:** Không; `main()` đổi thành `fs_main` chạy trên thread.
- **Designer:** Ngoài phạm vi.

### 26. App có hoạt động hoàn toàn offline sau khi cài đặt, bao gồm engine analysis không?
- **Developer:** Theo code: có. Chỉ mới kiểm tra trên simulator (`memory-bank/progress.md:33`); cần test airplane mode trên iPhone thật.
- **BA:** Theo thiết kế có (README "Offline", font bundled). Developer/QA xác nhận trên máy thật.
- **Designer:** Nút [SOURCE CODE] cần trạng thái offline: "No connection — the license text above is available offline."

### 27. App có thu thập analytics, tracking, device identifiers hoặc personal data ngoài những gì đã khai báo không?
- **Developer:** Không. Không có SDK analytics/tracking/crash; `shared_preferences` chỉ lưu trạng thái fair-play notice. CHANGELOG: "No account, ads, analytics, or data collection".
- **BA:** Không (OB-008, OB-040 A-D4, OB-035 M-D2).
- **Designer:** Chỉ dùng copy "No account, no ads, no tracking" khi Dev xác nhận (đã xác nhận ở trên).

### 28. App Privacy answers trong App Store Connect có hoàn toàn khớp với hành vi thực tế của app không?
- **Developer:** Unknown. Theo code, đáp án đúng là "Data Not Collected". Chưa có `PrivacyInfo.xcprivacy` cho app (`docs/ios-testflight-release.md` §4.3).
- **BA:** Unknown — chưa điền; kế hoạch "Data Not Collected" (OB-040). Chưa có privacy policy URL. Owner: PO; Legal duyệt policy.
- **Designer:** Ngoài phạm vi.

### 29. App có yêu cầu account/login hoặc bất kỳ external service nào để sử dụng Fairy-Stockfish không?
- **Developer:** Không; engine khởi động cục bộ (`suggestion_providers.dart:11`).
- **BA:** Không (OB-040, CHANGELOG).
- **Designer:** Không; flow Home → New Game → board không có bước tài khoản, reviewer dùng ngay.

### 30. Tất cả third-party dependencies khác ngoài Fairy-Stockfish đã được lập license inventory chưa?
- **Developer:** Một phần (OB-002:5), chưa có file inventory chính thức. Quét `.dart_tool/package_config.json`: tất cả BSD/MIT/Apache-2.0, không GPL khác. License Flutter engine (Skia, ICU…) qua `LicenseRegistry` nhưng chưa có UI.
- **BA:** Một phần (`chess`, Cburnett, JetBrains Mono, Noto Serif TC). Thiếu `flutter_riverpod`, `flutter_svg`, `ffi`, `shared_preferences`, `logging`, transitive deps — Developer lập từ `pubspec.lock`.
- **Designer:** Assets đã có license kèm (`assets/fonts/OFL.txt`, `assets/pieces/cburnett/LICENSE`, `assets/pieces/xiangqi/OFL.txt`); chỉ hiển thị được khi có màn license (Q13).

### 31. Tất cả third-party licenses có cho phép việc bundle và phân phối qua Apple App Store không?
- **Developer:** Có (BSD/MIT/Apache-2.0/OFL, tương thích GPLv3). Rủi ro duy nhất là GPLv3 của Fairy-Stockfish (Q19, Q42).
- **BA:** Các deps đã biết đều permissive; kết luận cuối phụ thuộc inventory Q30.
- **Designer:** OFL và BSD (Cburnett) cho phép phân phối store; Cburnett ghi rõ chọn BSD và có ghi chú đổi màu viền quân đen.

### 32. App có sử dụng trademark, logo, artwork hoặc tên của bên thứ ba mà chưa có quyền sử dụng không?
- **Developer:** Không thấy logo/artwork bên thứ ba ngoài Cburnett (BSD) và Noto Serif TC (OFL). Fair-play notice nhắc FIDE/EGF dạng mô tả. `branding/appstore.png`, screenshots, tên app: Unknown — PO/legal kiểm tra.
- **BA:** Nguồn/quyền icon trong `branding/` và tra cứu nhãn hiệu "SpookyMoove": Unknown (Designer/Legal). Chỉ dùng "Fairy-Stockfish" để ghi công.
- **Designer:** **Cần sửa.** Icon (`branding/appstore.png`, `AppIcon.appiconset/1024.png`) vẽ quân Shogi (将), Go, dấu X Gomoku — app không có các game này → gây hiểu lầm; hình mặt nạ gợi "stealth". Nguồn gốc artwork (AI? ai giữ quyền?) chưa rõ. Font/quân cờ có license; không có âm thanh; không logo bên thứ ba.

### 33. Fair-play notice có nói rõ rằng app dành cho training/casual/friendly play và không phải công cụ cho rated/tournament play nếu không được phép không?
- **Developer:** Có: "for training, casual study, handicap games…" và "Do NOT use it during rated, sanctioned or tournament games", có bản VI (`fair_play_notice.dart:22–39`). Wording chờ legal review.
- **BA:** Có (OB-008 xong): hiện lần đầu, EN/VI, cấm dùng trong ván rated/giải nếu chưa được trọng tài cho phép. Chờ Legal duyệt.
- **Designer:** Đạt về ý, mở lại được qua nút "FAIR PLAY". Nhưng copy nhắc EGF/Nihon Ki-in (cờ vây) → đổi thành "FIDE, national chess or xiangqi federations, or any other organisation"; thay "cheating" bằng "breaks fair-play rules"; tăng `fairPlayNoticeVersion`. Marketing lặp lại đúng câu "training, casual study, handicap games and friendly offline play".
- **Recheck:** Copy đã sửa: "FIDE, national chess or xiangqi federations, or any other organisation", "breaks fair-play rules" (không còn EGF/Nihon Ki-in/cheating), `fairPlayNoticeVersion` = 4; hiển thị theo ngôn ngữ app (OB-053). Chờ Legal duyệt wording.

### 34. Các claims về engine strength trong App Store metadata có chính xác và có bằng chứng kiểm chứng không?
- **Developer:** Unknown — không có benchmark/Elo; `docs/marketing-feature-list.md:160` cấm claim "Grandmaster-level"/rating khi chưa sign-off.
- **BA:** Chưa có metadata. Engine giới hạn ~900 ms và 2 thread (OB-021 D14) → "Full-strength"/"Maximum strength analysis" có nguy cơ sai (Guideline 2.3). PO sửa wording.
- **Designer:** Không có bằng chứng sức mạnh. Đổi tên cấp "God" (`persona_tier.dart`) thành "Champion" hoặc "Max"; copy chỉ định tính.
- **Recheck:** Cấp 7 đổi thành BIG BRAIN / CAO THỦ với mô tả định tính ("strongest move the app can find"), không claim tuyệt đối (OB-054). Metadata store vẫn chưa có.

### 35. App có hoạt động ổn định trên real iPhones, không chỉ simulator, trước khi submit không?
- **Developer:** Chưa — chỉ simulator (`memory-bank/progress.md:33`, `docs/marketing-feature-list.md:149`). Cần `flutter run --release` trên iPhone thật cho Chess và Xiangqi + `integration_test/fairy_stockfish_engine_test.dart`.
- **BA:** Không. Commit "release v1.0.0" và CHANGELOG có trước khi test thiết bị.
- **Designer:** Unknown. Cần kiểm tra trên máy thật: độ dễ đọc, vùng chạm, notch/Dynamic Island, cỡ chữ hệ thống lớn.

### 36. App có vượt qua TestFlight testing trên các thiết bị iPhone mục tiêu không?
- **Developer:** Unknown — không có kết quả TestFlight; docs khuyến nghị chỉ test internal khi OB-032 còn mở.
- **BA:** Unknown, nhiều khả năng chưa (chỉ có build simulator). QA/Developer chạy TestFlight internal trên iPhone mục tiêu (A12+, iOS 15+).
- **Designer:** Unknown. Thêm checklist duyệt UI vào TestFlight: About, Fair Play, Settings.

### 37. Có bất kỳ feature nào được mô tả trong App Store nhưng chưa hoàn thiện hoặc chưa được test trên thiết bị thật không?
- **Developer:** Có rủi ro: "Fast suggestions" và "about 10 MB" chưa xác nhận trên máy thật; Settings placeholder; About/Licenses Planned; restyle In progress (`docs/marketing-feature-list.md:45,102,110–111,128`).
- **BA:** Có. CHANGELOG liệt kê "Settings and Language dialogs" trong khi Settings là placeholder. Không đưa vào metadata; xét ẩn Settings rỗng (2.1). Owner: PO.
- **Designer:** Có rủi ro. Listing/screenshot không nhắc Settings, ngôn ngữ, tablet, lịch sử ván, Shogi/Go/Gomoku, "≈1s / 10MB". Ẩn nút Settings/ngôn ngữ hoặc để Settings chỉ chứa About.
- **Recheck:** Settings có ABOUT & LICENSES; Language có ENGLISH + TIẾNG VIỆT (OB-053). "Fast suggestions" / "about 10 MB" vẫn chưa đo trên máy thật.

### 38. App có đáp ứng App Review Guideline về minimum functionality và cung cấp utility/experience thực sự native không?
- **Developer:** Theo code đáp ứng: Flutter native, luật Chess/Xiangqi, engine on-device, 7 level, undo, haptics; không phải web wrapper.
- **BA:** Nhiều khả năng đạt; rủi ro nhỏ từ Settings rỗng và nút ngôn ngữ một lựa chọn.
- **Designer:** Về cơ bản có giá trị thật (2 game, 7 cấp, offline, haptics, nhãn screen reader). Bỏ placeholder; screenshot thể hiện bối cảnh dùng với bàn cờ thật.
- **Recheck:** Không còn placeholder (Settings có About, Language 2 lựa chọn).

### 39. App Review Notes có giải thích rõ Fairy-Stockfish được sử dụng ở đâu, license là GPLv3, source code ở đâu và cách reviewer kiểm tra feature này không?
- **Developer:** Chưa có bản nháp. Cần nêu: Fairy-Stockfish (GPLv3), commit `433d411`, URL source, cách kiểm tra (New game → đi một nước → xem suggestion).
- **BA:** Chưa có (OB-034 mới là checklist). Ghi: engine offline on-device, URL source + tag, cách test (Home → Chess → chọn bên/cấp → nhập nước → xem gợi ý), mục đích dùng với bàn cờ thật.
- **Designer:** Đề xuất: *"SpookyMoove is an offline training companion for physical Chess/Xiangqi boards. Tap Chess → START GAME, enter moves with two taps; the suggestion card is computed on-device by Fairy-Stockfish (GPLv3), linked into the app; no network or account needed. License text and source link: Settings → About & Licenses. Source: <URL @ commit>. A fair-play notice appears on first launch (reopen via FAIR PLAY)."*

### 40. Nếu Apple hỏi về GPLv3/Fairy-Stockfish trong review, chúng ta có thể cung cấp ngay license, exact source commit, corresponding source và build information không?
- **Developer:** Có ngay: license (`third_party/fairy-stockfish/Copying.txt`), commit `433d411`, build config (`hook/build.dart`). Thiếu: URL source public đã xác minh, tag app repo, build-info (Xcode/Flutter).
- **BA:** Hiện chưa. Chuẩn bị "compliance pack" trước khi submit (Developer/PO).
- **Designer:** Chuẩn bị sẵn screenshot About và màn license để gửi kèm.
- **Recheck:** Có: license, commit `433d411`, URL public, tag `v1.0.0+2`, toolchain (`BUILDING.md`). Còn soạn Review Notes (Q39).

### 41. Toàn bộ thông tin trên đã được kiểm tra lại trên chính archive/IPA build sẽ submit, thay vì chỉ kiểm tra source repository chưa?
- **Developer:** Chưa. Không có `build/ios/archive` hay `build/ios/ipa`, chỉ build Debug simulator. Cần `flutter build ipa --release` rồi kiểm tra framework, không NNUE, notice, commit/tag.
- **BA:** Chưa. Kiểm tra thêm privacy manifest và `ITSAppUsesNonExemptEncryption` (chưa có trong `Info.plist`, khuyến nghị ở `docs/ios-testflight-release.md` §4.2).
- **Designer:** Chụp About/license/Fair Play trên đúng IPA submit để version khớp `1.0.0+1`.
- **Recheck:** IPA `1.0.0+2` đã kiểm tra: framework engine có, 0 `.nnue`, license assets có, version 1.0.0 (2), localizations en/vi. Thiếu `PrivacyInfo.xcprivacy` và `ITSAppUsesNonExemptEncryption`. Chưa chụp About trên máy thật.

### 42. Có bất kỳ điều khoản nào trong Apple Developer Program License Agreement / App Review Guidelines mâu thuẫn với cách chúng ta đang phân phối Fairy-Stockfish không?
- **Developer:** Unknown — GPLv3 vs Usage Rules/DPLA đang tranh cãi (OB-032:34); `docs/ios-testflight-release.md:17–22` đánh dấu release blocker. Counsel kết luận.
- **BA:** Xung đột tiềm ẩn: Apple Standard EULA (Usage Rules) vs GPLv3 §10 (tiền lệ VLC 2011). Guidelines 2.5.2, 4.2, 5.1 không có vẻ xung đột. Context: SmallFish, Lichess (GPL, dùng Stockfish) vẫn có trên App Store — không phải bảo đảm pháp lý. Legal xác nhận (OB-032 Q2).
- **Designer:** Ngoài phạm vi.

---

References: [Fairy-Stockfish](https://github.com/fairy-stockfish/Fairy-Stockfish), [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), [Apple Developer terms](https://developer.apple.com/support/terms)
