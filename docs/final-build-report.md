# Final build report: Moon Cycle v1 (local-only)

12 October 2026 · branch `claude/full-build` (pushed; not merged into `main`)

## Where it stands

All of v1 that can be built inside the repository is built. The app runs end to end on the iOS Simulator and the Android emulator, and both release builds compile. What's left to reach testers needs things only you can provide: store accounts and signing, a crash-reporting account, content review, and a few business details.

| # | Milestone | Status | Commit |
|---|---|---|---|
| 1–4 | Foundation, cycle domain, design system, app shell | DONE (on `main`) | `4e889be` |
| 5 | Encrypted local database | DONE | `9dbcfc3` |
| 6 | Content catalogue and filters | DONE | `8828f98` |
| 7 | Onboarding | DONE | `a39a816` |
| 8 | Home | DONE | `a4b8cc9` |
| 9 | Shopping domain | DONE | `c982c2f` |
| 10 | Foods and ingredient sheet | DONE | `cda7306` |
| 11 | Recipes and recipe detail | DONE | `71576b1` |
| 12 | Shop | DONE | `e749aa1` |
| 13 | Settings, export, delete my data | DONE | `24507d0` |
| 14 | Local reminders | DONE | `0af1848`, `fffd1e8` |
| 15 | Hardening | DONE in the repository · BLOCKED for the beta upload | `775e9f3` |
| 16–18 | Supabase, accounts, sync | NOT STARTED: v1.1, needs your Supabase projects | |
| 19 | Analytics | NOT STARTED: optional; recommended "not at launch" | |
| 20 | Store release | BLOCKED: Apple and Google accounts | |
| 21 | Subscriptions | NOT STARTED: later | |

Details per milestone are in `build-progress.md`.

## What the app does

- **Onboarding:** last period (or "I'm not sure"), cycle and period length, diet and foods to avoid, then the phase reveal.
- **Home:** the moon-orbit hero with the current phase, a drag preview of other days, the late-period card and Log a period. Below it, foods for today, recipes and the shopping summary.
- **Foods:** the phase's foods by category, filtered by diet and avoidances. The ingredient sheet links to recipes and adds the food to the list.
- **Recipes:** filters by phase, meal type and one "Cook with…" ingredient. Recipe detail adds the ingredients to the list and merges duplicates.
- **Shop:**
  - one list, grouped by aisle, with merged sources;
  - a Done section, plus Clear all with Undo.
- **Settings:**
  - My Cycle: history with averages after 3 cycles, and editing periods and lengths;
  - food preferences and allergies;
  - notifications;
  - subscription (the launch promo);
  - Privacy & Data: export as JSON and CSV through the share sheet;
  - Help, and Delete my data, which wipes the database and its key, cancels reminders and restarts at onboarding.
- **Reminders:** phase starts and "two days before your period", at 9:00 local time and three cycles ahead. They're rescheduled on every change.
- **Privacy:** everything stays on the phone, in an encrypted database (SQLCipher-compatible) whose key is in the Keychain or Keystore. Phone backups are off on Android. There are no analytics. Crash reporting is off until you enable it, and when on it strips personal data.

## Quality evidence

- **Tests:** all pass.
  - 364 unit, widget and integration tests.
  - 88 golden screenshots: every screen in light and dark, compared side by side with the design PNGs, with differences of 1–2 pt.
  - The accessibility suite (36 checks) covers every screen, including onboarding:
    - 44 pt tap targets, labelled controls and text contrast;
    - no overflow on a 320 pt phone at 1.5× text.
- **Coverage:** 92% of `lib/`, 93% of domain code, 100% of the cycle domain.
- **Static checks:** `flutter analyze` is clean; `dart run tool/check_layers.dart` passes, so the domain stays pure Dart.
- **Devices:**
  - iOS Simulator (iPhone 17 Pro): onboarding, every tab, Settings flows, export, delete and restart, the permission prompt, and a delivered reminder.
  - Android emulator (API 36): the same flows, the Android 13 permission prompt, scheduled alarms, a delivered reminder with the monochrome icon, and the prod release APK with R8 and obfuscation (icon, splash, onboarding).
- **Release builds:** an obfuscated prod APK, and an obfuscated unsigned iOS build (26.8 MB).

## What needs you, in order of urgency

### Before anyone outside tests it
1. **Allergen and diet data for the 157 foods** (`open-questions.md` 4). This is safety-relevant and the current data is a conservative draft. Someone qualified should review it.
2. **Store accounts, signing and beta upload** (13): Apple Developer and Google Play accounts, an Android upload key, Apple certificates, and the app records. Play's 14-day closed-testing clock starts with the first upload.
3. **Crash reporting** (12): create a Sentry project (EU region recommended). Put its DSN in the uncommitted `env/prod.json`, and its auth token in CI secrets for uploading symbols.

### Before release
4. **Support email and policy URLs** (7). Contact support is disabled and the policy rows do nothing until these are set in `lib/app/config/app_links.dart`.
5. **Launch-free end date** (8). The designed placeholder "[launch-free end date]" shows until it's set.
6. **Help answers** (9). One question has a placeholder, and all five need content review (spec §11.5).
7. **Reminder wording and lock-screen privacy** (11).
8. **Content flags:** foods (2), recipes (3) and recipe photos (5).
9. **Design sign-off:** 33 open entries in `design-deviations.md` (10–43). Each is either something the design doesn't cover or a small accessibility or size adaptation; none changes a drawn screen at the design size.

### Later
10. Which features are Plus (10). Tab labels at large text sizes (1). Quantities on the shopping list (6).

## Not done, and why
- **Home-hero frame timing on a real mid-range phone, and a manual VoiceOver/TalkBack pass:** both need physical devices and people. The automated guideline checks pass.
- **M16–M18 (Supabase), M20 (stores), M21 (subscriptions):** v1.1, or blocked on accounts and decisions, as set in your instructions.

## Known limitations
- **Android reminders:** delivery depends on the system. Some manufacturers (Xiaomi, Huawei) block background alarms, and reminders are inexact by design, so they may arrive a few minutes late.
- **Late period:** reminders stop while the period is late, and start again once a new period is logged.
- **Export:** the file is unencrypted once it leaves the app, which is inherent in exporting. The app deletes its own temporary copy after sharing.
- **Native crashes:** the native Sentry SDKs report them without the Dart-side scrubbing. Crashes like that are rare in Flutter.
- **Help:** "What if my cycle is irregular?" shows "[Answer needs content review]".

## How to run
```bash
flutter run --flavor dev --dart-define-from-file=env/dev.json
```
Checks, golden tests, icon and splash generation, and release builds are in `README.md`.

## Repository hygiene
- **Git:** work is on `claude/full-build` only. Every milestone was committed and pushed. Nothing was force-pushed, no history was rewritten, no branches were deleted, and nothing was merged into `main`.
- **Secrets:** none are committed. `env/*.json` is git-ignored (only `*.example.json` templates are tracked). No keys, certificates or tokens are in the repository.
- **Dependencies:** every new package is recorded with its reason in `decisions.md`.
