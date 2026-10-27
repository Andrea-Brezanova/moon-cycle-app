# Release readiness checklist (TestFlight / App Store)

Status: **deferred.** The owner has postponed Apple Developer enrollment, so nothing here is
being done and nothing is uploaded. This is the read-only checklist that was drafted in
PR #16 (written when `main` was at 21415a2, 25 Oct 2026), kept here so it is not lost when
that stale PR is closed. Items may have changed since; re-check before acting.

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
