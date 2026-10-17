import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/shell/tab_scroll.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/domain/browse_scope.dart';
import '../../content/application/content_providers.dart';
import '../../cycle/application/cycle_providers.dart';
import '../../cycle/application/viewing_phase.dart';
import '../../cycle/presentation/log_period_sheet.dart';
import '../../foods/application/browse_scope.dart';
import '../../foods/presentation/ingredient_sheet.dart';
import '../../recipes/application/recipe_filter.dart';
import '../../recipes/application/recipes_scope.dart';
import '../application/home_discovery.dart';
import 'home_sheets.dart';
import 'widgets/home_hero.dart';
import 'widgets/home_sections.dart';

/// The Home tab (`06-home`): the shared viewing phase, moved by dragging the
/// moon. It starts on the user's real phase.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// From 3 days late, Home asks whether the period has started (spec §7.2).
  static const latePromptAfterDays = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final state = ref.watch(cycleStateProvider).value;
    if (state == null) return Scaffold(backgroundColor: c.bg);

    // Every phase-dependent block follows the shared viewing phase.
    final phase = ref.watch(viewingPhaseProvider);
    // Today's food belongs to today: the real phase, never the one being
    // previewed.
    final actual = ref.watch(actualPhaseProvider);
    final todays = ref.watch(todaysFoodProvider(actual));
    final late = state.isLate && state.daysLate >= latePromptAfterDays;
    final gap = late ? 44.0 : MoonSpace.sectionGap;

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
          SizedBox(height: late ? 8 : 44),
          if (late) ...[
            padded(LatePeriodCard(onLog: () => showLogPeriodSheet(context))),
            SizedBox(height: gap),
          ],
          padded(
            FocusSection(
              phase: phase,
              onMore: () {
                ref.read(foodsScopeProvider.notifier).set(BrowseScope.phase);
                context.go(AppTab.foods.path);
              },
            ),
          ),
          if (todays != null) ...[
            SizedBox(height: gap),
            padded(
              TodaysFoodSection(
                food: todays,
                phase: actual,
                onWhy: () => showIngredientSheet(
                  context,
                  food: todays,
                  phase: actual,
                  category: ref
                      .read(catalogueProvider)
                      .categoryFor(todays)
                      .name,
                ),
                onRecipes: () {
                  // Its recipes are the real phase's. Switching phase clears
                  // the ingredient filter, so do it first.
                  ref.read(viewingPhaseProvider.notifier).showActual();
                  ref
                      .read(recipesScopeProvider.notifier)
                      .set(BrowseScope.phase);
                  ref
                      .read(recipeFilterProvider.notifier)
                      .showRecipesWith(todays.id);
                  context.go(AppTab.recipes.path);
                },
              ),
            ),
          ],
          SizedBox(height: gap),
          padded(
            HomeActions(
              onBuildMeal: () => showBuildMealSheet(context, phase: phase),
              onTryNew: () => showTryNewSheet(context, phase: phase),
            ),
          ),
        ],
      ),
    );
  }
}
