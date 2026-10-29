# Privacy and data protection audit

Static review of how MoonCycle stores and handles personal data, on `main` after PR #68. **No personal data was transmitted or read for this audit, and no local data was changed.** The only phone check was the file list (names and sizes) of the app's data folder, before and after a reinstall, to confirm data survived.

## What stays on the phone

| Data | Where and how | Notes |
|---|---|---|
| Cycle dates and history, preferences, diary, symptoms, notes, activities, saved recipes, shopping list, collections, routines | One SQLCipher-encrypted database (`moon_cycle.db`) in the app's private support folder | 256-bit random key, held in the iOS Keychain / Android Keystore (`first_unlock`). A database that cannot be opened is moved aside, never sent anywhere |
| Interface choices, collection order, Me hero choice | `UiPrefs` JSON file, not encrypted | Holds no cycle or diary data. The personal Me hero photo is re-encoded (max 1,600 px, quality 85, no full metadata request) and stored in the app's private folder, not the photo library |
| Export | JSON and CSV written to a temporary folder, shared, then deleted in a `finally` block | The files are plain text while the share sheet is open |
| Delete my data | Cancels reminders, deletes the database, journal files, any moved-aside copy and the key, and the UI preferences and hero image | Covers the moved-aside copies |

## What leaves the phone

| Path | What is sent | Status |
|---|---|---|
| External recipe lookup (TheMealDB) | The names of the foods chosen in Build a Meal | **Debug builds of the dev flavour only.** Off in release and the prod flavour. No cycle data |
| Cloud recipe generation (built, in `features/generation/data`) | Bearer token, **the current cycle phase**, selected food ids, an idempotency key | **Not wired into the UI.** If enabled, the Privacy and Help copy "Nothing is sent to a server" becomes false and a consent step is needed. The Android release manifest also lacks the INTERNET permission |
| Crash reports (Sentry) | Nothing today: `SENTRY_DSN` is empty in the dev and prod environment files | If enabled: no user, no breadcrumbs, no screenshots, dates masked, PII off |
| Analytics, ads, third-party SDKs | None found | |

## Permissions

- Android release: only `RECEIVE_BOOT_COMPLETED` (for reminders). No INTERNET, no storage, no location. Backups and device-transfer extraction are off.
- iOS: camera and photo-library prompts (Me hero photo) only.
- No clipboard use, no location, no contacts, no microphone.

## Findings

| # | Finding | Severity | Action |
|---|---|---|---|
| P1 | **Lock-screen notifications stated period and phase information** ("Period due in 2 days", with an estimated date) when reminders were on | Medium (privacy, user-visible) | **Fixed (29 Oct):** reminders are now discreet by default ("Moon Cycle: You have a reminder."). Details are an explicit opt-in in Settings › Notifications › Show details in reminders. Cycle calculations, saved reminder settings and scheduled dates are unchanged. Android notifications are also marked private on a locked screen |
| P2 | Cloud recipe generation would send the current cycle phase together with an account token. The in-app copy says nothing is sent | Medium if enabled, none today | Keep it unwired until consent and copy exist. A new test now fails if the UI starts using it |
| P3 | SQLite may write temporary files (large sorts) to the temp folder | Low | **Assessed, not changed.** On the app's own SQLite build `temp_store` is 0 (files allowed). A forced spill left no visible temporary file (SQLite deletes it on open) and the encrypted database file contained no plaintext. Nothing demonstrates exposure. Optional hardening if you want it: `PRAGMA temp_store = MEMORY` on open |
| P4 | An export file could remain in the temp folder if the app is killed while the share sheet is open | Low | **Fixed (29 Oct):** the export folder is deleted at every start-up (`deleteStaleExports`), with tests. Nothing else in the temp folder is touched |
| P5 | The app snapshot shown in the iOS app switcher may show cycle data. iOS keeps these launch snapshots (about 3 MB) in the app's own data folder (`Library/SplashBoard`) and replaces them on reinstall | Low | **Proposal only.** A blur on backgrounding is a platform-level behaviour change that affects every screen and can flicker when the notification centre is pulled down; it needs your decision and a device test |
| P6 | If Sentry is enabled, the vendor sees device and IP metadata and stack traces even with the scrubbing in place | Low | Update the privacy copy at that point |

P1 and P4 were then implemented with tests (see the table); P3 and P5 remain proposals. Tests now lock the current posture (`test/privacy/privacy_posture_test.dart`): no backups, the exact permission list, only two iOS prompts, ignored environment files, an allow-list of network code, cloud generation unwired, external lookups debug-only, crash-report settings, export cleanup, and no logging of user content.

## Decisions for you
1. P3: whether to add `PRAGMA temp_store = MEMORY` (optional; no exposure was demonstrated).
2. P5: whether to blur the app in the app switcher (needs a device test).
3. Whether the detailed-reminder wording needs a content review (the notification copy has an open TODO).
4. Before any cloud feature ships: consent, copy, Android INTERNET permission, vendor terms.
