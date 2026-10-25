import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router/routes.dart';
import '../../content/application/content_providers.dart';
import '../../generation/application/generation_providers.dart';
import '../../generation/data/saved_recipe_repository.dart';
import '../../recipes/presentation/widgets/recipe_image.dart';
import '../data/collection_link_repository.dart';
import '../domain/collection_link.dart';

/// The three My Collections categories. Workouts and Spa fill in as their
/// libraries arrive; recipes are the existing saved and written recipes. (A
/// link in Spa is stored under the legacy key `sounds`, which avoids a
/// migration.)
enum CollectionCategory { recipes, workouts, spa }

/// What each category holds, counted from the real stores.
final class CollectionSummary {
  const CollectionSummary({
    required this.recipesSaved,
    required this.recipesMine,
    required this.recipeLinks,
    required this.workoutLinks,
    required this.spaLinks,
  });

  final int recipesSaved;
  final int recipesMine;
  final int recipeLinks;
  final int workoutLinks;
  final int spaLinks;

  int get recipes => recipesSaved + recipesMine + recipeLinks;
  int get total => recipes + workoutLinks + spaLinks;

  int of(CollectionCategory c) => switch (c) {
    CollectionCategory.recipes => recipes,
    CollectionCategory.workouts => workoutLinks,
    CollectionCategory.spa => spaLinks,
  };
}

/// One line in "Recently saved": something from any category, newest first.
final class RecentItem {
  const RecentItem({
    required this.id,
    required this.title,
    required this.badge,
    required this.detail,
    required this.savedAt,
    required this.route,
    required this.category,
    this.image,
  });

  final String id;
  final String title;

  /// The small label: "Recipe", "YouTube", "Yours"...
  final String badge;

  /// "From Moon Cycle", "Added by you", "Slow Flow Studio".
  final String detail;
  final DateTime savedAt;

  /// Where tapping it goes.
  final String route;
  final CollectionCategory category;
  final ImageProvider? image;
}

/// How many are shown on the landing page.
const recentlySavedCount = 5;

/// Counts for the Me card and the landing tiles.
final collectionSummaryProvider = Provider<CollectionSummary>((ref) {
  final saved = ref.watch(savedRecipeRefsProvider).value ?? const [];
  final mine = ref.watch(personalRecipesProvider).value ?? const [];
  final links = ref.watch(collectionLinksProvider).value ?? const [];
  int linksIn(LinkCategory c) => links.where((l) => l.category == c).length;
  return CollectionSummary(
    recipesSaved: saved.length,
    recipesMine: mine.length,
    recipeLinks: linksIn(LinkCategory.recipes),
    workoutLinks: linksIn(LinkCategory.workouts),
    spaLinks: linksIn(LinkCategory.sounds),
  );
});

/// Everything in My Collections as one list, newest first. Read from the
/// existing recipe stores and the links table; nothing is copied.
final collectionItemsProvider = Provider<List<RecentItem>>((ref) {
  final catalogue = ref.watch(catalogueProvider);
  final saved = ref.watch(savedRecipeRefsProvider).value ?? const [];
  final mine = ref.watch(personalRecipesProvider).value ?? const [];
  final links = ref.watch(collectionLinksProvider).value ?? const [];
  final items = <RecentItem>[
    for (final r in saved)
      RecentItem(
        id: 'saved-${r.id}',
        title: r.title,
        badge: 'Recipe',
        detail: r.isExternal
            ? (r.providerId == 'themealdb' ? 'TheMealDB' : r.providerId)
            : 'From Moon Cycle',
        savedAt: r.savedAt,
        route: Routes.recipe(r.refId),
        category: CollectionCategory.recipes,
        image: (() {
          final recipe = catalogue.recipe(r.refId);
          return recipe == null ? null : recipeImage(recipe);
        })(),
      ),
    for (final p in mine)
      RecentItem(
        id: 'mine-${p.id}',
        title: p.recipe.title,
        badge: 'Recipe',
        detail: 'Added by you',
        savedAt: p.createdAt,
        route: Routes.recipe(p.id),
        category: CollectionCategory.recipes,
        image: recipeImage(p.recipe),
      ),
    for (final l in links)
      RecentItem(
        id: 'link-${l.id}',
        title: l.title,
        badge: l.source,
        detail: l.creator ?? 'Saved link',
        savedAt: l.createdAt,
        route: Routes.collectionLink(l.id),
        category: switch (l.category) {
          LinkCategory.recipes => CollectionCategory.recipes,
          LinkCategory.workouts => CollectionCategory.workouts,
          LinkCategory.sounds => CollectionCategory.spa,
        },
      ),
  ]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  return items;
});

/// Recently saved across all three categories.
final recentlySavedProvider = Provider<List<RecentItem>>(
  (ref) => ref.watch(collectionItemsProvider).take(recentlySavedCount).toList(),
);

/// Opens an address in the system browser or the source's own app. Tests
/// replace it; it returns whether something opened.
final linkLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);
