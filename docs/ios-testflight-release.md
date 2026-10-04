# Publishing SpookyMoove to TestFlight

Step-by-step guide for uploading the iOS build of SpookyMoove to TestFlight.

| Item | Value |
|---|---|
| App name (display) | SpookyMoove |
| Bundle ID | `com.spookymoove.app` |
| Apple Team ID | `Z9ZLKTXDX5` |
| Minimum iOS | 15.0 |
| Signing | Automatic (Xcode-managed) |
| Version source | `pubspec.yaml` → `version: 1.0.0+1` (`1.0.0` = marketing version, `1` = build number) |

---

## 0. Release gate: licensing (read first)

Fairy-Stockfish (the Chess/Xiangqi engine bundled via `hook/build.dart`) is GPLv3.
OB-002 / OB-032 flag GPL vs. App Store terms as an **open release blocker**.
TestFlight distribution goes through Apple's App Store terms too.

- **Internal testing** (your own team, up to 100 App Store Connect users, no Beta App Review) is the lowest-risk option while OB-032 is open.
- **External testing** (public link / email invites) requires Beta App Review. Get PO sign-off on OB-032 before you use it.

---

## 1. Prerequisites (one-time)

1. **Apple Developer Program membership** (paid, $99/year) on the account that owns team `Z9ZLKTXDX5`.
   Check at <https://developer.apple.com/account> → Membership details.
2. **Mac tooling**
   ```bash
   xcode-select -p            # should point at Xcode.app
   xcodebuild -version        # use the latest stable Xcode
   flutter doctor -v          # iOS toolchain must be green
   ```
3. **Sign in to Xcode**: Xcode → Settings → Accounts → `+` → Apple ID. Make sure team `Z9ZLKTXDX5` appears.
4. **Agreements**: in App Store Connect → Business, accept the latest **Free Apps Agreement** (and Paid Apps later if monetization ships). Uploads fail if agreements are pending.

---

## 2. Register the App ID (one-time)

1. Go to <https://developer.apple.com/account/resources/identifiers/list>.
2. `+` → **App IDs** → **App** → Continue.
3. Description: `SpookyMoove`. Bundle ID: **Explicit** → `com.spookymoove.app`.
4. Capabilities: leave everything off (the app is offline, with no push, iCloud, or IAP yet).
5. Register.

> If Xcode's automatic signing already created this ID, you'll see it in the list. Skip creating it again.

---

## 3. Create the app record in App Store Connect (one-time)

1. Go to <https://appstoreconnect.apple.com> → **Apps** → `+` → **New App**.
2. Fill in:
   - Platform: **iOS**
   - Name: `SpookyMoove` (must be unique on the App Store; if taken, use e.g. `SpookyMoove – Board Game Advisor`)
   - Primary language: English (or your choice)
   - Bundle ID: `com.spookymoove.app`
   - SKU: `spookymoove-ios` (any internal unique string)
   - User access: Full Access
3. Create.

---

## 4. Prepare the project (per release)

### 4.1 Bump the version

Edit `pubspec.yaml`:

```yaml
version: 1.0.0+1   # first upload
# next uploads: 1.0.0+2, 1.0.0+3, ... (build number must increase every upload)
# new marketing version: 1.1.0+4
```

App Store Connect rejects an upload that reuses a build number for the same version.

### 4.2 Export compliance (recommended, one-time)

The app uses no custom encryption, so declare that in `ios/Runner/Info.plist` to skip the encryption question on every build:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

### 4.3 Privacy manifest check

Apple requires privacy manifests for "required reason" APIs. `shared_preferences` (UserDefaults) ships its own manifest in the plugin. If the upload email warns about `ITMS-91053 Missing API declaration`, add `ios/Runner/PrivacyInfo.xcprivacy` declaring the API it names.

### 4.4 App icon

`ios/Runner/Assets.xcassets/AppIcon.appiconset/` must contain a **1024×1024 PNG with no alpha channel**. Check it:

```bash
sips -g hasAlpha ios/Runner/Assets.xcassets/AppIcon.appiconset/1024.png
```

If `hasAlpha: yes`, re-export it without transparency. Otherwise the upload is rejected.

### 4.5 Signing in Xcode

```bash
open ios/Runner.xcworkspace
```

Runner target → **Signing & Capabilities** (for both Debug and Release):
- ✅ Automatically manage signing
- Team: `Z9ZLKTXDX5`
- Bundle Identifier: `com.spookymoove.app`
- There should be no red errors. Xcode creates the Apple Distribution certificate and provisioning profile when you archive.

---

## 5. Verify a release build locally

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
```

Run the release build on a real iPhone to confirm the native Fairy-Stockfish engine (compiled by `hook/build.dart`) loads and returns moves:

```bash
flutter run --release -d <your-iphone-id>   # list devices: flutter devices
```

Check that a Chess and a Xiangqi session both show engine suggestions. The engine is skipped in host tests, so only a device build proves it works.

---

## 6. Build the archive

### Option A: Flutter CLI (recommended)

```bash
flutter build ipa --release
```

Output:
- Archive: `build/ios/archive/Runner.xcarchive`
- IPA: `build/ios/ipa/*.ipa`

If the IPA export step fails on signing, the `.xcarchive` is still usable. Continue with option B, step 3.

### Option B: Xcode

1. `open ios/Runner.xcworkspace`
2. Select the run destination **Any iOS Device (arm64)**.
3. **Product → Archive**. When it finishes, the Organizer window opens.

---

## 7. Upload to App Store Connect

Pick one:

**Xcode Organizer** (simplest)
1. Window → Organizer → Archives → select the newest `Runner` archive.
2. **Distribute App** → **App Store Connect** → **Upload**.
3. Keep the defaults (automatic signing, upload symbols) → Upload.

**Transporter app** (for the IPA from `flutter build ipa`)
1. Install **Transporter** from the Mac App Store and sign in.
2. Drag `build/ios/ipa/*.ipa` in → **Deliver**.

**Command line**
```bash
xcrun altool --upload-app --type ios \
  -f build/ios/ipa/*.ipa \
  --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
```
(Requires an App Store Connect API key from Users and Access → Integrations, saved as `~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8`.)

---

## 8. Wait for processing

- App Store Connect → Apps → SpookyMoove → **TestFlight** tab.
- The build shows **Processing** for about 5–30 minutes. Apple emails you if processing fails (for example, an icon with alpha or a missing privacy declaration).
- If you skipped step 4.2, answer the **Export Compliance** prompt: "None of the algorithms mentioned above" / no encryption.

---

## 9. Distribute to testers

### Internal testing (no review, available right away)
1. TestFlight → **Internal Testing** → `+` → create a group, e.g. `Core Team`.
2. Add testers. They must be users in App Store Connect (Users and Access) with any role.
3. Add the build to the group. Testers get an email and install it with the **TestFlight** app on their iPhone.

### External testing (requires Beta App Review; see section 0)
1. TestFlight → **External Testing** → `+` → create a group.
2. Fill in **Test Information**: beta description, feedback email, privacy policy URL, and contact info for the review.
3. Add the build → **Submit for Review**. The first review usually takes about 24–48 hours. Later builds of the same version are often auto-approved.
4. Invite testers by email or enable a **Public Link**. External testing allows up to 10,000 testers.

TestFlight builds expire after **90 days**.

---

## 10. Next uploads (checklist)

1. Bump the build number in `pubspec.yaml` (`+N`).
2. `flutter test`, then a release run on a device.
3. `flutter build ipa --release`
4. Upload (Organizer / Transporter).
5. Wait for processing, then add the build to the tester groups.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `No signing certificate "iOS Distribution" found` | Xcode → Settings → Accounts → Manage Certificates → `+` Apple Distribution. |
| `The bundle version must be higher than the previously uploaded version` | Increase `+N` in `pubspec.yaml`. |
| `Invalid large app icon … alpha channel` | Re-export `1024.png` without transparency. |
| `ITMS-91053: Missing API declaration` | Add/extend `PrivacyInfo.xcprivacy` with the reason the email names. |
| Engine doesn't respond in the TestFlight build | Check the release device run (step 5). Confirm `hook/build.dart` built the iOS arm64 library (look at `flutter build ipa -v` output). |
| Upload blocked by agreements | App Store Connect → Business → accept pending agreements. |
| Build stuck in "Processing" for more than 2 hours | Upload again with a higher build number. |
