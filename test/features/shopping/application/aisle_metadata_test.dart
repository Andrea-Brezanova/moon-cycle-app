import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/application/content_providers.dart';
import 'package:moon_cycle/features/shopping/application/shopping_controller.dart';
import 'package:moon_cycle/features/shopping/data/shopping_repository.dart';
import 'package:moon_cycle/features/shopping/domain/shopping_list.dart';

import '../../../helpers/test_catalogue.dart';

/// Pantry staples and butter are grouped under sensible shopping aisles, not
/// "Other". Aisle metadata only: categories and featured phases are separate.
void main() {
  const expected = {
    'olive-oil': 'pantry',
    'avocado-oil': 'pantry',
    'coconut-oil': 'pantry',
    'honey': 'pantry',
    'maple-syrup': 'pantry',
    'wheat-flour': 'pantry',
    'butter': 'dairy-alternatives',
  };

  test('audited foods carry the corrected aisle', () {
    for (final MapEntry(key: id, value: aisle) in expected.entries) {
      expect(testCatalogue.food(id)!.aisleId, aisle, reason: id);
    }
  });

  test(
    'on the list they group under Pantry and Dairy & alternatives',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          catalogueProvider.overrideWithValue(testCatalogue),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      final controller = container.read(shoppingControllerProvider.notifier);
      for (final id in expected.keys) {
        await controller.addFood(testCatalogue.food(id)!, Phase.follicular);
      }
      final items = await container.read(shoppingRepositoryProvider).items();
      final groups = toBuyByAisle(items, [
        for (final a in testCatalogue.aisles) a.id,
      ]);
      final byAisle = {
        for (final (aisle, list) in groups)
          aisle: [for (final i in list) i.key],
      };
      expect(byAisle.keys.toSet(), {'pantry', 'dairy-alternatives'});
      expect(byAisle['dairy-alternatives'], ['food:butter']);
      expect(
        byAisle['pantry'],
        unorderedEquals([
          for (final e in expected.entries)
            if (e.value == 'pantry') 'food:${e.key}',
        ]),
      );
      expect(testCatalogue.aisle('pantry').name, 'Pantry');
      expect(
        testCatalogue.categoryFor(testCatalogue.food('butter')!).id,
        'dairy-alternatives',
      );
    },
  );
}
