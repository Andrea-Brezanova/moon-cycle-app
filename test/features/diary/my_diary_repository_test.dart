import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/features/diary/data/diary_repository.dart';
import 'package:moon_cycle/features/diary/data/symptom_repository.dart';
import 'package:moon_cycle/features/diary/domain/diary_entry.dart';
import 'package:moon_cycle/features/diary/domain/symptoms.dart';

import '../../helpers/fake_stamp.dart';

void main() {
  late AppDatabase db;
  late DiaryRepository meals;
  late SymptomRepository symptoms;
  final day = LocalDate(2026, 10, 17);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    final stamp = fakeStamp();
    meals = DiaryRepository(db, stamp);
    symptoms = SymptomRepository(db, stamp);
  });
  tearDown(() => db.close());

  DiaryDraft own(
    String title, {
    String? note,
    DiaryMeal meal = DiaryMeal.lunch,
  }) => DiaryDraft(
    date: day,
    meal: meal,
    kind: DiaryItemKind.custom,
    itemId: '',
    title: title,
    amount: 1,
    unit: DiaryUnit.serving,
    note: note,
  );

  group('meals', () {
    test('a note is stored, read back, edited and cleared', () async {
      final e = await meals.add(
        DiaryDraft(
          date: day,
          meal: DiaryMeal.dinner,
          kind: DiaryItemKind.food,
          itemId: 'kale',
          title: 'Kale',
          amount: 1,
          unit: DiaryUnit.serving,
          note: 'With lemon',
        ),
      );
      expect(e.note, 'With lemon');
      await meals.update(e.id, note: const Value('Very good'));
      expect((await meals.all()).single.note, 'Very good');
      await meals.update(e.id, note: const Value(null));
      expect((await meals.all()).single.note, isNull);
    });

    test('an own meal needs no food id and is never merged', () async {
      final a = await meals.add(own('Oatmeal with blueberries', note: 'Warm'));
      final b = await meals.add(own('Oatmeal with blueberries'));
      expect(a.id, isNot(b.id));
      expect(a.kind, DiaryItemKind.custom);
      expect(a.itemId, a.id); // its own row id, not a catalogue item
      expect(a.note, 'Warm');
      expect(await meals.all(), hasLength(2));
    });

    test(
      'an own meal can be retitled, moved to another meal, deleted',
      () async {
        final e = await meals.add(own('Toast'));
        await meals.update(
          e.id,
          title: 'Toast and eggs',
          meal: DiaryMeal.breakfast,
        );
        final changed = (await meals.all()).single;
        expect(changed.title, 'Toast and eggs');
        expect(changed.meal, DiaryMeal.breakfast);
        await meals.delete(e.id);
        expect(await meals.all(), isEmpty);
      },
    );

    test('re-logging the same food keeps an earlier note', () async {
      DiaryDraft d(String? note) => DiaryDraft(
        date: day,
        meal: DiaryMeal.lunch,
        kind: DiaryItemKind.food,
        itemId: 'apple',
        title: 'Apple',
        amount: 1,
        unit: DiaryUnit.serving,
        note: note,
      );
      await meals.add(d('Crisp'));
      await meals.add(d(null));
      final e = (await meals.all()).single;
      expect(e.amount, 2);
      expect(e.note, 'Crisp');
    });
  });

  group('symptoms', () {
    SymptomDay full() => SymptomDay(
      date: day,
      energy: EnergyLevel.good,
      sleep: SleepQuality.okay,
      moods: {Mood.calm, Mood.motivated},
      body: {BodySymptom.bloating: Strength.mild, BodySymptom.cramps: null},
      note: 'Felt lighter after a walk.',
    );

    test('a day round-trips with severity and note', () async {
      await symptoms.saveDay(full());
      final d = (await symptoms.day(day))!;
      expect(d.energy, EnergyLevel.good);
      expect(d.sleep, SleepQuality.okay);
      expect(d.moods, {Mood.calm, Mood.motivated});
      expect(d.body[BodySymptom.bloating], Strength.mild);
      expect(d.body.containsKey(BodySymptom.cramps), isTrue);
      expect(d.body[BodySymptom.cramps], isNull);
      expect(d.note, 'Felt lighter after a walk.');
    });

    test('bleeding uses its own scale', () {
      expect(BodySymptom.bleeding.strengths.map((s) => s.label), [
        'Spotting',
        'Light',
        'Medium',
        'Heavy',
      ]);
      expect(BodySymptom.cramps.strengths.map((s) => s.label), [
        'Mild',
        'Moderate',
        'Strong',
      ]);
    });

    test(
      'editing changes, adds and removes answers, without duplicates',
      () async {
        await symptoms.saveDay(full());
        await symptoms.saveDay(
          SymptomDay(
            date: day,
            energy: EnergyLevel.low, // replaces good
            moods: {Mood.calm, Mood.anxious}, // motivated out, anxious in
            body: {
              BodySymptom.bloating: Strength.strong,
            }, // stronger; cramps out
          ),
        );
        final d = (await symptoms.day(day))!;
        expect(d.energy, EnergyLevel.low);
        expect(d.sleep, isNull);
        expect(d.moods, {Mood.calm, Mood.anxious});
        expect(d.body, {BodySymptom.bloating: Strength.strong});
        expect(d.note, isNull);
        // One live row per answer: energy, 2 moods, 1 body.
        expect(
          await (db.select(
            db.symptomCheckins,
          )..where((t) => t.deletedAt.isNull())).get(),
          hasLength(4),
        );
      },
    );

    test('saving the same day twice does not duplicate', () async {
      await symptoms.saveDay(full());
      await symptoms.saveDay(full());
      final live = await (db.select(
        db.symptomCheckins,
      )..where((t) => t.deletedAt.isNull())).get();
      expect(live, hasLength(7));
    });

    test('another day is untouched; history is newest first', () async {
      final earlier = LocalDate(2026, 10, 15);
      await symptoms.saveDay(
        SymptomDay(date: earlier, energy: EnergyLevel.low),
      );
      await symptoms.saveDay(full());
      final history = await symptoms.watchHistory().first;
      expect(history.map((d) => d.date), [day, earlier]);
      expect((await symptoms.day(earlier))!.energy, EnergyLevel.low);
    });

    test('clearing a day removes it from the day and the history', () async {
      await symptoms.saveDay(full());
      await symptoms.clearDay(day);
      expect(await symptoms.day(day), isNull);
      expect(await symptoms.watchHistory().first, isEmpty);
    });

    test('a summary says only what was answered, with no interpretation', () {
      final s = SymptomDay(
        date: day,
        energy: EnergyLevel.low,
        body: {BodySymptom.cramps: Strength.mild},
        sleep: SleepQuality.restless,
      ).summary;
      expect(s, 'Energy low · Cramps, mild · Sleep restless');
    });
  });
}
