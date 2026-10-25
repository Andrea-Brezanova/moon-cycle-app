import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/shell/tab_scroll.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/domain/phase.dart';
import '../../collections/application/collections_providers.dart';
import '../../collections/domain/collection_link.dart';

/// The Move and Relax tabs until Moon Cycle's own workouts, meditations and
/// audio are written, reviewed and approved. It offers only what works today:
/// open your saved items, or save a link. It says plainly that the rest is on
/// its way and shows no inert buttons and no sample content.
class CollectionHubPage extends ConsumerWidget {
  const CollectionHubPage.move({super.key})
    : tab = AppTab.move,
      title = 'Move',
      icon = MoonIconName.move,
      phase = Phase.luteal,
      category = CollectionCategory.workouts,
      linkCategory = LinkCategory.workouts,
      openTitle = 'Your workouts',
      addTitle = 'Save a workout link',
      note =
          'Moon Cycle’s own beginner-friendly workouts are being prepared '
          'and reviewed. Until then, keep the ones you like here.',
      openRoute = Routes.collectionWorkouts;

  const CollectionHubPage.relax({super.key})
    : tab = AppTab.relax,
      title = 'Relax',
      icon = MoonIconName.relax,
      phase = Phase.ovulatory,
      category = CollectionCategory.spa,
      linkCategory = LinkCategory.sounds,
      openTitle = 'Your spa',
      addTitle = 'Save a meditation or sound link',
      note =
          'Moon Cycle’s own breathing and relaxation sessions are being '
          'prepared and reviewed. Until then, keep the ones you like here.',
      openRoute = Routes.collectionSpa;

  final AppTab tab;
  final String title;
  final MoonIconName icon;
  final Phase phase;
  final CollectionCategory category;
  final LinkCategory linkCategory;
  final String openTitle;
  final String addTitle;
  final String note;
  final String openRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final count = ref.watch(collectionSummaryProvider).of(category);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          controller: ref.watch(tabScrollProvider).of(tab),
          padding: const EdgeInsets.fromLTRB(
            MoonSpace.gutter,
            10,
            MoonSpace.gutter,
            42,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: MoonType.h1.copyWith(color: c.text)),
              ),
              const SizedBox(height: 10),
              Text(note, style: dmSans(15, height: 1.5, color: c.textMuted)),
              const SizedBox(height: 22),
              _Card(
                key: ValueKey('hub-open-${tab.name}'),
                icon: icon,
                phase: phase,
                title: openTitle,
                body: count == 0
                    ? 'Nothing saved yet'
                    : '$count saved ${count == 1 ? 'item' : 'items'}',
                onTap: () => context.push(openRoute),
              ),
              const SizedBox(height: 12),
              _Card(
                key: ValueKey('hub-add-${tab.name}'),
                icon: MoonIconName.plus,
                phase: phase,
                title: addTitle,
                body: 'Kept privately on this phone',
                onTap: () => context.push(
                  Routes.collectionLinkNew(category: linkCategory.name),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A full-width card like the ones on the Eat hub: tinted icon disc, title, a
/// line, a chevron.
class _Card extends StatelessWidget {
  const _Card({
    super.key,
    required this.icon,
    required this.phase,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final MoonIconName icon;
  final Phase phase;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final palette = c.phase(phase);
    return Pressable(
      onTap: onTap,
      semanticLabel: '$title. $body',
      child: Container(
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
        decoration: BoxDecoration(
          color: c.raised,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(22),
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: palette.tint,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: MoonIcon(icon, size: 24, color: palette.text),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: fraunces(21, height: 1.15, color: c.text),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: dmSans(14, height: 1.4, color: c.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              MoonIcon(MoonIconName.chev, size: 18, color: c.chevron),
            ],
          ),
        ),
      ),
    );
  }
}
