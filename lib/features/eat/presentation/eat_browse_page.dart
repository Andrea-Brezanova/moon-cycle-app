import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/domain/browse_scope.dart';
import '../../content/application/content_providers.dart';
import '../../cycle/application/viewing_phase.dart';
import '../../foods/application/browse_scope.dart';
import '../../foods/presentation/foods_page.dart';
import '../../recipes/application/recipes_scope.dart';
import '../../recipes/presentation/recipes_page.dart';
import '../application/eat_segment.dart';
import 'browse_phase_sheet.dart';

/// The Foods or Recipes browsing page, opened from the Eat hub. It is the
/// unchanged Foods / Recipes content under a back link to Eat.
class EatBrowsePage extends ConsumerWidget {
  const EatBrowsePage({super.key, required this.segment});

  final EatSegment segment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final foodsAll = ref.watch(foodsScopeProvider) == BrowseScope.all;
    final recipesAll = ref.watch(recipesScopeProvider) == BrowseScope.all;
    final viewing = ref.watch(viewingPhaseProvider);
    final catalogue = ref.watch(catalogueProvider);

    final all = segment == EatSegment.foods ? foodsAll : recipesAll;
    final phaseName = all ? 'All phases' : catalogue.phase(viewing).name;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                SubScreenHeader(
                  backLabel: 'Eat',
                  onBack: () => context.canPop()
                      ? context.pop()
                      : context.go(AppTab.eat.path),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    MoonSpace.gutter,
                    6,
                    MoonSpace.gutter,
                    14,
                  ),
                  // Wraps (pill under the title) at large text sizes.
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 8,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          segment == EatSegment.foods ? 'Foods' : 'Recipes',
                          style: MoonType.h1.copyWith(color: c.text),
                        ),
                      ),
                      _PhasePill(label: phaseName, all: all),
                    ],
                  ),
                ),
                Expanded(
                  child: switch (segment) {
                    EatSegment.foods => const FoodsPage(),
                    EatSegment.recipes => const RecipesPage(),
                  },
                ),
              ],
            ),
            Positioned(
              right: 20,
              bottom: 16,
              child: _BuildMealPill(
                onTap: () => context.push(Routes.mealBuilder()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The phase on show; opens "Browse by phase".
class _PhasePill extends ConsumerWidget {
  const _PhasePill({required this.label, required this.all});

  final String label;
  final bool all;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final viewing = ref.watch(viewingPhaseProvider);
    return Pressable(
      key: const ValueKey('phase-pill'),
      onTap: () => showBrowsePhaseSheet(context),
      semanticLabel: 'Browse by phase. Showing $label',
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: ShapeDecoration(
          color: all ? c.sand : c.phase(viewing).tint,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!all) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: c.phase(viewing).accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                style: dmSans(
                  14,
                  weight: FontWeight.w600,
                  height: 1.2,
                  color: c.text,
                ),
              ),
            ),
            const SizedBox(width: 6),
            MoonIcon(MoonIconName.down, size: 14, color: c.text),
          ],
        ),
      ),
    );
  }
}

/// The floating "Build a meal" shortcut.
class _BuildMealPill extends StatelessWidget {
  const _BuildMealPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Build a meal',
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: ShapeDecoration(
          color: c.inverseBg,
          shape: const StadiumBorder(),
          shadows: const [
            BoxShadow(
              color: Color(0x331B152E),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MoonIcon(MoonIconName.recipes, size: 18, color: c.inverseText),
            const SizedBox(width: 8),
            Text(
              'Build a meal',
              style: dmSans(
                14,
                weight: FontWeight.w600,
                height: 1.2,
                color: c.inverseText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
