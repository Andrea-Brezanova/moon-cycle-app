import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/shopping/domain/item_key.dart';
import 'package:moon_cycle/features/shopping/domain/quantity.dart';
import 'package:moon_cycle/features/shopping/domain/shopping_item.dart';
import 'package:moon_cycle/features/shopping/domain/shopping_list.dart';
import 'package:moon_cycle/features/shopping/domain/shopping_merger.dart';

import '../../../helpers/test_catalogue.dart';

void main() {
  var ids = 0;
  final now = DateTime.utc(2025, 10, 4, 9);
  AddOutcome add(List<ShoppingItem> list, AddRequest r) =>
      addToList(list, r, newId: () => 'id-${++ids}', now: now);

  AddRequest lemon(ShoppingSource source) => AddRequest(
    key: foodKey('lemon'),
    foodId: 'lemon',
    name: 'Lemon',
    aisleId: 'produce',
    source: source,
  );
  const fromPhase = ShoppingSource(
    id: '',
    type: SourceType.phaseFood,
    phase: Phase.follicular,
  );
  ShoppingSource fromRecipe(String id, {double? amount, String? unit}) =>
      ShoppingSource(
        id: '',
        type: SourceType.recipe,
        recipeId: id,
        amount: amount,
        unit: unit,
      );

  test('a new food creates an item', () {
    final o = add(const [], lemon(fromPhase));
    expect(o, isA<ItemCreated>());
    expect(o.item.sources, hasLength(1));
    expect(o.item.isMerged, isFalse);
  });

  test('the same food from the same phase twice changes nothing', () {
    final first = add(const [], lemon(fromPhase)).item;
    expect(add([first], lemon(fromPhase)), isA<ItemUnchanged>());
  });

  test('the same food from a phase and a recipe merges', () {
    final first = add(const [], lemon(fromPhase)).item;
    final o = add([first], lemon(fromRecipe('zesty', amount: 1)));
    expect(o, isA<ItemMerged>());
    expect(o.item.sources, hasLength(2));
    expect(o.item.isMerged, isTrue);
    expect(o.item.hasRecipeSource, isTrue);
  });

  test('the same recipe twice never doubles its quantities', () {
    final first = add(const [], lemon(fromRecipe('zesty', amount: 1))).item;
    final o = add([first], lemon(fromRecipe('zesty', amount: 1)));
    expect(o, isA<ItemUnchanged>());
    expect(displayQuantity(o.item.sources), '1');
  });

  test('a Done item added again moves back to To buy', () {
    final first = add(const [], lemon(fromPhase)).item;
    final done = first.copyWith(done: true, doneAt: now);
    final o = add([done], lemon(fromRecipe('zesty', amount: 1)));
    expect(o, isA<ItemMerged>().having((m) => m.reopened, 'reopened', true));
    expect(o.item.done, isFalse);
    // Same reason again on a Done item: reopened, no new source.
    final again = add([done], lemon(fromPhase));
    expect(again, isA<ItemMerged>().having((m) => m.source, 'source', isNull));
    expect(again.item.done, isFalse);
  });

  group('quantities', () {
    ShoppingSource q(double? amount, String? unit, [String? text]) =>
        ShoppingSource(
          id: '',
          type: SourceType.recipe,
          amount: amount,
          unit: unit,
          qtyText: text,
        );

    test('200 g + 1 kg = 1.2 kg', () {
      expect(displayQuantity([q(200, 'g'), q(1, 'kg')]), '1.2 kg');
    });
    test('volume and mass are never converted', () {
      expect(displayQuantity([q(1, 'tbsp'), q(100, 'g')]), '1 tbsp + 100 g');
      expect(displayQuantity([q(250, 'ml'), q(1, 'l')]), '1¼ l');
    });
    test('pieces show the number; other units keep their name', () {
      expect(displayQuantity([q(1, 'piece'), q(2, 'piece')]), '3');
      expect(displayQuantity([q(2, 'handful'), q(1, 'handful')]), '3 handful');
      expect(displayQuantity([q(0.5, 'piece')]), '½');
    });
    test('words are listed once, after the amounts', () {
      expect(
        displayQuantity([
          q(null, null, 'to serve'),
          q(150, 'g'),
          q(null, null, 'to serve'),
        ]),
        '150 g + to serve',
      );
    });
    test('no amounts: nothing to show', () {
      expect(displayQuantity(const [fromPhase]), '');
    });
  });

  group('typed items', () {
    test('a synonym finds the food', () {
      final t = resolveTyped(' courgette ', testCatalogue)!;
      expect(t.key, 'food:zucchini');
      expect(t.name, 'Zucchini');
      expect(t.aisleId, 'produce');
    });
    test('a catalogue food typed by name resolves to the food', () {
      final t = resolveTyped('oat  milk', testCatalogue)!;
      expect(t.key, 'food:oat-milk');
      expect(t.foodId, 'oat-milk');
      expect(t.name, 'Oat milk');
      expect(t.aisleId, 'dairy-alternatives');
    });
    test('no match: free text in Other', () {
      final t = resolveTyped('kitchen  paper', testCatalogue)!;
      expect(t.key, 'text:kitchen paper');
      expect(t.foodId, isNull);
      expect(t.name, 'Kitchen paper');
      expect(t.aisleId, otherAisle);
    });
    test('blank text is nothing', () {
      expect(resolveTyped('   ', testCatalogue), isNull);
    });
  });

  test('To buy is grouped by aisle in the fixed order; Done is separate', () {
    ShoppingItem item(String key, String aisle, {bool done = false}) =>
        ShoppingItem(
          id: key,
          key: key,
          name: key,
          aisleId: aisle,
          done: done,
          sources: const [],
          createdAt: now,
        );
    final groups = toBuyByAisle(
      [
        item('miso', 'fermented'),
        item('lemon', 'produce'),
        item('salt', 'pantry', done: true),
        item('kale', 'produce'),
      ],
      ['produce', 'protein', 'fermented', 'pantry'],
    );
    expect(
      [for (final (a, items) in groups) '$a:${items.map((i) => i.key)}'],
      ['produce:(lemon, kale)', 'fermented:(miso)'],
    );
  });
}
