import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_colors.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/centered_header.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_chip.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/recipe_photo.dart';
import '../../../core/domain/phase.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../content/domain/recipe.dart';
import '../../cycle/application/viewing_phase.dart';
import '../../diary/domain/diary_entry.dart';
import '../../eat/application/eat_segment.dart';
import '../../entitlements/application/entitlement_providers.dart';
import '../../entitlements/domain/entitlements.dart';
import '../../recipes/application/recipe_filter.dart';
import '../../recipes/application/recipes_scope.dart';
import '../../shopping/application/shopping_controller.dart';
import '../../shopping/application/shopping_summary.dart';
import '../application/food_providers.dart';
import 'food_emoji.dart';
import 'widgets/food_profile_sections.dart';

/// Opens [food]'s page. A food featured in [phase] shows that phase's "Why
/// this food?"; any other food opens without phase context, so no phase
/// rationale is invented for it.
void openFoodDetail(
  BuildContext context,
  WidgetRef ref, {
  required Food food,
  required Phase phase,
}) => context.push(
  Routes.food(food.id, phase: phase, general: food.why[phase] == null),
);

/// A food's page (one page for every food, found by its stable id): the
/// illustration, category, name, why we feature it, and four actions.
///
/// [phase] is the phase whose reason is shown (the viewing phase if null).
/// With [general] the page is opened without phase context.
class FoodDetailPage extends ConsumerWidget {
  const FoodDetailPage({
    super.key,
    required this.foodId,
    this.phase,
    this.general = false,
  });

  final String foodId;
  final Phase? phase;
  final bool general;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final catalogue = ref.watch(catalogueProvider);
    final food = catalogue.food(foodId);
    final viewing = ref.watch(viewingPhaseProvider);
    final shown = phase ?? viewing;
    final palette = c.phase(shown);

    // Back goes to whichever screen opened this page; with nothing to go back
    // to (a link), it falls back to Foods.
    Widget header() => CenteredHeader(
      title: 'Food',
      onBack: () =>
          context.canPop() ? context.pop() : goEat(context, EatSegment.foods),
    );

    if (food == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MoonSpace.gutter,
                ),
                child: Text(
                  'We couldn’t find that food.',
                  style: MoonType.body.copyWith(color: c.text),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final why = general ? null : food.why[shown];
    final counts = general
        ? ref.watch(allRecipeCountsProvider)
        : ref.watch(recipeCountsProvider(shown));
    final count = counts[food.id] ?? 0;
    // Why there may be no recipes: none exist, or the user's food preferences
    // hide the ones that do. Counted before the preferences are applied.
    bool usesFood(Recipe r) => r.keyFoodIds.contains(food.id);
    final inScope = (general ? catalogue.recipes : catalogue.recipesFor(shown))
        .where(usesFood)
        .length;
    final anywhere = catalogue.recipes.where(usesFood).length;
    // From the stored shopping list itself (any state, to buy or done), never a
    // local flag, so it survives navigation and restarts and follows changes
    // made on the Shopping list page.
    final listed = (ref.watch(shoppingItemsProvider).value ?? const [])
        .where((i) => i.foodId == food.id)
        .firstOrNull;
    final gate = ref.watch(featureGateProvider);
    // Only a reviewed, publishable profile is shown; none is bundled yet.
    final profile = switch (ref.watch(foodProfileProvider(foodId))) {
      final p? when p.publishable => p,
      _ => null,
    };
    final canMeal = gate.canUse(Feature.buildMeal);
    final canDiary = gate.canUse(Feature.logDiary);
    final category = catalogue.categoryFor(food).name;
    final name = food.displayName.toLowerCase();
    final qualifier = food.qualifier;
    // Phases whose lists include the food (general information).
    final featuredIn = [
      for (final p in Phase.values)
        if (food.why[p] != null) p.name,
    ];

    void toSubscription() =>
        context.go(Routes.settings(SettingsPage.subscription));

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 42 + 76),
          children: [
            header(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MoonSpace.gutter,
                8,
                MoonSpace.gutter,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FoodHero(food: food, palette: palette),
                  const SizedBox(height: 22),
                  Overline(category),
                  const SizedBox(height: 10),
                  Semantics(
                    header: true,
                    child: Text(
                      food.displayName,
                      style: fraunces(42, height: 1, color: c.text),
                    ),
                  ),
                  if (qualifier != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      qualifier,
                      style: dmSans(14, height: 1.4, color: c.textMuted),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (why != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: MoonPill(
                        catalogue.sheetLabel.replaceAll('{phase}', shown.name),
                        background: palette.tint,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Overline('Why this food?'),
                    const SizedBox(height: 6),
                    Text(
                      why.short,
                      style: MoonType.body.copyWith(color: c.text),
                    ),
                  ] else if (featuredIn.isNotEmpty) ...[
                    const Overline('About this food'),
                    const SizedBox(height: 6),
                    Text(
                      'Featured in the ${featuredIn.length == 1 ? featuredIn.single : '${featuredIn.sublist(0, featuredIn.length - 1).join(', ')} and ${featuredIn.last}'} '
                      '${featuredIn.length == 1 ? 'phase' : 'phases'}.',
                      style: MoonType.body.copyWith(color: c.text),
                    ),
                  ],
                  if (profile != null)
                    FoodProfileSections(
                      profile: profile,
                      cycleHeading: ref.watch(profileCycleHeadingProvider),
                    ),
                  if ((profile?.cautions ?? food.cautions).isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _GoodToKnow(cautions: profile?.cautions ?? food.cautions),
                  ],
                  const SizedBox(height: 26),
                  // 1. Recipes with this food. Always shown; disabled, with the
                  // reason, when there are none to find.
                  MoonButton(
                    'Find recipes with $name',
                    trailingIcon: MoonIconName.arrow,
                    onPressed: count > 0
                        ? () {
                            // A phase's recipes: show that phase; "all"
                            // otherwise.
                            if (general) {
                              ref.read(recipesScopeProvider.notifier).showAll();
                            } else {
                              ref
                                  .read(viewingPhaseProvider.notifier)
                                  .choose(shown);
                            }
                            ref
                                .read(recipeFilterProvider.notifier)
                                .showRecipesWith(food.id);
                            // Pushed, so Back returns to this food.
                            context.push(Routes.eatRecipes);
                          }
                        : null,
                  ),
                  if (count == 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      key: const ValueKey('no-recipes-note'),
                      inScope > 0
                          ? (inScope == 1
                                ? 'The only recipe with $name is hidden by '
                                      'your food preferences.'
                                : 'All $inScope recipes with $name are hidden '
                                      'by your food preferences.')
                          : anywhere > 0
                          ? 'No ${shown.name} recipes with $name yet.'
                          : 'No recipes with $name yet.',
                      style: dmSans(14, height: 1.4, color: c.textMuted),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // 2. Make your own meal (Premium). Herbs season a meal and
                  // are not chosen as its ingredients, so theirs is disabled.
                  MoonButton(
                    'Build a Meal with $name',
                    variant: MoonButtonVariant.ghost,
                    trailingIcon: canMeal ? null : MoonIconName.lock,
                    onPressed: isHerb(food)
                        ? null
                        : canMeal
                        ? () =>
                              context.push(Routes.mealBuilder(foodId: food.id))
                        : toSubscription,
                  ),
                  if (isHerb(food)) ...[
                    const SizedBox(height: 8),
                    Text(
                      key: const ValueKey('herb-meal-note'),
                      'Herbs season a meal; they aren’t chosen as ingredients '
                      'in Build a Meal.',
                      style: dmSans(14, height: 1.4, color: c.textMuted),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // 3. The shopping list (free, independent of the rest).
                  if (listed != null)
                    MoonButton(
                      'Remove from shopping list',
                      variant: MoonButtonVariant.ghost,
                      trailingIcon: MoonIconName.check,
                      onPressed: () => ref
                          .read(shoppingControllerProvider.notifier)
                          .remove(listed),
                    )
                  else
                    MoonButton(
                      'Add to shopping list',
                      variant: MoonButtonVariant.ghost,
                      onPressed: () => ref
                          .read(shoppingControllerProvider.notifier)
                          .addFood(food, shown),
                    ),
                  const SizedBox(height: 12),
                  // 4. The diary (free): log this food as eaten.
                  MoonButton(
                    'Log meal',
                    variant: MoonButtonVariant.ghost,
                    trailingIcon: canDiary ? null : MoonIconName.lock,
                    onPressed: canDiary
                        ? () => context.push(
                            Routes.logMeal(
                              kind: DiaryItemKind.food,
                              itemId: food.id,
                              title: food.displayName,
                              from: 'food',
                            ),
                          )
                        : toSubscription,
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

/// The food's illustration: its emoji on the phase's tint with the app's
/// organic shape. Swapping in real art later means changing only this widget.
class FoodHero extends StatelessWidget {
  const FoodHero({super.key, required this.food, required this.palette});

  final Food food;
  final PhasePalette palette;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(MoonRadius.recipeFeature),
      child: Container(
        height: 190,
        width: double.infinity,
        color: palette.tint,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              right: -30,
              bottom: -50,
              child: OrganicShape(
                variant: 1,
                color: palette.accent,
                width: 190,
                height: 180,
                opacity: 0.22,
              ),
            ),
            Positioned(
              left: -40,
              top: -50,
              child: OrganicShape(
                variant: 2,
                color: palette.accent,
                width: 150,
                height: 140,
                opacity: 0.14,
              ),
            ),
            Text(
              foodEmoji(food),
              style: const TextStyle(fontSize: 88, height: 1),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The food's cautions, exactly as written in the content, in the app's info
/// note.
class _GoodToKnow extends StatelessWidget {
  const _GoodToKnow({required this.cautions});

  final List<String> cautions;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return InfoNote(
      key: const ValueKey('food-cautions'),
      icon: MoonIconName.help,
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Good to know',
            style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
          ),
          for (final caution in cautions)
            TextSpan(text: cautions.length > 1 ? '\n• $caution' : '\n$caution'),
        ],
      ),
    );
  }
}
