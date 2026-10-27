import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/diary/application/diary_providers.dart';
import 'package:moon_cycle/features/diary/data/diary_repository.dart';
import 'package:moon_cycle/features/diary/domain/diary_entry.dart';

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
    c.listen(todayMealCountProvider, (_, _) {}); // Home keeps it alive
  });
  tearDown(() async {
    c.dispose();
    await db.close();
  });

  Future<int> count() async {
    await pumpEventQueue();
    return c.read(todayMealCountProvider);
  }

  Future<DiaryEntry> log(LocalDate date, String id, DiaryMeal m) => c
      .read(diaryRepositoryProvider)
      .add(
        DiaryDraft(
          date: date,
          meal: m,
          kind: DiaryItemKind.food,
          itemId: id,
          title: id,
          amount: 1,
          unit: DiaryUnit.serving,
        ),
      );

  test('nothing logged: zero', () async => expect(await count(), 0));

  test('each meal counts once, however many items it holds', () async {
    await log(day, 'apple', DiaryMeal.breakfast);
    await log(day, 'kale', DiaryMeal.breakfast);
    expect(await count(), 1);
    await log(day, 'plum', DiaryMeal.lunch);
    expect(await count(), 2);
    await log(day, 'fig', DiaryMeal.dinner);
    await log(day, 'pear', DiaryMeal.snack);
    expect(await count(), 4);
  });

  test('only today: other dates are not counted', () async {
    await log(day.addDays(-1), 'apple', DiaryMeal.lunch);
    await log(day.addDays(1), 'kale', DiaryMeal.lunch);
    expect(await count(), 0);
  });

  test('deleting the last item of a meal removes it; a moved entry follows '
      'its date', () async {
    final a = await log(day, 'apple', DiaryMeal.lunch);
    final b = await log(day, 'kale', DiaryMeal.lunch);
    expect(await count(), 1);
    await c.read(diaryRepositoryProvider).delete(a.id);
    expect(await count(), 1); // kale is still in lunch
    await c.read(diaryRepositoryProvider).delete(b.id);
    expect(await count(), 0);
    final m = await log(day, 'plum', DiaryMeal.dinner);
    await c.read(diaryRepositoryProvider).update(m.id, date: day.addDays(-1));
    expect(await count(), 0);
  });

  test('at midnight the count is for the new day', () async {
    await log(day, 'apple', DiaryMeal.lunch);
    expect(await count(), 1);
    (c.read(todayProvider.notifier) as _TestToday).set(day.addDays(1));
    expect(await count(), 0);
    (c.read(todayProvider.notifier) as _TestToday).set(day);
    expect(await count(), 1);
  });
}
