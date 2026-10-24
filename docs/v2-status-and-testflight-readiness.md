# V2 status and TestFlight readiness (main at 21415a2)

## Completed
Home (hero ring, Today's focus, Today's picks, photographic Quick access with live
counts), Eat hub, Foods and Recipes with the phase + type filters, 3 Plants a Day
(selectable cards), My Diary hub, Notes, Activities, Add a Recipe (write my own,
paste text; local parsing, review before save, unchecked ingredients flagged),
My recipes (saved, added by me), shopping list, light/dark, 320 pt and large text.

## Unfinished
- **URL import** (Add a Recipe part 3): plan only; awaiting owner decisions.
- Move and Relax tabs are placeholders; More sub-screens, Food detail, Recipe detail,
  Learn more, Meal Builder and Onboarding still carry the pre-V2 design.
- More plant/food photography; Eat hero photograph (a recipe photo stands in).
- Old Home widgets (`home_editorial.dart`) to remove; premium/avoidance Home goldens
  are redundant.

## Release blockers (TestFlight)
Checked read-only; nothing has been changed or uploaded.
1. **Apple Developer Program membership** must be confirmed active (needed for
   App Store Connect, a distribution certificate and profile).
2. **Bundle id and flavour:** the installed dev build is `app.mooncycle.mobile.dev`.
   A TestFlight build needs the prod flavour (`env/prod.json`) and its App Store
   Connect record; confirm the prod id and that it does not collide with the dev app
   (a separate id would be a separate install, so beta data would not carry over
   from the dev app; say if you want that handled).
3. **Version:** `pubspec.yaml` is `0.1.0+1`; each upload needs a unique build number.
4. **Privacy manifest:** `ios/Runner/PrivacyInfo.xcprivacy` is missing; Apple
   requires declared required-reason APIs. Plugin manifests are included by the
   plugins, the app's own must be added.
5. **Export compliance:** `ITSAppUsesNonExemptEncryption` is absent from
   `Info.plist`. The app uses SQLCipher, so the encryption questionnaire applies;
   needs your answer.
6. **App Store Connect metadata:** privacy policy URL, App Privacy answers (health
   data stays on device), beta description, test contact, and TestFlight review
   notes (a cycle-tracking app should state it is not medical advice).
7. **Signing:** automatic signing with the existing development identity; a
   distribution identity is created at archive time once membership is confirmed.
   No signing setting has been changed.
8. **Data:** a TestFlight build with the same bundle id updates in place and keeps
   data; a different id is a fresh install.
9. Open owner decisions: URL import answers; photo licences for AI-generated
   Quick access images (credited as supplied by you).

## Proposed upload steps (after your approval)
`flutter build ipa --release --flavor prod --dart-define-from-file=env/prod.json`,
validate, then upload via Xcode Organizer or Transporter. Not run.
