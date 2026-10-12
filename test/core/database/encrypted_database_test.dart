import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/database/database_opener.dart';
import 'package:moon_cycle/core/database/encryption_key_store.dart';
import 'package:moon_cycle/features/cycle/data/cycle_repository.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_profile.dart';
import 'package:sqlite3/sqlite3.dart';

/// Secure storage stand-in: a value in memory.
class MemoryKeyStore extends EncryptionKeyStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<String> create() async => value = EncryptionKeyStore.newKey();

  @override
  Future<void> delete() async => value = null;
}

void main() {
  late Directory dir;
  late MemoryKeyStore keys;
  const profile = CycleProfile(typicalCycleLength: 30, typicalPeriodLength: 4);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('moon_cycle_db_');
    keys = MemoryKeyStore();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  File dbFile() => File('${dir.path}/$databaseFileName');

  Future<AppDatabase> open() => openAppDatabase(directory: dir, keys: keys);

  Future<void> writeProfile() async {
    final db = await open();
    await CycleRepository(db).saveProfile(profile);
    await db.close();
  }

  test('keys are 256-bit, as 64 hex characters, and random', () {
    final a = EncryptionKeyStore.newKey();
    expect(a, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(EncryptionKeyStore.newKey(), isNot(a));
  });

  test('data survives closing and reopening (an app restart)', () async {
    await writeProfile();
    final db = await open();
    addTearDown(db.close);
    expect(await CycleRepository(db).profile(), profile);
  });

  test('the file on disk is not plain SQLite', () async {
    await writeProfile();
    final header = dbFile().readAsBytesSync().take(15);
    expect(String.fromCharCodes(header), isNot('SQLite format 3'));
  });

  test('the file can only be read with its key', () async {
    await writeProfile();
    expect(canOpenEncrypted(dbFile(), keys.value!), isTrue);
    expect(canOpenEncrypted(dbFile(), EncryptionKeyStore.newKey()), isFalse);

    final plain = sqlite3.open(dbFile().path);
    addTearDown(plain.close);
    expect(
      () => plain.select('SELECT * FROM cycle_profiles'),
      throwsA(isA<SqliteException>()),
    );
  });

  test(
    'a key left from an earlier install is replaced on first launch',
    () async {
      keys.value = 'stale';
      final db = await open();
      await db.close();
      expect(keys.value, isNot('stale'));
      expect(canOpenEncrypted(dbFile(), keys.value!), isTrue);
    },
  );

  test(
    'a lost key: the unreadable file is set aside and a new one starts',
    () async {
      await writeProfile();
      keys.value = null;
      final db = await open();
      addTearDown(db.close);
      expect(await CycleRepository(db).profile(), isNull);
      final names = dir.listSync().map((e) => e.uri.pathSegments.last);
      expect(names, contains(startsWith('$databaseFileName.unreadable-')));
    },
  );
}
