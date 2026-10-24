import 'package:flutter/material.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_colors.dart';
import '../../../../core/design/tokens/moon_layout.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/moon_icon.dart';
import '../../../../core/design/widgets/pressable.dart';
import '../../../../core/design/widgets/recipe_photo.dart';
import '../../../../core/design/widgets/tap_target.dart';
import '../../../content/domain/recipe.dart';
import 'recipe_image.dart';

/// All · Breakfast · Meals · Snacks, as text tabs over a hairline.
class MealTabs extends StatelessWidget {
  const MealTabs({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.available,
  });

  /// Null is "All".
  final MealType? selected;
  final ValueChanged<MealType?> onChanged;

  /// Only meal types with recipes in the scope get a tab.
  final List<MealType> available;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    Widget tab(String label, MealType? type) {
      final active = type == selected;
      return Pressable(
        onTap: () => onChanged(type),
        selected: active,
        semanticLabel: label,
        child: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 20),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            border: active
                ? Border(bottom: BorderSide(color: c.ochre, width: 2.5))
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: dmSans(
              16,
              weight: active ? FontWeight.w600 : FontWeight.w500,
              height: 1,
              color: active ? c.text : c.textMuted,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            tab('All', null),
            for (final type in available) tab(type.label, type),
          ],
        ),
      ),
    );
  }
}

/// "Cook with… choose an ingredient" (no ingredient chosen).
class CookWithField extends StatelessWidget {
  const CookWithField({super.key, required this.palette, required this.onTap});

  final PhasePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Cook with, choose an ingredient',
      child: Container(
        height: 50,
        padding: const EdgeInsets.only(left: 8, right: 16),
        decoration: ShapeDecoration(
          color: c.raised,
          shape: StadiumBorder(side: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: palette.tint,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: MoonIcon(
                MoonIconName.search,
                size: 16,
                color: palette.text,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Cook with…',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: c.text,
                      ),
                    ),
                    const TextSpan(text: '  choose an ingredient'),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: dmSans(15, height: 1, color: c.textMuted),
              ),
            ),
            MoonIcon(
              MoonIconName.chev,
              size: 16,
              color: c.removeIcon,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// The first recipe: a large photo with a time badge, the title and its key
/// ingredients.
class FeatureRecipeCard extends StatelessWidget {
  const FeatureRecipeCard({
    super.key,
    required this.recipe,
    required this.keyIngredients,
    required this.palette,
    required this.onTap,
  });

  final Recipe recipe;

  /// "Green lentil, broccoli, zucchini".
  final String keyIngredients;
  final PhasePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final meta = '${recipe.mealType.label} · $keyIngredients';
    return Pressable(
      onTap: onTap,
      semanticLabel: '${recipe.title}, ${recipe.minutes} minutes, $meta',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              RecipePhoto(
                height: 250,
                radius: MoonRadius.recipeFeature,
                palette: palette,
                image: recipeImage(recipe),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: ShapeDecoration(
                    color: c.bg,
                    shape: const StadiumBorder(),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MoonIcon(
                        MoonIconName.clock,
                        size: 13,
                        color: c.text,
                        strokeWidth: 2,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${recipe.minutes} min',
                        style: dmSans(
                          12,
                          weight: FontWeight.w600,
                          height: 1,
                          color: c.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(recipe.title, style: fraunces(26, height: 1.15, color: c.text)),
          const SizedBox(height: 8),
          Text(
            meta,
            style: dmSans(
              13,
              weight: FontWeight.w500,
              height: 1.3,
              color: c.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// A recipe in the two-across grid.
class GridRecipeCard extends StatelessWidget {
  const GridRecipeCard({
    super.key,
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
    final meta = recipe.minutes > 0
        ? '${recipe.mealType.label} · ${recipe.minutes} min'
        : recipe.mealType.label;
    return Pressable(
      onTap: onTap,
      semanticLabel: '${recipe.title}, $meta',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecipePhoto(
            height: 170,
            radius: MoonRadius.gridCard,
            palette: palette,
            image: recipeImage(recipe),
          ),
          const SizedBox(height: 10),
          Text(
            recipe.title,
            style: fraunces(
              18,
              weight: FontWeight.w500,
              height: 1.2,
              color: c.text,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            meta,
            style: dmSans(
              12,
              weight: FontWeight.w500,
              height: 1,
              color: c.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// All · Breakfast · Meals · Snacks as wrapping pills; the chosen one is plum.
/// A 34-tall pill with a 44 touch target.
class MealChips extends StatelessWidget {
  const MealChips({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.available,
  });

  /// Null is "All".
  final MealType? selected;
  final ValueChanged<MealType?> onChanged;

  /// Only meal types with recipes in the scope get a pill.
  final List<MealType> available;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final slop = tapTargetSlop(height: 34);
    Widget chip(String label, MealType? type) {
      final active = type == selected;
      return ExpandedTapTarget(
        extra: slop,
        child: Pressable(
          onTap: () => onChanged(type),
          selected: active,
          semanticLabel: label,
          child: Padding(
            padding: slop,
            child: Container(
              constraints: const BoxConstraints(minHeight: 34),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: ShapeDecoration(
                color: active ? c.inverseBg : c.sand,
                shape: const StadiumBorder(),
              ),
              child: Text(
                label,
                style: dmSans(
                  13.5,
                  weight: active ? FontWeight.w700 : FontWeight.w500,
                  height: 1.2,
                  color: active ? c.inverseText : c.text,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        chip('All', null),
        for (final type in available) chip(type.label, type),
      ],
    );
  }
}

/// A recipe as a rounded row: thumbnail, title, meta and key ingredients, and
/// (when [onHeart] is given) a heart that saves it to My recipes.
class RecipeListCard extends StatelessWidget {
  const RecipeListCard({
    super.key,
    required this.recipe,
    required this.palette,
    required this.onTap,
    this.subtitle,
    this.onHeart,
    this.hearted = false,
  });

  final Recipe recipe;
  final PhasePalette palette;
  final VoidCallback onTap;

  /// A line under the meta, e.g. the key ingredients.
  final String? subtitle;

  /// Saves or removes the recipe; null hides the heart.
  final VoidCallback? onHeart;
  final bool hearted;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final meta = recipe.minutes > 0
        ? '${recipe.mealType.label} · ${recipe.minutes} min'
        : recipe.mealType.label;
    // At large text sizes the picture goes on top, so the title keeps the
    // card's whole width and words stay whole.
    final stacked = MediaQuery.textScalerOf(context).scale(16) > 22;

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recipe.title,
          style: fraunces(
            18,
            weight: FontWeight.w500,
            height: 1.2,
            color: c.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          meta,
          style: dmSans(
            12.5,
            weight: FontWeight.w500,
            height: 1.3,
            color: c.textMuted,
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty)
          Text(subtitle!, style: dmSans(12.5, height: 1.3, color: c.textMuted)),
      ],
    );
    final photo = ExcludeSemantics(
      child: stacked
          ? RecipePhoto(
              height: 120,
              radius: 16,
              palette: palette,
              image: recipeImage(recipe),
            )
          : SizedBox(
              width: 84,
              child: RecipePhoto(
                height: 84,
                radius: 16,
                palette: palette,
                image: recipeImage(recipe),
              ),
            ),
    );
    final heart = onHeart == null
        ? null
        : Pressable(
            onTap: onHeart,
            checked: hearted,
            semanticLabel: hearted
                ? 'Remove ${recipe.title} from My recipes'
                : 'Save ${recipe.title} to My recipes',
            child: SizedBox(
              width: 52,
              height: 52,
              child: Center(
                child: MoonIcon(
                  MoonIconName.heart,
                  size: 22,
                  color: hearted ? palette.text : c.textMuted,
                  strokeWidth: hearted ? 2.6 : 1.8,
                ),
              ),
            ),
          );
    return Container(
      decoration: BoxDecoration(
        color: c.raised,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Pressable(
                  onTap: onTap,
                  semanticLabel: '${recipe.title}, $meta',
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                    child: photo,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Pressable(
                        onTap: onTap,
                        semanticLabel: '${recipe.title}, $meta',
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 4, 14),
                          child: text,
                        ),
                      ),
                    ),
                    ?heart,
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Pressable(
                    onTap: onTap,
                    semanticLabel: '${recipe.title}, $meta',
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          photo,
                          const SizedBox(width: 14),
                          Expanded(child: text),
                        ],
                      ),
                    ),
                  ),
                ),
                ?heart,
              ],
            ),
    );
  }
}
