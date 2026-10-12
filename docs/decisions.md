# Decisions

One list of the decisions that shape this repository, newest first. Add a line when a decision changes, with the date and the reason.

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
