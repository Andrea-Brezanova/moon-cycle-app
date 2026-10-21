import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/features/diary/data/diary_repository.dart';
import 'package:moon_cycle/features/diary/domain/diary_entry.dart';

import '../../helpers/fake_stamp.dart';

DiaryDraft food(
  String id, {
  LocalDate? date,
  DiaryMeal meal = DiaryMeal.lunch,
  double amount = 1,
  DiaryUnit unit = DiaryUnit.serving,
  DiaryItemKind kind = DiaryItemKind.food,
}) => DiaryDraft(
  date: date ?? LocalDate(2026, 10, 17),
  meal: meal,
  kind: kind,
  itemId: id,
  title: id,
  amount: amount,
  unit: unit,
);

void main() {
  late AppDatabase db;
  late DiaryRepository repo;
  final day = LocalDate(2026, 10, 17);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DiaryRepository(db, fakeStamp());
  });
  tearDown(() => db.close());

  test('adds an entry, read back by day', () async {
    final e = await repo.add(food('salmon'));
    expect(e.title, 'salmon');
    expect(e.quantity, '1 serving');
    expect(await repo.watchDay(day).first, hasLength(1));
    expect(await repo.watchDay(LocalDate(2026, 10, 16)).first, isEmpty);
  });

  test('logging the same thing again in the same meal adds to it', () async {
    await repo.add(food('salmon', amount: 1));
    final again = await repo.add(food('salmon', amount: 0.5));
    expect(again.amount, 1.5);
    final entries = await repo.watchDay(day).first;
    expect(entries, hasLength(1));
    expect(entries.single.quantity, '1½ servings');
  });

  test('a different meal, unit, kind or day is a different entry', () async {
    await repo.add(food('salmon'));
    await repo.add(food('salmon', meal: DiaryMeal.dinner));
    await repo.add(food('salmon', unit: DiaryUnit.gram, amount: 150));
    await repo.add(
      food('salmon', kind: DiaryItemKind.recipe),
    ); // a recipe that shares an id string
    await repo.add(food('salmon', date: LocalDate(2026, 10, 18)));
    expect(await repo.watchDay(day).first, hasLength(4));
    expect(await repo.watchDay(LocalDate(2026, 10, 18)).first, hasLength(1));
  });

  test('edit the amount', () async {
    final e = await repo.add(food('salmon'));
    await repo.update(e.id, amount: 2);
    expect((await repo.watchDay(day).first).single.amount, 2);
  });

  test('moving an entry onto an identical one merges them', () async {
    await repo.add(food('salmon', meal: DiaryMeal.lunch, amount: 1));
    final dinner = await repo.add(
      food('salmon', meal: DiaryMeal.dinner, amount: 2),
    );
    await repo.update(dinner.id, meal: DiaryMeal.lunch);
    final entries = await repo.watchDay(day).first;
    expect(entries, hasLength(1));
    expect(entries.single.amount, 3);
    expect(entries.single.meal, DiaryMeal.lunch);
  });

  test('moving to another day', () async {
    final e = await repo.add(food('salmon'));
    await repo.update(e.id, date: LocalDate(2026, 10, 16));
    expect(await repo.watchDay(day).first, isEmpty);
    expect(await repo.watchDay(LocalDate(2026, 10, 16)).first, hasLength(1));
  });

  test('delete is a tombstone and frees the slot', () async {
    final e = await repo.add(food('salmon'));
    await repo.delete(e.id);
    expect(await repo.watchDay(day).first, isEmpty);
    expect(await repo.all(), isEmpty);
    final again = await repo.add(food('salmon'));
    expect(again.amount, 1);
    expect(await repo.watchDay(day).first, hasLength(1));
  });

  test('history lists days with entries, newest first', () async {
    await repo.add(food('a', date: LocalDate(2026, 10, 15)));
    await repo.add(food('b', date: LocalDate(2026, 10, 17)));
    await repo.add(
      food('c', date: LocalDate(2026, 10, 17), meal: DiaryMeal.snack),
    );
    final history = await repo.watchHistory().first;
    expect(history.map((d) => d.date), [
      LocalDate(2026, 10, 17),
      LocalDate(2026, 10, 15),
    ]);
    expect(history.first.entries, hasLength(2));
    expect(history.first.of(DiaryMeal.snack).single.itemId, 'c');
  });

  group('units and defaults', () {
    test('quantity text', () {
      expect(DiaryUnit.serving.format(1), '1 serving');
      expect(DiaryUnit.serving.format(2.5), '2½ servings');
      expect(DiaryUnit.gram.format(150), '150 g');
      expect(DiaryUnit.cup.format(0.25), '¼ cup'.replaceAll('cup', 'cups'));
      expect(DiaryUnit.piece.format(1), '1 piece');
    });

    test('a default meal for the hour', () {
      expect(DiaryMeal.forHour(8), DiaryMeal.breakfast);
      expect(DiaryMeal.forHour(12), DiaryMeal.lunch);
      expect(DiaryMeal.forHour(16), DiaryMeal.snack);
      expect(DiaryMeal.forHour(20), DiaryMeal.dinner);
    });
  });
}
