# Build progress

Where the build stands, milestone by milestone (numbering from `technical-plan.md` §18). Work happens on the branch `claude/full-build`; `main` is only changed by you.

**Now:** v1 build complete up to the beta; waiting on accounts and content review. Final report: `final-build-report.md`.

| # | Milestone | Status | Commit |
|---|---|---|---|
| 1 | Repository and Flutter foundation | DONE | `06b3113` (main) |
| 2 | Cycle domain | DONE | `0bbaa4b` (main) |
| 3 | Design system | DONE | `39aaf6e` (main) |
| 4 | App shell and navigation | DONE | `4e889be` (main) |
| 5 | Local persistence (encrypted Drift) | DONE | `9dbcfc3` |
| 6 | Content pipeline and catalogue | DONE | `8828f98` |
| 7 | Onboarding | DONE | `a39a816` |
| 8 | Home | DONE | `a4b8cc9` |
| 9 | Shopping domain and repository | DONE | `c982c2f` |
| 10 | Foods and ingredient sheet | DONE | `cda7306` |
| 11 | Recipes, Cook with… and recipe detail | DONE | `71576b1` |
| 12 | Shop | DONE | `e749aa1` |
| 13 | Settings, preferences and privacy | DONE | `24507d0` |
| 14 | Local reminders | DONE | `0af1848` |
| 15 | Hardening and internal beta | DONE (in-repo part) · BLOCKED (beta upload: needs your accounts) | `775e9f3` |
| 16–18 | Supabase backend, accounts, sync | NOT STARTED: v1.1, needs your Supabase projects | |
| 19 | Analytics | NOT STARTED: optional, recommended "not at launch" | |
| 20 | Store release | NOT STARTED: needs your Apple/Google accounts | |
| 21 | Subscriptions | NOT STARTED: later | |

Open decisions are in `open-questions.md`. Each milestone's details are below, newest first.

---

## Milestone 15: Hardening and internal beta — DONE (in-repo) · BLOCKED (beta upload)
- **What:** accessibility pass (44 pt targets everywhere, labels, contrast), small-phone and large-text pass, dark mode (every screen has dark goldens), crash reporting (off until a DSN), app icons and launch screens, obfuscated release builds.
- **Fixes found by the new checks:** phase selector, chips, ×, switches, calendar targets under 44 pt; overflows at 320 pt / 1.5× in the Home header, recipe detail time line, Shop count and Settings values.
- **Files added:** `lib/core/design/widgets/tap_target.dart`, `lib/core/crash/crash_reporting.dart`, `flutter_launcher_icons.yaml`, `flutter_native_splash.yaml`, generated icons and splash resources; tests `test/a11y/accessibility_test.dart` (36), `test/core/crash/crash_reporting_test.dart` (3). Totals: 361 tests plus 88 goldens, all passing.
- **Devices:** prod release APK (R8, obfuscated) installed and run on the Android emulator: splash, new adaptive icon, onboarding. iOS release build (unsigned) compiles.
- **Blocked:** TestFlight and Play closed testing (accounts, signing; `open-questions.md` 13); Sentry DSN (`open-questions.md` 12). **Not done:** Home-hero frame timing on a real phone and a manual VoiceOver/TalkBack pass; both need physical devices.
- **Deviations:** 40–43.

## Milestone 14: Local reminders — DONE
- **What:** phase-change and period reminders, planned and scheduled on the phone; the Notifications switches drive them; permission is asked when Reminders is turned on; Delete my data cancels them.
- **Files added:** `lib/features/reminders/{domain/reminder_plan.dart, domain/reminder_copy.dart, data/reminder_scheduler.dart, application/reminder_providers.dart}`; Android manifest receivers and boot permission, desugaring, `res/raw/keep.xml`; iOS notification delegate.
- **Tests:** `reminder_plan_test` (9: off, order, horizon, today, each switch, late, 35/7, ids, copy), `reminder_sync_test` (5: off, on/off, recompute after a period log, no needless reschedule, wipe cancels), Notifications permission granted/refused widget tests. Totals: 322 tests plus 88 goldens, all passing.
- **Devices:** iOS Simulator: the system prompt on turning Reminders on, then the test reminder delivered as a banner. Android emulator: the Android 13+ prompt, the alarms registered with the system, and the test reminder posted on the "Reminders" channel (private on the lock screen).
- **Deviations:** 37–39. **Open question:** 11 (reminder wording and lock-screen privacy).

## Milestone 13: Settings — DONE
- **What:** Settings root (v1), My Cycle (next period, values with history averages, history, edit period, lengths sheet, Log a period), Food Preferences, Allergies & foods to avoid, Notifications (saved; scheduling in M14), Subscription (launch promo), Privacy & Data (export), Help (FAQ, Contact support, disclaimer), Delete my data (wipe and restart at onboarding). Entitlement scaffold. Content now clips below the status bar on the tab roots.
- **Files added:** `lib/features/settings/**`, `lib/features/entitlements/**`, `lib/features/privacy/**`, `lib/features/cycle/domain/cycle_history.dart`, `lib/app/app_root.dart`, `lib/app/config/{app_links,app_version}.dart`. Removed `lib/app/placeholders/`.
- **Tests:** `cycle_history_test` (14), `entitlements_test` (8), `data_export_test` (3), `local_data_wiper_test` (2, on a real encrypted file), `settings_test` (13 widget tests: summaries, editing the cycle, averages, diet filtering, allergies, notifications, subscription, help, privacy), `app_root_test` (delete → wipe → onboarding), `settings_golden_test` (18 goldens, 9 screens × 2 themes). Totals: 307 tests plus 88 goldens, all passing; `flutter analyze` clean; `check_layers` OK.
- **Design check:** every Settings screen compared side by side with `25`–`33` at 390 pt; differences are within 1–2 pt after making list rows 80 pt (CSS content-box) and moving the Delete actions to the drawn position.
- **Devices:** iOS Simulator (iPhone 17 Pro): Settings with real data, My Cycle, Edit period saved, export share sheet with 2 files (temporary files deleted afterwards), Delete my data → fresh database file and onboarding. Android emulator: Settings, Privacy & Data, export share sheet ("Sharing 2 files").
- **Deviations:** 28–36. **Open questions:** 7 (support email, policy URLs), 8 (launch-free date), 9 (Help answers), 10 (Plus features).

## Milestone 12: Shop — DONE
- **What:** the Shop tab: summary count, progress line, add field, To buy by aisle with source lines and Merged tags, ×, Done (collapsed, expandable) with Clear all and the 8-second Undo toast, and the empty state.
- **Files added:** `lib/features/shopping/presentation/{shop_page.dart,widgets/shop_row.dart}`; tests `test/features/shopping/presentation/shop_page_test.dart` (7), `test/goldens/screens/shop_golden_test.dart` (6 goldens).
- **Files changed:** router (Shop tab), design system (`RoundCheckMark`, `Pressable.checked`, text-field submit/outside-tap behaviour), older tests.
- **Tests:** analyze clean; 266 passed; 70 goldens; `check_layers` OK. New: empty state → Foods, typed items (Other, synonym → Produce, aisle order), tick to Done → expand → untick, × removes, Clear all → Undo and expiry after 8 s, merged source line, Home's block follows the list.
- **Visual check:** goldens vs `09-shop`, `35-shop-empty`, `36-shop-undo` (light and dark): match after the two-line source and the "0 done" rule.
- **Devices:** iOS Simulator: add typed items (synonym → Scallion), tick, Clear all → toast. **Found and fixed:** typed entries ran together on iOS.
- **Unresolved:** deviations 25–27; open question 6 (quantities).
- **Next:** Milestone 13.

## Milestone 11: Recipes, Cook with… and recipe detail — DONE
- **What:** the Recipes tab (meal tabs, Cook with… field and chip, count line, feature card and grid, four empty states), the Cook with… sheet (search, categories, counts, no-match), and recipe detail (pills, meta, intro, ingredients with "On your list", add with merge note, added state, method).
- **Files added:** `lib/features/recipes/**` (`recipe_list.dart`, pages, sheet, copy, widgets); tests `test/features/recipes/**`, `test/goldens/screens/recipes_golden_test.dart` (18 goldens).
- **Files changed:** router (Recipes tab and detail), `showMoonSheet` (tall sheets), `PhaseHeader` (options), shopping summary (`onListKeys`), `lineKey` shared with the shopping controller, placeholders and older tests.
- **Tests:** analyze clean; 259 passed; 64 goldens; `check_layers` OK. New: list and cards, meal types and Snacks empty, Cook with search/choose/no match, breakfast with chicken empty state and clearing, phase change clears the ingredient, nothing fits the preferences, detail add → added state (8 items stored) → back keeps the filter, merge note; copy unit tests.
- **Visual check:** goldens vs `08`, `13`–`20` (light and dark): match after two 1 pt row-height fixes and the sheet's list offset.
- **Devices:** Android emulator: Recipes and detail.
- **Unresolved:** deviations 22–24 for sign-off.
- **Next:** Milestone 12.

## Milestone 10: Foods and the ingredient sheet — DONE
- **What:** the Foods tab (phase selector, current/browsing line, intro, hint line, categories with two-column food rows, recipe counts, on-list marks, avoided foods hidden) and the ingredient sheet (copy, recipes button, add to list, "On your list"), opened from Foods and from Home's chips.
- **Files added:** `lib/features/foods/**`, `lib/features/cycle/presentation/phase_header.dart`, `lib/features/recipes/application/recipe_filter.dart`; tests `test/features/foods/**`, `test/goldens/screens/foods_golden_test.dart` (8 goldens).
- **Files changed:** router (Foods tab), Home (chips open the sheet; "All recipes" resets the filter), `Catalogue.categoryOf`, `italicLastWord` moved to the design system, older tests updated for the real Foods page.
- **Tests:** analyze clean; 248 passed; 46 goldens; `check_layers` OK. New: categories and counts, browsing another phase and back, avoided foods and empty categories hidden, sheet add → "On your list" → row mark, no-recipes sheet, "See N recipes" sets the filter and opens Recipes.
- **Visual check:** goldens vs `07-foods`, `11-ingredient-sheet`, `12-ingredient-sheet-on-list` (light and dark): match.
- **Devices:** Android emulator: Foods → Barley sheet → add → "On your list", row mark, Home chip shows on-list.
- **Unresolved:** none new.
- **Next:** Milestone 11.

## Milestone 9: Shopping domain and repository — DONE
- **What:** the shopping list's rules and storage: item keys, the merge rule, derived quantities, aisle grouping, add (food, typed, whole recipe skipping avoided lines), done, remove, Clear all with an 8-second Undo; the real summary now feeds Home's block.
- **Files added:** `lib/features/shopping/{domain,data,application}/…`; tests `test/features/shopping/**` (29).
- **Files changed:** `shopping_summary.dart` (real data instead of zeros).
- **Tests:** analyze clean; 242 passed; 38 goldens; `check_layers` OK. Every plan §9.3 case: new food, same food twice, phase + recipe, same recipe twice, Done re-added, unit merging (200 g + 1 kg = 1.2 kg; 1 tbsp + 100 g), text quantities, typed synonym, typed no match → Other, avoided ingredient skipped, Clear all + Undo within and after 8 s. Not here: the two-device duplicate merge (sync, v1.1).
- **Devices:** no new screens in this milestone (Shop UI is Milestone 12).
- **Unresolved:** none.
- **Next:** Milestone 10.

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
