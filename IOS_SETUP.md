# iOS setup & shipping guide (Mac + Xcode)

Written for picking the project up on a **Mac** to build, test, and eventually
ship the iOS app. NomNap has been developed entirely on Windows so far and has
**never been built for iOS** — this is the first-time setup. Read it top to
bottom; the repo-specific traps are called out inline and recapped at the end.

> Companion doc: [`RELEASE.md`](RELEASE.md) covers Android release + cross-platform
> gotchas and the production-readiness baseline. This doc is iOS-only.

---

## The mental model (VS Code vs Xcode)

You use **both**, for different jobs. You do **not** "develop in Xcode" the way
you would a native app.

| Task | Tool |
|---|---|
| Edit Dart, run / hot-reload, `flutter build`, use Claude | **VS Code** (or a terminal) — your primary driver |
| iOS signing, capabilities, add `GoogleService-Info.plist`, final Archive → upload | **Xcode** |

When you open Xcode, open **`ios/Runner.xcworkspace`** — **never**
`ios/Runner.xcodeproj`. The `.xcworkspace` is the one that includes the
CocoaPods dependencies; opening the bare project fails to build.

Plan: install VS Code on the Mac, clone the repo, run/iterate from VS Code, and
drop into Xcode only for the iOS plumbing below.

---

## Project facts (so you don't have to rediscover them)

- Flutter app. Bundle / app ID: **`com.nomnap.app`** (already set in the iOS
  project — no change needed).
- Backend: Firebase project **`nomnap-d3f25`** — anonymous auth + Firestore
  (EU), invite-code caregiver sharing, plus Crashlytics. Firebase is initialized
  from `lib/firebase_options.dart`, which **already contains the iOS keys**.
- Crash reporting: `firebase_crashlytics` is wired via a global error funnel in
  `lib/main.dart` (disabled in debug).
- iOS project uses the modern template (`SceneDelegate.swift` present).
- Tests live in `test/` — run `flutter test` anytime.

### Repo-specific iOS traps (details in the steps)
1. **`ios/Runner/GoogleService-Info.plist` is missing** — must be downloaded and
   added to the Runner target.
2. **iOS deployment target is `13.0`** in the Xcode project — too low for the
   current Firebase pods. Bump to **15.0** or `pod install` fails.
3. **No `ios/Podfile` exists yet** — it's generated on first build; then set its
   platform line.

---

## Step 1 — Mac toolchain

After the macOS + Xcode updates finish:

1. **Xcode** — install/update from the App Store, launch once to let it finish
   installing components, then:
   ```bash
   sudo xcodebuild -license accept
   xcode-select --install          # command-line tools
   ```
   Apple Silicon Mac only:
   ```bash
   sudo softwareupdate --install-rosetta --agree-to-license
   ```

2. **Homebrew** — https://brew.sh (if not already installed).

3. **CocoaPods** — install via Homebrew, **not** `sudo gem install` (recent macOS
   ships a locked-down system Ruby that breaks that route):
   ```bash
   brew install cocoapods
   ```

4. **Flutter** (it's only on the Windows box today):
   ```bash
   brew install --cask flutter     # or download the SDK from flutter.dev
   ```

5. **VS Code** + the **Flutter** extension (Marketplace). It pulls in the Dart
   extension automatically.

6. **Verify the whole chain:**
   ```bash
   flutter doctor -v
   ```
   You want green checks on **Xcode** and **CocoaPods**. Resolve anything it
   flags before continuing.

---

## Step 2 — Get the project

```bash
git clone https://github.com/emilgras/nomnap.git
cd nomnap
flutter pub get
```

Everything (production-readiness fixes, Crashlytics, tests) is already on
`origin/main`, so a fresh clone is complete. Sanity check:
```bash
flutter analyze     # expect: No issues found
flutter test        # expect: all pass
```

---

## Step 3 — iOS-specific prep

### 3a. Add the missing Firebase iOS config
- Firebase Console → project **`nomnap-d3f25`** → **Project settings → Your apps**.
- If an **iOS app** with bundle ID `com.nomnap.app` exists, **download
  `GoogleService-Info.plist`**. If not, **Add app → iOS**, bundle ID
  `com.nomnap.app`, then download it.
- Keep the file handy — you add it to the Xcode **target** in Step 4 (not just
  the folder; target membership matters).

### 3b. Bump the iOS deployment target (do this or pods fail)
The Xcode project is at **iOS 13.0**; the current Firebase pods need a higher
minimum. Use **15.0** (iOS 13/14 are effectively dead in 2026):

```bash
# Generate the Podfile + native config without a full build:
flutter build ios --config-only
```
Then edit **`ios/Podfile`** — near the top set:
```ruby
platform :ios, '15.0'
```
Also set it in Xcode (Step 4): Runner target → **General → Minimum Deployments →
iOS 15.0**. Then:
```bash
cd ios && pod install && cd ..
```
If `pod install` still complains about the deployment target, raise both the
Podfile line and the Xcode setting to whatever version the error names, and
re-run.

> Consider committing the resulting `ios/Podfile` and the deployment-target bump
> so future clones don't repeat this. Ask Claude to make it a permanent change.

---

## Step 4 — Xcode: signing + the plist

```bash
open ios/Runner.xcworkspace
```

1. Select the **Runner** project → **Runner** target → **Signing & Capabilities**.
2. Check **Automatically manage signing**, choose your **Team**:
   - A **free Apple ID** can run on **your own device** (7-day provisioning,
     re-sign weekly) — enough to test.
   - **TestFlight / App Store** needs the **Apple Developer Program ($99/yr)**.
3. Confirm **Bundle Identifier = `com.nomnap.app`** (already set).
4. **Add the plist:** drag `GoogleService-Info.plist` into the **Runner** group in
   Xcode's navigator → in the dialog tick **Copy items if needed** and check the
   **Runner** target checkbox.
5. (Optional, later) For native crash symbolication, add the Crashlytics dSYM
   upload Run Script per Firebase docs. Dart/Flutter errors already report
   without it — skip for now.

---

## Step 5 — Run it

**Simulator** (fastest loop):
```bash
open -a Simulator
flutter run
```

**Your physical iPhone** (recommended — real network / Firebase behavior):
- Plug in, unlock, tap **Trust**.
- After first install, on the phone: **Settings → General → VPN & Device
  Management → trust your developer certificate**.
- ```bash
  flutter devices            # find the device id
  flutter run -d <device-id>
  ```

Run from VS Code's Run panel or the terminal — **not** Xcode's Run button for
day-to-day testing.

**Smoke test on device:**
- Anonymous sign-in succeeds (no login screen, lands on the tracker).
- Log a sleep/feed/diaper event; kill and relaunch — it's still there.
- Create an invite code, redeem it on a second device — data appears live.
- Toggle airplane mode: writes still work offline and sync on reconnect.

---

## Step 6 — Build for TestFlight / App Store (needs the $99/yr program)

```bash
flutter build ipa --release
```
Produces `build/ios/archive/Runner.xcarchive` and an `.ipa` in
`build/ios/ipa/`. Upload with either:
- **Xcode → Window → Organizer** → select the archive → **Distribute App**, or
- the **Transporter** app (Mac App Store) using the `.ipa`.

Then in **App Store Connect**:
- Create the app record (bundle `com.nomnap.app`).
- Fill the listing — reuse `STORE_LISTING.md`.
- Complete the **privacy** questionnaire: **no data collected** — all data is
  local or in the user's own Firebase household.
- Link the privacy policy: https://emilgras.github.io/nomnap/privacy.html
- Submit to TestFlight (internal testing) or App Review.

Bump `version:` in `pubspec.yaml` (`x.y.z+build`) — the **build number must
increase** for every upload to App Store Connect.

---

## Gotcha recap
1. Open **`Runner.xcworkspace`**, never `Runner.xcodeproj`.
2. **`GoogleService-Info.plist` is missing** — download it, add it to the
   **Runner target** (target membership, not just the folder).
3. **Deployment target 13.0 → 15.0** in the Podfile *and* Xcode, or `pod install`
   fails.
4. Install CocoaPods via **`brew install cocoapods`**, not `sudo gem install`.
5. **Free Apple ID = on-device testing only**; TestFlight/App Store needs the
   paid Developer Program.
6. Drive builds from **VS Code / terminal** (Flutter); use **Xcode** only for
   signing, the plist, and the final Archive → upload.
