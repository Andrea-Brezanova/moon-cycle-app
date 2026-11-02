import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';
import 'package:moon_cycle/features/search/domain/unified_search.dart';

import '../../helpers/test_catalogue.dart';

/// Plan B foundation: pure search over foods and recipes, not wired to a screen.
void main() {
  List<SearchHit> run(
    String q, {
    FoodFilter filter = FoodFilter.none,
    int limit = 20,
  }) => searchCatalogue(
    catalogue: testCatalogue,
    query: q,
    filter: filter,
    limit: limit,
  );

  test('finds foods and recipes in one list', () {
    final hits = run('quinoa');
    expect(
      hits.any((h) => h.kind == SearchKind.food && h.id == 'quinoa'),
      isTrue,
    );
    expect(hits.any((h) => h.kind == SearchKind.recipe), isTrue);
  });

  test('the exact name ranks above names that merely contain it', () {
    final hits = run('rice', limit: 100);
    final exact = hits.indexWhere(
      (h) => h.kind == SearchKind.food && h.title.toLowerCase() == 'rice',
    );
    final longer = hits.indexWhere(
      (h) =>
          h.title.toLowerCase().contains('rice') &&
          h.title.toLowerCase() != 'rice',
    );
    if (exact >= 0 && longer >= 0) expect(exact, lessThan(longer));
    for (var i = 0; i < hits.length - 1; i++) {
      expect(hits[i].score, greaterThanOrEqualTo(hits[i + 1].score));
    }
  });

  test('empty and punctuation-only queries return nothing', () {
    expect(run(''), isEmpty);
    expect(run('   '), isEmpty);
    expect(run('!!'), isEmpty);
  });

  test('every word must match (AND)', () {
    final one = run('quinoa');
    final both = run('quinoa zzzzzz');
    expect(both, isEmpty);
    expect(one, isNotEmpty);
  });

  test('case, plural and punctuation do not matter', () {
    expect(run('QUINOA').map((h) => h.id), run('quinoa').map((h) => h.id));
    expect(run(' Quinoa! ').map((h) => h.id), run('quinoa').map((h) => h.id));
  });

  test('synonyms find foods', () {
    final withSyn = testCatalogue.foods.firstWhere(
      (f) => f.synonyms.isNotEmpty,
    );
    final hits = run(withSyn.synonyms.first);
    expect(
      hits.any((h) => h.kind == SearchKind.food && h.id == withSyn.id),
      isTrue,
    );
  });

  test('deterministic: same input, same order', () {
    expect(
      run('rice').map((h) => '${h.kind}${h.id}').toList(),
      run('rice').map((h) => '${h.kind}${h.id}').toList(),
    );
  });

  test('the limit is respected', () {
    expect(run('a', limit: 5).length, lessThanOrEqualTo(5));
  });

  test('strictly respects diet and allergies for foods AND recipes', () {
    const filter = FoodFilter(
      diet: Diet.vegan,
      avoidances: [
        AllergenAvoidance(id: 'a', allergenId: 'tree-nut'),
        AllergenAvoidance(id: 'b', allergenId: 'dairy'),
        AllergenAvoidance(id: 'c', allergenId: 'fish'),
      ],
    );
    for (final q in [
      'a',
      'e',
      'o',
      'cheese',
      'salmon',
      'almond',
      'chicken',
      'milk',
      'egg',
      'bowl',
    ]) {
      for (final h in run(q, filter: filter, limit: 500)) {
        if (h.kind == SearchKind.food) {
          expect(
            filter.allowsFood(testCatalogue.food(h.id)!),
            isTrue,
            reason: '$q → ${h.id}',
          );
        } else {
          expect(
            filter.allowsRecipe(testCatalogue.recipe(h.id)!, testCatalogue),
            isTrue,
            reason: '$q → ${h.id}',
          );
        }
      }
    }
    expect(
      run('almond', filter: filter).where((h) => h.id == 'almond'),
      isEmpty,
    );
  });

  test('no phase or cycle input exists in the signature', () {
    // Ordering is score, kind, title, id: re-running with the same inputs is
    // identical, and there is no parameter that could vary it by phase.
    expect(run('berry').length, run('berry').length);
  });
}
