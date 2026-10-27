import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/shell/tab_scroll.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/hub_card.dart';
import '../../../core/design/widgets/hub_hero.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../cycle/application/viewing_phase.dart';
import '../../cycle/presentation/phase_overline.dart';
import '../../foods/application/browse_scope.dart';
import '../../recipes/application/recipe_filter.dart';

/// Eat: the hub. A photograph and a short introduction, then the three ways
/// in: Foods, Recipes and Build a Meal. Each opens an existing page.
class EatPage extends ConsumerWidget {
  const EatPage({super.key});

  /// The hero photograph. A recipe photo already in the app, standing in
  /// until the approved photograph is added (see docs/v2-ui-roadmap.md).
  static const heroAsset =
      'assets/images/recipes/red-cabbage-apricot-chickpea-salad.jpg';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    // The icons wear the colours of the phase being viewed.
    final phase = ref.watch(viewingPhaseProvider);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        // Five blocks, all built: no need for a lazy list.
        child: SingleChildScrollView(
          controller: ref.watch(tabScrollProvider).of(AppTab.eat),
          padding: const EdgeInsets.fromLTRB(
            MoonSpace.gutter,
            10,
            MoonSpace.gutter,
            42,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                // The search button lines up with the title.
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const PhaseOverline(),
                        Semantics(
                          header: true,
                          child: Text(
                            'Eat',
                            style: MoonType.h1.copyWith(color: c.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Pressable(
                    key: const ValueKey('eat-search'),
                    // The foods search lives on "All foods".
                    onTap: () {
                      ref.read(foodsScopeProvider.notifier).showAll();
                      context.push(Routes.eatFoods);
                    },
                    semanticLabel: 'Search foods',
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: MoonIcon(
                          MoonIconName.search,
                          size: 22,
                          color: c.text,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const HubHero(
                asset: heroAsset,
                heading: 'Nourish your cycle',
                body:
                    'Seasonal foods, simple recipes and meal ideas to support '
                    'your current phase.',
              ),
              const SizedBox(height: 16),
              HubCard(
                icon: MoonIconName.apple,
                phase: phase,
                title: 'Foods',
                body: 'Browse foods by phase and benefit.',
                onTap: () => context.push(Routes.eatFoods),
              ),
              const SizedBox(height: 12),
              HubCard(
                icon: MoonIconName.utensils,
                phase: phase,
                title: 'Recipes',
                body: 'Find nourishing recipes for every phase.',
                onTap: () {
                  // Entering from Eat is plain browsing, not an earlier search.
                  ref.read(recipeFilterProvider.notifier).reset();
                  context.push(Routes.eatRecipes);
                },
              ),
              const SizedBox(height: 12),
              HubCard(
                icon: MoonIconName.recipes,
                phase: phase,
                title: 'Build a Meal',
                body: 'Create a balanced meal with foods or recipes.',
                onTap: () => context.push(Routes.mealBuilder()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
