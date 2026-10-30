import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/features/generation/data/saved_recipe_repository.dart';

import '../../helpers/fake_stamp.dart';

void main() {
  late AppDatabase db;
  late SavedRecipeRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = SavedRecipeRepository(db, fakeStamp());
  });
  tearDown(() => db.close());

  test('an external recipe is saved as a reference only', () async {
    await repo.save(
      providerId: 'themealdb',
      refId: 'x-themealdb-1',
      externalId: '1',
      title: 'Synthetic Carrot Side',
      sourceUrl: 'https://example.com/r',
    );
    final r = (await repo.all()).single;
    expect(r.isExternal, isTrue);
    expect(r.title, 'Synthetic Carrot Side');
    expect(r.sourceUrl, 'https://example.com/r');
    // There is nowhere to keep ingredients or a method: the table has no such
    // column.
    final columns = db.savedRecipeRefs.$columns.map((c) => c.$name).toSet();
    expect(columns.any((c) => c.contains('ingredient')), isFalse);
    expect(
      columns.any((c) => c.contains('instruction') || c.contains('step')),
      isFalse,
    );
  });

  test('saving twice keeps one; removing frees it', () async {
    for (var i = 0; i < 2; i++) {
      await repo.save(providerId: 'moon-cycle', refId: 'lib-1', title: 'Stew');
    }
    expect(await repo.all(), hasLength(1));
    await repo.remove('lib-1');
    expect(await repo.all(), isEmpty);
    await repo.save(providerId: 'moon-cycle', refId: 'lib-1', title: 'Stew');
    expect(await repo.all(), hasLength(1));
  });

  test('newest first', () async {
    await repo.save(providerId: 'moon-cycle', refId: 'a', title: 'A');
    await repo.save(providerId: 'moon-cycle', refId: 'b', title: 'B');
    expect((await repo.all()).map((r) => r.refId), ['b', 'a']);
  });
}
