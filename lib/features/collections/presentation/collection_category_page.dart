import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/widgets/centered_header.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/domain/phase.dart';
import '../application/collections_providers.dart';
import '../data/collection_link_repository.dart';
import '../domain/collection_link.dart';
import 'widgets/link_card.dart';

/// My Workouts or My Spa: the links saved here. Moon Cycle's own workouts
/// and sounds will join them when that content exists; until then this says so
/// plainly and offers no button that does nothing.
class CollectionCategoryPage extends ConsumerWidget {
  const CollectionCategoryPage({super.key, required this.category});

  final CollectionCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final workouts = category == CollectionCategory.workouts;
    final linkCategory = workouts ? LinkCategory.workouts : LinkCategory.sounds;
    final links = [
      for (final l
          in ref.watch(collectionLinksProvider).value ??
              const <CollectionLink>[])
        if (l.category == linkCategory) l,
    ];
    Widget gutter(Widget child, {double top = 0}) => Padding(
      padding: EdgeInsets.fromLTRB(MoonSpace.gutter, top, MoonSpace.gutter, 0),
      child: child,
    );
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CenteredHeader(
              title: workouts ? 'My Workouts' : 'My Spa',
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(Routes.collections),
              trailingIcon: MoonIconName.plus,
              trailingLabel: 'Add a link',
              trailingKey: const ValueKey('add-link-plus'),
              onTrailing: () => context.push(
                Routes.collectionLinkNew(category: linkCategory.name),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 42 + 76),
                children: [
                  if (links.isEmpty)
                    gutter(
                      EmptyState(
                        icon: workouts ? MoonIconName.move : MoonIconName.relax,
                        title: workouts
                            ? 'No workouts saved yet'
                            : 'Nothing in My Spa yet',
                        body: workouts
                            ? 'Save a link to a workout you like with the plus, '
                                  'and it will be kept here, privately on this '
                                  'phone.'
                            : 'Save a link to a meditation, breathing '
                                  'session, sleep story, relaxing sound or '
                                  'self-care ritual you like with the plus, and '
                                  'it will be kept here, privately on this '
                                  'phone.',
                        palette: c.phase(
                          workouts ? Phase.luteal : Phase.ovulatory,
                        ),
                      ),
                      top: 24,
                    )
                  else
                    for (final l in links)
                      gutter(CollectionLinkCard(link: l), top: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
