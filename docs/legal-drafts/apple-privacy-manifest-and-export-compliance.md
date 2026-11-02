# Apple privacy manifest and export compliance: audit (1 Nov 2026)

**Draft for the owner.** Nothing here is submitted, signed or committed to the Xcode project. Method: a fresh unsigned release build (`flutter build ios --release --no-codesign --flavor prod`, 41.0 MB) was inspected: every `PrivacyInfo.xcprivacy` inside the app bundle was read, and the undefined symbols of each binary were listed. Not verified: an Xcode archive's *Privacy Report* (needs the owner's Apple account and a signed archive), and Apple's current required-reason policy text (taken from memory of Apple's published rules; re-read it before submitting).

## 1. What the release bundle contains

| Manifest | Tracking | Collected data declared | Required-reason APIs declared |
|---|---|---|---|
| Flutter.framework | no | none | FileTimestamp (0A2A.1, C617.1), SystemBootTime (35F9.1) |
| flutter_local_notifications | no | none | UserDefaults (CA92.1) |
| flutter_secure_storage_darwin | no | none | none |
| flutter_timezone, image_picker_ios, package_info_plus, share_plus, url_launcher_ios | no | none | none |
| **Sentry.framework** | (unset) | **Crash data, Performance data, Other diagnostic data** | UserDefaults, SystemBootTime, FileTimestamp |
| **The app's own `Runner`** | **no manifest** | | |
| `sqlite3mc.framework`, `objective_c.framework`, `App.framework` | **no manifest** | | |

## 2. Findings

1. **The app has no `PrivacyInfo.xcprivacy` of its own** (item 4 of `docs/release-readiness.md`). Apple expects one that declares tracking = no, no tracking domains and the data the app collects. A draft is in section 4. It is not added to the Xcode project: adding a resource needs a project-file edit and a build check, which is a small separate step once the owner approves.
2. **`sqlite3mc.framework` uses `stat`, `fstat`, `lstat` and `statfs`/`fstatfs`** (symbol check) and ships without a manifest. File-timestamp use is covered by the declared FileTimestamp reasons in Flutter's manifest only if Apple attributes it to the app; **`statfs`/`fstatfs` can fall in Apple's "disk space" category**, which needs a declared reason. This is a **possible App Store Connect warning or rejection** and cannot be confirmed without the Privacy Report on an archive. Mitigation if confirmed: declare DiskSpace with an applicable reason in the app manifest, or ask the package for a manifest. **Unverified.**
3. **Sentry is linked into the release build even though it is off** (`SENTRY_DSN` is empty). Its manifest declares collected diagnostic data types, so Xcode's Privacy Report will list them, which may not match an App Privacy answer of *Data Not Collected*. Options for the owner: (a) remove `sentry_flutter` until crash reporting is wanted, which makes the label and the policy simply true; (b) keep it and answer the label with Diagnostics, and update the policy. Recommendation: (a) for the first TestFlight build, because it removes both the mismatch and an unused dependency. **Not changed.**
4. **`objective_c.framework` and `App.framework`**: no required-reason symbols found.
5. **Export compliance key `ITSAppUsesNonExemptEncryption` is absent** from `Info.plist`, so App Store Connect will ask on every upload. See section 5.

## 3. What the app itself collects (for the manifest and the App Privacy label)

Nothing is sent off the device: no accounts, no server, no analytics, no advertising identifier, no tracking. Camera and photo library are used only for the optional Me photo and stay on the phone. The user-started *Export my data* shares a file the user chooses where to send. Draft label answer: **Data Not Collected** (unchanged if Sentry stays off and is removed from the build, finding 3).

## 4. Draft app manifest (not applied)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key><false/>
  <key>NSPrivacyTrackingDomains</key><array/>
  <key>NSPrivacyCollectedDataTypes</key><array/>
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <dict>
      <key>NSPrivacyAccessedAPIType</key><string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
      <key>NSPrivacyAccessedAPITypeReasons</key><array><string>C617.1</string></array>
    </dict>
    <!-- DiskSpace (E174.1) only if the Privacy Report on an archive shows it is needed for sqlite3mc. -->
  </array>
</dict>
</plist>
```
Why FileTimestamp C617.1: the app reads file times inside its own container (it checks the database file's modification time when quarantining an unreadable copy; `database_opener.dart`). If Sentry is kept and enabled, `NSPrivacyCollectedDataTypes` must list Crash Data, Performance Data and Other Diagnostic Data (not linked to identity, not used for tracking).

## 5. Export compliance (a legal answer, not mine)

Facts: the app stores user data in a database encrypted with SQLite3 Multiple Ciphers (a standard symmetric cipher chosen through SQLite3MC's default configuration; the key is a random 256-bit value held in the Keychain). It makes no network connections in release builds, so it uses no encryption for communication. It uses the operating system's Keychain.

Apple's question is whether the app contains encryption beyond what the operating system provides. SQLite3MC is **encryption the app ships itself**, so the simple "only uses the OS's HTTPS" exemption does not obviously apply. Whether an exemption (for example, for encryption limited to protecting data stored on the device) or a self-classification and annual report applies is a US export-control determination for the owner and a qualified adviser. Two possible outcomes for `ITSAppUsesNonExemptEncryption` in `Info.plist`: `false` only if counsel concludes the encryption is exempt; otherwise `true` with the required documentation. **I have not set it.** Do not guess the answer in App Store Connect either.

## 6. Order of work once the owner approves (each small)

1. Decide Sentry (finding 3). 2. Add the manifest and re-check the Privacy Report on a signed archive (needs membership). 3. Settle DiskSpace if shown. 4. Counsel's export answer, then the `Info.plist` key. 5. Fill `AppLinks` with the published policy.
