import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_colors.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_chip.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/design/widgets/recipe_photo.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/recipe.dart';
import '../../cycle/application/viewing_phase.dart' show actualPhaseProvider;
import '../../cycle/presentation/cycle_orbit.dart';
import '../../diary/domain/diary_entry.dart';
import '../../discovery/application/discovery_providers.dart';
import '../../discovery/data/recipe_sources.dart' show ExternalRecipe;
import '../../entitlements/application/entitlement_providers.dart';
import '../../entitlements/domain/entitlements.dart';
import '../../generation/application/generation_providers.dart';
import '../../generation/data/personal_recipe_repository.dart';
import '../../generation/data/saved_recipe_repository.dart';
import '../../generation/domain/personal_recipe.dart';
import '../../generation/domain/recipe_image_service.dart';
import '../../generation/domain/recipe_submission_service.dart';
import '../../generation/domain/saved_recipe_ref.dart';
import '../../shopping/application/shopping_controller.dart';
import '../../shopping/application/shopping_summary.dart';
import '../../shopping/domain/item_key.dart';
import 'widgets/recipe_image.dart';

/// Recipe detail (`19-recipe-detail`, `20-recipe-detail-added`), inside the
/// Recipes stack, so back returns to the same list, filters and scroll.
class RecipeDetailPage extends ConsumerWidget {
  const RecipeDetailPage({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final catalogue = ref.watch(catalogueProvider);
    final isExternal = recipeId.startsWith('x-');
    final lookup = ref.watch(recipeByIdProvider(recipeId));
    final externalLookup = isExternal
        ? ref.watch(externalRecipeProvider(recipeId))
        : null;
    if (lookup.isLoading || (externalLookup?.isLoading ?? false)) {
      return Scaffold(backgroundColor: c.bg);
    }
    final external = externalLookup?.value;
    final recipe = isExternal
        ? external?.recipe.copyWith(phase: ref.watch(actualPhaseProvider))
        : lookup.value;
    // An external recipe may only be put on the shopping list if its terms let
    // us keep its ingredients.
    final canShop = !isExternal || (external?.rights.mayStore ?? false);
    final personal = recipeId.startsWith(personalRecipePrefix)
        ? ref.watch(personalRecipeProvider(recipeId)).value
        : null;
    if (recipe == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Center(
          child: TextLink(
            'This recipe isn’t available',
            onTap: () => context.pop(),
          ),
        ),
      );
    }
    final palette = c.phase(recipe.phase);
    final onListKeys = ref.watch(shoppingSummaryProvider).onListKeys;
    final skipped = ref
        .watch(foodFilterProvider)
        .avoidedLines(recipe, catalogue);
    bool onList(RecipeIngredient l) =>
        onListKeys.contains(lineKey(l, catalogue));
    final toAdd = [
      for (final l in recipe.ingredients)
        if (!skipped.contains(l)) l,
    ];
    final alreadyOn = [
      for (final l in toAdd)
        if (onList(l)) l,
    ];
    final allAdded = toAdd.isNotEmpty && alreadyOn.length == toAdd.length;

    return Scaffold(
      backgroundColor: c.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              RecipePhoto(
                height: 330,
                radius: 0,
                palette: palette,
                image: recipeImage(recipe, rights: external?.rights),
              ),
              Positioned(
                top: MediaQuery.viewPaddingOf(context).top + 7,
                left: 20,
                child: _BackButton(onTap: () => context.pop()),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 300),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.bg,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(MoonRadius.recipeFeature),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    MoonSpace.gutter,
                    26,
                    MoonSpace.gutter,
                    42,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (personal != null) ...[
                        _PersonalNote(recipe: personal),
                        const SizedBox(height: 16),
                      ],
                      _Intro(
                        recipe: recipe,
                        palette: palette,
                        showPhase: !isExternal,
                      ),
                      if (external != null) ...[
                        const SizedBox(height: 16),
                        _ExternalNote(external: external),
                      ],
                      const SizedBox(height: 12),
                      _SaveLink(recipe: recipe, external: external),
                      const SizedBox(height: 18),
                      _Ingredients(
                        recipe: recipe,
                        palette: palette,
                        onList: onList,
                        skipped: skipped,
                      ),
                      const SizedBox(height: 20),
                      if (!canShop) ...[
                        Text(
                          'This recipe comes from another source, so its '
                          'ingredients can’t be added to your shopping list.',
                          key: const ValueKey('no-shopping-external'),
                          textAlign: TextAlign.center,
                          style: dmSans(13, height: 1.45, color: c.textMuted),
                        ),
                      ] else if (allAdded) ...[
                        MoonDoneButton(
                          'Added to shopping list',
                          checkColor: palette.text,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            runSpacing: 6,
                            children: [
                              Text(
                                'All ${toAdd.length} ingredients are on your list.',
                                style: dmSans(
                                  13,
                                  height: 1.45,
                                  color: c.textMuted,
                                ),
                              ),
                              TextLink(
                                'Open shopping list',
                                size: 13,
                                onTap: () => context.go(Routes.shopping),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        MoonButton(
                          'Add ingredients to shopping list',
                          onPressed: () => ref
                              .read(shoppingControllerProvider.notifier)
                              .addRecipe(recipe),
                        ),
                        if (mergeNote(alreadyOn) case final note?) ...[
                          const SizedBox(height: 12),
                          Text(
                            note,
                            textAlign: TextAlign.center,
                            style: dmSans(13, height: 1.45, color: c.textMuted),
                          ),
                        ],
                      ],
                      if (skipNote(skipped) case final note?) ...[
                        const SizedBox(height: 12),
                        Text(
                          note,
                          textAlign: TextAlign.center,
                          style: dmSans(13, height: 1.45, color: c.textMuted),
                        ),
                      ],
                      if (ref
                          .watch(featureGateProvider)
                          .canUse(Feature.logDiary)) ...[
                        const SizedBox(height: 12),
                        MoonButton(
                          'Log meal',
                          variant: MoonButtonVariant.ghost,
                          onPressed: () => context.push(
                            Routes.logMeal(
                              kind: DiaryItemKind.recipe,
                              itemId: recipe.id,
                              title: recipe.title,
                              from: 'recipe',
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 30),
                      _Method(recipe: recipe, palette: palette),
                      if (personal != null) ...[
                        const SizedBox(height: 30),
                        if (personal.isManual) ...[
                          Center(
                            child: TextLink(
                              'Edit this recipe',
                              onTap: () =>
                                  context.push(Routes.editRecipe(personal.id)),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        Center(
                          child: TextLink(
                            'Delete this recipe',
                            onTap: () => _confirmDelete(context, ref, personal),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Broccoli, lemon and sauerkraut are already on your list. We’ll merge
/// them, not add them twice."
String? mergeNote(List<RecipeIngredient> alreadyOn) {
  if (alreadyOn.isEmpty) return null;
  final one = alreadyOn.length == 1;
  return '${_list(alreadyOn)} ${one ? 'is' : 'are'} already on your list. '
      'We’ll merge ${one ? 'it' : 'them'}, not add ${one ? 'it' : 'them'} twice.';
}

/// Lines left out because the user avoids them (PRD §9).
String? skipNote(List<RecipeIngredient> skipped) {
  if (skipped.isEmpty) return null;
  return 'We’ll leave out ${_list(skipped, capitalise: false)}: '
      '${skipped.length == 1 ? 'it’s' : 'they’re'} on your avoid list.';
}

String _list(List<RecipeIngredient> lines, {bool capitalise = true}) {
  final names = [
    for (final (i, l) in lines.indexed)
      i == 0 && capitalise ? l.label : l.label.toLowerCase(),
  ];
  return names.length == 1
      ? names.single
      : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Back to recipes',
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: c.raised,
          shape: BoxShape.circle,
          // The one shadow in the design: the button floats on the photo.
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E1B152E),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: MoonIcon(
          MoonIconName.back,
          size: 20,
          color: c.text,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

/// Who a recipe is from and where to read the original: required wherever the
/// provider's terms ask for credit, and shown for every external recipe.
class _ExternalNote extends StatelessWidget {
  const _ExternalNote({required this.external});

  final ExternalRecipe external;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final style = dmSans(13, height: 1.45, color: c.textMuted);
    final url = external.rights.sourceUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          external.rights.attribution ?? 'From a partner recipe library',
          key: const ValueKey('external-attribution'),
          style: style,
        ),
        if (url != null)
          TextLink(
            'View the original recipe',
            size: 13,
            onTap: () =>
                launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView),
          ),
      ],
    );
  }
}

/// "Save to My recipes": keeps a reference, never a third-party recipe's text.
class _SaveLink extends ConsumerWidget {
  const _SaveLink({required this.recipe, required this.external});

  final Recipe recipe;
  final ExternalRecipe? external;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (recipe.id.startsWith(personalRecipePrefix)) {
      return const SizedBox.shrink();
    }
    final refs =
        ref.watch(savedRecipeRefsProvider).value ?? const <SavedRecipeRef>[];
    final saved = refs.any((r) => r.refId == recipe.id);
    final repo = ref.read(savedRecipeRepositoryProvider);
    return Align(
      alignment: Alignment.centerLeft,
      child: TextLink(
        saved ? 'Saved to My recipes · Remove' : 'Save to My recipes',
        size: 14,
        onTap: () => saved
            ? repo.remove(recipe.id)
            : repo.save(
                providerId: external?.providerId ?? 'moon-cycle',
                refId: recipe.id,
                externalId: external?.externalId,
                title: recipe.title,
                sourceUrl: external?.rights.sourceUrl,
              ),
      ),
    );
  }
}

/// Says who made a personal recipe, and the state of its picture. A
/// development sample is never presented as generated by the live service.
class _PersonalNote extends ConsumerWidget {
  const _PersonalNote({required this.recipe});

  final PersonalRecipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final style = dmSans(13, height: 1.45, color: c.textMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recipe.isManual
              ? 'Added by you · saved privately on this phone. Ingredients '
                    'you typed that we don’t recognise can’t be checked '
                    'against your food preferences.'
              : recipe.isDevSample
              ? 'Development sample · made from templates, not by an AI. '
                    'Saved privately to your recipes.'
              : 'Created for you · saved privately to your recipes.',
          key: const ValueKey('personal-recipe-note'),
          style: style,
        ),
        if (_lifecycleLine(recipe.lifecycle) case final line?) ...[
          const SizedBox(height: 4),
          Text(line, key: const ValueKey('lifecycle-line'), style: style),
        ],
        if (recipe.lifecycle == RecipeLifecycle.privateSaved &&
            recipe.remoteId != null &&
            !recipe.isDevSample &&
            ref.watch(submissionAvailableProvider)) ...[
          const SizedBox(height: 4),
          TextLink(
            'Suggest to Moon Cycle',
            size: 13,
            onTap: () => _suggest(context, ref, recipe),
          ),
        ],
        if (recipe.imageStatus == ImageStatus.pending) ...[
          const SizedBox(height: 4),
          Text('Adding a picture…', style: style),
        ],
        if (recipe.imageStatus == ImageStatus.failed) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('The picture couldn’t be made.', style: style),
              TextLink(
                'Try again',
                size: 13,
                onTap: () => ref.read(retryImageProvider)(recipe),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

String? _lifecycleLine(RecipeLifecycle l) => switch (l) {
  RecipeLifecycle.privateSaved => null,
  RecipeLifecycle.published => 'Part of the Moon Cycle recipe library.',
  _ =>
    'Suggested to Moon Cycle. It stays private unless an editor approves it.',
};

/// The user's explicit, informed request to have a recipe reviewed. Nothing is
/// shared by this: only an editor's approval can publish.
Future<void> _suggest(
  BuildContext context,
  WidgetRef ref,
  PersonalRecipe recipe,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Suggest to Moon Cycle?'),
      content: const Text(
        'Moon Cycle’s editors may review this recipe for the shared library. '
        'Your name and account are never shown with it, and nothing is '
        'published unless an editor approves it. You can withdraw it any time '
        'before then.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Not now'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Suggest it'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  String? problem;
  try {
    final lifecycle = await ref
        .read(recipeSubmissionServiceProvider)
        .submit(recipe.remoteId!);
    await ref
        .read(personalRecipeRepositoryProvider)
        .setLifecycle(recipe.ownerId, recipe.id, lifecycle);
  } on SubmissionException catch (e) {
    problem = switch (e.failure) {
      SubmissionFailure.alreadySubmitted => 'It has already been suggested.',
      SubmissionFailure.notReviewable => 'This recipe can’t be suggested.',
      SubmissionFailure.notSignedIn => 'Please sign in first.',
      _ => 'We couldn’t send it just now. Please try again.',
    };
  }
  if (problem != null && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(problem)));
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  PersonalRecipe recipe,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete this recipe?'),
      content: const Text('It will be removed from your recipes.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep it'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  await ref
      .read(personalRecipeRepositoryProvider)
      .delete(recipe.ownerId, recipe.id);
  if (context.mounted) context.pop();
}

class _Intro extends StatelessWidget {
  const _Intro({
    required this.recipe,
    required this.palette,
    this.showPhase = true,
  });

  final Recipe recipe;
  final PhasePalette palette;

  /// False for an external recipe: it has no phase of its own.
  final bool showPhase;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (showPhase)
              MoonPill(
                phaseName(recipe.phase),
                background: palette.tint,
                dot: palette.accent,
              ),
            MoonPill(recipe.mealType.label, background: c.sand),
          ],
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            recipe.title,
            style: fraunces(30, height: 1.12, color: c.text),
          ),
        ),
        const SizedBox(height: 12),
        // Times and servings are shown only when the source gave them.
        if (recipe.minutes > 0 || recipe.serves > 0)
          Row(
            children: [
              MoonIcon(
                MoonIconName.clock,
                size: 16,
                color: c.textMuted,
                strokeWidth: 1.8,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  [
                    if (recipe.minutes > 0) '${recipe.minutes} min',
                    if (recipe.serves > 0) 'Serves ${recipe.serves}',
                  ].join(' · '),
                  style: dmSans(
                    14,
                    weight: FontWeight.w500,
                    height: 1,
                    color: c.textMuted,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        Text(recipe.intro, style: MoonType.body.copyWith(color: c.text)),
        if (recipe.whyThisPhase.isNotEmpty) ...[
          const SizedBox(height: 20),
          Semantics(
            header: true,
            child: Text(
              'Why this recipe?',
              style: dmSans(
                14,
                weight: FontWeight.w600,
                height: 1.2,
                color: c.text,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            recipe.whyThisPhase,
            key: const ValueKey('recipe-why-this-phase'),
            style: dmSans(14, height: 1.45, color: c.textMuted),
          ),
        ],
      ],
    );
  }
}

class _Ingredients extends StatelessWidget {
  const _Ingredients({
    required this.recipe,
    required this.palette,
    required this.onList,
    required this.skipped,
  });

  final Recipe recipe;
  final PhasePalette palette;
  final bool Function(RecipeIngredient) onList;
  final List<RecipeIngredient> skipped;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final n = recipe.ingredients.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Ingredients',
                  style: fraunces(24, weight: FontWeight.w500, color: c.text),
                ),
              ),
            ),
            Text(
              '$n ${n == 1 ? 'item' : 'items'}',
              style: dmSans(
                13,
                weight: FontWeight.w500,
                height: 1,
                color: c.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final (i, line) in recipe.ingredients.indexed)
          _IngredientRow(
            line: line,
            onList: onList(line),
            avoided: skipped.contains(line),
            palette: palette,
            divider: i > 0,
          ),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.line,
    required this.onList,
    required this.avoided,
    required this.palette,
    required this.divider,
  });

  final RecipeIngredient line;
  final bool onList;
  final bool avoided;
  final PhasePalette palette;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final quantity = line.quantityLabel;
    return MergeSemantics(
      child: Container(
        // 54 plus the divider, as on the canvas.
        constraints: BoxConstraints(minHeight: divider ? 55 : 54),
        decoration: BoxDecoration(
          border: divider ? Border(top: BorderSide(color: c.line)) : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.label,
                    style: dmSans(
                      16,
                      weight: FontWeight.w500,
                      height: 1.25,
                      color: c.text,
                    ),
                  ),
                  if (onList || avoided) ...[
                    const SizedBox(height: 2),
                    Text(
                      avoided ? 'You avoid this' : 'On your list',
                      style: dmSans(
                        12,
                        weight: FontWeight.w500,
                        height: 1,
                        color: avoided ? c.textMuted : palette.text,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (quantity.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 124),
                child: Text(
                  quantity,
                  textAlign: TextAlign.end,
                  style: dmSans(14, height: 1.25, color: c.textMuted),
                ),
              ),
            const SizedBox(width: 12),
            if (onList)
              OnListMark(palette: palette)
            else
              const SizedBox(width: 22),
          ],
        ),
      ),
    );
  }
}

class _Method extends StatelessWidget {
  const _Method({required this.recipe, required this.palette});

  final Recipe recipe;
  final PhasePalette palette;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Method',
            style: fraunces(24, weight: FontWeight.w500, color: c.text),
          ),
        ),
        for (final (i, step) in recipe.steps.indexed) ...[
          SizedBox(height: i == 0 ? 16 : 18),
          MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: palette.tint,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: dmSans(
                      14,
                      weight: FontWeight.w600,
                      height: 1,
                      color: palette.text,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      step,
                      style: MoonType.body.copyWith(color: c.text),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
