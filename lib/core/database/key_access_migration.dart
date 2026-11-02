// Moves the database key from one Keychain accessibility class to another
// without ever leaving the app with no readable copy of it.
//
// NOT WIRED: nothing in the app calls this yet. `EncryptionKeyStore` still
// uses `first_unlock`. See `docs/keychain-accessibility-migration.md` for why
// the switch waits for the owner's decision.

/// How a stored secret may be read (the two Keychain classes in question).
enum KeyAccess { afterFirstUnlock, afterFirstUnlockThisDeviceOnly }

/// The few secure-storage operations the migration needs, so it can be tested
/// with an in-memory fake and later backed by `flutter_secure_storage`.
abstract interface class KeyVault {
  Future<String?> read(String name);

  /// Writes [value] under [name] with [access]. Must REPLACE an existing item
  /// (delete then add): updating an item in place keeps its old class.
  Future<void> write(String name, String value, KeyAccess access);

  Future<void> delete(String name);
}

enum KeyMigrationOutcome {
  /// No key stored: nothing to migrate (a fresh install makes its key in the
  /// target class directly).
  noKey,

  /// Already in the target class; nothing changed.
  alreadyMigrated,

  /// The key was moved and verified.
  migrated,

  /// The stored key does not open the database, so it was left untouched.
  keyDoesNotOpenDatabase,

  /// A step failed verification or threw; the original key is still readable.
  failedKeyIntact,
}

class KeyAccessMigration {
  KeyAccessMigration(
    this._vault, {
    this.keyName = 'moon_cycle.db_key',
    this.target = KeyAccess.afterFirstUnlockThisDeviceOnly,
  });

  final KeyVault _vault;
  final String keyName;
  final KeyAccess target;

  String get _staging => '$keyName.staging';
  String get _marker => '$keyName.access';

  /// Run first on every launch (cheap): finishes a migration that was
  /// interrupted, and returns the key the database should be opened with.
  ///
  /// Order of trust: the main item, then the staging copy. A staging copy is
  /// only ever written after the main key was verified against the database,
  /// so it is always a valid key.
  Future<String?> recoverKey() async {
    final main = await _vault.read(keyName);
    if (main != null) return main;
    final staged = await _vault.read(_staging);
    if (staged == null) return null;
    await _vault.write(keyName, staged, target);
    if (await _vault.read(keyName) == staged) {
      await _vault.write(_marker, target.name, target);
      await _vault.delete(_staging);
    }
    return staged;
  }

  /// Moves the key to [target]. [opensDatabase] must try the key on the real
  /// database file; the key is never touched unless it does.
  Future<KeyMigrationOutcome> migrate({
    required bool Function(String key) opensDatabase,
  }) async {
    final key = await recoverKey();
    if (key == null) return KeyMigrationOutcome.noKey;
    if (await _vault.read(_marker) == target.name) {
      // Tidy a leftover copy from a run that stopped at the very last step.
      await _vault.delete(_staging);
      return KeyMigrationOutcome.alreadyMigrated;
    }
    if (!opensDatabase(key)) return KeyMigrationOutcome.keyDoesNotOpenDatabase;
    try {
      // 1. A second copy in the target class, read back before anything else.
      await _vault.write(_staging, key, target);
      if (await _vault.read(_staging) != key) {
        await _vault.delete(_staging);
        return KeyMigrationOutcome.failedKeyIntact;
      }
      // 2. Replace the main item (the original is gone for an instant, but the
      //    verified staging copy exists and `recoverKey` restores from it).
      await _vault.delete(keyName);
      await _vault.write(keyName, key, target);
      if (await _vault.read(keyName) != key) {
        return KeyMigrationOutcome.failedKeyIntact;
      }
      // 3. Mark done, then drop the staging copy.
      await _vault.write(_marker, target.name, target);
      await _vault.delete(_staging);
      return KeyMigrationOutcome.migrated;
    } on Object {
      return KeyMigrationOutcome.failedKeyIntact;
    }
  }
}
