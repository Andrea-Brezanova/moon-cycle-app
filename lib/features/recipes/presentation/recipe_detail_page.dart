import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_colors.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_chip.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/design/widgets/recipe_photo.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/recipe.dart';
import '../../cycle/presentation/cycle_orbit.dart';
import '../../shopping/application/shopping_controller.dart';
import '../../shopping/application/shopping_summary.dart';
import '../../shopping/domain/item_key.dart';

/// Recipe detail (`19-recipe-detail`, `20-recipe-detail-added`), inside the
/// Recipes stack, so back returns to the same list, filters and scroll.
class RecipeDetailPage extends ConsumerWidget {
  const RecipeDetailPage({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final catalogue = ref.watch(catalogueProvider);
    final recipe = catalogue.recipe(recipeId);
    if (recipe == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Center(
          child: TextLink(
            'This recipe isn’t available',
            onTap: () => context.pop(),
          ),
        ),
      );
    }
    final palette = c.phase(recipe.phase);
    final onListKeys = ref.watch(shoppingSummaryProvider).onListKeys;
    final skipped = ref
        .watch(foodFilterProvider)
        .avoidedLines(recipe, catalogue);
    bool onList(RecipeIngredient l) =>
        onListKeys.contains(lineKey(l, catalogue));
    final toAdd = [
      for (final l in recipe.ingredients)
        if (!skipped.contains(l)) l,
    ];
    final alreadyOn = [
      for (final l in toAdd)
        if (onList(l)) l,
    ];
    final allAdded = toAdd.isNotEmpty && alreadyOn.length == toAdd.length;

    return Scaffold(
      backgroundColor: c.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              RecipePhoto(height: 330, radius: 0, palette: palette),
              Positioned(
                top: MediaQuery.viewPaddingOf(context).top + 7,
                left: 20,
                child: _BackButton(onTap: () => context.pop()),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 300),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.bg,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(MoonRadius.recipeFeature),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    MoonSpace.gutter,
                    26,
                    MoonSpace.gutter,
                    42,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Intro(recipe: recipe, palette: palette),
                      const SizedBox(height: 30),
                      _Ingredients(
                        recipe: recipe,
                        palette: palette,
                        onList: onList,
                        skipped: skipped,
                      ),
                      const SizedBox(height: 20),
                      if (allAdded) ...[
                        MoonDoneButton(
                          'Added to shopping list',
                          checkColor: palette.text,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            runSpacing: 6,
                            children: [
                              Text(
                                'All ${toAdd.length} ingredients are on your list.',
                                style: dmSans(
                                  13,
                                  height: 1.45,
                                  color: c.textMuted,
                                ),
                              ),
                              TextLink(
                                'Open shopping list',
                                size: 13,
                                onTap: () => context.go(AppTab.shop.path),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        MoonButton(
                          'Add ingredients to shopping list',
                          onPressed: () => ref
                              .read(shoppingControllerProvider.notifier)
                              .addRecipe(recipe),
                        ),
                        if (mergeNote(alreadyOn) case final note?) ...[
                          const SizedBox(height: 12),
                          Text(
                            note,
                            textAlign: TextAlign.center,
                            style: dmSans(13, height: 1.45, color: c.textMuted),
                          ),
                        ],
                      ],
                      if (skipNote(skipped) case final note?) ...[
                        const SizedBox(height: 12),
                        Text(
                          note,
                          textAlign: TextAlign.center,
                          style: dmSans(13, height: 1.45, color: c.textMuted),
                        ),
                      ],
                      const SizedBox(height: 30),
                      _Method(recipe: recipe, palette: palette),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Broccoli, lemon and sauerkraut are already on your list. We’ll merge
/// them, not add them twice."
String? mergeNote(List<RecipeIngredient> alreadyOn) {
  if (alreadyOn.isEmpty) return null;
  final one = alreadyOn.length == 1;
  return '${_list(alreadyOn)} ${one ? 'is' : 'are'} already on your list. '
      'We’ll merge ${one ? 'it' : 'them'}, not add ${one ? 'it' : 'them'} twice.';
}

/// Lines left out because the user avoids them (PRD §9).
String? skipNote(List<RecipeIngredient> skipped) {
  if (skipped.isEmpty) return null;
  return 'We’ll leave out ${_list(skipped, capitalise: false)}: '
      '${skipped.length == 1 ? 'it’s' : 'they’re'} on your avoid list.';
}

String _list(List<RecipeIngredient> lines, {bool capitalise = true}) {
  final names = [
    for (final (i, l) in lines.indexed)
      i == 0 && capitalise ? l.label : l.label.toLowerCase(),
  ];
  return names.length == 1
      ? names.single
      : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Back to recipes',
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: c.raised,
          shape: BoxShape.circle,
          // The one shadow in the design: the button floats on the photo.
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E1B152E),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: MoonIcon(
          MoonIconName.back,
          size: 20,
          color: c.text,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.recipe, required this.palette});

  final Recipe recipe;
  final PhasePalette palette;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            MoonPill(
              phaseName(recipe.phase),
              background: palette.tint,
              dot: palette.accent,
            ),
            MoonPill(recipe.mealType.label, background: c.sand),
          ],
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            recipe.title,
            style: fraunces(30, height: 1.12, color: c.text),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            MoonIcon(
              MoonIconName.clock,
              size: 16,
              color: c.textMuted,
              strokeWidth: 1.8,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${recipe.minutes} min · Serves ${recipe.serves}',
                style: dmSans(
                  14,
                  weight: FontWeight.w500,
                  height: 1,
                  color: c.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(recipe.intro, style: MoonType.body.copyWith(color: c.text)),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text(
            'Why this recipe?',
            style: dmSans(
              14,
              weight: FontWeight.w600,
              height: 1.2,
              color: c.text,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          recipe.whyThisPhase,
          key: const ValueKey('recipe-why-this-phase'),
          style: dmSans(14, height: 1.45, color: c.textMuted),
        ),
      ],
    );
  }
}

class _Ingredients extends StatelessWidget {
  const _Ingredients({
    required this.recipe,
    required this.palette,
    required this.onList,
    required this.skipped,
  });

  final Recipe recipe;
  final PhasePalette palette;
  final bool Function(RecipeIngredient) onList;
  final List<RecipeIngredient> skipped;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final n = recipe.ingredients.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Ingredients',
                  style: fraunces(24, weight: FontWeight.w500, color: c.text),
                ),
              ),
            ),
            Text(
              '$n ${n == 1 ? 'item' : 'items'}',
              style: dmSans(
                13,
                weight: FontWeight.w500,
                height: 1,
                color: c.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final (i, line) in recipe.ingredients.indexed)
          _IngredientRow(
            line: line,
            onList: onList(line),
            avoided: skipped.contains(line),
            palette: palette,
            divider: i > 0,
          ),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.line,
    required this.onList,
    required this.avoided,
    required this.palette,
    required this.divider,
  });

  final RecipeIngredient line;
  final bool onList;
  final bool avoided;
  final PhasePalette palette;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final quantity = line.quantityLabel;
    return MergeSemantics(
      child: Container(
        // 54 plus the divider, as on the canvas.
        constraints: BoxConstraints(minHeight: divider ? 55 : 54),
        decoration: BoxDecoration(
          border: divider ? Border(top: BorderSide(color: c.line)) : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.label,
                    style: dmSans(
                      16,
                      weight: FontWeight.w500,
                      height: 1.25,
                      color: c.text,
                    ),
                  ),
                  if (onList || avoided) ...[
                    const SizedBox(height: 2),
                    Text(
                      avoided ? 'You avoid this' : 'On your list',
                      style: dmSans(
                        12,
                        weight: FontWeight.w500,
                        height: 1,
                        color: avoided ? c.textMuted : palette.text,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (quantity.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 124),
                child: Text(
                  quantity,
                  textAlign: TextAlign.end,
                  style: dmSans(14, height: 1.25, color: c.textMuted),
                ),
              ),
            const SizedBox(width: 12),
            if (onList)
              OnListMark(palette: palette)
            else
              const SizedBox(width: 22),
          ],
        ),
      ),
    );
  }
}

class _Method extends StatelessWidget {
  const _Method({required this.recipe, required this.palette});

  final Recipe recipe;
  final PhasePalette palette;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Method',
            style: fraunces(24, weight: FontWeight.w500, color: c.text),
          ),
        ),
        for (final (i, step) in recipe.steps.indexed) ...[
          SizedBox(height: i == 0 ? 16 : 18),
          MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: palette.tint,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: dmSans(
                      14,
                      weight: FontWeight.w600,
                      height: 1,
                      color: palette.text,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      step,
                      style: MoonType.body.copyWith(color: c.text),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
