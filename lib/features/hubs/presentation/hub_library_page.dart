import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/centered_header.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../../core/domain/phase.dart';
import '../../collections/domain/collection_link.dart';
import '../../collections/presentation/widgets/collection_chips.dart';
import '../application/hub_providers.dart';
import '../domain/hub_item.dart';

/// Which tab a kind belongs to, and which saved-link category its links use.
AppTab hubTabOf(HubKind k) => k.isMovement ? AppTab.move : AppTab.relax;
LinkCategory hubLinkCategory(HubKind k) =>
    k.isMovement ? LinkCategory.workouts : LinkCategory.sounds;

/// A browsable library: the approved items of one kind, optionally narrowed by
/// a practical category. With none approved yet it says so plainly and offers
/// the one thing that works, saving a link of your own.
class HubLibraryPage extends ConsumerStatefulWidget {
  const HubLibraryPage({super.key, required this.kind});

  final HubKind kind;

  @override
  ConsumerState<HubLibraryPage> createState() => _HubLibraryPageState();
}

class _HubLibraryPageState extends ConsumerState<HubLibraryPage> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final kind = widget.kind;
    final tab = hubTabOf(kind);
    final all = ref.watch(hubItemsOfKindProvider(kind));
    final categories = <String>{for (final i in all) ?i.category}.toList()
      ..sort();
    final category = categories.contains(_category) ? _category : null;
    final items = [
      for (final i in all)
        if (category == null || i.category == category) i,
    ];
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CenteredHeader(
              title: kind.label,
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(tab.path),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  MoonSpace.gutter,
                  14,
                  MoonSpace.gutter,
                  40,
                ),
                children: [
                  if (categories.length > 1) ...[
                    CollectionChips(
                      options: [
                        ('All', all.length),
                        for (final k in categories)
                          (k, all.where((i) => i.category == k).length),
                      ],
                      selected: category == null
                          ? 0
                          : categories.indexOf(category) + 1,
                      onSelected: (i) => setState(
                        () => _category = i == 0 ? null : categories[i - 1],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (all.isEmpty)
                    EmptyState(
                      icon: tab == AppTab.move
                          ? MoonIconName.move
                          : MoonIconName.relax,
                      title: 'Nothing here yet',
                      body: _emptyBody(kind),
                      palette: c.phase(
                        tab == AppTab.move ? Phase.luteal : Phase.ovulatory,
                      ),
                      actions: [
                        TextLink(
                          kind.isMovement
                              ? 'Save a workout link'
                              : 'Save a link to My Spa',
                          onTap: () => context.push(
                            Routes.collectionLinkNew(
                              category: hubLinkCategory(kind).name,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    for (final i in items) ...[
                      _ItemRow(item: i, tab: tab),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _emptyBody(HubKind k) => switch (k) {
    HubKind.exercise =>
      'Moon Cycle’s exercises are being written and reviewed before they '
          'appear. Nothing is shown until it has been checked.',
    HubKind.workout =>
      'Moon Cycle’s workouts are being written and reviewed before they '
          'appear. Nothing is shown until it has been checked.',
    HubKind.meditation =>
      'Short meditations and breathing sessions are being written and '
          'reviewed before they appear.',
    HubKind.sound =>
      'Calming sounds need confirmed rights before they can be added, so '
          'none are here yet.',
    HubKind.ritual =>
      'Simple spa rituals are being written and reviewed before they appear.',
  };
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.tab});

  final HubItem item;
  final AppTab tab;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final meta = [
      if (item.durationMinutes != null) '${item.durationMinutes} min',
      if (item.intensity != null) item.intensity!,
      if (item.category != null) item.category!,
    ].join(' · ');
    return Pressable(
      key: ValueKey('hub-item-${item.id}'),
      onTap: () => context.push(Routes.hubItem(tab, item.id)),
      semanticLabel: [item.title, if (meta.isNotEmpty) meta].join('. '),
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
        decoration: BoxDecoration(
          color: c.raised,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: fraunces(18, height: 1.2, color: c.text),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        style: dmSans(13, height: 1.3, color: c.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              MoonIcon(MoonIconName.chev, size: 16, color: c.chevron),
            ],
          ),
        ),
      ),
    );
  }
}
