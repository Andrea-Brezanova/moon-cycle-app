import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/key_access_migration.dart';

/// In-memory vault that remembers each item's class and can fail on the n-th
/// operation, to prove the key is never lost whichever step stops.
class FakeVault implements KeyVault {
  final values = <String, String>{};
  final access = <String, KeyAccess>{};
  int ops = 0;
  int? failAtOp;
  bool corruptStagingWrites = false;

  void _tick() {
    ops++;
    if (failAtOp == ops) throw StateError('simulated failure at op $ops');
  }

  @override
  Future<String?> read(String name) async {
    _tick();
    return values[name];
  }

  @override
  Future<void> write(String name, String value, KeyAccess a) async {
    _tick();
    values[name] = corruptStagingWrites && name.endsWith('.staging')
        ? 'corrupt'
        : value;
    access[name] = a;
  }

  @override
  Future<void> delete(String name) async {
    _tick();
    values.remove(name);
    access.remove(name);
  }
}

const key =
    'k'
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcde';

FakeVault legacyVault() {
  final v = FakeVault();
  v.values['moon_cycle.db_key'] = key;
  v.access['moon_cycle.db_key'] = KeyAccess.afterFirstUnlock;
  return v;
}

void main() {
  test('moves the key to the device-only class and keeps its value', () async {
    final v = legacyVault();
    final out = await KeyAccessMigration(v)
        .migrate(opensDatabase: (k) => k == key);
    expect(out, KeyMigrationOutcome.migrated);
    expect(v.values['moon_cycle.db_key'], key);
    expect(
      v.access['moon_cycle.db_key'],
      KeyAccess.afterFirstUnlockThisDeviceOnly,
    );
    expect(v.values.containsKey('moon_cycle.db_key.staging'), isFalse);
  });

  test('a second run changes nothing', () async {
    final v = legacyVault();
    final m = KeyAccessMigration(v);
    await m.migrate(opensDatabase: (k) => true);
    v.ops = 0;
    final out = await m.migrate(opensDatabase: (k) => true);
    expect(out, KeyMigrationOutcome.alreadyMigrated);
    expect(
      v.access['moon_cycle.db_key'],
      KeyAccess.afterFirstUnlockThisDeviceOnly,
    );
  });

  test('no stored key: nothing to do, nothing written', () async {
    final v = FakeVault();
    final out = await KeyAccessMigration(v).migrate(opensDatabase: (k) => true);
    expect(out, KeyMigrationOutcome.noKey);
    expect(v.values, isEmpty);
  });

  test('a key that does not open the database is never touched', () async {
    final v = legacyVault();
    final out = await KeyAccessMigration(v)
        .migrate(opensDatabase: (k) => false);
    expect(out, KeyMigrationOutcome.keyDoesNotOpenDatabase);
    expect(v.values, {'moon_cycle.db_key': key});
    expect(v.access['moon_cycle.db_key'], KeyAccess.afterFirstUnlock);
  });

  test(
    'a staging copy that reads back wrong aborts with the key intact',
    () async {
      final v = legacyVault()..corruptStagingWrites = true;
      final out = await KeyAccessMigration(v)
          .migrate(opensDatabase: (k) => true);
      expect(out, KeyMigrationOutcome.failedKeyIntact);
      expect(v.values['moon_cycle.db_key'], key);
      expect(v.access['moon_cycle.db_key'], KeyAccess.afterFirstUnlock);
      expect(v.values.containsKey('moon_cycle.db_key.staging'), isFalse);
    },
  );

  test('stopping at ANY storage operation never loses the key', () async {
    // Count the operations of a clean run, then fail at each one in turn.
    final probe = legacyVault();
    await KeyAccessMigration(probe).migrate(opensDatabase: (k) => true);
    final total = probe.ops;
    expect(total, greaterThan(5));
    for (var n = 1; n <= total; n++) {
      final v = legacyVault()..failAtOp = n;
      final m = KeyAccessMigration(v);
      try {
        await m.migrate(opensDatabase: (k) => true);
      } on Object {
        // recoverKey itself may throw on the very first read; that is a
        // failed launch step, not a lost key.
      }
      v.failAtOp = null;
      // The next launch gets the same key back, from either slot.
      final recovered = await KeyAccessMigration(v).recoverKey();
      expect(recovered, key, reason: 'failure injected at operation $n');
      // And a later run completes the migration.
      final out = await KeyAccessMigration(v)
          .migrate(opensDatabase: (k) => k == key);
      expect(
        out,
        anyOf(
          KeyMigrationOutcome.migrated,
          KeyMigrationOutcome.alreadyMigrated,
        ),
        reason: 'operation $n',
      );
      expect(v.values['moon_cycle.db_key'], key, reason: 'operation $n');
    }
  });

  test('an interrupted run is finished from the staging copy', () async {
    final v = FakeVault();
    v.values['moon_cycle.db_key.staging'] = key; // main item gone
    v.access['moon_cycle.db_key.staging'] =
        KeyAccess.afterFirstUnlockThisDeviceOnly;
    final recovered = await KeyAccessMigration(v).recoverKey();
    expect(recovered, key);
    expect(v.values['moon_cycle.db_key'], key);
    expect(v.values.containsKey('moon_cycle.db_key.staging'), isFalse);
  });
}
