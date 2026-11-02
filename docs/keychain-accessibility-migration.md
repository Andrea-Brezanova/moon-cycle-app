# Keychain accessibility: `first_unlock` vs `first_unlock_this_device`

Status: **investigation and tested, unwired foundation. The setting has NOT been changed.** Written 2026-11-01. Statements about iOS behaviour come from Apple's documented Keychain semantics as I know them and are marked **(verify on device)** where the app's own behaviour must be confirmed before any switch.

## 1. Where things stand

- The database (`moon_cycle.db`, SQLCipher) opens with a random 256-bit key held in the Keychain item `moon_cycle.db_key`, class `first_unlock` (`kSecAttrAccessibleAfterFirstUnlock`): readable after the first unlock since boot, so reminders and background work can open the database.
- The database file is in the app's data folder and is **not** excluded from backups (no backup-exclusion code found in `ios/Runner` or `lib/main.dart`).
- `openAppDatabase` (`lib/core/database/database_opener.dart`): if the file exists but the stored key is missing or does not open it, the file is moved aside as `moon_cycle.db.unreadable-<time>` and an empty database starts. That avoids a crash but, to the user, looks like total data loss.
- Android: Keystore with backups disabled; this document is about iOS only.

## 2. What each class means

| | `first_unlock` (today) | `first_unlock_this_device` |
|---|---|---|
| Readable in background after first unlock | Yes | Yes (unchanged) |
| Included in an **encrypted** local backup and restored to a **new** iPhone | Yes | **No** |
| Included in iCloud Backup and restored to a new iPhone | Yes | **No** |
| Restored to the **same** iPhone from a backup | Yes | Yes |
| Included in an **unencrypted** local backup | No (keychain is not in unencrypted backups) | No |

## 3. Consequences of switching

1. **Encrypted backup / device transfer.** With `first_unlock`, a new iPhone restored from an encrypted backup or iCloud Backup gets both the database and the key: the data works. With the `this_device` class the database arrives but the key does not, so the opener quarantines the file and the user starts empty. **This is the main risk: switching converts a working phone-upgrade path into data loss.**
2. **Unencrypted backups** already lose the key today (database present, key absent). So the app already has this failure for users who restore from an unencrypted backup; the switch widens it to everyone who restores onto a different phone.
3. **App upgrades.** A normal App Store or development update keeps Keychain items and their class. Changing the class requires deleting and re-adding the item; updating a stored value in place does not change it **(verify on device with `SecItemCopyMatching` / `kSecReturnAttributes`)**.
4. **Reinstall.** The Keychain survives uninstall on iOS. The opener already handles a leftover key with no database (it makes a new key).
5. **Recovery.** There is no key escrow by design. If the key is lost the data cannot be read; the quarantined `.unreadable-*` file stays on the phone but is useless without the key.
6. **Development signing renewals** keep the bundle id and team, so the Keychain item stays readable; the existing before/after data check on the phone remains the guard.
7. **Delete my data** must also remove the migration's extra items (`moon_cycle.db_key.staging`, `moon_cycle.db_key.access`) when the migration is wired. Not needed while it is unwired.

## 4. What the switch buys

The key could no longer leave the phone inside a backup. For a local-only app whose backups are protected by the user's iCloud/backup encryption, the extra protection is narrow (an attacker would need the backup and its password/iCloud credentials). It is a real hardening, but it trades against loss of the user's own history on a phone upgrade.

## 5. Recommendation

**Do not switch now.** Keep `first_unlock` until the app has a way to carry data to a new phone that does not depend on the Keychain, for example an encrypted in-app export/import, or sync. After that, the switch is low-risk because a restore without the key can be recovered from the export.

Independent of the switch, two small improvements reduce today's risk and need no class change (proposals, not built):
- When the database exists but the key does not open it, show a clear explanation and an option to import an export, instead of silently starting empty. The quarantined file is already preserved.
- Offer an export reminder before a phone upgrade.

## 6. Non-destructive migration plan (for when the owner approves)

Implemented now as an **unwired** class, `lib/core/database/key_access_migration.dart`, with tests in `test/core/database/key_access_migration_test.dart`. It never writes unless the current key opens the real database, and at every step at least one verified copy is readable:

1. Read the key; stop if absent. Try it on the database; stop if it does not open.
2. Write a staging copy (`.staging`) in the new class and read it back; abort and leave the original if it differs.
3. Delete and re-add the main item in the new class; read it back.
4. Write a marker `.access`, then delete the staging copy.
5. On every launch `recoverKey()` runs first: if the main item is missing but a staging copy exists, it restores from staging. So a crash, kill or Keychain error at any step cannot lose the key.

Tests (7): normal migration keeps the value and moves the class; second run is a no-op; no key; a key that does not open the database is untouched; a corrupt staging read aborts safely; **failure injected at every single storage operation, followed by recovery and completion, never loses or changes the key**; an interrupted run is finished from staging.

Gates before wiring (all required):
1. Owner decision (this document, section 5).
2. A real `KeyVault` over `flutter_secure_storage` whose `write` does delete-then-add, with an on-device check of the resulting accessibility attribute **(verify on device)**.
3. An export/import path or sync so a device transfer is recoverable.
4. Delete my data removes the staging and marker items; test added.
5. On-device rehearsal on a throwaway install, then the real phone with the usual before/after data comparison.

## 7. What is not verified

Apple behaviour was not re-checked against live documentation in this pass; the table in section 2 reflects documented class semantics. No test exercises a real iOS Keychain (tests use an in-memory vault). Whether `flutter_secure_storage`'s `write` over an existing item changes its class was not tested.
