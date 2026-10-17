import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/phase.dart';
import '../../../core/time/today.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../foods/application/food_providers.dart';

/// A small, stable string hash (FNV-1a), so a day's pick never changes
/// between rebuilds, launches or platforms.
int stableHash(String text) {
  var hash = 0x811c9dc5;
  for (final unit in text.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return hash;
}

/// The foods [phase] features that the user eats, in the stored order.
final _phaseFoodsProvider = Provider.family<List<Food>, Phase>((ref, phase) {
  final catalogue = ref.watch(catalogueProvider);
  final filter = ref.watch(foodFilterProvider);
  return [
    for (final food in catalogue.foodsFor(phase))
      if (filter.allowsFood(food)) food,
  ];
});

/// Home's "Today's food": one food featured in [phase], the same all day.
///
/// Chosen from the day's date and the phase by a fixed hash (no randomness,
/// no history). Foods with a recipe in the phase are preferred so "Recipes"
/// has something to show; the user's diet and avoidances are respected.
final todaysFoodProvider = Provider.family<Food?, Phase>((ref, phase) {
  final foods = ref.watch(_phaseFoodsProvider(phase));
  if (foods.isEmpty) return null;
  final withRecipes = ref.watch(recipeCountsProvider(phase));
  final pool = [
    for (final f in foods)
      if ((withRecipes[f.id] ?? 0) > 0) f,
  ];
  final from = pool.isEmpty ? foods : pool;
  final today = ref.watch(todayProvider);
  return from[stableHash('today|$today|${phase.name}') % from.length];
});

/// The pages "Try something new" shows, three foods each: [phase]'s featured
/// foods except Today's food, no food on two pages, each page from three
/// different categories where the phase allows. The categories with the most
/// foods left are used first; the date only turns the starting point.
final tryNewPagesProvider = Provider.family<List<List<Food>>, Phase>((
  ref,
  phase,
) {
  final catalogue = ref.watch(catalogueProvider);
  final todays = ref.watch(todaysFoodProvider(phase));
  final byCategory = <String, List<Food>>{};
  for (final food in ref.watch(_phaseFoodsProvider(phase))) {
    if (food.id == todays?.id) continue;
    byCategory.putIfAbsent(food.categoryId, () => []).add(food);
  }
  final today = ref.watch(todayProvider);
  final lanes = [for (final c in catalogue.categories) ?byCategory[c.id]];
  if (lanes.isEmpty) return const [];
  // Turn each lane (and the order of lanes) by the date, so days differ.
  final seed = stableHash('try|$today|${phase.name}');
  final queues = [
    for (final (i, lane) in lanes.indexed)
      [
        ...lane.skip((seed + i) % lane.length),
        ...lane.take((seed + i) % lane.length),
      ],
  ];
  final turn = seed % queues.length;
  final ordered = [...queues.skip(turn), ...queues.take(turn)];

  final pages = <List<Food>>[];
  while (ordered.any((q) => q.isNotEmpty)) {
    final live = [
      for (final q in ordered)
        if (q.isNotEmpty) q,
    ]..sort((a, b) => b.length - a.length); // stable: ties keep the order
    final page = [for (final q in live.take(3)) q.removeAt(0)];
    pages.add(page);
  }
  // Once fewer than three categories are left, a page borrows foods from
  // other pages (never one it already has), so every page has three.
  final all = [for (final page in pages) ...page];
  if (all.length >= 3) {
    for (final page in pages) {
      for (final f in all) {
        if (page.length >= 3) break;
        if (!page.any((o) => o.id == f.id)) page.add(f);
      }
    }
  }
  return pages;
});

/// Page [page] (0, 1, …) of [pages], wrapping around.
List<Food> pageOfThree(List<List<Food>> pages, int page) =>
    pages.isEmpty ? const [] : pages[page % pages.length];
