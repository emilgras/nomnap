# Store assets

Marketing images for the Google Play and Apple App Store listings — the images
users see when browsing the store. Organized by **language**, because that's the
only thing that actually changes: the captions and the app UI are translated,
but the *same* screenshots are used for both stores.

```
store_assets/
├── shared/     ← store-wide graphics that aren't per-language
├── en/  da/  nb/  sv/  fi/  is/   ← one screenshot set per language
```

## One size that works for both stores

Make each screenshot at **1290 × 2796 px (portrait)**. That is exactly Apple's
required 6.9" iPhone size, and Google Play accepts it as a phone screenshot too —
so one set per language covers both stores. Provide **2–8** screenshots per
language (both stores are happy in that range).

Put the finished screenshots directly in the language folder, e.g.:

```
en/01_track.png  en/02_stats.png  en/03_history.png  en/04_share.png
da/01_track.png  da/02_stats.png  ...
```

Keep the same base names across languages so each shot lines up with its
translation.

## shared/ — not per-language

| File | Size | Used by | Notes |
|------|------|---------|-------|
| `icon_512.png`            | 512×512 (PNG, alpha)  | Play only  | Play listing icon. iOS pulls its marketing icon from the app itself. |
| `feature_graphic_1024x500.png` | 1024×500 (no alpha) | Play only | Required banner on the Play listing. |

These have no text, so they're the same for every language — hence `shared/`
rather than copies in each folder.

## Upload locale codes (the folder name → store name)

The stores use slightly different codes than the app's, so map them at upload:

| Folder (app locale) | Language          | Play code | App Store code |
|---------------------|-------------------|-----------|----------------|
| `en`                | English (default) | `en-US`   | `en-US`        |
| `da`                | Danish            | `da-DK`   | `da`           |
| `nb`                | Norwegian Bokmål  | `no-NO`   | `no`           |
| `sv`                | Swedish           | `sv-SE`   | `sv`           |
| `fi`                | Finnish           | `fi-FI`   | `fi`           |
| `is`                | Icelandic         | `is-IS` * | — (unsupported)|

\* Icelandic: **App Store has no Icelandic localization**, so those users see the
English listing — the `is/` set is Play-only (and only if the Play Console lists
Icelandic; otherwise it also falls back to English). English is the default
listing on both stores — fill it first; any empty locale inherits it.

## Not included (optional, add later if you want)

- **Tablet / iPad screenshots** — only needed if you want device-specific art;
  both stores otherwise scale the phone set. iPad screenshots are required *only*
  if you ship an iPad build.
