# Release readiness: prelaunch checklist

Updated 1 Nov 2026. **Nothing here has been submitted, uploaded or published**, and no setting, name or identifier was changed. "Verified" means checked in the repository on this date; "Needs you" means a decision, account or professional input is required. This is a practical checklist, not legal advice or a clearance of any name, licence or trademark.

## 1. Blockers (TestFlight)

| # | Item | State |
|---|---|---|
| 1 | Apple Developer Program membership (needed for App Store Connect, a distribution certificate and profile) | Needs you. Enrolment was postponed. |
| 2 | Production flavour: `env/prod.json` (git-ignored; `prod.example.json` is tracked), bundle id `app.mooncycle.mobile` (dev is `app.mooncycle.mobile.dev`, so the two install side by side and do not share data) | Verified. The build refuses a flavour/env mismatch (`AppConfig`). |
| 3 | Version `0.1.0+1`; every upload needs a new build number | Verified. Bump at upload time. |
| 4 | **Privacy manifest** `ios/Runner/PrivacyInfo.xcprivacy` | **Missing.** Apple requires the app's own manifest declaring required-reason APIs (plugin manifests ship with the plugins). Prepare after membership; low risk. |
| 5 | **Export compliance** `ITSAppUsesNonExemptEncryption` | **Absent** in `Info.plist`. The app uses SQLCipher and the Keychain, so the encryption questions apply. Needs your answer (an exemption claim is typical for standard encryption, but you answer it). |
| 6 | App Store Connect record, privacy policy URL, App Privacy answers, test notes | Needs you (see 3 and 4 below). |
| 7 | Brand name | **Under review.** Not renamed; bundle id unchanged; no domain acquired. |

## 2. Configuration and signing

- **Development:** automatic signing, team `39DM9ZXV6N`, 7-day development profile. Renewed 1 Nov 2026; **expires 8 Nov 2026 04:44 UTC**. Renew with `tool/renew_ios_signing.sh --renew` with the phone connected (it refuses unless it can see `moon_cycle.db`, then reinstalls in place and compares the data listing).
- **Production:** needs a distribution certificate and an App Store profile after enrolment; `flutter build ipa --release --flavor prod --dart-define-from-file=env/prod.json`, then validate and upload via Xcode Organizer or Transporter. Not run.
- **Android:** release signing keystore does not exist in the repository (correct). Create and store it outside Git before any Play release. Backups and device-transfer extraction are off.
- External recipe providers (TheMealDB, Recipe API) are enabled in **debug builds of the dev flavour only** (guarded by a test); release builds make no recipe network calls.

## 3. Privacy policy and disclosures

- **In-app links** (`AppLinks.privacyPolicy`, `terms`, `dataUse`) are `null`, so those three rows are not tappable. No policy text exists yet. Needs you (and a qualified adviser): write and host the policy before TestFlight external testing.
- **Facts the policy and the App Privacy answers can rely on (verified by tests in `test/privacy/`):** health and cycle data are stored only on the phone in an encrypted database; the key is in the Keychain/Keystore; no analytics, advertising or tracking SDKs; no accounts; no server; the only network code is the debug-only recipe lookup; the only permissions are camera and photo library (for the optional Me photo, chosen by the user and copied locally) and, on Android, boot-completed (for reminders). Notifications ask permission at runtime.
- **App Privacy "nutrition label" (draft answer):** *Data not collected*, provided crash reporting stays off. If Sentry is enabled: Diagnostics (crash data, performance), not linked to identity by configuration, and the policy must say so. The user-initiated export is a file the user shares themselves.
- **Reminders** are discreet by default; the opt-in detailed text can show the phase or an estimated period date on a lock screen (documented in the privacy audit). The optional app-switcher shield is off by default.

## 4. Account and data deletion

There are no accounts, so Apple's in-app account-deletion rule does not apply. **Delete my data** (Me › My App) removes the database, journal and moved-aside copies, the encryption key, the UI preferences (which resets the shield and detailed reminders) and personal images, and cancels reminders. Export is available first. Both are covered by tests; a device walk-through before release is still advisable.

## 5. Content, licensing and AI credits

- **Done:** Credits & Sources states that some food and lifestyle illustrations (including the recipe images) were generated using AI; Unsplash photographers are credited; fonts are under the SIL OFL; nutrient data comes from USDA FoodData Central and NIH ODS.
- **Remaining, needs you:** confirm the terms of the image generator that applied on each generation date (records are private); decide whether the TheMealDB or Recipe API fixtures/recipes may ever ship (today they are dev-only and the fixtures are synthetic); keep "not clinically reviewed" until a named reviewer reviews; Wave 1 stays unpublished until you approve.
- The 112-recipe library and the food guidance are authored in-house with no recorded third-party source; this is a statement of the record, not a rights clearance.

## 6. Accessibility

Verified by tests: iOS tap-target size, labelled tap targets and text contrast on 40+ screens (light), no overflow at 320 pt and 1.5× text. **Not done:** a manual VoiceOver and Dynamic Type walk-through on the phone, dark-mode contrast tests on every screen, Switch Control. No looping animations exist, so reduced-motion exposure is small (toggle and press-fade only).

## 7. Reliability and crash reporting

Options, in order of fit: (a) Apple's own crash reports via TestFlight and Xcode Organizer: no SDK, no new data flow, recommended for the first betas; (b) Sentry (already integrated, scrubbed, off unless `SENTRY_DSN` is set): useful, but needs a privacy-policy line and a vendor DPA; (c) Crashlytics: adds a Google SDK; not recommended. Before release: a soak test on the phone (kill and relaunch, offline, low storage), schema-migration test from the oldest supported version (the migration tests exist), and a backup/restore check.

## 8. TestFlight preparation (after membership)

1. Privacy manifest and export-compliance key. 2. Unique build number. 3. App Store Connect record with the final name. 4. Beta description and review notes ("general food guidance, not medical advice; no account; data stays on the phone"). 5. Test contact. 6. Internal testers first.

## 9. App Store screenshots and description

Screenshots can be produced from the existing golden renders (6.7" and 6.1" sizes) after the name is final. Keep the copy to what the app does: cycle-aware food ideas, recipes, shopping list, diary, private by design. **Avoid** medical, fertility, contraception, hormone-balancing or "detox" claims, and do not describe foods as recommended for a phase. Suggested category: Health & Fitness or Food & Drink; set the age rating honestly (no medical device claims).

## 10. Legal and trademark (needs a qualified adviser)

The brand is under review. I make no clearance statement. Needs you: a trademark search and opinion in the intended markets before the name is used publicly, domain decisions, terms of use, and the privacy policy. Private evidence files exist and are kept out of the repository.

## Drafts added 1 Nov 2026 (not published, for the owner and a legal adviser)
- `docs/legal-drafts/privacy-policy-draft.md` and `terms-of-use-draft.md`: written from the app's verified data practices; bracketed items are the owner's decisions.
- `docs/legal-drafts/apple-privacy-manifest-and-export-compliance.md`: audit of a fresh release build. Findings: no app-level privacy manifest; `sqlite3mc` uses `statfs` and has no manifest (possible disk-space reason needed, unverified); Sentry is linked and its manifest declares collected data although it is off; export-compliance key absent and a legal decision.
- `docs/accessibility-manual-checklist.md`: what the 89 automated tests cover and the manual VoiceOver, Dynamic Type and display checks still needed.
