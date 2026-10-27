import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/widgets/centered_header.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/domain/phase.dart';
import '../../routines/data/routine_repository.dart';
import '../../routines/domain/routine.dart';
import '../application/collections_providers.dart';
import '../data/collection_link_repository.dart';
import '../domain/collection_link.dart';
import 'my_routines_page.dart' show RoutineCard;
import 'widgets/collection_chips.dart';
import 'widgets/link_row.dart';

/// My Workouts or My Spa: the links saved here, filtered by where they are
/// from. Moon Cycle's own workouts and sounds will join them when that content
/// exists; until then an empty page says so plainly and offers no button that
/// does nothing.
class CollectionCategoryPage extends ConsumerStatefulWidget {
  const CollectionCategoryPage({super.key, required this.category});

  final CollectionCategory category;

  @override
  ConsumerState<CollectionCategoryPage> createState() =>
      _CollectionCategoryPageState();
}

class _CollectionCategoryPageState
    extends ConsumerState<CollectionCategoryPage> {
  /// The chosen source; null is "All".
  LinkPlatform? _source;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final workouts = widget.category == CollectionCategory.workouts;
    final linkCategory = workouts ? LinkCategory.workouts : LinkCategory.sounds;
    final built = workouts
        ? ref.watch(builtWorkoutsProvider).value ?? const <Routine>[]
        : const <Routine>[];
    final all = <CollectionLink>[
      for (final l
          in ref.watch(collectionLinksProvider).value ??
              const <CollectionLink>[])
        if (l.category == linkCategory) l,
    ];
    // One chip per source that has something, in a steady order.
    final sources = <LinkPlatform>[
      for (final p in LinkPlatform.values)
        if (all.any((l) => l.platform == p)) p,
    ];
    final source = sources.contains(_source) ? _source : null;
    final links = <CollectionLink>[
      for (final l in all)
        if (source == null || l.platform == source) l,
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
              trailingLabel: workouts ? 'Add a workout' : 'Add to My Spa',
              trailingKey: const ValueKey('add-link-plus'),
              onTrailing: () => context.push(
                Routes.collectionLinkNew(category: linkCategory.name),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  if (sources.length > 1)
                    gutter(
                      CollectionChips(
                        options: [
                          ('All', all.length),
                          for (final p in sources)
                            (p.label, all.where((l) => l.platform == p).length),
                        ],
                        selected: source == null
                            ? 0
                            : sources.indexOf(source) + 1,
                        onSelected: (i) => setState(
                          () => _source = i == 0 ? null : sources[i - 1],
                        ),
                      ),
                      top: 14,
                    ),
                  if (workouts && built.isNotEmpty) ...[
                    gutter(const Overline('Workouts you built'), top: 18),
                    for (final w in built)
                      gutter(
                        RoutineCard(key: ValueKey('built-${w.id}'), routine: w),
                        top: 10,
                      ),
                    if (links.isNotEmpty)
                      gutter(const Overline('Saved links'), top: 24),
                  ],
                  if (links.isEmpty && !(workouts && built.isNotEmpty))
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
                            : 'Save a link to a meditation, breathing session, '
                                  'sleep story, relaxing sound or self-care '
                                  'ritual you like with the plus, and it will '
                                  'be kept here, privately on this phone.',
                        palette: c.phase(
                          workouts ? Phase.luteal : Phase.ovulatory,
                        ),
                      ),
                      top: 24,
                    )
                  else if (links.isNotEmpty)
                    gutter(CollectionLinkGroup(links: links), top: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
