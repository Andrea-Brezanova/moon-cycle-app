import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/domain/phase.dart';
import '../application/collections_providers.dart';
import 'collection_photos.dart';

/// My Collections: a large My Recipes tile, My Workouts and My Spa, a search
/// over everything saved, and what was saved most recently. All counts and
/// rows come from the real stores (the recipe tables and the links table); it
/// keeps no copy of anything.
class CollectionsPage extends ConsumerStatefulWidget {
  const CollectionsPage({super.key});

  @override
  ConsumerState<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends ConsumerState<CollectionsPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final summary = ref.watch(collectionSummaryProvider);
    final recent = ref.watch(recentlySavedProvider);
    final q = _query.trim().toLowerCase();
    final results = q.isEmpty
        ? const <RecentItem>[]
        : [
            for (final i in ref.watch(collectionItemsProvider))
              if ('${i.title} ${i.badge} ${i.detail}'.toLowerCase().contains(q))
                i,
          ];

    Widget gutter(Widget child, {double top = 0}) => Padding(
      padding: EdgeInsets.fromLTRB(MoonSpace.gutter, top, MoonSpace.gutter, 0),
      child: child,
    );

    String recipesLine() {
      final parts = [
        if (summary.recipesSaved > 0) '${summary.recipesSaved} saved',
        if (summary.recipesMine > 0) '${summary.recipesMine} added by me',
        if (summary.recipeLinks > 0)
          '${summary.recipeLinks} ${summary.recipeLinks == 1 ? 'link' : 'links'}',
      ];
      return parts.isEmpty ? 'Nothing saved yet' : parts.join(' · ');
    }

    String linksLine(int n) =>
        n == 0 ? 'Nothing yet' : '$n saved ${n == 1 ? 'link' : 'links'}';

    final workouts = _Tile(
      key: const ValueKey('collection-workouts'),
      category: CollectionCategory.workouts,
      title: 'My Workouts',
      line: linksLine(summary.workoutLinks),
      onTap: () => context.push(Routes.collectionWorkouts),
    );
    final spa = _Tile(
      key: const ValueKey('collection-spa'),
      category: CollectionCategory.spa,
      title: 'My Spa',
      line: linksLine(summary.spaLinks),
      onTap: () => context.push(Routes.collectionSpa),
    );
    final narrow =
        MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(14) > 18;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 42 + 76),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
              child: Row(
                children: [
                  Pressable(
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go(AppTab.more.path),
                    semanticLabel: 'Back to Me',
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: MoonIcon(
                          MoonIconName.back,
                          size: 22,
                          color: c.text,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Pressable(
                    key: const ValueKey('add-to-collections'),
                    onTap: () => context.push(Routes.collectionLinkNew()),
                    semanticLabel: 'Add to My Collections',
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: c.inverseBg,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: MoonIcon(
                            MoonIconName.plus,
                            size: 20,
                            color: c.inverseText,
                            strokeWidth: 2.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            gutter(
              Semantics(
                header: true,
                child: Text(
                  'My Collections',
                  style: fraunces(34, height: 1.1, color: c.text),
                ),
              ),
              top: 4,
            ),
            gutter(
              Text(
                'Things you love, save or want to try.',
                style: dmSans(15, height: 1.45, color: c.textMuted),
              ),
              top: 6,
            ),
            gutter(
              MoonTextField(
                hint: 'Search your collections',
                leadingIcon: MoonIconName.search,
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                trailing: _query.isEmpty
                    ? null
                    : Pressable(
                        onTap: () => setState(() {
                          _search.clear();
                          _query = '';
                        }),
                        semanticLabel: 'Clear search',
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: MoonIcon(
                            MoonIconName.close,
                            size: 16,
                            color: c.textMuted,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
              ),
              top: 16,
            ),
            if (q.isNotEmpty) ...[
              gutter(
                Text(
                  results.isEmpty
                      ? 'Nothing matches “${_query.trim()}”.'
                      : '${results.length} ${results.length == 1 ? 'result' : 'results'}',
                  style: dmSans(13, height: 1.4, color: c.textMuted),
                ),
                top: 18,
              ),
              for (final item in results) gutter(_ItemRow(item: item), top: 10),
            ] else ...[
              gutter(
                _Tile(
                  key: const ValueKey('collection-recipes'),
                  category: CollectionCategory.recipes,
                  title: 'My Recipes',
                  line: recipesLine(),
                  big: true,
                  onTap: () => context.push(Routes.myRecipes),
                ),
                top: 18,
              ),
              gutter(
                narrow
                    ? Column(
                        children: [workouts, const SizedBox(height: 12), spa],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: workouts),
                          const SizedBox(width: 12),
                          Expanded(child: spa),
                        ],
                      ),
                top: 12,
              ),
              gutter(const Overline('Recently saved'), top: 30),
              if (recent.isEmpty)
                gutter(
                  EmptyState(
                    icon: MoonIconName.heart,
                    title: 'Nothing saved yet',
                    body:
                        'Tap the heart on a recipe, or add your own link, and '
                        'it will appear here.',
                    palette: c.phase(Phase.follicular),
                  ),
                  top: 10,
                )
              else
                for (final item in recent)
                  gutter(_ItemRow(item: item), top: 10),
            ],
          ],
        ),
      ),
    );
  }
}

/// A category tile: photograph on top, title and live count below. The large
/// version (My Recipes) has a taller photograph.
class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.category,
    required this.title,
    required this.line,
    required this.onTap,
    this.big = false,
  });

  final CollectionCategory category;
  final String title;
  final String line;
  final VoidCallback onTap;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Pressable(
      onTap: onTap,
      semanticLabel: '$title. $line',
      child: Container(
        decoration: BoxDecoration(
          color: c.raised,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: big ? 2.3 : 1.55,
              child: CollectionPhoto(category),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: fraunces(
                            big ? 22 : 18,
                            height: 1.15,
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          line,
                          style: dmSans(13, height: 1.35, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  MoonIcon(
                    MoonIconName.chev,
                    size: 16,
                    color: c.textMuted,
                    strokeWidth: 2,
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

/// A row in Recently saved or in the search results: a thumbnail (the
/// recipe's photo, or the category's icon), the title, a small source badge and
/// who it is from.
class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final RecentItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final icon = switch (item.category) {
      CollectionCategory.recipes => MoonIconName.recipes,
      CollectionCategory.workouts => MoonIconName.move,
      CollectionCategory.spa => MoonIconName.relax,
    };
    return Pressable(
      key: ValueKey(item.id),
      onTap: () => context.push(item.route),
      semanticLabel: '${item.title}, ${item.badge}, ${item.detail}',
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
        decoration: BoxDecoration(
          color: c.raised,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: item.image != null
                      ? Image(image: item.image!, fit: BoxFit.cover)
                      : ColoredBox(
                          color: c.sand,
                          child: Center(
                            child: MoonIcon(icon, size: 22, color: c.textMuted),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: fraunces(16.5, height: 1.2, color: c.text),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: c.sand,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item.badge,
                            style: dmSans(
                              11.5,
                              weight: FontWeight.w700,
                              height: 1.3,
                              color: c.text,
                            ),
                          ),
                        ),
                        Text(
                          item.detail,
                          style: dmSans(12.5, height: 1.3, color: c.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              MoonIcon(
                MoonIconName.chev,
                size: 15,
                color: c.textMuted,
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
