# Decisions

One list of the decisions that shape this repository, newest first. Add a line when a decision changes, with the date and the reason.

## 11 October 2026: Milestone 7 (onboarding)
- **Measurements from the canvas source:** the Editorial artboards' HTML (`Ed*.dc.html`, read from the design canvas) gives exact sizes, gaps and colours; the PNGs are the visual check. Golden screenshots of every onboarding screen in both themes are compared side by side with the PNGs.
- **Each step is a route** (`/onboarding`, `/onboarding/last-period`, …), so Android back and iOS swipe-back go one step back with answers kept. The answers live in memory until step 4, then one transaction saves the period, profile, diet, avoidances and "onboarding complete" (plan §7.2). The reveal can't go back.
- **Killed at the reveal:** everything is already saved, so the app reopens on the tabs.
- **No `intl`:** English date wording is a 40-line helper (`core/format/dates.dart`); v1 is English only.
- **"Today"** is a provider that updates at local midnight and when the app returns to the foreground (`core/time/today.dart`); tests fix the clock.
- **Cycle state** is a provider built from the stored profile and newest period (`cycleStateProvider`); the reveal and Home read it.
- **Status bar:** set app-wide from the theme; plum screens set light icons themselves.
- **Sheets cover the tab bar** (spec §6): `showMoonSheet` now opens on the root navigator and rises above the keyboard.
- **Design-system additions:** `InfoNote.plain`, the `welcomeBody` colour, `PinnedActionsScroll` (content at the top, actions at the bottom, scrolls when it doesn't fit), search hooks on `MoonTextField`; the on-plum ring mark now uses the theme's accents (the dark ring is brighter, as on the canvas).
- **Tests:** drift query streams close synchronously in tests, and database reads from widget tests go through `tester.runAsync`, otherwise fake-async widget tests hang or end with pending timers.

## 11 October 2026: Milestone 6 (content pipeline)
- **One copy of the content:** `assets/content/*.json` is both the reviewable source and the bundled asset. The plan's `tool/build_content.dart` step and generated file aren't needed: the audit notes stay in `design/content/` and never entered these files. `test/content/content_validation_test.dart` (in CI) proves placement, copy and recipes still match the handoff verbatim.
- **No `json_serializable`:** a hand-written, strict parser (about 150 lines) rejects unknown ids, so a content mistake fails a test instead of reaching a user. No new packages in this milestone.
- **Allergens = the nine chips in the design** (Peanuts, Tree nuts, Shellfish, Fish, Dairy, Eggs, Gluten, Soy, Sesame), not the EU-14 list in the plan. Shellfish covers crustaceans and molluscs.
- **Food metadata is an authored draft** (aisle, animal source, allergens, synonyms), derived from the audit's caution notes where possible and conservative elsewhere. It must be reviewed before release (`open-questions.md`).
- **Filter rules (plan §8.4):** diet by animal source; avoided allergens, foods and typed phrases (whole words, plural-tolerant, synonyms) exclude foods and recipe lines; a recipe is hidden if any line is excluded. Unknown-safe: when in doubt, leave it out.
- **Recipe key foods** are the recipe's Emergent ingredient tags; they drive recipe counts and "Cook with…".
- **Not-ship-ready foods** (Hijiki, Salt, Alcohol, Ketchup) keep their verbatim data in the file but are dropped when loading, so approving one is a one-flag change.
- **Loaded before the first frame** with the database, so screens read the catalogue synchronously.

## 11 October 2026: Milestone 5 (local persistence)
- **Packages:** `drift`, `sqlite3`, `flutter_secure_storage`, `path_provider`, `uuid`; `drift_dev` and `build_runner` for development. All are the standard, actively maintained choices for Drift.
- **Encryption: SQLite3MultipleCiphers, not `sqlcipher_flutter_libs`.** The plan named SQLCipher through `sqlcipher_flutter_libs`, which is end-of-life: `package:sqlite3` 3.x now bundles its own SQLite builds, chosen in `pubspec.yaml`. Of its two encrypting builds, SQLite3MultipleCiphers is the one its documentation recommends; it tracks current SQLite and needs no OpenSSL on Android. Same protection (256-bit key, `PRAGMA key`). Export compliance: standard encryption either way.
- **No `drift_flutter`:** the app opens the database itself, because the key must be read from secure storage first, and the opener checks the encrypting build is present.
- **Keychain item** uses "after first unlock", so reminders can read the database in the background, and the key moves to a new iPhone inside an encrypted backup together with the database.
- **Android backup and device transfer are off** for the app's data: the Keystore key never leaves the device, so a backed-up database couldn't be opened, and cycle data stays on the phone unless exported.
- **Lost key:** an unreadable database is moved aside and a fresh one starts, instead of the app failing to open.
- **Schema v1 has every user table** of plan §8.3, including shopping, so later milestones need no migration. **Not added yet:** the sync outbox and `lastPulledAt` (with sync in v1.1, as a v2 migration) and an entitlements table (v1's launch promo is a bundled date).
- **Period logs carry `isEstimated`** (the onboarding "I'm not sure" date) instead of a profile-level flag: it's the date that is uncertain.
- **Repositories are concrete classes** over Drift, tested on an in-memory database; no interface layer until a second implementation exists.
- **Onboarding state is stored from now on** (planned for M7): the gate's first value is read from the database before the first frame. The M4 stub is gone.
- **Generated code is committed** (`*.g.dart`), so CI and a fresh checkout build without running `build_runner`.

## 11 October 2026: Milestone 4 (shell and navigation)
- **One new package:** `go_router`.
- **Android back:** inside a tab, one screen back; on the first screen of Foods, Recipes, Shop or Settings, to Home; on Home, Android may close the app.
- **Transitions:** tab switches are instant, with no animation. Pages pushed inside a tab use the platform's standard transition, including iOS swipe-back.
- **Onboarding status is a stub** that starts as completed during development, so the app opens on Home. Both paths of the redirect are tested. Milestone 7 replaces it with the saved status.
- **"Delete my data" has no tab bar** (spec), so it opens above the shell; its back link still returns to Settings.
- **Debug gallery cannot ship:** its route exists only when `kDebugMode`, a compile-time constant, so release and profile builds drop the route and the gallery code. Checked by searching the prod release APK's compiled code: the gallery's text and class names are absent.
- **Screen-reader fix found while testing:** wrapping a `Pressable` in `Semantics(excludeSemantics: true)` also removed its tap action, and the sub-screen back link merged with the page title. `Pressable` now takes a `semanticLabel` and is always its own node; the back link, tab items, round icon buttons and chip remove buttons use it.
- **Golden diff images** (`failures/`) are git-ignored; eight committed by mistake in Milestone 3 are removed.

## 11 October 2026: Milestone 3 (design system)
- **Tokens:** ported value for value from `design/code/theme.ts`. The hero orbit colours equal the phase palettes, so the orbit reads the theme's palettes rather than a second copy.
- **Fonts bundled, never downloaded:** families `Fraunces72` (40 pt and up), `Fraunces24` (below 40), `DMSans` and `Gwendolyn`. `fraunces()` asserts if a weight the static cuts don't have is requested. Every Editorial style uses even leading (CSS-like line height) and no decoration.
- **Icons in code:** the 23 line icons are embedded from `design/assets/icons`, because the design draws them with different stroke widths per use. The wordmark, lockups and phase-ring mark stay SVG assets.
- **One new package:** `flutter_svg`.
- **Text size:** body text scales with the system up to 1.5×, headings up to 1.3×.
- **Golden tests** are made on macOS and tagged `golden`; CI runs `flutter test --exclude-tags golden`. Regenerate after an intentional visual change with `flutter test --tags golden --update-goldens`.
- **Undesigned states** (disabled, pressed, long labels) and font approximations are listed in `design-deviations.md` for sign-off.
- **Component gallery:** a debug-only screen (linked from the placeholder in debug builds) for comparing components with the design.

## 11 October 2026: Milestone 2 (cycle domain)
- **Pure Dart, "today" passed in:** the domain never reads the clock; `check_layers` rejects `DateTime.now(` in `domain/`.
- **Reference parity:** phase ranges are an exact port of `design/code/cycle.ts`, checked against a committed fixture for all 1,575 valid combinations. This proves parity with the approved reference algorithm only; it does not validate the algorithm's medical assumptions.
- **Estimates:** phases, the ovulatory window and the next-period date are calculated estimates. Field names say so (`estimatedNextPeriodDate`, `estimatedNextPhaseDate`), and later UI copy must not present estimated ovulation as a confirmed biological event.
- **Limits:** cycle 21–45 (default 28), period 2–10 (default 5), luteal 10–16 (default 14). Stored values outside the limits are clamped when calculating; input outside them is rejected by `checkCycleInput`.
- **Late period:** past the cycle length with no new period, the phase stays luteal, the cycle day keeps counting, the orbit marker and phase day stay on the last day, `daysToNextPhase` is 0 and `daysLate` counts up. When Home shows the "Has your period started?" card is a UI decision (the design says from 3 days late).
- **Long gaps:** a last period start of any past date is valid. More than 90 days ago is only flagged (`CycleInputWarning.lastPeriodStartOver90DaysAgo`, `CycleState.isLongGap`) so the UI can handle it later.
- **Future start dates are invalid:** `checkCycleInput` reports `lastPeriodStartInFuture`, and `calculateCycleState` throws `ArgumentError` rather than guessing.
- **History averages later:** the calculator only takes `CycleLengths`. Averages from logged periods will be a second way of building them (`LengthsSource.historyAverage`), added with period logging.

## 11 October 2026: Milestone 1
- **Baseline:** Flutter 3.47.7 stable, Dart 3.13.5, Xcode 26.3. CI pins the same Flutter version (`.github/workflows/ci.yaml`).
- **Flavours:** `dev` (`app.mooncycle.mobile.dev`, "Moon Cycle Dev") and `prod` (`app.mooncycle.mobile`, "Moon Cycle"). No `stg` until Supabase arrives in v1.1, because a local-only app has no distinct staging configuration.
- **One entry point** (`lib/main.dart`). The flavour comes from `--flavor`; settings from `--dart-define-from-file=env/<flavour>.json`; `AppConfig` checks they match.
- **Platforms:** iOS 15+ (iPhone only) and Android 8.0+ (minSdk 26), portrait only.
- **iOS flavours:** build configurations `Debug/Profile/Release-<flavour>`, schemes `dev` and `prod`. Bundle ID and display name live only in `ios/Flutter/dev.xcconfig` and `prod.xcconfig`. iOS plugins use Swift Package Manager (no CocoaPods).
- **Android flavours:** `productFlavors` in `android/app/build.gradle.kts`; the app name comes from a manifest placeholder (`${appName}`).
- **Design reference:** Editorial handoff v3 copied verbatim into `design/` (182 files), without the PDFs and zip. Treated as immutable: never regenerated or edited during development.
- **Architecture tooling:** only `tool/check_layers.dart`. No further enforcement tooling unless it solves a real problem.
- **Dependencies so far:** `flutter_riverpod` (and `flutter_lints` for development). Others are added in the milestone that first needs them.

## 11 October 2026: product and stack (from the technical plan)
- **v1.0 is local-only:** no account or sign-in. Supabase Auth and Postgres with RLS come in v1.1.
- **Stack:** Riverpod 3, go_router, Drift with an encrypted database, Sentry for crash reporting. No Firebase in v1.
- **Subscriptions:** feature gates in code, no RevenueCat yet. Everything is free until one fixed launch-free end date.
- **UI:** the Editorial direction (cream, plum and ochre) is the only visual source of truth.
- **App ID:** `app.mooncycle.mobile` (domain `mooncycle.app` is owned). It never changes after the first store upload.
