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
import '../application/hub_providers.dart';
import '../domain/hub_item.dart';

/// The Move and Relax tabs: a hub of sections, like Eat. A library section
/// says how many reviewed items it holds, or that none are ready yet; a
/// "My ..." section opens what the user has saved.
class HubHomePage extends ConsumerWidget {
  const HubHomePage.move({super.key})
    : tab = AppTab.move,
      intro =
          'Gentle ways to move, at your own pace. Browse, save what you '
          'like, or put a routine together.',
      phase = Phase.luteal,
      sections = const [
        HubSection(
          'exercises',
          MoonIconName.move,
          'Exercises',
          kind: HubKind.exercise,
        ),
        HubSection(
          'workouts',
          MoonIconName.play,
          'Workouts',
          kind: HubKind.workout,
        ),
        HubSection(
          'routine',
          MoonIconName.clock,
          'Build Your Routine',
          body: 'String saved workouts into a routine',
          route: Routes.collectionRoutines,
        ),
        HubSection(
          'mine',
          MoonIconName.bookmark,
          'My Workouts',
          saved: CollectionCategory.workouts,
          route: Routes.collectionWorkouts,
        ),
      ];

  const HubHomePage.relax({super.key})
    : tab = AppTab.relax,
      intro =
          'Small moments of calm: breathing, listening and simple rituals. '
          'Save the ones you come back to.',
      phase = Phase.ovulatory,
      sections = const [
        HubSection(
          'meditations',
          MoonIconName.relax,
          'Meditations',
          kind: HubKind.meditation,
        ),
        HubSection('sounds', MoonIconName.play, 'Sounds', kind: HubKind.sound),
        HubSection('spa', MoonIconName.cup, 'Spa', kind: HubKind.ritual),
        HubSection(
          'mine',
          MoonIconName.bookmark,
          'My Spa',
          saved: CollectionCategory.spa,
          route: Routes.collectionSpa,
        ),
      ];

  final AppTab tab;
  final String intro;
  final Phase phase;
  final List<HubSection> sections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final summary = ref.watch(collectionSummaryProvider);
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
                child: Text(
                  tab.label,
                  style: MoonType.h1.copyWith(color: c.text),
                ),
              ),
              const SizedBox(height: 10),
              Text(intro, style: dmSans(15, height: 1.5, color: c.textMuted)),
              const SizedBox(height: 22),
              for (final s in sections) ...[
                _SectionCard(
                  key: ValueKey('hub-${tab.name}-${s.key}'),
                  section: s,
                  phase: phase,
                  body: s.body ?? _body(ref, s, summary),
                  onTap: () => context.push(
                    s.route ?? Routes.hubLibrary(tab, s.kind!.json),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _body(WidgetRef ref, HubSection s, CollectionSummary summary) {
    if (s.saved != null) {
      final n = summary.of(s.saved!);
      return n == 0
          ? 'Nothing saved yet'
          : '$n saved ${n == 1 ? 'item' : 'items'}';
    }
    final n = ref.watch(hubItemsOfKindProvider(s.kind!)).length;
    return n == 0 ? 'Being prepared and reviewed' : '$n to browse';
  }
}

class HubSection {
  const HubSection(
    this.key,
    this.icon,
    this.title, {
    this.kind,
    this.saved,
    this.body,
    this.route,
  });

  final String key;
  final MoonIconName icon;
  final String title;
  final HubKind? kind;
  final CollectionCategory? saved;
  final String? body;
  final String? route;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.section,
    required this.phase,
    required this.body,
    required this.onTap,
  });

  final HubSection section;
  final Phase phase;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final palette = c.phase(phase);
    return Pressable(
      onTap: onTap,
      semanticLabel: '${section.title}. $body',
      child: Container(
        constraints: const BoxConstraints(minHeight: 84),
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: palette.tint,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: MoonIcon(section.icon, size: 22, color: palette.text),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
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
