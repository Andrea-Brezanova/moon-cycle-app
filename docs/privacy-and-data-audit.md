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
| P1 | **Lock-screen notifications state period information** ("Period due in 2 days", with an estimated date) when reminders are on. Anyone who can see the lock screen sees it, subject to the user's notification-preview setting | Medium (privacy, user-visible) | Proposal: an optional "discreet reminders" setting with neutral wording. Needs your approval (UI and copy) |
| P2 | Cloud recipe generation would send the current cycle phase together with an account token. The in-app copy says nothing is sent | Medium if enabled, none today | Keep it unwired until consent and copy exist. A new test now fails if the UI starts using it |
| P3 | SQLite may write temporary files (large sorts) to the temp folder. SQLite3 Multiple Ciphers encrypts the database and journal; temporary spill files are a separate case | Low | Proposal: `PRAGMA temp_store = MEMORY` on open. Not a demonstrated defect, so not changed |
| P4 | An export file could remain in the temp folder if the app is killed while the share sheet is open | Low | Proposal: sweep the export folder at launch |
| P5 | The app snapshot shown in the iOS app switcher may show cycle data | Low | Proposal: blur on backgrounding. Product decision |
| P6 | If Sentry is enabled, the vendor sees device and IP metadata and stack traces even with the scrubbing in place | Low | Update the privacy copy at that point |

No clearly demonstrated, low-risk security defect was found, so **no code was changed**. Tests now lock the current posture (`test/privacy/privacy_posture_test.dart`): no backups, the exact permission list, only two iOS prompts, ignored environment files, an allow-list of network code, cloud generation unwired, external lookups debug-only, crash-report settings, export cleanup, and no logging of user content.

## Decisions for you
1. P1 discreet reminders (recommended).
2. P3, P4: harden the temp-file handling (small, safe changes; say yes and I will do them with tests).
3. P5: whether to blur the app in the app switcher.
4. Before any cloud feature ships: consent, copy, Android INTERNET permission, vendor terms.
