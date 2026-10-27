import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/shell/tab_scroll.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/hub_card.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/domain/phase.dart';
import '../../content/application/content_providers.dart';
import '../../cycle/application/cycle_providers.dart';
import '../../foods/application/browse_scope.dart';
import '../../recipes/application/recipe_filter.dart';

/// Eat: the hub. A photograph and a short introduction, then the three ways
/// in: Foods, Recipes and the meal builder. Each opens an existing page.
class EatPage extends ConsumerWidget {
  const EatPage({super.key});

  /// The hero photograph. A recipe photo already in the app, standing in
  /// until the approved photograph is added (see docs/v2-ui-roadmap.md).
  static const heroAsset =
      'assets/images/recipes/red-cabbage-apricot-chickpea-salad.jpg';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
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
                        _PhaseOverline(),
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
              const _Intro(),
              const SizedBox(height: 16),
              HubCard(
                icon: MoonIconName.apple,
                phase: Phase.menstrual,
                title: 'Foods',
                body: 'Browse foods by phase and benefit.',
                onTap: () => context.push(Routes.eatFoods),
              ),
              const SizedBox(height: 12),
              HubCard(
                icon: MoonIconName.utensils,
                phase: Phase.ovulatory,
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
                phase: Phase.luteal,
                title: 'Meal builder',
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

/// The photograph with the "Nourish your cycle" card joined beneath it.
class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Container(
      decoration: BoxDecoration(
        color: c.raised,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Decorative: the heading below says what the page is.
          ExcludeSemantics(
            child: AspectRatio(
              aspectRatio: 1.86,
              child: Image.asset(
                EatPage.heroAsset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EditorialHeading(
                  italicLastWord('Nourish your cycle'),
                  style: fraunces(28, height: 1.15, color: c.text),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seasonal foods, simple recipes and meal ideas to support '
                  'your current phase.',
                  style: dmSans(15, height: 1.5, color: c.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A phase dot and "FOLLICULAR · DAY 7" (the real phase and cycle day), 8 pt
/// above the title.
class _PhaseOverline extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final state = ref.watch(cycleStateProvider).value;
    if (state == null) return const SizedBox.shrink();
    final name = ref.watch(catalogueProvider).phase(state.phase).name;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: c.phase(state.phase).accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              '${name.toUpperCase()} · DAY ${state.cycleDay}',
              style: dmSans(
                12,
                weight: FontWeight.w700,
                height: 1.2,
                tracking: 0.18,
                color: c.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
