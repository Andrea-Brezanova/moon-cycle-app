import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/application/content_providers.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';
import 'package:moon_cycle/features/shopping/application/shopping_controller.dart';
import 'package:moon_cycle/features/shopping/application/shopping_summary.dart';
import 'package:moon_cycle/features/shopping/data/shopping_repository.dart';
import 'package:moon_cycle/features/shopping/domain/quantity.dart';

import '../../../helpers/test_catalogue.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  ProviderContainer make({FoodFilter filter = FoodFilter.none}) {
    db = AppDatabase(NativeDatabase.memory());
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        catalogueProvider.overrideWithValue(testCatalogue),
        foodFilterProvider.overrideWithValue(filter),
        undoWindowProvider.overrideWithValue(const Duration(milliseconds: 80)),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await db.close();
    });
    return c;
  }

  ShoppingController controller() =>
      container.read(shoppingControllerProvider.notifier);
  Future<List<String>> keys() async => [
    for (final i in await container.read(shoppingRepositoryProvider).items())
      i.key,
  ];

  test('a food from Foods, then the same food from a recipe: merged', () async {
    container = make();
    final c = controller();
    await c.addFood(testCatalogue.food('lemon')!, Phase.follicular);
    final added = await c.addRecipe(
      testCatalogue.recipe('tuna-pea-lemon-pasta')!,
    );
    expect(added.added, 6); // 7 lines, lemon merged
    expect(added.merged, 1);
    final items = await container.read(shoppingRepositoryProvider).items();
    final lemon = items.firstWhere((i) => i.key == 'food:lemon');
    expect(lemon.isMerged, isTrue);
    // A recipe line named like a catalogue food resolves to it (Olive oil).
    final oil = items.firstWhere((i) => i.name == 'Olive oil');
    expect(oil.key, 'food:olive-oil');
    // The catalogue puts olive oil in the `other` aisle (Foods v2 is frozen).
    expect(oil.aisleId, 'other');
    expect(displayQuantity(oil.sources), '2 tbsp');
  });

  test('the same recipe twice changes nothing', () async {
    container = make();
    final recipe = testCatalogue.recipe('zucchini-feta-herb-frittata')!;
    await controller().addRecipe(recipe);
    final again = await controller().addRecipe(recipe);
    expect(again.added, 0);
    expect(again.merged, 0);
  });

  test('avoided ingredients are skipped and named', () async {
    container = make(
      filter: const FoodFilter(
        avoidances: [AllergenAvoidance(id: 'a', allergenId: 'sesame')],
      ),
    );
    final added = await controller().addRecipe(
      testCatalogue.recipe('tahini-chickpea-sweet-potato-tray')!,
    );
    expect(added.skipped.map((l) => l.label), ['Tahini']);
    expect(await keys(), isNot(contains('food:sesame-seeds')));
  });

  test('typed text: a synonym merges with the food', () async {
    container = make();
    await controller().addFood(
      testCatalogue.food('zucchini')!,
      Phase.follicular,
    );
    await controller().addTyped('courgette');
    expect(await keys(), ['food:zucchini']);
    await controller().addTyped('  ');
    expect(await keys(), hasLength(1));
  });

  test('Clear all then Undo within the window restores', () async {
    container = make();
    final c = controller();
    final item = (await c.addFood(
      testCatalogue.food('lemon')!,
      Phase.follicular,
    )).item;
    await c.toggle(item);
    await c.clearDone();
    expect(
      container.read(shoppingControllerProvider)!.message,
      '1 done item cleared',
    );
    expect(await keys(), isEmpty);
    await c.undoClear();
    expect(await keys(), ['food:lemon']);
    expect(container.read(shoppingControllerProvider), isNull);
  });

  test('after the window, Undo is gone', () async {
    container = make();
    final c = controller();
    final item = (await c.addFood(
      testCatalogue.food('lemon')!,
      Phase.follicular,
    )).item;
    await c.toggle(item);
    await c.clearDone();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(container.read(shoppingControllerProvider), isNull);
    await c.undoClear();
    expect(await keys(), isEmpty);
  });

  test('the summary counts To buy, Done and recipe items', () async {
    container = make();
    final sub = container.listen(shoppingSummaryProvider, (_, _) {});
    addTearDown(sub.close);
    final c = controller();
    final lemon = (await c.addFood(
      testCatalogue.food('lemon')!,
      Phase.follicular,
    )).item;
    await c.addRecipe(testCatalogue.recipe('avocado-egg-arugula-toast')!);
    await c.toggle(lemon);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final s = container.read(shoppingSummaryProvider);
    expect(s.toBuy, 6);
    expect(s.done, 1);
    expect(s.fromRecipes, 6);
    expect(s.onListFoodIds, contains('avocado'));
    expect(s.onListFoodIds, isNot(contains('lemon')));
  });
}
