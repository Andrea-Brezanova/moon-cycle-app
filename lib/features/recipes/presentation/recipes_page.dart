import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_colors.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/centered_header.dart';
import '../../../core/design/widgets/moon_chip.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/catalogue.dart';
import '../../content/domain/recipe.dart';
import '../../eat/presentation/phase_pill.dart';
import '../../generation/application/generation_providers.dart';
import '../../generation/data/saved_recipe_repository.dart';
import '../../generation/domain/saved_recipe_ref.dart';
import '../application/recipe_filter.dart';
import '../application/recipe_list.dart';
import 'cook_with_sheet.dart';
import 'recipe_copy.dart';
import 'widgets/recipe_widgets.dart';

/// The Recipes screen (V2): a centred title with back and the ingredient
/// search, the phase, meal type pills, one optional "Cook with" ingredient and
/// the matching recipes as rounded cards with a heart that saves them to My
/// recipes (PRD §9).
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
    final mine = ref.watch(personalRecipesProvider).value?.length ?? 0;
    final saved =
        ref.watch(savedRecipeRefsProvider).value ?? const <SavedRecipeRef>[];
    final savedIds = {for (final r in saved) r.refId};
    final repo = ref.read(savedRecipeRepositoryProvider);
    final phaseName = list.all
        ? 'All phases'
        : catalogue.phase(list.phase).name;

    Future<void> chooseIngredient() async {
      final chosen = await showCookWithSheet(context, phase: list.phase);
      if (chosen != null) filter.cookWith(chosen.id);
    }

    void open(Recipe r) => context.push(Routes.recipe(r.id));
    void toggleSaved(Recipe r) => savedIds.contains(r.id)
        ? repo.remove(r.id)
        : repo.save(providerId: 'moon-cycle', refId: r.id, title: r.title);

    Widget gutter(Widget child, {double top = 0}) => Padding(
      padding: EdgeInsets.fromLTRB(MoonSpace.gutter, top, MoonSpace.gutter, 0),
      child: child,
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CenteredHeader(
              title: 'Recipes',
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(AppTab.eat.path),
              // The ingredient search lists the viewing phase's foods, so it
              // isn't offered under "All phases".
              trailingIcon: list.all ? null : MoonIconName.search,
              trailingLabel: 'Search ingredients',
              trailingKey: const ValueKey('recipes-search'),
              onTrailing: chooseIngredient,
            ),
            gutter(
              Align(
                alignment: Alignment.centerLeft,
                child: PhasePill(label: phaseName, all: list.all),
              ),
              top: 6,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 42 + 76),
                children: [
                  gutter(
                    MealChips(
                      selected: list.filter.mealType,
                      onChanged: filter.setMealType,
                      available: list.mealTypes,
                    ),
                    top: 14,
                  ),
                  if (!(food == null && list.all))
                    gutter(
                      food == null
                          ? CookWithField(
                              palette: palette,
                              onTap: chooseIngredient,
                            )
                          : Row(
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
                      top: 12,
                    ),
                  gutter(
                    Text(
                      recipeCountLine(list, foodName: foodName),
                      style: dmSans(
                        13,
                        weight: FontWeight.w500,
                        height: 1.2,
                        color: c.textMuted,
                      ),
                    ),
                    top: 20,
                  ),
                  if (empty != null)
                    gutter(
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
                      top: 10,
                    )
                  else
                    for (final r in list.recipes)
                      gutter(
                        RecipeListCard(
                          recipe: r,
                          palette: paletteOf(r),
                          subtitle: keyIngredients(r, catalogue),
                          onTap: () => open(r),
                          hearted: savedIds.contains(r.id),
                          onHeart: () => toggleSaved(r),
                        ),
                        top: 12,
                      ),
                  gutter(
                    _MyRecipesButton(
                      count: mine + saved.length,
                      onTap: () => context.push(Routes.myRecipes),
                    ),
                    top: 24,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The prominent "My recipes" button under the list.
class _MyRecipesButton extends StatelessWidget {
  const _MyRecipesButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final label = count == 0 ? 'My recipes' : 'My recipes ($count)';
    return Pressable(
      key: const ValueKey('my-recipes-button'),
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: ShapeDecoration(
          color: c.inverseBg,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MoonIcon(MoonIconName.heart, size: 18, color: c.inverseText),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: dmSans(
                  15,
                  weight: FontWeight.w600,
                  height: 1.2,
                  color: c.inverseText,
                ),
              ),
            ),
            const SizedBox(width: 10),
            MoonIcon(
              MoonIconName.arrow,
              size: 16,
              color: c.inverseText,
              strokeWidth: 2,
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
