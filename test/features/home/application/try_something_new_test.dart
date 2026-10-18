import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/foods/application/todays_food.dart';
import 'package:moon_cycle/features/home/application/try_something_new.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';

import '../../../helpers/test_catalogue.dart';
import '../../foods/application/todays_food_test.dart' show make, stateFor;

typedef Pages = List<List<DiscoverySuggestion>>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final start = LocalDate(2025, 9, 28);

  /// Every day of a cycle: (today, container).
  List<(LocalDate, ProviderContainer)> days({
    FoodFilter filter = FoodFilter.none,
  }) => [
    for (var d = 0; d < 28; d++)
      (
        start.addDays(d),
        make(
          cycle: stateFor(start, start.addDays(d)),
          today: start.addDays(d),
          filter: filter,
        ),
      ),
  ];

  test(
    'Today’s food first, then two foods, each with a recipe that uses it',
    () {
      for (final (today, c) in days()) {
        final state = stateFor(start, today);
        final pages = c.read(tryNewPagesProvider);
        expect(pages, isNotEmpty, reason: '$today');
        final todays = c.read(todaysFoodProvider)!;
        for (final page in pages) {
          expect(page, hasLength(3));
          expect(page.first.isTodaysFood, isTrue);
          expect(page.first.food.id, todays.id);
          expect(page.map((s) => s.food.id).toSet(), hasLength(3));
          for (final s in page) {
            // The recipe really contains the food, in the real phase.
            expect(s.recipe.keyFoodIds, contains(s.food.id));
            expect(s.recipe.phase, state.phase);
            expect(
              testCatalogue.phase(state.phase).foodIds,
              contains(s.food.id),
            );
          }
        }
      }
    },
  );

  test('the two extra foods come from different categories', () {
    for (final (_, c) in days()) {
      final first = c.read(tryNewPagesProvider).first;
      expect(first[1].food.categoryId, isNot(first[2].food.categoryId));
    }
  });

  test('"Show me more" gives a different page, and wraps around', () {
    final c = days().first.$2;
    final pages = c.read(tryNewPagesProvider);
    expect(pages.length, greaterThan(1));
    final a = suggestionPage(pages, 0).map((s) => s.food.id).toSet();
    final b = suggestionPage(pages, 1).map((s) => s.food.id).toSet();
    expect(a.difference(b), isNotEmpty);
    expect(suggestionPage(pages, pages.length), suggestionPage(pages, 0));
    expect(suggestionPage(const [], 3), isEmpty);
  });

  test('stable for the day', () {
    final today = start.addDays(8);
    String ids() => make(cycle: stateFor(start, today), today: today)
        .read(tryNewPagesProvider)
        .map((p) => p.map((s) => '${s.food.id}:${s.recipe.id}').join(','))
        .join('|');
    expect(ids(), ids());
  });

  test('vegan: every suggested recipe is vegan', () {
    const filter = FoodFilter(diet: Diet.vegan);
    for (final (_, c) in days(filter: filter)) {
      for (final s in c.read(tryNewPagesProvider).expand((p) => p)) {
        expect(
          filter.allowsRecipe(s.recipe, testCatalogue),
          isTrue,
          reason: s.recipe.id,
        );
      }
    }
  });

  test('avoided allergens never appear in a suggestion', () {
    const filter = FoodFilter(
      avoidances: [
        AllergenAvoidance(id: 'g', allergenId: 'gluten'),
        AllergenAvoidance(id: 'd', allergenId: 'dairy'),
      ],
    );
    for (final (_, c) in days(filter: filter)) {
      for (final s in c.read(tryNewPagesProvider).expand((p) => p)) {
        expect(filter.allowsRecipe(s.recipe, testCatalogue), isTrue);
        expect(filter.allowsFood(s.food), isTrue);
      }
    }
  });

  test('it follows the real phase', () {
    final today = start.addDays(6);
    final c = make(cycle: stateFor(start, today), today: today);
    final Pages pages = c.read(tryNewPagesProvider);
    expect(pages.first.first.recipe.phase, Phase.follicular);
  });
}
