import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/design/widgets/recipe_photo.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/catalogue.dart';
import '../../entitlements/application/entitlement_providers.dart';
import '../../entitlements/domain/entitlements.dart';
import '../../recipes/presentation/widgets/recipe_image.dart';
import '../application/discovery_providers.dart';
import '../domain/match_config.dart';
import '../domain/recipe_candidate.dart';
import '../domain/recipe_discovery.dart';
import '../domain/recipe_matcher.dart';
import '../domain/recipe_source.dart';

/// The real recipes that use the foods the user chose, best first: those using
/// the most of their foods lead, and the group headings say honestly how many
/// of the chosen foods each recipe has. A useful first set is shown, with a
/// button for more. Nothing is generated: if no recipe fits, the page says so.
class MealResultsPage extends ConsumerStatefulWidget {
  const MealResultsPage({super.key, required this.choice});

  final MealChoice choice;

  @override
  ConsumerState<MealResultsPage> createState() => _MealResultsPageState();
}

class _MealResultsPageState extends ConsumerState<MealResultsPage> {
  int? _shown;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final catalogue = ref.watch(catalogueProvider);
    final config = ref.watch(matchConfigProvider);
    final allowed = ref.watch(featureGateProvider).canUse(Feature.buildMeal);
    final result = ref.watch(mealDiscoveryProvider(widget.choice.key));
    final names = [
      for (final id in widget.choice.ids) ?catalogue.food(id)?.displayName,
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
                            'Recipes for your meal',
                            style: fraunces(30, height: 1.12, color: c.text),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          names.join(' · '),
                          key: const ValueKey('chosen-foods'),
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
                          data: (r) => _body(context, catalogue, config, r),
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
    Catalogue catalogue,
    MatchConfig config,
    DiscoveryResult r,
  ) {
    final c = context.moon;
    if (r.isEmpty) {
      return [
        Text(
          'No recipes use these foods yet.',
          key: const ValueKey('no-results'),
          style: fraunces(22, height: 1.2, color: c.text),
        ),
        const SizedBox(height: 10),
        Text(
          'Try taking a food out, or choosing a different one. Foods you avoid '
          'are always left out.',
          style: MoonType.body.copyWith(color: c.text),
        ),
        const SizedBox(height: 18),
        MoonButton('Change my foods', onPressed: () => context.pop()),
      ];
    }

    final count = _shown ?? config.initialResults;
    final visible = r.results.take(count).toList();
    final n = widget.choice.ids.length;
    final widgets = <Widget>[
      Text(
        '${r.results.length} ${r.results.length == 1 ? 'recipe' : 'recipes'}',
        key: const ValueKey('result-count'),
        style: dmSans(
          13,
          weight: FontWeight.w500,
          height: 1,
          color: c.textMuted,
        ),
      ),
    ];
    MatchLevel? lastLevel;
    for (final cand in visible) {
      if (cand.match.level != lastLevel) {
        lastLevel = cand.match.level;
        widgets
          ..add(const SizedBox(height: 22))
          ..add(
            Overline(switch (cand.match.level) {
              MatchLevel.complete =>
                n == 1 ? 'Uses your food' : 'Uses all your foods',
              MatchLevel.good => 'Uses most of your foods',
              MatchLevel.partial => 'Uses some of your foods',
            }, key: ValueKey('group-${cand.match.level.name}')),
          );
      }
      widgets
        ..add(const SizedBox(height: 18))
        ..add(
          _ResultCard(candidate: cand, chosenCount: n, catalogue: catalogue),
        );
    }
    if (visible.length < r.results.length) {
      widgets
        ..add(const SizedBox(height: 24))
        ..add(
          MoonButton(
            'See more recipes',
            variant: MoonButtonVariant.ghost,
            onPressed: () =>
                setState(() => _shown = count + config.moreResults),
          ),
        );
    }
    return widgets;
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.candidate,
    required this.chosenCount,
    required this.catalogue,
  });

  final RecipeCandidate candidate;
  final int chosenCount;
  final Catalogue catalogue;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final recipe = candidate.recipe;
    final match = candidate.match;
    final external = candidate.source != RecipeSource.internal;
    final url = candidate.rights.sourceUrl;
    final matchedNames = [
      for (final id in match.matchedIds) ?catalogue.food(id)?.displayName,
    ];
    final uses = candidate.isComplete
        ? (chosenCount == 1
              ? 'Uses your food'
              : 'Uses all $chosenCount of your foods')
        : 'Uses ${match.matchedIds.length} of your $chosenCount foods';
    final minutes = recipe.minutes > 0 ? '${recipe.minutes} min' : null;
    final sourceText = switch (candidate.source) {
      RecipeSource.internal => 'Moon Cycle recipe',
      RecipeSource.externalApi =>
        candidate.rights.attribution ?? 'From a partner library',
      RecipeSource.aiGenerated => 'Created for you',
    };

    ImageProvider? image = recipeImage(recipe);
    if (external && candidate.rights.mayShowImage && recipe.imageUrl != null) {
      image = NetworkImage(recipe.imageUrl!);
    }

    void open() {
      if (external && url != null) {
        launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
      } else {
        context.push(Routes.recipe(recipe.id));
      }
    }

    return Pressable(
      onTap: open,
      semanticLabel:
          '${recipe.title}. $uses: ${matchedNames.join(', ')}. '
          '${minutes ?? ''} $sourceText',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecipePhoto(
            height: 190,
            radius: MoonRadius.gridCard,
            palette: c.phase(recipe.phase),
            image: image,
          ),
          const SizedBox(height: 10),
          Text(
            recipe.title,
            style: fraunces(
              20,
              weight: FontWeight.w500,
              height: 1.2,
              color: c.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            uses,
            key: ValueKey('uses-${recipe.id}'),
            style: dmSans(
              14,
              weight: FontWeight.w600,
              height: 1.3,
              color: c.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Includes ${matchedNames.join(', ').toLowerCase()}',
            key: ValueKey('includes-${recipe.id}'),
            style: dmSans(13, height: 1.35, color: c.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            [?minutes, sourceText].join(' · '),
            style: dmSans(12, height: 1.3, color: c.textMuted),
          ),
          if (external && url != null) ...[
            const SizedBox(height: 4),
            TextLink('View original recipe', size: 13, onTap: open),
          ],
        ],
      ),
    );
  }
}
