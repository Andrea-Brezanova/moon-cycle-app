import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/database_opener.dart';
import 'package:moon_cycle/features/collections/data/collection_link_repository.dart';
import 'package:moon_cycle/features/collections/domain/collection_link.dart';
import 'package:moon_cycle/features/cycle/data/cycle_repository.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_profile.dart';
import 'package:moon_cycle/features/privacy/data/local_data_wiper.dart';

import '../../helpers/memory_key_store.dart';

void main() {
  late Directory dir;
  late MemoryKeyStore keys;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('moon_cycle_wipe_');
    keys = MemoryKeyStore();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('deletes the database files and the key, and runs extra steps '
      '(reminders)', () async {
    final db = await openAppDatabase(directory: dir, keys: keys);
    await CycleRepository(db).saveProfile(
      const CycleProfile(typicalCycleLength: 28, typicalPeriodLength: 5),
    );
    // An unreadable copy moved aside earlier, and an unrelated file.
    File('${dir.path}/$databaseFileName.unreadable-1').writeAsStringSync('x');
    File('${dir.path}/other.txt').writeAsStringSync('keep');
    var remindersCancelled = false;

    await LocalDataWiper(
      database: db,
      directory: dir,
      keys: keys,
      extraSteps: [() async => remindersCancelled = true],
    ).wipe();

    final left = [for (final f in dir.listSync()) f.uri.pathSegments.last];
    expect(left, ['other.txt']);
    expect(keys.value, isNull);
    expect(remindersCancelled, isTrue);
  });

  test('after a wipe the app opens an empty database with a new key', () async {
    final db = await openAppDatabase(directory: dir, keys: keys);
    await CycleRepository(db).saveProfile(
      const CycleProfile(typicalCycleLength: 30, typicalPeriodLength: 4),
    );
    final oldKey = keys.value;
    await LocalDataWiper(database: db, directory: dir, keys: keys).wipe();

    final fresh = await openAppDatabase(directory: dir, keys: keys);
    addTearDown(fresh.close);
    expect(await CycleRepository(fresh).profile(), isNull);
    expect(keys.value, isNot(oldKey));
  });

  test('saved links do not survive a wipe', () async {
    final db = await openAppDatabase(directory: dir, keys: keys);
    await CollectionLinkRepository(db).add(
      category: LinkCategory.sounds,
      address: 'https://example.com/calm',
      title: 'Calm',
    );
    await LocalDataWiper(database: db, directory: dir, keys: keys).wipe();
    final fresh = await openAppDatabase(directory: dir, keys: keys);
    addTearDown(fresh.close);
    expect(await CollectionLinkRepository(fresh).all(), isEmpty);
    expect(await fresh.select(fresh.collectionLinks).get(), isEmpty);
  });
}
