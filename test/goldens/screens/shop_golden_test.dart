@Tags(['golden'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/shopping/application/shopping_controller.dart';
import 'package:moon_cycle/features/shopping/application/shopping_summary.dart';
import 'package:moon_cycle/features/shopping/data/shopping_repository.dart';
import 'package:moon_cycle/features/shopping/domain/shopping_item.dart';
import 'package:moon_cycle/features/shopping/presentation/shop_page.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/moon_fonts.dart';
import 'home_golden_test.dart' show stateOnDay;

const _staple = ShoppingSource(
  id: 's',
  type: SourceType.phaseFood,
  phase: Phase.follicular,
);
const _chicken = ShoppingSource(
  id: 'r',
  type: SourceType.recipe,
  recipeId: 'lemon-herb-chicken-artichoke',
);
const _you = ShoppingSource(id: 'm', type: SourceType.manual);

ShoppingItem _item(
  String name,
  String aisle,
  List<ShoppingSource> sources, {
  bool done = false,
}) => ShoppingItem(
  id: name,
  key: 'food:$name',
  foodId: name.toLowerCase(),
  name: name,
  aisleId: aisle,
  done: done,
  doneAt: done ? DateTime(2025, 10, 4) : null,
  sources: sources,
  createdAt: DateTime(2025, 10, 3),
);

/// The list in the design (`sample-content.json` › `sampleShoppingList`).
final _sample = [
  _item('Avocado', 'produce', [_staple]),
  _item('Broccoli', 'produce', [_staple]),
  _item('Lemon', 'produce', [_staple, _chicken]),
  _item('Artichoke', 'produce', [_chicken]),
  _item('Parsley', 'produce', [_chicken]),
  _item('Green pea', 'produce', [_chicken]),
  _item('Chicken', 'protein', [_chicken]),
  _item('Rye bread', 'grains', [_staple], done: true),
  _item('Barley', 'grains', [_chicken]),
  _item('Sauerkraut', 'fermented', [_staple], done: true),
  _item('Oat milk', 'dairy-alternatives', [_you], done: true),
];

class _Undo extends ShoppingController {
  @override
  ClearUndo? build() => ClearUndo(
    ClearedItems(itemIds: const ['a', 'b', 'c'], at: DateTime(2025, 10, 4)),
  );
}

void main() {
  setUpAll(loadMoonFonts);

  List<Override> list(List<ShoppingItem> items) => [
    cycleStateProvider.overrideWithValue(stateOnDay(7)),
    shoppingItemsProvider.overrideWithValue(AsyncData(items)),
  ];

  final cases = <String, List<Override>>{
    'shop': list(_sample),
    'empty': list(const []),
    'undo': [
      ...list([
        for (final i in _sample)
          if (!i.done) i,
      ]),
      shoppingControllerProvider.overrideWith(_Undo.new),
    ],
  };

  for (final MapEntry(key: theme, value: dark) in themes.entries) {
    for (final MapEntry(key: name, value: overrides) in cases.entries) {
      testWidgets('$name, $theme', (tester) async {
        await pumpScreen(
          tester,
          const ShopPage(),
          dark: dark,
          height: name == 'shop' ? 1400 : 844,
          overrides: overrides,
        );
        await expectLater(
          find.byType(ShopPage),
          matchesGoldenFile('goldens/$theme-shop-$name.png'),
        );
      });
    }
  }
}
