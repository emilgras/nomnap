# NomNap

A cozy, iOS-elegant baby tracker. Four actions: **start sleep**, **end sleep**, **start feed**, **end feed**. The app handles all the timing math. Everything is stored locally on the device — no account, no backend.

> Logo and brand assets live in [assets/logo/](assets/logo/). Open [assets/logo/preview.html](assets/logo/preview.html) in a browser to see the icon, mark, wordmark, and a fake home-screen.

Built with **Flutter** so a single codebase ships native binaries for both Google Play and the Apple App Store.

---

## What's inside

- **Track tab** — two big cards (Sleep, Feed). One tap to start, one tap to stop. Live timer while a session is active. Today's totals + recent activity below.
- **Stats tab** — daily averages, session averages, longest sleep, and a per-day breakdown.
- **History tab** — every event, grouped by day. Tap a row to edit its time or delete it. Trash icon clears everything.
- **Offline-first** — all data persisted with `shared_preferences`. No login, no network.
- **Cupertino UI** — uses Flutter's iOS widget set so the app feels native on iPhone and clean on Android.

## Project structure

```
lib/
├── main.dart                       App entry, CupertinoApp theme
├── models/
│   └── baby_event.dart             Event model + JSON serialization
├── services/
│   ├── event_store.dart            ChangeNotifier-backed persistent store
│   └── statistics.dart             Sessions, daily totals, averages
├── theme/
│   └── app_theme.dart              Colors, text styles, radii
├── widgets/
│   ├── format.dart                 Duration / time formatting helpers
│   └── section_card.dart           Reusable card + section header
└── screens/
    ├── app_shell.dart              CupertinoTabScaffold (3 tabs)
    ├── tracker_screen.dart         Sleep + Feed action cards
    ├── stats_screen.dart           Averages and daily breakdown
    └── history_screen.dart         Editable event history
```

## Run locally

```bash
flutter pub get
flutter run                  # pick a device when prompted
flutter run -d chrome        # web smoke test
```

## Shipping to Google Play (Android)

App identity, release signing, and the build config are **already done**:

- **Application ID**: `com.nomnap.app` (set in `android/app/build.gradle.kts` and the
  iOS project; the Dart package is `nomnap`).
- **Upload keystore**: `android/app/upload-keystore.jks` (gitignored), wired up via
  `android/key.properties` (gitignored). `build.gradle.kts` loads it automatically for
  release builds and falls back to debug signing when the file is absent.

> ⚠️ **Back up the keystore + password.** `android/app/upload-keystore.jks` and the
> password in `android/key.properties` are the *only* way to publish future updates to
> this app. If you lose them you can never update the app again. Copy both into a
> password manager / secure backup now. They are gitignored on purpose, so they are
> **not** in version control.

What's left is local tooling + the build, which need the Android SDK:

1. **Install Android Studio** → https://developer.android.com/studio
   On first launch it installs the Android SDK. Then run `flutter doctor --android-licenses` and accept all licenses.
2. **Confirm setup**: `flutter doctor` should show a green check for "Android toolchain".
3. **Build the App Bundle** (the format Google Play wants):
   ```bash
   flutter build appbundle --release
   ```
   Output: `build/app/outputs/bundle/release/app-release.aab` — upload this to the Play Console.
4. **Create a Play Console account** ($25 one-time), complete the store listing, content
   rating, and Data safety form (declare: no data collected/shared — see the privacy
   policy), then upload the `.aab`.

**Privacy policy** (required by both stores) is published at
https://emilgras.github.io/nomnap/privacy.html (source: [docs/privacy.html](docs/privacy.html)).

## Shipping to the App Store (iOS)

Building an `.ipa` file requires **macOS + Xcode** — Apple does not support iOS builds from Windows. Two options:

- **Borrow a Mac** for the build/submit step. Code is identical, just clone and run `flutter build ipa --release`.
- **Codemagic** (https://codemagic.io) — free tier covers a personal project, builds iOS in the cloud from your Windows repo, can auto-submit to App Store Connect.

You'll need an Apple Developer account ($99/year) and to set up an App ID + provisioning profile in App Store Connect. The Flutter docs cover this here: https://docs.flutter.dev/deployment/ios

## Storage notes

Events are persisted as JSON in `SharedPreferences` under the key `babytrack.events.v1` (key intentionally kept stable across the BabyTrack → NomNap rename so existing installs don't lose data). On Android this is backed by `SharedPreferences` (cleared if the user clears app data); on iOS it's `NSUserDefaults`. If you ever want cloud sync later, the `EventStore` is the only file that needs to change.
