import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router/routes.dart';
import '../../generation/application/generation_providers.dart';
import '../../generation/data/saved_recipe_repository.dart';
import '../data/collection_link_repository.dart';
import '../domain/collection_link.dart';

/// The three My Collections categories. Workouts and sounds fill in as their
/// libraries arrive; recipes are the existing saved and written recipes.
enum CollectionCategory { recipes, workouts, sounds }

/// One line in "Recently saved": something from any category, newest first.
final class RecentItem {
  const RecentItem({
    required this.id,
    required this.title,
    required this.kind,
    required this.savedAt,
    required this.route,
    required this.category,
  });

  final String id;
  final String title;

  /// "Saved recipe", "Your recipe"...
  final String kind;
  final DateTime savedAt;

  /// Where tapping it goes.
  final String route;
  final CollectionCategory category;
}

/// How many are shown on the landing page.
const recentlySavedCount = 5;

/// The number of items in each category (recipes: saved plus written).
final collectionCountsProvider = Provider<Map<CollectionCategory, int>>((ref) {
  final saved = ref.watch(savedRecipeRefsProvider).value ?? const [];
  final mine = ref.watch(personalRecipesProvider).value ?? const [];
  final links = ref.watch(collectionLinksProvider).value ?? const [];
  int linksIn(LinkCategory c) => links.where((l) => l.category == c).length;
  return {
    CollectionCategory.recipes:
        saved.length + mine.length + linksIn(LinkCategory.recipes),
    CollectionCategory.workouts: linksIn(LinkCategory.workouts),
    CollectionCategory.sounds: linksIn(LinkCategory.sounds),
  };
});

/// Recently saved across all three categories, newest first. Read from the
/// existing recipe stores; nothing is copied.
final recentlySavedProvider = Provider<List<RecentItem>>((ref) {
  final saved = ref.watch(savedRecipeRefsProvider).value ?? const [];
  final mine = ref.watch(personalRecipesProvider).value ?? const [];
  final links = ref.watch(collectionLinksProvider).value ?? const [];
  final items = <RecentItem>[
    for (final r in saved)
      RecentItem(
        id: 'saved-${r.id}',
        title: r.title,
        kind: 'Saved recipe',
        savedAt: r.savedAt,
        route: Routes.recipe(r.refId),
        category: CollectionCategory.recipes,
      ),
    for (final p in mine)
      RecentItem(
        id: 'mine-${p.id}',
        title: p.recipe.title,
        kind: 'Your recipe',
        savedAt: p.createdAt,
        route: Routes.recipe(p.id),
        category: CollectionCategory.recipes,
      ),
    for (final l in links)
      RecentItem(
        id: 'link-${l.id}',
        title: l.title,
        kind:
            '${l.category.label.replaceAll(RegExp(r's$'), '')} link · '
            '${l.source}',
        savedAt: l.createdAt,
        route: Routes.collectionLink(l.id),
        category: CollectionCategory.values.byName(l.category.name),
      ),
  ]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  return items.take(recentlySavedCount).toList();
});

/// Opens an address in the system browser or the source's own app. Tests
/// replace it; it returns whether something opened.
final linkLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);
