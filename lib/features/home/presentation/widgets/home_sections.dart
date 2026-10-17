import 'package:flutter/material.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_colors.dart';
import '../../../../core/design/tokens/moon_layout.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/editorial_text.dart';
import '../../../../core/design/widgets/moon_button.dart';
import '../../../../core/design/widgets/moon_chip.dart';
import '../../../../core/design/widgets/moon_icon.dart';
import '../../../../core/design/widgets/pressable.dart';
import '../../../../core/design/widgets/recipe_photo.dart';
import '../../../../core/design/widgets/text_link.dart';
import '../../../../core/domain/phase.dart';
import '../../../content/domain/food.dart';
import '../../../content/domain/phase_content.dart';
import '../../../content/domain/recipe.dart';
import '../../../cycle/domain/phase_guidance.dart';

/// "Your focus": the phase tagline (last word in italic) and three general
/// principles. No individual foods; those are in "Foods for this phase".
class FocusSection extends StatelessWidget {
  const FocusSection({super.key, required this.content, required this.phase});

  final PhaseContent content;
  final Phase phase;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final accent = c.phase(phase).accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Overline('Your focus'),
        const SizedBox(height: 10),
        EditorialHeading(
          italicLastWord(content.tagline),
          style: fraunces(30, height: 1.12),
        ),
        const SizedBox(height: 14),
        for (final principle in phaseFocusPrinciples(phase))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    principle,
                    style: MoonType.body.copyWith(color: c.text),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// "Foods for this phase" with up to six chips.
class FoodsForPhaseSection extends StatelessWidget {
  const FoodsForPhaseSection({
    super.key,
    required this.foods,
    required this.onList,
    required this.palette,
    required this.onFood,
    required this.onAllFoods,
  });

  final List<Food> foods;
  final Set<String> onList;
  final PhasePalette palette;
  final ValueChanged<Food> onFood;
  final VoidCallback onAllFoods;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionHead(
        'Foods for this phase',
        linkLabel: 'All foods',
        onLink: onAllFoods,
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: MoonSpace.chipGap,
        runSpacing: MoonSpace.chipGap,
        children: [
          for (final food in foods)
            MoonChip(
              food.displayName,
              palette: palette,
              state: onList.contains(food.id)
                  ? MoonChipState.onList
                  : MoonChipState.normal,
              onTap: () => onFood(food),
            ),
        ],
      ),
    ],
  );
}

/// "Recipes for this phase": a horizontal row of cards, or the no-recipes state.
class RecipesForPhaseSection extends StatelessWidget {
  const RecipesForPhaseSection({
    super.key,
    required this.recipes,
    required this.palette,
    required this.onRecipe,
    required this.onAllRecipes,
    required this.onReviewPreferences,
  });

  final List<Recipe> recipes;
  final PhasePalette palette;
  final ValueChanged<Recipe> onRecipe;
  final VoidCallback onAllRecipes;
  final VoidCallback onReviewPreferences;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    if (recipes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: MoonSpace.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHead('Recipes for this phase'),
            const SizedBox(height: 16),
            Text(
              'No recipes for this phase fit your food preferences.',
              style: dmSans(15, height: 1.5, color: c.textMuted),
            ),
            const SizedBox(height: 16),
            TextLink('Review food preferences', onTap: onReviewPreferences),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MoonSpace.gutter),
          child: SectionHead(
            'Recipes for this phase',
            linkLabel: 'All recipes',
            onLink: onAllRecipes,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: MoonSpace.gutter),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, recipe) in recipes.indexed) ...[
                if (i > 0) const SizedBox(width: 16),
                _RecipeCard(
                  recipe: recipe,
                  palette: palette,
                  onTap: () => onRecipe(recipe),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe,
    required this.palette,
    required this.onTap,
  });

  final Recipe recipe;
  final PhasePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final meta = '${recipe.mealType.label} · ${recipe.minutes} min';
    return Pressable(
      onTap: onTap,
      semanticLabel: '${recipe.title}, $meta',
      child: SizedBox(
        width: 268,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecipePhoto(
              height: 300,
              radius: 26,
              palette: palette,
              image: AssetImage(recipe.imageAsset),
            ),
            const SizedBox(height: 12),
            Text(
              recipe.title,
              style: MoonType.cardTitle.copyWith(color: c.text),
            ),
            const SizedBox(height: 8),
            Text(
              meta,
              style: dmSans(
                13,
                weight: FontWeight.w500,
                height: 1,
                color: c.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The plum "Your shopping list" block; opens Shop.
class ShoppingBlock extends StatelessWidget {
  const ShoppingBlock({
    super.key,
    required this.toBuy,
    required this.fromRecipes,
    required this.onTap,
  });

  final int toBuy;
  final int fromRecipes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final summary = fromRecipes > 0
        ? '$toBuy to buy · $fromRecipes from recipes'
        : '$toBuy to buy';
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Your shopping list, $summary',
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 22, 22, 22),
        decoration: BoxDecoration(
          color: c.shopBlockBg,
          borderRadius: BorderRadius.circular(MoonRadius.shopBlock),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your shopping list',
                    style: fraunces(22, height: 1.08, color: c.shopBlockText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary,
                    style: dmSans(14, height: 1, color: c.shopBlockSub),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: c.ochre, shape: BoxShape.circle),
              child: Center(
                child: MoonIcon(
                  MoonIconName.arrow,
                  size: 20,
                  color: c.onOchre,
                  strokeWidth: 1.9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Has your period started?" (`21-home-period-late`), from 3 days late.
class LatePeriodCard extends StatelessWidget {
  const LatePeriodCard({super.key, required this.onLog});

  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(MoonRadius.lateCard),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Overline('Your period'),
          const SizedBox(height: 10),
          EditorialHeading(
            'Has your period *started?*',
            style: fraunces(26, height: 1.12),
          ),
          const SizedBox(height: 10),
          Text(
            'Log it and your cycle restarts at day 1. Until then, we’ll keep '
            'you in your luteal phase.',
            style: dmSans(15, height: 1.5, color: c.textMuted),
          ),
          const SizedBox(height: 16),
          MoonButton('Log my period', onPressed: onLog, expand: false),
        ],
      ),
    );
  }
}
