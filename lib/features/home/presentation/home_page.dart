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
import '../../eat/application/eat_segment.dart';
import '../../entitlements/application/entitlement_providers.dart';
import '../../entitlements/domain/entitlements.dart';
import '../../foods/application/browse_scope.dart';
import '../../plants/application/plant_providers.dart';
import '../../recipes/application/recipe_filter.dart';
import '../../recipes/application/recipes_scope.dart';
import 'widgets/home_editorial.dart';
import 'widgets/home_hero.dart';
import 'widgets/home_sections.dart';

/// The Home tab (`06-home`): the shared viewing phase, moved by dragging the
/// moon. It starts on the user's real phase.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// From 3 days late, Home asks whether the period has started (spec §7.2).
  static const latePromptAfterDays = 3;

  /// The space between the sections below Your focus.
  static const _sectionGap = 40.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final state = ref.watch(cycleStateProvider).value;
    if (state == null) return Scaffold(backgroundColor: c.bg);

    // Every phase-dependent block follows the shared viewing phase.
    final phase = ref.watch(viewingPhaseProvider);
    final catalogue = ref.watch(catalogueProvider);
    final gate = ref.watch(featureGateProvider);
    final canBuildMeal = gate.canUse(Feature.buildMeal);
    void toSubscription() =>
        context.go(Routes.settings(SettingsPage.subscription));
    final late = state.isLate && state.daysLate >= latePromptAfterDays;
    final gap = late ? 44.0 : MoonSpace.sectionGap;
    final realPhase = ref.watch(actualPhaseProvider);
    final plants = ref.watch(threePlantsProvider);
    void openRecipes() {
      ref.read(recipesScopeProvider.notifier).set(BrowseScope.phase);
      ref.read(recipeFilterProvider.notifier).reset();
      goEat(ref, context, EatSegment.recipes);
    }

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
              onMore: () => context.push(Routes.learnMore),
            ),
          ),
          SizedBox(height: gap),
          const SizedBox(height: _sectionGap),
          padded(
            PlantsSection(
              plants: plants,
              phaseName: catalogue.phase(realPhase).name.toLowerCase(),
              onFood: (food) =>
                  context.push(Routes.food(food.id, phase: realPhase)),
              // Today's plants page: pick some and it finds recipes with them.
              onFindRecipes: () => context.push(Routes.threePlants),
            ),
          ),
          const SizedBox(height: _sectionGap),
          padded(
            BuildMealCard(
              phase: phase,
              onCreate: canBuildMeal
                  ? () => context.push(Routes.mealBuilder())
                  : toSubscription,
              onExploreFoods: () {
                ref.read(foodsScopeProvider.notifier).set(BrowseScope.phase);
                goEat(ref, context, EatSegment.foods);
              },
              onExploreRecipes: openRecipes,
            ),
          ),
          const SizedBox(height: 30),
          padded(
            GoToSection(
              onShopping: () => context.go(Routes.shopping),
              onDiary: () => context.push(Routes.diary),
            ),
          ),
        ],
      ),
    );
  }
}
