import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/shell/tab_scroll.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/hub_card.dart';
import '../../../core/design/widgets/hub_hero.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../collections/application/collections_providers.dart';
import '../../cycle/application/viewing_phase.dart';
import '../../cycle/presentation/phase_overline.dart';
import '../application/hub_providers.dart';
import '../domain/hub_item.dart';

/// The Move and Relax tabs: a hub laid out like Eat (phase line and title, a
/// hero card, then the section cards in the colours of the phase being
/// viewed). A library section says how many reviewed items it holds, or that
/// none are ready yet; a "My ..." section opens what the user has saved.
class HubHomePage extends ConsumerWidget {
  const HubHomePage.move({super.key})
    : tab = AppTab.move,
      heroAsset = 'assets/images/home/home_move_yoga_mat.jpg',
      heroHeading = 'Move your way',
      heroBody =
          'Gentle ways to move at your own pace, whatever your phase. Browse, '
          'save what you like, or build a workout.',
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
          'build',
          MoonIconName.plus,
          'Build Your Workout',
          body: 'Put a workout together from exercises',
          route: Routes.buildWorkout,
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
      heroAsset = 'assets/images/home/home_relax_tea.jpg',
      heroHeading = 'Make a moment of calm',
      heroBody =
          'Breathing, listening and simple rituals. Save the ones you come '
          'back to.',
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

  /// The hero photograph: an image already in the app that fits the section,
  /// standing in until a dedicated one is approved (docs/hero-image-requests.md).
  final String heroAsset;
  final String heroHeading;
  final String heroBody;
  final List<HubSection> sections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final summary = ref.watch(collectionSummaryProvider);
    final phase = ref.watch(viewingPhaseProvider);
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PhaseOverline(),
                  Semantics(
                    header: true,
                    child: Text(
                      tab.label,
                      style: MoonType.h1.copyWith(color: c.text),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              HubHero(asset: heroAsset, heading: heroHeading, body: heroBody),
              const SizedBox(height: 16),
              for (final s in sections) ...[
                HubCard(
                  key: ValueKey('hub-${tab.name}-${s.key}'),
                  icon: s.icon,
                  phase: phase,
                  title: s.title,
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

/// One card on a hub.
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
