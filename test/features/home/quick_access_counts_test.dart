import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/diary/application/diary_providers.dart';
import 'package:moon_cycle/features/diary/data/diary_activity_repository.dart';
import 'package:moon_cycle/features/diary/data/diary_note_repository.dart';
import 'package:moon_cycle/features/diary/data/diary_repository.dart';
import 'package:moon_cycle/features/diary/data/symptom_repository.dart';
import 'package:moon_cycle/features/diary/domain/diary_activity.dart';
import 'package:moon_cycle/features/diary/domain/diary_entry.dart';
import 'package:moon_cycle/features/diary/domain/symptoms.dart';
import 'package:moon_cycle/features/home/presentation/widgets/home_v2.dart';

class _TestToday extends Today {
  void set(LocalDate d) => state = d;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final day = LocalDate(2026, 10, 18);
  late AppDatabase db;
  late ProviderContainer c;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 18, 9)),
        todayProvider.overrideWith(_TestToday.new),
      ],
    );
    // Home keeps the count alive while it shows.
    c.listen(todayDiaryEntryCountProvider, (_, _) {});
  });
  tearDown(() async {
    c.dispose();
    await db.close();
  });

  Future<int> count() async {
    await pumpEventQueue();
    return c.read(todayDiaryEntryCountProvider);
  }

  Future<DiaryEntry> meal(LocalDate date, String id) => c
      .read(diaryRepositoryProvider)
      .add(
        DiaryDraft(
          date: date,
          meal: DiaryMeal.lunch,
          kind: DiaryItemKind.food,
          itemId: id,
          title: id,
          amount: 1,
          unit: DiaryUnit.serving,
        ),
      );

  test('nothing recorded: zero', () async {
    expect(await count(), 0);
  });

  test('one entry of each kind: four, counted individually', () async {
    await meal(day, 'apple');
    await meal(day, 'kale'); // a second meal entry is a second entry
    await c
        .read(symptomRepositoryProvider)
        .saveDay(
          SymptomDay(
            date: day,
            energy: EnergyLevel.good,
            moods: const {Mood.calm, Mood.happy},
            note: 'ok',
          ),
        );
    await c
        .read(diaryActivityRepositoryProvider)
        .add(date: day, type: ActivityType.walk);
    await c
        .read(diaryNoteRepositoryProvider)
        .add(date: day, title: 'T', body: 'Writing');
    // Two meals + one check-in (however many answers) + one activity + one note.
    expect(await count(), 5);
  });

  test(
    'only today: other dates, in the past or future, are not counted',
    () async {
      await meal(day.addDays(-1), 'apple');
      await meal(day.addDays(1), 'kale');
      await c
          .read(diaryNoteRepositoryProvider)
          .add(date: day.addDays(-7), body: 'old');
      await c
          .read(diaryActivityRepositoryProvider)
          .add(date: day.addDays(-1), type: ActivityType.run);
      expect(await count(), 0);
      await meal(day, 'plum');
      expect(await count(), 1);
    },
  );

  test('deleted entries stop counting; unsaved drafts never count', () async {
    final m = await meal(day, 'apple');
    final a = (await c
        .read(diaryActivityRepositoryProvider)
        .add(date: day, type: ActivityType.yoga))!;
    final n = (await c
        .read(diaryNoteRepositoryProvider)
        .add(date: day, body: 'x'))!;
    expect(await count(), 3);
    await c.read(diaryRepositoryProvider).delete(m.id);
    expect(await count(), 2);
    await c.read(diaryActivityRepositoryProvider).delete(a.id);
    await c.read(diaryNoteRepositoryProvider).delete(n.id);
    expect(await count(), 0);
    // A blank note is not stored, so it can't be counted.
    await c.read(diaryNoteRepositoryProvider).add(date: day, body: '  ');
    expect(await count(), 0);
  });

  test('moving an entry to another date changes the count', () async {
    final m = await meal(day, 'apple');
    expect(await count(), 1);
    await c.read(diaryRepositoryProvider).update(m.id, date: day.addDays(-1));
    expect(await count(), 0);
    await c.read(diaryRepositoryProvider).update(m.id, date: day);
    expect(await count(), 1);

    final a = (await c
        .read(diaryActivityRepositoryProvider)
        .add(date: day, type: ActivityType.walk))!;
    expect(await count(), 2);
    await c
        .read(diaryActivityRepositoryProvider)
        .update(a.id, date: day.addDays(-3), type: ActivityType.walk);
    expect(await count(), 1);
  });

  test('a clearing check-in and a changed one stay one entry', () async {
    final repo = c.read(symptomRepositoryProvider);
    await repo.saveDay(SymptomDay(date: day, energy: EnergyLevel.low));
    expect(await count(), 1);
    await repo.saveDay(
      SymptomDay(date: day, energy: EnergyLevel.good, moods: const {Mood.calm}),
    );
    expect(await count(), 1);
    await repo.saveDay(SymptomDay(date: day)); // cleared
    expect(await count(), 0);
  });

  test('at midnight the count is for the new day', () async {
    await meal(day, 'apple');
    await meal(day, 'kale');
    expect(await count(), 2);
    (c.read(todayProvider.notifier) as _TestToday).set(day.addDays(1));
    expect(await count(), 0); // nothing yet recorded for the new day
    await meal(day.addDays(1), 'plum');
    expect(await count(), 1);
    (c.read(todayProvider.notifier) as _TestToday).set(day); // back again
    expect(await count(), 2);
  });

  test('the wording', () {
    expect(diaryEntriesToday(0), 'Start your daily check-in');
    expect(diaryEntriesToday(1), '1 entry today');
    expect(diaryEntriesToday(3), '3 entries today');
    expect(diaryEntriesToday(8), '8 entries today');
    expect(shoppingToBuy(0), 'Your list is empty');
    expect(shoppingToBuy(1), '1 item to buy');
    expect(shoppingToBuy(8), '8 items to buy');
  });
}
