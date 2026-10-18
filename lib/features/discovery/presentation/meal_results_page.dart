import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/catalogue.dart';
import '../../entitlements/application/entitlement_providers.dart';
import '../../entitlements/domain/entitlements.dart';
import '../../generation/application/generation_providers.dart';
import '../../recipes/presentation/recipes_page.dart' show keyIngredients;
import '../../recipes/presentation/widgets/recipe_widgets.dart';
import '../application/discovery_providers.dart';
import '../domain/recipe_candidate.dart';
import '../domain/recipe_discovery.dart';
import '../domain/recipe_matcher.dart';
import '../domain/recipe_source.dart';

/// What Moon Cycle has for the foods the user chose. Recipes that use **all**
/// of them come first, from the library and then any approved provider. If
/// there are none, close matches are offered as suggestions (never as the
/// requested meal), and a new recipe can be created as the fallback.
class MealResultsPage extends ConsumerWidget {
  const MealResultsPage({super.key, required this.choice});

  final MealChoice choice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final catalogue = ref.watch(catalogueProvider);
    final allowed = ref.watch(featureGateProvider).canUse(Feature.buildMeal);
    final result = ref.watch(mealDiscoveryProvider(choice.key));
    final names = [
      for (final id in choice.ids) ?catalogue.food(id)?.displayName,
    ];

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 42 + 76),
          children: [
            SubScreenHeader(
              backLabel: 'Build a meal',
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(Routes.mealBuilder()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MoonSpace.gutter,
                12,
                MoonSpace.gutter,
                0,
              ),
              child: !allowed
                  ? Text(
                      'Build a Meal is part of Moon Cycle Premium.',
                      style: MoonType.body.copyWith(color: c.text),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'Your meal',
                            style: fraunces(30, height: 1.12, color: c.text),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          names.join(' · '),
                          style: MoonType.body.copyWith(color: c.textMuted),
                        ),
                        const SizedBox(height: 24),
                        ...result.when(
                          loading: () => [
                            const Center(child: CircularProgressIndicator()),
                          ],
                          error: (_, _) => [
                            Text(
                              'We couldn’t look for recipes just now. Please '
                              'try again.',
                              style: MoonType.body.copyWith(color: c.text),
                            ),
                          ],
                          data: (r) => _body(context, ref, catalogue, r),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    WidgetRef ref,
    Catalogue catalogue,
    DiscoveryResult r,
  ) {
    final c = context.moon;
    final nameOf = {
      for (final id in choice.ids) id: catalogue.food(id)?.displayName ?? id,
    };

    Widget feature(RecipeCandidate cand) => Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeatureRecipeCard(
            recipe: cand.recipe,
            keyIngredients: keyIngredients(cand.recipe, catalogue),
            palette: c.phase(cand.recipe.phase),
            onTap: () => context.push(Routes.recipe(cand.recipe.id)),
          ),
          if (cand.source != RecipeSource.internal &&
              cand.rights.attribution != null) ...[
            const SizedBox(height: 6),
            Text(
              cand.rights.attribution!,
              style: dmSans(12, height: 1.3, color: c.textMuted),
            ),
          ],
        ],
      ),
    );

    Widget close(RecipeCandidate cand) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridRecipeCard(
          recipe: cand.recipe,
          palette: c.phase(cand.recipe.phase),
          onTap: () => context.push(Routes.recipe(cand.recipe.id)),
        ),
        const SizedBox(height: 6),
        Text(
          'Without ${cand.match.missingIds.map((id) => (nameOf[id] ?? id).toLowerCase()).join(', ')}',
          key: ValueKey('missing-${cand.recipe.id}'),
          style: dmSans(12, height: 1.3, color: c.textMuted),
        ),
      ],
    );

    List<Widget> closeMatches() => [
      const SizedBox(height: 8),
      const Overline('Close matches'),
      const SizedBox(height: 6),
      Text(
        'These don’t use everything you chose.',
        style: dmSans(13, height: 1.4, color: c.textMuted),
      ),
      for (var i = 0; i < r.partial.length; i += 2) ...[
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: close(r.partial[i])),
            const SizedBox(width: 14),
            Expanded(
              child: i + 1 < r.partial.length
                  ? close(r.partial[i + 1])
                  : const SizedBox(),
            ),
          ],
        ),
      ],
    ];

    if (r.complete.isNotEmpty) {
      return [
        const Overline('Recipes with all your foods'),
        const SizedBox(height: 14),
        for (final cand in r.complete) feature(cand),
        if (r.partial.isNotEmpty) ...closeMatches(),
      ];
    }

    final canCreate = ref.watch(generationAvailableProvider);
    return [
      Text(
        'No recipe uses all of these foods.',
        key: const ValueKey('no-complete-match'),
        style: fraunces(22, height: 1.2, color: c.text),
      ),
      const SizedBox(height: 10),
      Text(
        canCreate
            ? 'You can have a new recipe made for this exact meal. It is '
                  'saved privately to your recipes.'
            : 'Creating a new recipe isn’t available yet.',
        style: MoonType.body.copyWith(color: c.text),
      ),
      if (canCreate) ...[
        const SizedBox(height: 16),
        MoonButton(
          'Create a new recipe',
          onPressed: () => context.push(
            Routes.mealCreate(
              protein: choice.proteinId,
              base: choice.baseId,
              plants: choice.plantIds,
            ),
          ),
        ),
      ],
      const SizedBox(height: 26),
      if (r.partial.isNotEmpty) ...closeMatches(),
    ];
  }
}
