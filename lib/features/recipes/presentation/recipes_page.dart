import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/shell/tab_scroll.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_colors.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/moon_chip.dart';
import '../../../core/design/widgets/moon_segmented.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../../core/domain/browse_scope.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/catalogue.dart';
import '../../content/domain/recipe.dart';
import '../../cycle/presentation/phase_header.dart';
import '../application/recipe_filter.dart';
import '../application/recipe_list.dart';
import '../application/recipes_scope.dart';
import 'cook_with_sheet.dart';
import 'recipe_copy.dart';
import 'widgets/recipe_widgets.dart';

/// The Recipes tab (`08-recipes` and its filtered and empty states): phase,
/// meal type and one optional ingredient (PRD §9). The first recipe is the
/// feature card; the rest form a two-across grid.
class RecipesPage extends ConsumerWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final catalogue = ref.watch(catalogueProvider);
    final list = ref.watch(recipeListProvider);
    final palette = c.phase(list.phase);
    final filter = ref.read(recipeFilterProvider.notifier);
    final food = list.filter.foodId == null
        ? null
        : catalogue.food(list.filter.foodId!);
    // "All recipes" mixes phases, so each card wears its own phase's colour.
    PhasePalette paletteOf(Recipe r) => list.all ? c.phase(r.phase) : palette;
    final foodName = food?.displayName.toLowerCase();
    final empty = recipesEmptyCopy(list, foodName: foodName);

    Future<void> chooseIngredient() async {
      final chosen = await showCookWithSheet(context, phase: list.phase);
      if (chosen != null) filter.cookWith(chosen.id);
    }

    void open(Recipe r) => context.push(Routes.recipe(r.id));

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          controller: ref.watch(tabScrollProvider).of(AppTab.recipes),
          padding: const EdgeInsets.only(bottom: 42),
          children: [
            const PhaseHeader(title: 'Recipes', showPhaseLine: false, gap: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MoonSpace.gutter,
                16,
                MoonSpace.gutter,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MoonSegmented<BrowseScope>(
                    semanticLabel: 'Show',
                    options: const [
                      (BrowseScope.phase, 'This phase'),
                      (BrowseScope.all, 'All recipes'),
                    ],
                    selected: ref.watch(recipesScopeProvider),
                    onChanged: ref.read(recipesScopeProvider.notifier).set,
                  ),
                  const SizedBox(height: 16),
                  MealTabs(
                    selected: list.filter.mealType,
                    onChanged: filter.setMealType,
                    available: list.mealTypes,
                  ),
                  const SizedBox(height: 16),
                  // "Cook with…" lists the viewing phase's foods, so it isn't
                  // offered under "All recipes".
                  if (food == null && list.all)
                    const SizedBox.shrink()
                  else if (food == null)
                    CookWithField(palette: palette, onTap: chooseIngredient)
                  else
                    Row(
                      children: [
                        Flexible(
                          child: MoonRemovableChip(
                            prefix: 'Cook with: ',
                            label: food.displayName,
                            tint: palette.tint,
                            height: 44,
                            onRemove: filter.clearIngredient,
                            removeLabel: 'Clear ingredient',
                          ),
                        ),
                        const SizedBox(width: 14),
                        if (!list.all)
                          TextLink('Change', onTap: chooseIngredient),
                      ],
                    ),
                  const SizedBox(height: 22),
                  Text(
                    recipeCountLine(list, foodName: foodName),
                    style: dmSans(
                      13,
                      weight: FontWeight.w500,
                      height: 1,
                      color: c.textMuted,
                    ),
                  ),
                  if (empty != null) ...[
                    const SizedBox(height: 10),
                    EmptyState(
                      icon: empty.icon,
                      title: empty.title,
                      body: empty.body,
                      palette: palette,
                      actions: [
                        for (final action in empty.actions)
                          switch (action) {
                            EmptyAction.showAllMealTypes => TextLink(
                              'Show all meal types',
                              onTap: () => filter.setMealType(null),
                            ),
                            EmptyAction.clearIngredient => TextLink(
                              'Clear ingredient',
                              onTap: filter.clearIngredient,
                            ),
                            EmptyAction.reviewPreferences => TextLink(
                              'Review food preferences',
                              onTap: () => context.go(
                                Routes.settings(SettingsPage.foodPreferences),
                              ),
                            ),
                          },
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 26),
                    FeatureRecipeCard(
                      recipe: list.recipes.first,
                      keyIngredients: keyIngredients(
                        list.recipes.first,
                        catalogue,
                      ),
                      palette: paletteOf(list.recipes.first),
                      onTap: () => open(list.recipes.first),
                    ),
                    for (var i = 1; i < list.recipes.length; i += 2) ...[
                      const SizedBox(height: 26),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: GridRecipeCard(
                              recipe: list.recipes[i],
                              palette: paletteOf(list.recipes[i]),
                              onTap: () => open(list.recipes[i]),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: i + 1 < list.recipes.length
                                ? GridRecipeCard(
                                    recipe: list.recipes[i + 1],
                                    palette: paletteOf(list.recipes[i + 1]),
                                    onTap: () => open(list.recipes[i + 1]),
                                  )
                                : const SizedBox(),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Green lentil, broccoli, zucchini": the first three key ingredients.
String keyIngredients(Recipe recipe, Catalogue catalogue) {
  final names = [
    for (final id in recipe.keyFoodIds.take(3))
      ?catalogue.food(id)?.displayName,
  ];
  return [for (final (i, n) in names.indexed) i == 0 ? n : n.toLowerCase()]
      .join(', ');
}
