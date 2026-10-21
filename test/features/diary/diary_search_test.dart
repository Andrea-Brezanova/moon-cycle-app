import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/features/diary/domain/diary_entry.dart';
import 'package:moon_cycle/features/diary/domain/diary_search.dart';

DiaryEntry entry(String id, DiaryItemKind kind, String itemId, String title) =>
    DiaryEntry(
      id: id,
      date: LocalDate(2026, 10, 19),
      meal: DiaryMeal.lunch,
      kind: kind,
      itemId: itemId,
      title: title,
      amount: 1,
      unit: DiaryUnit.serving,
      createdAt: DateTime(2026, 10, 19),
    );

void main() {
  group('recentDistinct', () {
    test('newest first, each item once, at its latest use', () {
      final r = recentDistinct([
        entry('1', DiaryItemKind.food, 'lettuce', 'Lettuce'),
        entry('2', DiaryItemKind.recipe, 'stew', 'Stew'),
        entry('3', DiaryItemKind.food, 'lettuce', 'Lettuce'), // older repeat
        entry('4', DiaryItemKind.food, 'kale', 'Kale'),
      ]);
      expect(r.map((c) => c.title), ['Lettuce', 'Stew', 'Kale']);
    });

    test('foods, recipes and typed meals stay distinct kinds', () {
      final r = recentDistinct([
        entry('1', DiaryItemKind.food, 'soup', 'Soup'),
        entry('2', DiaryItemKind.recipe, 'soup', 'Soup'), // same id, a recipe
        entry('3', DiaryItemKind.custom, 'row-3', 'Soup'),
      ]);
      expect(r.map((c) => c.kind), [
        DiaryItemKind.food,
        DiaryItemKind.recipe,
        DiaryItemKind.custom,
      ]);
    });

    test('a typed meal is the same item whatever its row id or casing', () {
      final r = recentDistinct([
        entry('a', DiaryItemKind.custom, 'row-a', 'Romaine lettuce'),
        entry('b', DiaryItemKind.custom, 'row-b', 'romaine  Lettuce'),
      ]);
      expect(r, hasLength(1));
      expect(r.single.itemId, ''); // a typed meal has no catalogue id
    });

    test('respects the limit', () {
      final many = [
        for (var i = 0; i < 20; i++)
          entry('$i', DiaryItemKind.food, 'f$i', 'Food $i'),
      ];
      expect(recentDistinct(many, limit: 5), hasLength(5));
    });
  });

  group('searchScore', () {
    test('exact, prefix, inside, one typo, none', () {
      expect(searchScore('romaine lettuce', 'Romaine lettuce'), 0);
      expect(searchScore('ROMAINE', 'Romaine lettuce'), 1);
      expect(searchScore('lettuce', 'Romaine lettuce'), 2);
      expect(searchScore('romane', 'Romaine lettuce'), 3); // missing letter
      expect(searchScore('lettice', 'Romaine lettuce'), 3); // wrong letter
      expect(searchScore('cabbage', 'Romaine lettuce'), isNull);
      expect(searchScore('', 'Romaine lettuce'), isNull);
    });

    test('short queries are not fuzzy', () {
      expect(searchScore('ric', 'Rice'), 1);
      expect(searchScore('rye', 'Rice'), isNull);
    });
  });

  group('rankChoices', () {
    const pool = [
      DiaryChoice(DiaryItemKind.food, 'lettuce', 'Lettuce'),
      DiaryChoice(DiaryItemKind.recipe, 'lettuce-wraps', 'Lettuce wraps'),
      DiaryChoice(DiaryItemKind.food, 'iceberg', 'Iceberg lettuce'),
      DiaryChoice(DiaryItemKind.custom, '', 'Romaine lettuce'),
    ];

    test('an exact match first, then logged-before, then the rest', () {
      final r = rankChoices(
        'lettuce',
        pool,
        recentKeys: {'custom|romaine lettuce'},
      );
      expect(r.map((c) => c.title), [
        'Lettuce', // exact
        'Romaine lettuce', // logged before
        'Lettuce wraps', // starts with
        'Iceberg lettuce', // contains
      ]);
    });

    test('canonical ids are kept', () {
      final r = rankChoices('lettuce', pool, recentKeys: {});
      expect(r.first.itemId, 'lettuce');
      expect(r.first.kind, DiaryItemKind.food);
    });
  });
}
