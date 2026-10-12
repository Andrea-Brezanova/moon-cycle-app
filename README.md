# Moon Cycle

Cycle-aware food guidance, recipes and a shopping list, for iOS and Android, built with Flutter. v1 is local-only: no account, and all data stays on the phone.

## Requirements
- **Flutter 3.47.7 (stable) with Dart 3.13.5.** CI uses the same version.
- **Android:** Android Studio with the Android SDK; run `flutter doctor --android-licenses` once.
- **iOS:** Xcode, plus the iOS Simulator runtime. Xcode isn't needed for Android work.

Check your setup with `flutter doctor`.

## First run
1. Create your local env files from the templates (they're git-ignored):
   ```bash
   cp env/dev.example.json env/dev.json
   ```
   ```bash
   cp env/prod.example.json env/prod.json
   ```
2. Get packages:
   ```bash
   flutter pub get
   ```
3. Run the dev flavour (or pick "Moon Cycle (dev)" in Cursor's Run and Debug panel):
   ```bash
   flutter run --flavor dev --dart-define-from-file=env/dev.json
   ```

Always pass both the flavour and its env file. The app refuses to start if they don't match.

## Flavours
| Flavour | Bundle / application ID | Name on the phone | Use |
|---|---|---|---|
| `dev` | `app.mooncycle.mobile.dev` | Moon Cycle Dev | Daily development; installs next to prod |
| `prod` | `app.mooncycle.mobile` | Moon Cycle | TestFlight, Play testing and the stores |

A staging flavour is added with Supabase in v1.1.

## Checks (the same as CI)
```bash
dart format --output=none --set-exit-if-changed lib test tool
```
```bash
flutter analyze
```
```bash
dart run tool/check_layers.dart
```
```bash
flutter test --exclude-tags golden
```

Golden screenshot tests run locally on macOS (CI skips them):
```bash
flutter test --tags golden
```
After an intentional visual change, regenerate them with `flutter test --tags golden --update-goldens` and check the images in `test/goldens/goldens/`.

To look at every component: run the dev flavour and tap **Component gallery** (debug builds only).

## Repository map
| Path | What it is |
|---|---|
| `lib/` | App code. See `docs/architecture.md` for the folder map and dependency rules |
| `test/` | Tests, mirroring `lib/` |
| `design/` | **Read-only** Editorial v3 handoff: spec, screen PNGs (the visual source of truth), reference tokens and assets. Don't edit or regenerate these files |
| `docs/` | `architecture.md`, `decisions.md`, `design-deviations.md`, `technical-plan.md` (milestones) |
| `assets/` | Fonts, wordmark, lockups and phase-ring mark, copied from `design/assets/` |
| `env/` | Per-flavour build settings. Only the `*.example.json` templates are committed |
| `tool/` | `check_layers.dart`: keeps `domain/` code free of Flutter and database imports, and of `DateTime.now(` |
| `android/`, `ios/` | Native projects, with the flavours configured |

The handoff's PDFs and zip aren't in this repository; they're archived with the design files outside it.

## Status
Milestones 1 (foundation), 2 (cycle domain), 3 (Editorial design system) and 4 (shell and navigation, with placeholder screens) are in place. The next milestone is the local database; see `docs/technical-plan.md`.
