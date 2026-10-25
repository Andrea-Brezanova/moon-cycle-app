import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/widgets/centered_header.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/domain/phase.dart';
import '../application/collections_providers.dart';

/// My Collections: the three categories (recipes, workouts, sounds) and what
/// was saved most recently across them. Reads the existing recipe stores; it
/// keeps no copy of anything.
class CollectionsPage extends ConsumerWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final counts = ref.watch(collectionCountsProvider);
    final recent = ref.watch(recentlySavedProvider);

    String count(CollectionCategory category) {
      final n = counts[category] ?? 0;
      return n == 0 ? 'Nothing yet' : '$n ${n == 1 ? 'item' : 'items'}';
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CenteredHeader(
              title: 'My Collections',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go('/more'),
              trailingIcon: MoonIconName.plus,
              trailingLabel: 'Add a link to My Collections',
              trailingKey: const ValueKey('add-to-collections'),
              onTrailing: () => context.push(Routes.collectionLinkNew()),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  MoonSpace.gutter,
                  14,
                  MoonSpace.gutter,
                  42 + 76,
                ),
                children: [
                  MoonListGroup(
                    children: [
                      MoonListRow(
                        key: const ValueKey('collection-recipes'),
                        label: 'My Recipes',
                        icon: MoonIconName.recipes,
                        subtitle: count(CollectionCategory.recipes),
                        onTap: () => context.push(Routes.myRecipes),
                      ),
                      MoonListRow(
                        key: const ValueKey('collection-workouts'),
                        label: 'My Workouts',
                        icon: MoonIconName.move,
                        subtitle: count(CollectionCategory.workouts),
                        onTap: () => context.push(Routes.collectionWorkouts),
                      ),
                      MoonListRow(
                        key: const ValueKey('collection-sounds'),
                        label: 'My Sounds',
                        icon: MoonIconName.relax,
                        subtitle: count(CollectionCategory.sounds),
                        onTap: () => context.push(Routes.collectionSounds),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Overline('Recently saved'),
                  const SizedBox(height: 10),
                  if (recent.isEmpty)
                    EmptyState(
                      icon: MoonIconName.heart,
                      title: 'Nothing saved yet',
                      body:
                          'Tap the heart on a recipe, or add your own, and it '
                          'will appear here.',
                      palette: c.phase(Phase.follicular),
                    )
                  else
                    MoonListGroup(
                      children: [
                        for (final item in recent)
                          MoonListRow(
                            key: ValueKey(item.id),
                            label: item.title,
                            subtitle: item.kind,
                            onTap: () => context.push(item.route),
                          ),
                      ],
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
