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

The code is ready. You just need the Android toolchain locally.

1. **Install Android Studio** → https://developer.android.com/studio
   On first launch it installs the Android SDK. Then run `flutter doctor --android-licenses` and accept all licenses.
2. **Confirm setup**: `flutter doctor` should show a green check for "Android toolchain".
3. **Generate a release keystore** (one-time):
   ```bash
   keytool -genkey -v -keystore %USERPROFILE%\babytrack-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
4. **Wire the keystore** — create `android/key.properties`:
   ```
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=C:/Users/egr/babytrack-upload.jks
   ```
   And edit `android/app/build.gradle.kts` to load it. Flutter's docs walk through this: https://docs.flutter.dev/deployment/android#signing-the-app
5. **Build the App Bundle** (the format Google Play wants):
   ```bash
   flutter build appbundle --release
   ```
   Output: `build/app/outputs/bundle/release/app-release.aab` — upload this to the Play Console.

Bundle ID is currently `com.babytrack.babytrack` (the project's original internal name; only Dart code and bundle ids still carry it — user-facing branding is NomNap). Change it in `android/app/build.gradle.kts` (`applicationId`) before your first Play submission if you want a `com.nomnap.*` identifier.

## Shipping to the App Store (iOS)

Building an `.ipa` file requires **macOS + Xcode** — Apple does not support iOS builds from Windows. Two options:

- **Borrow a Mac** for the build/submit step. Code is identical, just clone and run `flutter build ipa --release`.
- **Codemagic** (https://codemagic.io) — free tier covers a personal project, builds iOS in the cloud from your Windows repo, can auto-submit to App Store Connect.

You'll need an Apple Developer account ($99/year) and to set up an App ID + provisioning profile in App Store Connect. The Flutter docs cover this here: https://docs.flutter.dev/deployment/ios

## Storage notes

Events are persisted as JSON in `SharedPreferences` under the key `babytrack.events.v1` (key intentionally kept stable across the BabyTrack → NomNap rename so existing installs don't lose data). On Android this is backed by `SharedPreferences` (cleared if the user clears app data); on iOS it's `NSUserDefaults`. If you ever want cloud sync later, the `EventStore` is the only file that needs to change.
