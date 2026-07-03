# Releasing NomNap

Operational notes and a pre-release checklist for shipping NomNap to the
Android Play Store and Apple App Store. Read the **Gotchas** before every
release — at least one of them silently breaks *release builds only* (they work
fine in `flutter run`).

---

## ⚠️ Gotchas that only bite in release builds

These passed `flutter run` and `flutter analyze` but would have shipped broken.
Re-verify them whenever the native config is regenerated or upgraded.

### 1. Android `INTERNET` permission (ship-blocker)
Flutter injects `android.permission.INTERNET` only into the **debug/profile**
manifests. Release builds use `android/app/src/main/AndroidManifest.xml` alone,
and current Firebase SDKs no longer merge the permission in. Without it the
released app has **no network**, Firebase auth/Firestore never connect, and
every user is stuck on the "Couldn't connect" screen forever.

- It must be declared in `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.INTERNET"/>
  ```
- **Verify the merged release manifest actually contains it** after building:
  ```bash
  grep -c "android.permission.INTERNET" \
    build/app/intermediates/packaged_manifests/release/processReleaseManifestForPackage/AndroidManifest.xml
  # must print a number >= 1
  ```

### 2. Keystore + password backup
The upload keystore (`android/app/upload-keystore.jks`) and `android/key.properties`
are gitignored. **If you lose them you can never publish updates.** Back up both
the keystore file and its password offline. `key.properties.example` shows the
expected shape.

### 3. iOS Firebase config not yet present
`ios/Runner/GoogleService-Info.plist` does **not** exist yet. Dart-level Firebase
+ Crashlytics init works via `lib/firebase_options.dart`, but before shipping iOS:
- add `GoogleService-Info.plist` (from `flutterfire configure` / Firebase console),
- add a "Run Script" build phase to upload dSYMs for symbolicated native crashes.

### 4. Crashlytics Gradle plugin (optional, intentionally omitted)
Dart/Flutter error reporting works with just the existing `google-services`
plugin. The Crashlytics **Gradle** plugin is only needed for native NDK crash
symbolication, which this pure-Flutter app doesn't produce. Don't add it unless
native crashes appear.

### 5. Don't change the SharedPreferences event key
The legacy storage key stays `babytrack.events.v1` on purpose. Changing it makes
existing installs lose their local data on upgrade.

### 6. Windows build prerequisite
`flutter build` with plugins needs **Developer Mode** enabled on Windows
(symlink support): `start ms-settings:developers`.

---

## Production-readiness baseline (established 2026-06-28)

These were fixed during the first production review; keep them intact.

- **Crash reporting:** Firebase Crashlytics is wired through a global error
  funnel in `lib/main.dart` (`runZonedGuarded` + `FlutterError.onError` +
  `platformDispatcher.onError`). Collection is disabled in debug.
- **Guarded writes:** all Firestore writes go through `runGuarded`
  (`lib/widgets/async_action.dart`), which surfaces a localized error dialog
  instead of throwing an unhandled async error. Use it for any new write.
- **Resilient parsing:** `EventTypeX.fromIdOrNull` + `_fromDoc` skip unknown /
  corrupt events so one bad document can't break the whole stream;
  `BabyEvent.decodeList` skips corrupt entries on import.
- **Data integrity:** `BabySession.duration` clamps negative durations to zero.
- **Tests** live under `test/` (model + statistics logic). Run them before every
  release. There are no widget/integration tests yet — add them when touching UI
  flows.

---

## Pre-release checklist

1. `flutter analyze` → **No issues found.**
2. `flutter test` → **all pass.**
3. Bump `version:` in `pubspec.yaml` (`x.y.z+build`). The build number must
   increase for every Play/App Store upload.
4. Confirm the Android INTERNET permission (Gotcha #1) and verify the merged
   release manifest after building.
5. Build the signed Android App Bundle:
   ```bash
   flutter build appbundle --release
   # → build/app/outputs/bundle/release/app-release.aab
   ```
   (`flutter build apk --release` for sideload testing.)
6. Smoke-test the **release** build on a real device with a fresh install:
   anonymous sign-in succeeds, an event logs and survives a relaunch, an invite
   code can be created and redeemed on a second device.
7. iOS (needs macOS + Xcode or a cloud builder like Codemagic): add the Firebase
   plist (Gotcha #3), build, sign, and archive.
8. Store-side: upload the artifact, update `STORE_LISTING.md` content, refresh
   screenshots / Play feature graphic, complete the Data safety form
   (**no data collected** — all data is local or in the user's own Firebase
   household).
9. Keep `docs/privacy.html` alive — it's linked from the store listings and must
   survive any `docs/` rebuild.

---

## Build artifacts & signing reference

- App / bundle ID: **com.nomnap.app** (Android namespace + applicationId, Kotlin
  package, iOS bundle id).
- Android release bundle: `build/app/outputs/bundle/release/app-release.aab`.
- Upload key: `CN=NomNap`, SHA1 `42:2F:F5:2F:CA:D3:49:7A:98:57:19:DE:30:F7:29:98:37:1D:04:B5`.
- Toolchain (as of last successful build): Gradle 8.14, Kotlin 2.2.20,
  AGP 8.11.1, Android platform/build-tools 36, system JDK 22.
- Privacy policy: https://emilgras.github.io/nomnap/privacy.html (source
  `docs/privacy.html`).
