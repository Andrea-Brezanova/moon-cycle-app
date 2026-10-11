# Decisions

One list of the decisions that shape this repository, newest first. Add a line when a decision changes, with the date and the reason.

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
