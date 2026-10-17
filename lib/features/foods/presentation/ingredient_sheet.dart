import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_chip.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/domain/phase.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../cycle/application/viewing_phase.dart';
import '../../recipes/application/recipe_filter.dart';
import '../../recipes/application/recipes_scope.dart';
import '../../shopping/application/shopping_controller.dart';
import '../../shopping/application/shopping_summary.dart';
import '../application/food_providers.dart';

/// The ingredient sheet (`11-ingredient-sheet`, `12-…-on-list`), over the
/// screen it was opened from: [phase] is the real phase from Home, the
/// viewing phase from Foods (PRD §8).
///
/// Without [phaseContext] (Foods › All foods) the sheet shows general
/// information about the food instead of a phase-specific "why"; [category]
/// names the category it was listed under.
Future<void> showIngredientSheet(
  BuildContext context, {
  required Food food,
  required Phase phase,
  bool phaseContext = true,
  String? category,
}) => showMoonSheet<void>(
  context,
  builder: (_) => IngredientSheet(
    food: food,
    phase: phase,
    phaseContext: phaseContext,
    category: category,
  ),
);

/// Opens [food]'s sheet for [phase] from a suggestion (Home, the meal
/// builder): a food featured in [phase] shows its phase "Why this food?";
/// any other food opens without phase context, so no rationale is invented.
Future<void> showFoodSuggestionSheet(
  BuildContext context,
  WidgetRef ref, {
  required Food food,
  required Phase phase,
}) => showIngredientSheet(
  context,
  food: food,
  phase: phase,
  phaseContext: food.why[phase] != null,
  category: ref.read(catalogueProvider).categoryFor(food).name,
);

class IngredientSheet extends ConsumerWidget {
  const IngredientSheet({
    super.key,
    required this.food,
    required this.phase,
    this.phaseContext = true,
    this.category,
  });

  final Food food;
  final Phase phase;

  /// Opened for a phase (Home, Foods › This phase): show "Why this food?".
  final bool phaseContext;

  /// The category it was listed under, when known.
  final String? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final catalogue = ref.watch(catalogueProvider);
    final palette = c.phase(phase);
    // Without phase context ("All foods") recipes are counted across every
    // phase, not just the one being viewed.
    final counts = phaseContext
        ? ref.watch(recipeCountsProvider(phase))
        : ref.watch(allRecipeCountsProvider);
    final count = counts[food.id] ?? 0;
    final onList = ref
        .watch(shoppingSummaryProvider)
        .onListFoodIds
        .contains(food.id);
    final category =
        this.category ?? catalogue.categoryOf(food.id, phase)?.name;
    final qualifier = food.qualifier;
    // Phases whose lists include the food, for the general information.
    final highlightedIn = [
      for (final p in Phase.values)
        if (food.why[p] != null) p.name,
    ];
    final name = food.displayName.toLowerCase();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (category != null) ...[
            Overline(category),
            const SizedBox(height: 10),
          ],
          Semantics(
            header: true,
            child: Text(
              food.displayName,
              style: fraunces(42, height: 1, color: c.text),
            ),
          ),
          if (qualifier != null) ...[
            const SizedBox(height: 8),
            Text(qualifier, style: dmSans(14, height: 1.4, color: c.textMuted)),
          ],
          const SizedBox(height: 16),
          // Only a food recommended for this phase has a phase rationale.
          if (!phaseContext)
            ..._general(context, highlightedIn)
          else if (food.why[phase] case final why?) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: MoonPill(
                catalogue.sheetLabel.replaceAll('{phase}', phase.name),
                background: palette.tint,
              ),
            ),
            const SizedBox(height: 18),
            const Overline('Why this food?'),
            const SizedBox(height: 6),
            Text(why.short, style: MoonType.body.copyWith(color: c.text)),
          ],
          if (count == 0) ...[
            const SizedBox(height: 16),
            Text(
              'No recipes with $name yet.',
              style: dmSans(14, height: 1.4, color: c.textMuted),
            ),
          ],
          if (food.cautions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _GoodToKnow(cautions: food.cautions),
          ],
          const SizedBox(height: 24),
          if (count > 0) ...[
            MoonButton(
              'See $count ${count == 1 ? 'recipe' : 'recipes'} with $name',
              trailingIcon: MoonIconName.arrow,
              onPressed: () {
                final router = GoRouter.of(context);
                if (phaseContext) {
                  ref.read(viewingPhaseProvider.notifier).choose(phase);
                } else {
                  ref.read(recipesScopeProvider.notifier).showAll();
                }
                ref
                    .read(recipeFilterProvider.notifier)
                    .showRecipesWith(food.id);
                Navigator.pop(context);
                router.go(AppTab.recipes.path);
              },
            ),
            const SizedBox(height: 12),
          ],
          if (onList)
            MoonDoneButton('On your list', checkColor: palette.text)
          else
            MoonButton(
              'Add to shopping list',
              variant: MoonButtonVariant.secondary,
              onPressed: () => ref
                  .read(shoppingControllerProvider.notifier)
                  .addFood(food, phase),
            ),
        ],
      ),
    );
  }
}

extension on IngredientSheet {
  /// General information for a food opened without phase context: which
  /// phase features it, from the approved lists. Nothing phase-specific.
  List<Widget> _general(BuildContext context, List<String> phases) {
    if (phases.isEmpty) return const [];
    final c = context.moon;
    final list = switch (phases.length) {
      1 => phases.single,
      _ =>
        '${phases.sublist(0, phases.length - 1).join(', ')} '
            'and ${phases.last}',
    };
    return [
      const Overline('About this food'),
      const SizedBox(height: 6),
      Text(
        'Featured in the $list '
        '${phases.length == 1 ? 'phase' : 'phases'}.',
        style: MoonType.body.copyWith(color: c.text),
      ),
    ];
  }
}

/// The food's cautions, exactly as written in the content, in the app's info
/// note. One note; each caution on its own line, with a bullet only when there
/// is more than one so a wrapped line can't be mistaken for a second caution.
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
