import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/shell/tab_scroll.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../content/application/content_providers.dart';
import '../../cycle/application/cycle_providers.dart';
import '../../cycle/application/viewing_phase.dart';
import '../../cycle/presentation/log_period_sheet.dart';
import '../../foods/presentation/ingredient_sheet.dart';
import '../../recipes/application/recipe_filter.dart';
import '../../shopping/application/shopping_summary.dart';
import '../application/home_providers.dart';
import 'widgets/home_hero.dart';
import 'widgets/home_sections.dart';

/// The Home tab (`06-home`): the user's real phase only, no phase selector.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// From 3 days late, Home asks whether the period has started (spec §7.2).
  static const latePromptAfterDays = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final state = ref.watch(cycleStateProvider).value;
    if (state == null) return Scaffold(backgroundColor: c.bg);

    final phase = state.phase;
    final palette = c.phase(phase);
    final content = ref.watch(catalogueProvider).phase(phase);
    final previewing = ref.watch(homePreviewProvider) != null;
    final shopping = ref.watch(shoppingSummaryProvider);
    final late = state.isLate && state.daysLate >= latePromptAfterDays;
    final gap = late ? 44.0 : MoonSpace.sectionGap;
    final viewing = ref.read(viewingPhaseProvider.notifier);

    Widget padded(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: MoonSpace.gutter),
      child: child,
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: ListView(
        controller: ref.watch(tabScrollProvider).of(AppTab.home),
        padding: const EdgeInsets.only(bottom: 42),
        children: [
          HomeHero(state: state),
          // The late card and the preview's pill sit closer to the content.
          SizedBox(height: late || previewing ? 8 : 44),
          if (late) ...[
            padded(LatePeriodCard(onLog: () => showLogPeriodSheet(context))),
            SizedBox(height: gap),
          ],
          padded(FocusSection(content: content, previewing: previewing)),
          SizedBox(height: gap),
          padded(
            FoodsTodaySection(
              foods: ref.watch(foodsForTodayProvider(phase)),
              onList: shopping.onListFoodIds,
              palette: palette,
              onFood: (food) =>
                  showIngredientSheet(context, food: food, phase: phase),
              onAllFoods: () {
                viewing.showActual();
                context.go(AppTab.foods.path);
              },
            ),
          ),
          SizedBox(height: gap),
          RecipesTodaySection(
            recipes: ref.watch(recipesForTodayProvider(phase)),
            palette: palette,
            onRecipe: (recipe) {
              viewing.showActual();
              context.go(Routes.recipe(recipe.id));
            },
            onAllRecipes: () {
              viewing.showActual();
              ref.read(recipeFilterProvider.notifier).reset();
              context.go(AppTab.recipes.path);
            },
            onReviewPreferences: () =>
                context.go(Routes.settings(SettingsPage.foodPreferences)),
          ),
          SizedBox(height: gap),
          padded(
            ShoppingBlock(
              toBuy: shopping.toBuy,
              fromRecipes: shopping.fromRecipes,
              onTap: () => context.go(AppTab.shop.path),
            ),
          ),
        ],
      ),
    );
  }
}
