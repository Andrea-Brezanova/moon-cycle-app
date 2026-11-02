# Privacy Policy: DRAFT for owner and legal review

*Not legal advice. Not published. Replace bracketed items. Written to match the app as of 2026-11-01; re-check against the app before every release.*

**App:** MoonCycle (the "App")
**Provider:** [OWNER LEGAL NAME / TRADING NAME AND ADDRESS]
**Contact:** [PRIVACY CONTACT EMAIL]
**Effective date:** [DATE]

## 1. The short version

- MoonCycle keeps your cycle and food information **on your phone**. We run no server for it and have no account system.
- We do **not** collect, receive, sell or share your personal data. We do not use advertising, analytics or tracking tools in the App.
- You can export your data and delete it at any time from inside the App.

## 2. What the App stores on your phone

When you use the App, it can store the following **only on your device**:

- Cycle information you enter: period dates, typical cycle and period length, and the phase the App calculates from them.
- Your food preferences: diet, foods or allergens you avoid, and foods you would rather not be suggested.
- Content you create: diary entries, meals, symptom check-ins, notes, activities, shopping list, saved recipes and links, and routines.
- Settings: appearance, reminder settings, and interface choices (for example, hiding the App in the app switcher).
- An optional photo for the top of your Me page, if you choose one. It is copied into the App's private storage and is not added to or removed from your photo library.

This information is health-related. The App stores it in an **encrypted database** on your device. The encryption key is kept in the iOS Keychain [or Android Keystore] and is not sent anywhere.

## 3. What we collect

**Nothing.** The App does not send your cycle, diary, preference or other personal data to us or to anyone else. We have no way to see it.

[IF CRASH REPORTING IS ENABLED BEFORE RELEASE, REPLACE THIS PARAGRAPH: "If the App crashes, a crash report may be sent to [VENDOR]. It contains technical information about the crash and device, does not include your entries, and is not linked to an identity." Today crash reporting is off and nothing is sent.]

## 4. Permissions

- **Camera and photo library:** only if you choose to set a Me photo. The App asks first. You can say no and still use everything else.
- **Notifications:** only if you turn on reminders. Reminders are generated on your device. By default they are discreet and do not show cycle details on your lock screen. If you turn on "Show details in reminders", the text can show your phase or an estimated period date on the lock screen.
- The App does not use your location, contacts, microphone or advertising identifier.

## 5. Links and sharing you start

- Links you save in My Collections open in your browser or another app when you tap them. That site's own policy applies, and the website you open can see that you visited it.
- **Export my data** creates a JSON/CSV file and opens your device's share sheet. Where it goes (Files, email, a messaging app, cloud storage) is your choice, and that service's policy applies. The temporary file is deleted afterwards. Anyone who receives the file can read it.

## 6. Backups and moving to a new phone

Your device's backup (for example iCloud Backup or an encrypted computer backup) may include the App's data and its encryption key, depending on your device settings. [VERIFY BEFORE PUBLISHING: Android backup is turned off in the App. iOS backup behaviour depends on the user's settings.] If you restore to a new phone without the key, the App cannot read the old data. Use **Export my data** first if you want a copy.

## 7. Your choices and rights

- **Access and portability:** use *Export my data* (Me › My App).
- **Deletion:** use *Delete my data* (Me › My App). It removes the database, the encryption key, your settings and your photo from the device, and cancels reminders. Deleting the App alone may leave the Keychain item; *Delete my data* removes it.
- **Correction:** edit or delete any entry in the App.
- Because we hold no copy of your data, there is nothing for us to retrieve or delete on a server. [ADD JURISDICTION-SPECIFIC RIGHTS LANGUAGE (GDPR/UK GDPR/CCPA/etc.) AND LEGAL BASIS ONLY IF COUNSEL ADVISES IT APPLIES TO A PROVIDER THAT DOES NOT PROCESS THE DATA.]

## 8. Children

The App is not directed to children under [AGE: 13 / 16 / OTHER]. [CONFIRM AGE RATING AND POLICY WITH COUNSEL.]

## 9. Not medical advice

The App's information is general and educational. It is not medical advice, diagnosis or treatment, and cycle predictions are estimates. [Link to Terms.]

## 10. Third-party content

The App includes nutrient information from public sources (USDA FoodData Central, NIH Office of Dietary Supplements), photographs from Unsplash (credited in the App), and illustrations, some generated using AI (see Credits & Sources in the App). These are bundled in the App and are not loaded from the internet while you use it.

## 11. Changes

If we change how the App handles data (for example, adding crash reporting, accounts or sync), we will update this policy and, where required, ask for your consent before the change takes effect. [DATE] and version are shown at the top.

## 12. Contact

[PRIVACY CONTACT EMAIL / POSTAL ADDRESS]

---
### Notes for the reviewer (delete before publishing)
1. Every statement in sections 2 to 6 is backed by `docs/privacy-and-data-audit.md` and `test/privacy/`. Unverified items are bracketed.
2. Dev-only features (external recipe lookups) are off in release builds and are deliberately not mentioned; if they are ever enabled, section 3 and the App Privacy answers must change first.
3. Decide with counsel whether health data you never receive triggers any controller duties; the draft says "nothing is collected" because that is the app's actual behaviour.
4. App Store "App Privacy" answer for the current build: *Data Not Collected* (see `docs/release-readiness.md` section 3).
