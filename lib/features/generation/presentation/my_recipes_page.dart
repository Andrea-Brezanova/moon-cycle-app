import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/domain/phase.dart';
import '../../recipes/presentation/widgets/recipe_widgets.dart';
import '../application/generation_providers.dart';
import '../domain/personal_recipe.dart';

/// "My recipes": the recipes the user made, saved privately on this phone.
class MyRecipesPage extends ConsumerWidget {
  const MyRecipesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final recipes = ref.watch(personalRecipesProvider).value ?? const [];
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 42 + 76),
          children: [
            SubScreenHeader(
              backLabel: 'Recipes',
              title: 'My recipes',
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(AppTab.recipes.path),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MoonSpace.gutter,
                8,
                MoonSpace.gutter,
                0,
              ),
              child: recipes.isEmpty
                  ? EmptyState(
                      icon: MoonIconName.recipes,
                      title: 'No recipes yet',
                      body:
                          'Recipes you create from Build a Meal are saved here, '
                          'privately.',
                      palette: c.phase(Phase.follicular),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Saved privately on this phone.',
                          style: dmSans(13, height: 1.4, color: c.textMuted),
                        ),
                        for (var i = 0; i < recipes.length; i += 2) ...[
                          const SizedBox(height: 26),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _card(context, recipes[i])),
                              const SizedBox(width: 14),
                              Expanded(
                                child: i + 1 < recipes.length
                                    ? _card(context, recipes[i + 1])
                                    : const SizedBox(),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, PersonalRecipe p) {
    final c = context.moon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridRecipeCard(
          recipe: p.recipe,
          palette: c.phase(p.recipe.phase),
          onTap: () => context.push(Routes.recipe(p.id)),
        ),
        if (p.isDevSample) ...[
          const SizedBox(height: 6),
          Text(
            'Development sample',
            style: dmSans(11, height: 1, color: c.textMuted),
          ),
        ],
      ],
    );
  }
}
