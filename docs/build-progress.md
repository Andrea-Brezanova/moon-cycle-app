# Build progress

Where the build stands, milestone by milestone (numbering from `technical-plan.md` §18). Work happens on the branch `claude/full-build`; `main` is only changed by you.

**Now:** Milestone 9, shopping domain. **IN PROGRESS**

| # | Milestone | Status | Commit |
|---|---|---|---|
| 1 | Repository and Flutter foundation | DONE | `06b3113` (main) |
| 2 | Cycle domain | DONE | `0bbaa4b` (main) |
| 3 | Design system | DONE | `39aaf6e` (main) |
| 4 | App shell and navigation | DONE | `4e889be` (main) |
| 5 | Local persistence (encrypted Drift) | DONE | `9dbcfc3` |
| 6 | Content pipeline and catalogue | DONE | `8828f98` |
| 7 | Onboarding | DONE | `a39a816` |
| 8 | Home | DONE | see below |
| 9 | Shopping domain and repository | IN PROGRESS | |
| 10 | Foods and ingredient sheet | NOT STARTED | |
| 11 | Recipes, Cook with… and recipe detail | NOT STARTED | |
| 12 | Shop | NOT STARTED | |
| 13 | Settings, preferences and privacy | NOT STARTED | |
| 14 | Local reminders | NOT STARTED | |
| 15 | Hardening and internal beta | NOT STARTED | |
| 16–18 | Supabase backend, accounts, sync | NOT STARTED: v1.1, needs your Supabase projects | |
| 19 | Analytics | NOT STARTED: optional, recommended "not at launch" | |
| 20 | Store release | NOT STARTED: needs your Apple/Google accounts | |
| 21 | Subscriptions | NOT STARTED: later | |

Open decisions are in `open-questions.md`. Each milestone's details are below, newest first.

---

## Milestone 8: Home — DONE
- **What:** the Home tab: full-bleed hero with the moon and the user's real phase, drag preview with "Back to today", "Your focus", foods for today, recipes for today (or the no-recipes line), the shopping block, the late state with "Has your period started?" and the Log a period sheet. Light and dark.
- **Files added:** `lib/features/home/**`; `lib/features/cycle/application/viewing_phase.dart`; `lib/features/cycle/domain/period_start_check.dart`; `lib/features/cycle/presentation/log_period_sheet.dart`; `lib/features/shopping/application/shopping_summary.dart` (zeros until M9); tests `test/features/home/**`, `test/features/cycle/domain/period_start_check_test.dart`, `test/goldens/screens/home_golden_test.dart` (14 goldens), helper `seed.dart`.
- **Files changed:** router (Home tab), placeholders (debug links moved to Settings), `RecipePhoto` (placeholder fills its width), test helpers.
- **Tests:** analyze clean; 213 passed; 38 goldens passed; `check_layers` OK. New: hero wording, preferences shaping foods and recipes, no-recipes state, drag preview and back, screen-reader adjust, late card → log → cycle restarts, 1–2 days late, navigation to recipe detail and Shop.
- **Visual check:** goldens vs `06-home`, `21-home-period-late`, `23-home-preview-day`, `24-home-no-recipes`, light and dark. Fixed: header height (+4 pt), placeholder width, preview spacing, cooking-line icon alignment.
- **Devices:** iOS Simulator: Home with real dates; drag preview (slow and fast) and Back to today work.
- **Found and fixed:** the orbit drag was being taken by page scrolling; the "Back to today" pill could overflow at large text.
- **Unresolved:** deviations 16–21 for sign-off; recipe photos (open question 5).
- **Next:** Milestone 9.

## Milestone 7: Onboarding — DONE
- **What:** the five onboarding screens (welcome, last period, cycle length, food preferences, phase reveal with the moon), in light and dark, saved in one transaction; the onboarding gate now uses the real flow.
- **Files added:** `lib/features/onboarding/{domain,data,application,presentation}/…`; `lib/features/cycle/application/cycle_providers.dart`; `lib/features/cycle/presentation/cycle_orbit.dart`; `lib/features/preferences/presentation/avoid_food_sheet.dart`; `lib/core/time/today.dart`; `lib/core/format/dates.dart`; `lib/core/design/widgets/pinned_actions_scroll.dart`; tests under `test/features/onboarding/`, `test/goldens/screens/` (16 screen goldens), helpers `golden_screen.dart`.
- **Files changed:** router (onboarding routes), app (status bar), design system (`InfoNote.plain`, `welcomeBody`, sheet on root navigator, text-field hooks, themed ring mark), placeholders (onboarding placeholder removed).
- **Tests:** analyze clean; 194 passed; 24 goldens passed; `check_layers` OK. New: full flow on a fixed clock (saves profile, period, diet, avoidance, completion; opens Foods), "I’m not sure", "Skip for now", back keeps answers, no way back from the reveal, reveal wording for every phase.
- **Visual check:** each screen's golden side by side with its design PNG, light and dark; matches. Fixed during the check: welcome ring colours in dark, bottom spacing, the hidden link's space, the reveal's meta line height and apostrophe.
- **Devices:** iOS Simulator (light) and Android emulator (dark): fresh install → full onboarding → reveal with the right day and dates → Foods. Status bar fixed (it stayed white after the welcome screen).
- **Unresolved:** design deviations 11–15 need sign-off (undrawn "Add another" sheet and states).
- **Next:** Milestone 8.

## Milestone 6: Content pipeline and catalogue — DONE
- **What:** the approved content bundled offline (`assets/content/`: phases, 157 foods, 12 recipes, taxonomy), a strict parser, the read-only `Catalogue`, and the diet/avoidance `FoodFilter` with its provider.
- **Files added:** `assets/content/{taxonomy,phases,foods,recipes}.json` + `README.md`; `lib/features/content/{domain,data,application}/`; `lib/features/preferences/application/preference_providers.dart`; tests `test/content/content_validation_test.dart`, `test/features/content/domain/`, `test/helpers/test_catalogue.dart`.
- **Files changed:** `main.dart` (loads the catalogue), `pubspec.yaml` (assets), test helper.
- **Tests:** analyze clean; 179 passed (new: content validation against the handoff — placement, copy, recipes verbatim; not-ship-ready foods absent — plus filter and catalogue tests); `check_layers` OK. No UI change, so goldens unchanged.
- **Devices:** Android emulator: starts and opens Home with the catalogue loaded.
- **Unresolved:** food metadata is a draft and content flags are open (`open-questions.md` 2–4); none block the build.
- **Next:** Milestone 7.

## Milestone 5: Local persistence — DONE
- **What:** an encrypted SQLite database (Drift + SQLite3MultipleCiphers), its key in the Keychain/Keystore, every user table from plan §8.3, and repositories for the cycle profile and period logs, preferences (diet, avoidances, reminders) and app state. The onboarding gate now reads the stored state.
- **Files added:** `lib/core/database/` (`app_database.dart` + generated `.g.dart`, `tables.dart`, `database_opener.dart`, `encryption_key_store.dart`, `row_ids.dart`); `lib/features/cycle/data/cycle_repository.dart`; `lib/features/cycle/domain/period_log.dart`; `lib/features/preferences/{domain,data}/`; `lib/features/onboarding/data/app_state_repository.dart`; `build.yaml`; `drift_schemas/`; `android/app/src/main/res/xml/data_extraction_rules.xml`; tests under `test/core/database/`, `test/features/*/data/`.
- **Files changed:** `main.dart` (opens the database before the first frame), `onboarding_status.dart`, `cycle_profile.dart` (`useHistoryAverages`), `AndroidManifest.xml` (backup off), `pubspec.yaml`, test helper.
- **Tests:** `flutter analyze` clean; `flutter test --exclude-tags golden` 149 passed (new: repositories, encryption — the file is unreadable without its key, survives reopen, stale and lost keys handled — and a schema-snapshot guard); `check_layers` OK. Golden tests unchanged (no UI change).
- **Devices:** iOS Simulator and Android emulator: fresh install shows the onboarding gate, Continue opens Home, the file on disk starts with random bytes (encrypted), and after killing the app it reopens on Home.
- **Unresolved:** none.
- **Next:** Milestone 6.
