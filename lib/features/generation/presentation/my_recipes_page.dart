import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/centered_header.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/design/widgets/tap_target.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../../core/domain/phase.dart';
import '../../collections/data/collection_link_repository.dart';
import '../../collections/domain/collection_link.dart';
import '../../collections/presentation/widgets/link_card.dart';
import '../../content/application/content_providers.dart';
import '../../eat/application/eat_segment.dart';
import '../../recipes/presentation/recipes_page.dart' show keyIngredients;
import '../../recipes/presentation/widgets/recipe_widgets.dart';
import '../application/generation_providers.dart';
import '../data/saved_recipe_repository.dart';
import '../domain/personal_recipe.dart';
import '../domain/saved_recipe_ref.dart';
import 'delete_recipe.dart';

enum _Show { all, saved, mine, links }

/// "My recipes": recipes the user saved and the ones made for them, kept
/// privately on this phone. Filter: All, Saved, Added by me.
class MyRecipesPage extends ConsumerStatefulWidget {
  const MyRecipesPage({super.key});

  @override
  ConsumerState<MyRecipesPage> createState() => _MyRecipesPageState();
}

class _MyRecipesPageState extends ConsumerState<MyRecipesPage> {
  _Show _show = _Show.all;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final catalogue = ref.watch(catalogueProvider);
    final recipes = ref.watch(personalRecipesProvider).value ?? const [];
    final saved = ref.watch(savedRecipeRefsProvider).value ?? const [];
    final repo = ref.read(savedRecipeRepositoryProvider);
    final links = [
      for (final l
          in ref.watch(collectionLinksProvider).value ??
              const <CollectionLink>[])
        if (l.category == LinkCategory.recipes) l,
    ];
    final showSaved = _show == _Show.all || _show == _Show.saved;
    final showMine = _show == _Show.all || _show == _Show.mine;
    final showLinks = _show == _Show.all || _show == _Show.links;

    Widget gutter(Widget child, {double top = 0}) => Padding(
      padding: EdgeInsets.fromLTRB(MoonSpace.gutter, top, MoonSpace.gutter, 0),
      child: child,
    );

    Widget savedCard(SavedRecipeRef r) {
      final recipe = catalogue.recipe(r.refId);
      if (recipe != null) {
        return RecipeListCard(
          key: ValueKey('saved-${r.refId}'),
          recipe: recipe,
          palette: c.phase(recipe.phase),
          subtitle: keyIngredients(recipe, catalogue),
          onTap: () => context.push(Routes.recipe(r.refId)),
          hearted: true,
          onHeart: () => repo.remove(r.refId),
        );
      }
      // An outside recipe: only its title and provider are kept.
      return Pressable(
        key: ValueKey('saved-${r.refId}'),
        onTap: () => context.push(Routes.recipe(r.refId)),
        semanticLabel: '${r.title}, saved recipe',
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.fromLTRB(18, 12, 6, 12),
          decoration: BoxDecoration(
            color: c.raised,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: fraunces(18, height: 1.2, color: c.text),
                    ),
                    if (r.isExternal)
                      Text(
                        r.providerId == 'themealdb'
                            ? 'TheMealDB'
                            : r.providerId,
                        style: dmSans(12.5, height: 1.4, color: c.textMuted),
                      ),
                  ],
                ),
              ),
              Pressable(
                onTap: () => repo.remove(r.refId),
                checked: true,
                semanticLabel: 'Remove ${r.title} from My recipes',
                child: SizedBox(
                  width: minTapTarget + 8,
                  height: minTapTarget + 8,
                  child: Center(
                    child: MoonIcon(
                      MoonIconName.heart,
                      size: 22,
                      color: c.phase(Phase.menstrual).text,
                      strokeWidth: 2.2,
                      filled: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget personalCard(PersonalRecipe p) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            RecipeListCard(
              recipe: p.recipe,
              palette: c.phase(p.recipe.phase),
              subtitle: keyIngredients(p.recipe, catalogue),
              onTap: () => context.push(Routes.recipe(p.id)),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Pressable(
                key: ValueKey('delete-${p.id}'),
                onTap: () => confirmDeleteRecipe(context, ref, p),
                semanticLabel: 'Delete ${p.recipe.title}',
                child: SizedBox(
                  width: minTapTarget,
                  height: minTapTarget,
                  child: Center(
                    child: MoonIcon(
                      MoonIconName.trash,
                      size: 19,
                      color: c.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (p.isDevSample) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              'Development sample',
              style: dmSans(11, height: 1, color: c.textMuted),
            ),
          ),
        ],
      ],
    );

    final cards = [
      if (showSaved)
        for (final r in saved) savedCard(r),
      if (showMine)
        for (final p in recipes) personalCard(p),
      if (showLinks)
        for (final l in links) CollectionLinkCard(link: l),
    ];
    final (emptyTitle, emptyBody) = switch (_show) {
      _Show.saved => (
        'No saved recipes yet',
        'Tap the heart on a recipe to keep it here.',
      ),
      _Show.mine => (
        'Nothing added by you yet',
        'Recipes you write are listed here, privately.',
      ),
      _Show.links => (
        'No saved links yet',
        'Save a link to a recipe you found elsewhere with “Add a link”.',
      ),
      _Show.all => (
        'No recipes yet',
        'Recipes you save are listed here, privately.',
      ),
    };

    Widget chip(String label, _Show value, int count) {
      final active = _show == value;
      final slop = tapTargetSlop(height: 34);
      return ExpandedTapTarget(
        extra: slop,
        child: Pressable(
          onTap: () => setState(() => _show = value),
          selected: active,
          semanticLabel: '$label, $count',
          child: Padding(
            padding: slop,
            child: Container(
              constraints: const BoxConstraints(minHeight: 34),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: ShapeDecoration(
                color: active ? c.inverseBg : c.sand,
                shape: const StadiumBorder(),
              ),
              child: Text(
                '$label $count',
                style: dmSans(
                  13.5,
                  weight: active ? FontWeight.w700 : FontWeight.w500,
                  height: 1.2,
                  color: active ? c.inverseText : c.text,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CenteredHeader(
              title: 'My recipes',
              onBack: () => context.canPop()
                  ? context.pop()
                  : goEat(context, EatSegment.recipes),
              trailingIcon: MoonIconName.plus,
              trailingLabel: 'Add a recipe',
              trailingKey: const ValueKey('add-recipe-plus'),
              onTrailing: () => context.push(Routes.addRecipe),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 42 + 76),
                children: [
                  gutter(
                    Text(
                      'Recipes you’ve saved and your own, kept privately on '
                      'this phone.',
                      textAlign: TextAlign.center,
                      style: dmSans(13.5, height: 1.45, color: c.textMuted),
                    ),
                    top: 6,
                  ),
                  gutter(
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        chip(
                          'All',
                          _Show.all,
                          saved.length + recipes.length + links.length,
                        ),
                        chip('Saved', _Show.saved, saved.length),
                        chip('Added by me', _Show.mine, recipes.length),
                        chip('Links', _Show.links, links.length),
                      ],
                    ),
                    top: 16,
                  ),
                  if (cards.isEmpty)
                    gutter(
                      EmptyState(
                        icon: MoonIconName.recipes,
                        title: emptyTitle,
                        body: emptyBody,
                        palette: c.phase(Phase.follicular),
                      ),
                      top: 18,
                    )
                  else
                    for (final card in cards) gutter(card, top: 12),
                  gutter(
                    MoonButton(
                      'Add a recipe',
                      onPressed: () => context.push(Routes.addRecipe),
                    ),
                    top: 24,
                  ),
                  gutter(
                    Center(
                      child: TextLink(
                        'Add a link to a recipe',
                        key: const ValueKey('add-recipe-link'),
                        onTap: () => context.push(
                          Routes.collectionLinkNew(
                            category: LinkCategory.recipes.name,
                          ),
                        ),
                      ),
                    ),
                    top: 6,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
