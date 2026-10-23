import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/database/database_opener.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/features/diary/data/diary_activity_repository.dart';
import 'package:moon_cycle/features/diary/domain/diary_activity.dart';

import '../../helpers/memory_key_store.dart';

void main() {
  late AppDatabase db;
  late DiaryActivityRepository repo;
  final day = LocalDate(2026, 10, 18);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DiaryActivityRepository(db);
  });
  tearDown(() => db.close());

  test('only the type is needed; the rest is optional', () async {
    final a = (await repo.add(date: day, type: ActivityType.walk))!;
    expect(
      (a.minutes, a.intensity, a.note, a.customName),
      (null, null, null, null),
    );
    expect(a.heading, 'Walk');
    expect(a.summary, '');
  });

  test('all fields round-trip; the summary reads naturally', () async {
    final a = (await repo.add(
      date: day,
      type: ActivityType.yoga,
      minutes: 45,
      intensity: ActivityIntensity.light,
      note: '  slow morning  ',
    ))!;
    expect(a.note, 'slow morning');
    expect(a.summary, '45 min · Light');
    expect(durationText(90), '1 h 30 min');
    expect(durationText(120), '2 h');
  });

  test('Other keeps its name; other types drop a stray name', () async {
    final o = (await repo.add(
      date: day,
      type: ActivityType.other,
      customName: ' Gardening ',
    ))!;
    expect(o.heading, 'Gardening');
    final w = (await repo.add(
      date: day,
      type: ActivityType.walk,
      customName: 'ignored',
    ))!;
    expect(w.customName, isNull);
  });

  test('minutes outside 1 to 1440 are stored as not given', () async {
    expect(
      (await repo.add(date: day, type: ActivityType.run, minutes: 0))!.minutes,
      isNull,
    );
    expect(
      (await repo.add(
        date: day,
        type: ActivityType.run,
        minutes: 5000,
      ))!.minutes,
      isNull,
    );
    expect(
      (await repo.add(
        date: day,
        type: ActivityType.run,
        minutes: 1440,
      ))!.minutes,
      1440,
    );
    expect(parseMinutes('abc'), isNull);
    expect(parseMinutes(' 30 '), 30);
  });

  test('several per day, newest day first', () async {
    await repo.add(date: day, type: ActivityType.walk);
    await repo.add(date: day, type: ActivityType.swim);
    await repo.add(date: day.addDays(-1), type: ActivityType.run);
    final all = await repo.all();
    expect(all.map((a) => a.type), [
      ActivityType.swim,
      ActivityType.walk,
      ActivityType.run,
    ]);
  });

  test('update changes every field, and can clear the optional ones', () async {
    final a = (await repo.add(
      date: day,
      type: ActivityType.walk,
      minutes: 20,
      intensity: ActivityIntensity.moderate,
      note: 'x',
    ))!;
    await repo.update(a.id, date: day.addDays(-1), type: ActivityType.hike);
    final got = (await repo.byId(a.id))!;
    expect((got.date, got.type), (day.addDays(-1), ActivityType.hike));
    expect((got.minutes, got.intensity, got.note), (null, null, null));
  });

  test('delete tombstones the row and empties its name and note', () async {
    final a = (await repo.add(
      date: day,
      type: ActivityType.other,
      customName: 'Private',
      note: 'words',
    ))!;
    await repo.delete(a.id);
    expect(await repo.all(), isEmpty);
    final raw = await db.select(db.diaryActivities).get();
    expect(raw.single.deletedAt, isNotNull);
    expect((raw.single.customName, raw.single.note), (null, null));
  });

  test(
    'an unknown type from a newer version is left out, not a crash',
    () async {
      await repo.add(date: day, type: ActivityType.walk);
      await db.customStatement(
        "UPDATE diary_activities SET type = 'from_the_future'",
      );
      expect(await repo.all(), isEmpty);
    },
  );

  test(
    'activities survive closing and reopening the encrypted database',
    () async {
      final dir = Directory.systemTemp.createTempSync('moon_cycle_acts_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final keys = MemoryKeyStore();
      final first = await openAppDatabase(directory: dir, keys: keys);
      final id = (await DiaryActivityRepository(first).add(
        date: day,
        type: ActivityType.other,
        customName: 'Moonlit stroll',
        minutes: 25,
      ))!.id;
      await first.close();

      final second = await openAppDatabase(directory: dir, keys: keys);
      addTearDown(second.close);
      final got = await DiaryActivityRepository(second).byId(id);
      expect((got?.heading, got?.minutes), ('Moonlit stroll', 25));
      final bytes = File('${dir.path}/$databaseFileName').readAsBytesSync();
      expect(String.fromCharCodes(bytes).contains('Moonlit stroll'), isFalse);
    },
  );
}
