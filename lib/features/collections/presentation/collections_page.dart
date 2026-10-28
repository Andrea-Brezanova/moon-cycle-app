import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
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
import '../../../core/storage/ui_prefs.dart';
import '../application/collections_providers.dart';
import 'collection_photos.dart';

/// My Collections: four equal square tiles (My Recipes, My Workouts, My Spa,
/// My Routines), a search
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

    Widget tile(String key, {bool preview = false}) => switch (key) {
      'recipes' => _Tile(
        key: preview ? null : const ValueKey('collection-recipes'),
        category: CollectionCategory.recipes,
        title: 'My Recipes',
        onTap: () => context.push(Routes.myRecipes),
      ),
      'workouts' => _Tile(
        key: preview ? null : const ValueKey('collection-workouts'),
        category: CollectionCategory.workouts,
        title: 'My Workouts',
        onTap: () => context.push(Routes.collectionWorkouts),
      ),
      'spa' => _Tile(
        key: preview ? null : const ValueKey('collection-spa'),
        category: CollectionCategory.spa,
        title: 'My Spa',
        onTap: () => context.push(Routes.collectionSpa),
      ),
      _ => _Tile(
        key: preview ? null : const ValueKey('collection-routines'),
        title: 'My Routines',
        onTap: () => context.push(Routes.collectionRoutines),
      ),
    };
    final order = ref.watch(collectionOrderProvider);
    void moveTile(String key, int to) => ref
        .read(uiPrefsProvider.notifier)
        .update(
          ref
              .read(uiPrefsProvider)
              .copyWith(collectionOrder: moveCollectionTile(order, key, to)),
        );
    final tiles = [
      for (final (i, key) in order.indexed)
        _ReorderableTile(
          key: ValueKey('cell-$key'),
          tileKey: key,
          index: i,
          count: order.length,
          title: _tileTitles[key]!,
          onMove: moveTile,
          builder: ({required bool preview}) => tile(key, preview: preview),
        ),
    ];

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
                Column(
                  children: [
                    for (var r = 0; r < 2; r++) ...[
                      if (r > 0) const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: tiles[r * 2]),
                          const SizedBox(width: 12),
                          Expanded(child: tiles[r * 2 + 1]),
                        ],
                      ),
                    ],
                  ],
                ),
                top: 18,
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

const _tileTitles = {
  'recipes': 'My Recipes',
  'workouts': 'My Workouts',
  'spa': 'My Spa',
  'routines': 'My Routines',
};

/// A tile that can be picked up with a long press and dropped on another tile
/// to change the order. Screen readers get "Move earlier" and "Move later"
/// actions instead of dragging. It never touches what a collection holds.
class _ReorderableTile extends StatelessWidget {
  const _ReorderableTile({
    super.key,
    required this.tileKey,
    required this.index,
    required this.count,
    required this.title,
    required this.onMove,
    required this.builder,
  });

  final String tileKey;
  final int index;
  final int count;
  final String title;
  final void Function(String key, int toIndex) onMove;
  final Widget Function({required bool preview}) builder;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Semantics(
      customSemanticsActions: {
        if (index > 0)
          const CustomSemanticsAction(label: 'Move earlier'): () =>
              onMove(tileKey, index - 1),
        if (index < count - 1)
          const CustomSemanticsAction(label: 'Move later'): () =>
              onMove(tileKey, index + 1),
      },
      child: DragTarget<String>(
        onWillAcceptWithDetails: (d) => d.data != tileKey,
        onAcceptWithDetails: (d) => onMove(d.data, index),
        builder: (context, over, _) => LayoutBuilder(
          builder: (context, box) => LongPressDraggable<String>(
            data: tileKey,
            feedback: SizedBox(
              width: box.maxWidth,
              child: Transform.scale(
                scale: 1.05,
                child: Material(
                  type: MaterialType.transparency,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: c.text.withValues(alpha: 0.22),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: IgnorePointer(child: builder(preview: true)),
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: IgnorePointer(child: builder(preview: true)),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: over.isEmpty ? const Color(0x00000000) : c.ochre,
                  width: 2,
                ),
              ),
              child: builder(preview: false),
            ),
          ),
        ),
      ),
    );
  }
}

/// The one tile every collection category uses: a photograph of fixed
/// proportions above a title area of fixed height, so the picture, the divider
/// and the title sit in the same place on all four tiles. It shows the title
/// only: no counts or status text.
class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    this.category,
    required this.title,
    required this.onTap,
  });

  /// Null for My Routines, which has no photograph yet.
  final CollectionCategory? category;
  final String title;
  final VoidCallback onTap;

  /// Width over height of the picture area.
  static const imageAspect = 1.25;

  static const titleSize = 17.5;
  static const titleLines = 2;
  static const titleHeightFactor = 1.15;
  static const titlePadding = EdgeInsets.fromLTRB(14, 10, 10, 12);

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    // Room for two lines at the current text size, the same on every tile.
    final scale = MediaQuery.textScalerOf(context).scale(titleSize) / titleSize;
    final titleArea =
        titlePadding.vertical +
        titleSize * titleHeightFactor * titleLines * scale;
    return Pressable(
      onTap: onTap,
      semanticLabel: title,
      child: Container(
        decoration: BoxDecoration(
          color: c.raised,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: imageAspect,
              child: category != null
                  ? CollectionPhoto(category!)
                  : ColoredBox(
                      color: c.phase(Phase.luteal).tint,
                      child: Center(
                        child: ExcludeSemantics(
                          child: MoonIcon(
                            MoonIconName.clock,
                            size: 34,
                            color: c.text,
                            strokeWidth: 1.6,
                          ),
                        ),
                      ),
                    ),
            ),
            SizedBox(
              height: titleArea,
              child: Padding(
                padding: titlePadding,
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          key: const ValueKey('tile-title'),
                          maxLines: titleLines,
                          overflow: TextOverflow.ellipsis,
                          style: fraunces(
                            titleSize,
                            height: titleHeightFactor,
                            color: c.text,
                          ),
                        ),
                      ),
                    ),
                    MoonIcon(
                      MoonIconName.chev,
                      key: const ValueKey('tile-arrow'),
                      size: 15,
                      color: c.textMuted,
                      strokeWidth: 2,
                    ),
                  ],
                ),
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
