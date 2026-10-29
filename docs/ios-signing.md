# iOS development signing: checking and renewing

The app on the phone is signed with a **development provisioning profile** (automatic signing, team `39DM9ZXV6N`, bundle id `app.mooncycle.mobile.dev`). With a free Apple account the profile lasts **7 days**. When it expires the app stops opening, but its data is not removed.

**Reinstalling the same build does not renew the profile.** Xcode reuses a profile that is still valid, so the expiry date stays the same. A renewal means getting a *new* profile.

## Check (changes nothing)
```bash
tool/renew_ios_signing.sh --check
```
Prints the profile's creation and expiry, the signing certificate, and the names and sizes of the files in the app's data folder on the phone (never their contents).

## Renew, rebuild and install in place
```bash
tool/renew_ios_signing.sh --renew
```
It: checks the git tree is clean (so the installed commit is exact); records the phone's data file list and refuses to continue if `moon_cycle.db` is not visible; backs up the cached profile to `~/.moon-cycle-signing-backup/<time>/`; removes the cached profile so Xcode issues a new one; builds with `tool/build_ios.sh`; installs over the existing app with `devicectl device install app`; and compares the data file list before and after.

It never uninstalls the app, never clears storage, never changes the bundle identifier and never uses `flutter install` (which would erase local data). If it fails after removing the profile, restore a backup into `~/Library/Developer/Xcode/UserData/Provisioning Profiles/`.

## When
Run it **at least a day before** the expiry shown by `--check` (the current profile expires 5 Nov 2026, 03:17 UTC). It needs the phone connected and unlocked, Xcode signed in to the same Apple ID, and the signing certificate in the keychain (valid to 13 Oct 2027).

## What it does not do
No TestFlight or App Store distribution, no change to the app's data, and no use of any account credential beyond Xcode's own signed-in session.
