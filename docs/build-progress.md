# Build progress

Where the build stands, milestone by milestone (numbering from `technical-plan.md` §18). Work happens on the branch `claude/full-build`; `main` is only changed by you.

**Now:** Milestone 6, content pipeline. **IN PROGRESS**

| # | Milestone | Status | Commit |
|---|---|---|---|
| 1 | Repository and Flutter foundation | DONE | `06b3113` (main) |
| 2 | Cycle domain | DONE | `0bbaa4b` (main) |
| 3 | Design system | DONE | `39aaf6e` (main) |
| 4 | App shell and navigation | DONE | `4e889be` (main) |
| 5 | Local persistence (encrypted Drift) | DONE | see below |
| 6 | Content pipeline and catalogue | IN PROGRESS | |
| 7 | Onboarding | NOT STARTED | |
| 8 | Home | NOT STARTED | |
| 9 | Shopping domain and repository | NOT STARTED | |
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

## Milestone 5: Local persistence — DONE
- **What:** an encrypted SQLite database (Drift + SQLite3MultipleCiphers), its key in the Keychain/Keystore, every user table from plan §8.3, and repositories for the cycle profile and period logs, preferences (diet, avoidances, reminders) and app state. The onboarding gate now reads the stored state.
- **Files added:** `lib/core/database/` (`app_database.dart` + generated `.g.dart`, `tables.dart`, `database_opener.dart`, `encryption_key_store.dart`, `row_ids.dart`); `lib/features/cycle/data/cycle_repository.dart`; `lib/features/cycle/domain/period_log.dart`; `lib/features/preferences/{domain,data}/`; `lib/features/onboarding/data/app_state_repository.dart`; `build.yaml`; `drift_schemas/`; `android/app/src/main/res/xml/data_extraction_rules.xml`; tests under `test/core/database/`, `test/features/*/data/`.
- **Files changed:** `main.dart` (opens the database before the first frame), `onboarding_status.dart`, `cycle_profile.dart` (`useHistoryAverages`), `AndroidManifest.xml` (backup off), `pubspec.yaml`, test helper.
- **Tests:** `flutter analyze` clean; `flutter test --exclude-tags golden` 149 passed (new: repositories, encryption — the file is unreadable without its key, survives reopen, stale and lost keys handled — and a schema-snapshot guard); `check_layers` OK. Golden tests unchanged (no UI change).
- **Devices:** iOS Simulator and Android emulator: fresh install shows the onboarding gate, Continue opens Home, the file on disk starts with random bytes (encrypted), and after killing the app it reopens on Home.
- **Unresolved:** none.
- **Next:** Milestone 6.
