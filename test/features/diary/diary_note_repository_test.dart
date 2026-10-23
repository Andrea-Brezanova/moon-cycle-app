import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/database/database_opener.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/features/diary/data/diary_note_repository.dart';

import '../../helpers/memory_key_store.dart';

void main() {
  late AppDatabase db;
  late DiaryNoteRepository repo;
  final day = LocalDate(2026, 10, 18);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DiaryNoteRepository(db);
  });
  tearDown(() => db.close());

  test('add, read back, and several notes on one day', () async {
    final a = await repo.add(date: day, title: ' Morning ', body: 'First');
    final b = await repo.add(date: day, body: 'Second, no title');
    expect(a!.title, 'Morning'); // trimmed
    expect(b!.title, isNull);
    final onDay = await repo.watchDay(day).first;
    expect(onDay.map((n) => n.body), ['First', 'Second, no title']);
    // Newest day first overall; within a day the latest written first.
    await repo.add(date: day.addDays(-1), body: 'Yesterday');
    final all = await repo.all();
    expect(all.map((n) => n.body), ['Second, no title', 'First', 'Yesterday']);
  });

  test('a blank note is not stored', () async {
    expect(await repo.add(date: day, body: '   \n '), isNull);
    expect(await repo.add(date: day, title: '  ', body: ''), isNull);
    expect(await repo.all(), isEmpty);
    // A title alone is something.
    expect(
      await repo.add(date: day, title: 'Only a title', body: ''),
      isNotNull,
    );
  });

  test('update changes the day, title and writing', () async {
    final n = (await repo.add(date: day, body: 'one'))!;
    await repo.update(
      n.id,
      date: day.addDays(-2),
      title: 'T',
      body: 'two\nlines',
    );
    final got = (await repo.byId(n.id))!;
    expect(
      (got.date, got.title, got.body),
      (day.addDays(-2), 'T', 'two\nlines'),
    );
    expect(got.updatedAt.isBefore(n.createdAt), isFalse);
  });

  test('delete tombstones the row and keeps none of the writing', () async {
    final n = (await repo.add(date: day, title: 'Secret', body: 'private'))!;
    await repo.delete(n.id);
    expect(await repo.all(), isEmpty);
    expect(await repo.byId(n.id), isNull);
    final raw = await db.select(db.diaryNotes).get();
    expect(raw.single.deletedAt, isNotNull);
    expect(raw.single.title, isNull);
    expect(raw.single.body, isEmpty);
  });

  test('a deleted note cannot be edited back to life', () async {
    final n = (await repo.add(date: day, body: 'x'))!;
    await repo.delete(n.id);
    await repo.update(n.id, date: day, body: 'again');
    expect(await repo.all(), isEmpty);
  });

  test('notes survive closing and reopening the encrypted database', () async {
    final dir = Directory.systemTemp.createTempSync('moon_cycle_notes_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final keys = MemoryKeyStore();
    final first = await openAppDatabase(directory: dir, keys: keys);
    final id = (await DiaryNoteRepository(
      first,
    ).add(date: day, title: 'Kept', body: 'across a restart'))!.id;
    await first.close();

    final second = await openAppDatabase(directory: dir, keys: keys);
    addTearDown(second.close);
    final got = await DiaryNoteRepository(second).byId(id);
    expect(got?.body, 'across a restart');
    // The writing is not readable as plain text in the file on disk.
    final bytes = File('${dir.path}/$databaseFileName').readAsBytesSync();
    expect(String.fromCharCodes(bytes).contains('across a restart'), isFalse);
  });
}
