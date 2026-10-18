import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../content/application/content_providers.dart';
import '../../discovery/domain/recipe_source.dart';
import '../../generation/domain/generation_failure.dart';
import '../../recipes/presentation/recipes_page.dart' show keyIngredients;
import '../../recipes/presentation/widgets/recipe_widgets.dart';
import '../application/try_new_trio.dart';

/// "Try something new": three foods, and up to three different recipes that
/// each use all of them. Existing recipes first; new ones are made only when
/// fewer exist and the build can make them. Whatever is found is shown; what is
/// missing is explained, never faked.
class TryNewResultsPage extends ConsumerStatefulWidget {
  const TryNewResultsPage({super.key, required this.foodIds});

  final List<String> foodIds;

  @override
  ConsumerState<TryNewResultsPage> createState() => _TryNewResultsPageState();
}

class _TryNewResultsPageState extends ConsumerState<TryNewResultsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(tryNewTrioProvider.notifier).start(widget.foodIds);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final catalogue = ref.watch(catalogueProvider);
    final state = ref.watch(tryNewTrioProvider);
    final names = [
      for (final id in widget.foodIds) ?catalogue.food(id)?.displayName,
    ];

    List<Widget> body() => switch (state) {
      TrioIdle() || TrioWorking() => [
        Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                state is TrioWorking && state.done > 0
                    ? 'Making recipe ${state.done + 1} of 3'
                    : 'Looking for recipes',
                key: const ValueKey('trio-progress'),
                style: MoonType.body.copyWith(color: c.text),
              ),
            ),
          ],
        ),
      ],
      TrioReady() => [
        if (state.items.isEmpty)
          Text(
            'No recipe uses all three of these foods yet.',
            key: const ValueKey('trio-none'),
            style: fraunces(22, height: 1.2, color: c.text),
          ),
        for (final item in state.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FeatureRecipeCard(
                  recipe: item.recipe,
                  keyIngredients: keyIngredients(item.recipe, catalogue),
                  palette: c.phase(item.recipe.phase),
                  onTap: () => context.push(Routes.recipe(item.recipe.id)),
                ),
                const SizedBox(height: 8),
                Text(
                  item.recipe.intro,
                  style: dmSans(14, height: 1.4, color: c.text),
                ),
                const SizedBox(height: 6),
                Text(
                  switch (item.source) {
                    RecipeSource.internal => 'From the Moon Cycle library',
                    RecipeSource.externalApi => 'From a partner library',
                    RecipeSource.aiGenerated =>
                      item.isDevSample
                          ? 'Development sample · not made by an AI'
                          : 'Made for you · saved to My recipes',
                  },
                  key: ValueKey('source-${item.recipe.id}'),
                  style: dmSans(12, height: 1.3, color: c.textMuted),
                ),
              ],
            ),
          ),
        if (state.failure case final f?) ...[
          Text(
            _failureText(f.kind),
            key: const ValueKey('trio-failure'),
            style: MoonType.body.copyWith(color: c.text),
          ),
          const SizedBox(height: 14),
          if (state.canRetry)
            MoonButton(
              'Try again',
              onPressed: ref.read(tryNewTrioProvider.notifier).retry,
            ),
        ] else if (state.premiumNeeded)
          Text(
            'Making new recipes from these foods is part of Moon Cycle '
            'Premium.',
            key: const ValueKey('trio-premium'),
            style: MoonType.body.copyWith(color: c.textMuted),
          )
        else if (!state.complete && !state.generationOffered)
          Text(
            'That’s every recipe we have with all three. Making new ones '
            'isn’t available yet.',
            key: const ValueKey('trio-unavailable'),
            style: MoonType.body.copyWith(color: c.textMuted),
          ),
      ],
    };

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 42 + 76),
          children: [
            SubScreenHeader(
              backLabel: 'Home',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(Routes.home),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MoonSpace.gutter,
                12,
                MoonSpace.gutter,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Try something new',
                      style: fraunces(30, height: 1.12, color: c.text),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    names.join(' · '),
                    style: MoonType.body.copyWith(color: c.textMuted),
                  ),
                  const SizedBox(height: 24),
                  ...body(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _failureText(GenerationFailureKind kind) => switch (kind) {
    GenerationFailureKind.quotaExceeded =>
      'You’ve used this month’s new recipes. They renew next month.',
    GenerationFailureKind.notEntitled =>
      'Making new recipes is part of Moon Cycle Premium.',
    GenerationFailureKind.notSignedIn =>
      'Making new recipes needs an account. Browsing never does.',
    GenerationFailureKind.unavailable =>
      'Making new recipes isn’t available right now.',
    _ => 'We couldn’t make every recipe. Nothing extra was used.',
  };
}
