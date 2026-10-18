import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/shell/tab_scroll.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/domain/browse_scope.dart';
import '../../content/application/content_providers.dart';
import '../../cycle/application/cycle_providers.dart';
import '../../cycle/application/viewing_phase.dart';
import '../../cycle/presentation/log_period_sheet.dart';
import '../../entitlements/application/entitlement_providers.dart';
import '../../entitlements/domain/entitlements.dart';
import '../../foods/application/browse_scope.dart';
import '../../recipes/application/recipe_filter.dart';
import '../../recipes/application/recipes_scope.dart';
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
    final palette = c.phase(phase);
    final catalogue = ref.watch(catalogueProvider);
    final filter = ref.watch(foodFilterProvider);
    final foodCount = [
      for (final f in catalogue.foodsFor(phase))
        if (filter.allowsFood(f)) f,
    ].length;
    final gate = ref.watch(featureGateProvider);
    final canBuildMeal = gate.canUse(Feature.buildMeal);
    final canLogDiary = gate.canUse(Feature.logDiary);
    void toSubscription() =>
        context.go(Routes.settings(SettingsPage.subscription));
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
              onMore: () => context.push(Routes.learnMore),
            ),
          ),
          SizedBox(height: gap),
          padded(
            HomeChoices(
              cards: [
                ChoiceCard(
                  icon: MoonIconName.foods,
                  title: 'Explore foods',
                  subtitle: '$foodCount foods for this phase',
                  palette: palette,
                  onTap: () {
                    ref
                        .read(foodsScopeProvider.notifier)
                        .set(BrowseScope.phase);
                    context.go(AppTab.foods.path);
                  },
                ),
                ChoiceCard(
                  icon: MoonIconName.book,
                  title: 'Explore recipes',
                  subtitle: 'Recipes for this phase',
                  palette: palette,
                  onTap: () {
                    ref
                        .read(recipesScopeProvider.notifier)
                        .set(BrowseScope.phase);
                    ref.read(recipeFilterProvider.notifier).reset();
                    context.go(AppTab.recipes.path);
                  },
                ),
                ChoiceCard(
                  icon: MoonIconName.recipes,
                  title: 'Build a meal',
                  subtitle: 'Protein → base → 2–3 plants',
                  palette: palette,
                  locked: !canBuildMeal,
                  onTap: canBuildMeal
                      ? () => context.push(Routes.mealBuilder())
                      : toSubscription,
                ),
                ChoiceCard(
                  icon: MoonIconName.compass,
                  title: '3 Plants a Day',
                  subtitle: 'Three plants to discover today',
                  palette: palette,
                  onTap: () => context.push(Routes.threePlants),
                ),
                ChoiceCard(
                  icon: MoonIconName.shop,
                  title: 'Shop',
                  subtitle: 'Your shopping list',
                  palette: palette,
                  onTap: () => context.go(AppTab.shop.path),
                ),
                ChoiceCard(
                  icon: MoonIconName.document,
                  title: 'Log diary',
                  subtitle: 'Your meals, by day',
                  palette: palette,
                  locked: !canLogDiary,
                  onTap: canLogDiary
                      ? () => context.push(Routes.diary)
                      : toSubscription,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
