import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/shopping/data/shopping_repository.dart';
import 'package:moon_cycle/features/shopping/domain/item_key.dart';
import 'package:moon_cycle/features/shopping/domain/quantity.dart';
import 'package:moon_cycle/features/shopping/domain/shopping_item.dart';
import 'package:moon_cycle/features/shopping/domain/shopping_merger.dart';

import '../../../helpers/fake_stamp.dart';

AddRequest food(
  String id, {
  SourceType type = SourceType.phaseFood,
  String? recipe,
  double? amount,
  String? unit,
}) => AddRequest(
  key: foodKey(id),
  foodId: id,
  name: id,
  aisleId: 'produce',
  source: ShoppingSource(
    id: '',
    type: type,
    phase: type == SourceType.phaseFood ? Phase.follicular : null,
    recipeId: recipe,
    amount: amount,
    unit: unit,
  ),
);

void main() {
  late AppDatabase db;
  late ShoppingRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ShoppingRepository(db, fakeStamp());
  });
  tearDown(() => db.close());

  test('adds, merges and keeps sources', () async {
    await repo.add(food('lemon'));
    await repo.add(
      food(
        'lemon',
        type: SourceType.recipe,
        recipe: 'zesty',
        amount: 1,
        unit: 'piece',
      ),
    );
    await repo.add(food('kale'));
    final items = await repo.items();
    expect(items.map((i) => i.key), ['food:lemon', 'food:kale']);
    expect(items.first.sources, hasLength(2));
    expect(displayQuantity(items.first.sources), '1');
  });

  test('the same recipe twice stores nothing new', () async {
    final r = food(
      'lemon',
      type: SourceType.recipe,
      recipe: 'zesty',
      amount: 1,
    );
    await repo.add(r);
    expect(await repo.add(r), isA<ItemUnchanged>());
    expect((await repo.items()).single.sources, hasLength(1));
  });

  test('a recipe is added in one transaction', () async {
    final outcomes = await repo.addAll([
      food('lemon', type: SourceType.recipe, recipe: 'zesty', amount: 1),
      food(
        'parsley',
        type: SourceType.recipe,
        recipe: 'zesty',
        amount: 1,
        unit: 'bunch',
      ),
    ]);
    expect(outcomes, everyElement(isA<ItemCreated>()));
    expect(await repo.items(), hasLength(2));
  });

  test('done, re-added: back in To buy', () async {
    final item = (await repo.add(food('lemon'))).item;
    await repo.setDone(item.id, done: true);
    expect((await repo.items()).single.done, isTrue);
    await repo.add(food('lemon', type: SourceType.recipe, recipe: 'zesty'));
    final again = (await repo.items()).single;
    expect(again.done, isFalse);
    expect(again.doneAt, isNull);
  });

  test('× removes at once (a tombstone)', () async {
    final item = (await repo.add(food('lemon'))).item;
    await repo.remove(item.id);
    expect(await repo.items(), isEmpty);
    final rows = await db.select(db.shoppingItems).get();
    expect(rows.single.deletedAt, isNotNull);
    // And it can be added again.
    await repo.add(food('lemon'));
    expect(await repo.items(), hasLength(1));
  });

  test('Clear all removes only Done items; Undo brings them back', () async {
    final a = (await repo.add(food('lemon'))).item;
    final b = (await repo.add(
      food(
        'kale',
        type: SourceType.recipe,
        recipe: 'x',
        amount: 2,
        unit: 'handful',
      ),
    )).item;
    await repo.add(food('rye'));
    await repo.setDone(a.id, done: true);
    await repo.setDone(b.id, done: true);
    final cleared = await repo.clearDone();
    expect(cleared.itemIds, unorderedEquals([a.id, b.id]));
    expect((await repo.items()).map((i) => i.key), ['food:rye']);

    await repo.restore(cleared);
    final back = await repo.items();
    expect(back, hasLength(3));
    final kale = back.firstWhere((i) => i.key == 'food:kale');
    expect(kale.done, isTrue);
    expect(displayQuantity(kale.sources), '2 handful');
  });

  test('Undo skips an item that was added again meanwhile', () async {
    final a = (await repo.add(food('lemon'))).item;
    await repo.setDone(a.id, done: true);
    final cleared = await repo.clearDone();
    await repo.add(food('lemon'));
    await repo.restore(cleared);
    expect(await repo.items(), hasLength(1));
  });

  test('watch emits the changes', () async {
    final stream = repo.watchItems();
    final expectation = expectLater(
      stream.map((items) => items.length),
      emitsInOrder([0, 1]),
    );
    await Future<void>.delayed(Duration.zero);
    await repo.add(food('lemon'));
    await expectation;
  });
}
