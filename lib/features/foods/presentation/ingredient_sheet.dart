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
import '../../shopping/application/shopping_controller.dart';
import '../../shopping/application/shopping_summary.dart';
import '../application/food_providers.dart';

/// The ingredient sheet (`11-ingredient-sheet`, `12-…-on-list`), over the
/// screen it was opened from: [phase] is the real phase from Home, the
/// viewing phase from Foods (PRD §8).
Future<void> showIngredientSheet(
  BuildContext context, {
  required Food food,
  required Phase phase,
}) => showMoonSheet<void>(
  context,
  builder: (_) => IngredientSheet(food: food, phase: phase),
);

class IngredientSheet extends ConsumerWidget {
  const IngredientSheet({super.key, required this.food, required this.phase});

  final Food food;
  final Phase phase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final catalogue = ref.watch(catalogueProvider);
    final palette = c.phase(phase);
    final count = ref.watch(recipeCountsProvider(phase))[food.id] ?? 0;
    final onList = ref
        .watch(shoppingSummaryProvider)
        .onListFoodIds
        .contains(food.id);
    final category = catalogue.categoryOf(food.id, phase)?.name;
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
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: MoonPill(
              catalogue.sheetLabel.replaceAll('{phase}', phase.name),
              background: palette.tint,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            food.why[phase]?.short ?? '',
            style: MoonType.body.copyWith(color: c.text),
          ),
          if (count == 0) ...[
            const SizedBox(height: 16),
            Text(
              'No recipes with $name yet.',
              style: dmSans(14, height: 1.4, color: c.textMuted),
            ),
          ],
          const SizedBox(height: 24),
          if (count > 0) ...[
            MoonButton(
              'See $count ${count == 1 ? 'recipe' : 'recipes'} with $name',
              trailingIcon: MoonIconName.arrow,
              onPressed: () {
                final router = GoRouter.of(context);
                ref.read(viewingPhaseProvider.notifier).choose(phase);
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
