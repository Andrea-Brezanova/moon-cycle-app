import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/shell/tab_scroll.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/domain/phase.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../cycle/application/cycle_providers.dart';
import '../../cycle/application/viewing_phase.dart';
import '../../cycle/presentation/log_period_sheet.dart';
import '../../foods/presentation/food_emoji.dart';
import '../../plants/application/plant_providers.dart';
import 'widgets/home_hero.dart';
import 'widgets/home_sections.dart';
import 'widgets/home_v2.dart';
import 'widgets/plant_photos.dart';

/// The Home tab (`06-home`): the shared viewing phase, moved by dragging the
/// moon. It starts on the user's real phase.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// From 3 days late, Home asks whether the period has started (spec §7.2).
  static const latePromptAfterDays = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final state = ref.watch(cycleStateProvider).value;
    if (state == null) return Scaffold(backgroundColor: c.bg);

    // Every phase-dependent block follows the shared viewing phase.
    final phase = ref.watch(viewingPhaseProvider);
    final catalogue = ref.watch(catalogueProvider);
    final late = state.isLate && state.daysLate >= latePromptAfterDays;
    final plants = ref.watch(threePlantsProvider);
    Widget padded(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: MoonSpace.gutter),
      child: child,
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: ListView(
        controller: ref.watch(tabScrollProvider).of(AppTab.home),
        padding: const EdgeInsets.only(bottom: 42),
        children: [
          HomeHero(state: state),
          // The late card and the preview's pill sit closer to the content.
          SizedBox(height: late ? 8 : 28),
          if (late) ...[
            padded(LatePeriodCard(onLog: () => showLogPeriodSheet(context))),
            const SizedBox(height: 28),
          ],
          padded(const HomeOverline('Today’s focus')),
          const SizedBox(height: 12),
          padded(
            TodaysFocusCard(
              phase: phase,
              headline: catalogue.phase(phase).tagline,
              body: catalogue.phase(phase).summary,
              onMore: () => context.push(Routes.learnMore),
            ),
          ),
          const SizedBox(height: 28),
          padded(const HomeOverline('3 a day')),
          const SizedBox(height: 12),
          padded(
            Column(
              children: [
                DailyCard(
                  label: 'EAT',
                  title: '3 plants',
                  body: 'Discover three plants selected for your phase today.',
                  accent: c.phase(Phase.follicular).text,
                  accentFill: c.phase(Phase.follicular).tint,
                  image: plantImage(
                    _featured(plants),
                    c.sand,
                    plants.isEmpty ? '🌱' : foodEmoji(plants.first),
                  ),
                  semanticLabel:
                      '3 plants. Discover three plants selected '
                      'for your phase today',
                  onTap: () => context.push(Routes.threePlants),
                ),
                const SizedBox(height: 10),
                DailyCard(
                  label: 'MOVE',
                  title: '3 ways to move',
                  body: 'Three movement ideas. Pick the one that feels right.',
                  accent: c.phase(Phase.luteal).text,
                  accentFill: c.phase(Phase.luteal).tint,
                  image: PlaceholderImage(
                    tone: c.phase(Phase.luteal).tint,
                    icon: MoonIconName.move,
                  ),
                  semanticLabel: '3 ways to move. Three movement ideas',
                  onTap: () => context.go(AppTab.move.path),
                ),
                const SizedBox(height: 10),
                DailyCard(
                  label: 'RELAX',
                  title: '3 minutes of calm',
                  body:
                      'A short breathing or mindfulness pause. '
                      'Stay longer if you like.',
                  accent: c.phase(Phase.ovulatory).text,
                  accentFill: c.phase(Phase.ovulatory).tint,
                  image: PlaceholderImage(
                    tone: c.phase(Phase.ovulatory).tint,
                    icon: MoonIconName.relax,
                  ),
                  semanticLabel: '3 minutes of calm. A short pause',
                  onTap: () => context.go(AppTab.relax.path),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          padded(const HomeOverline('Quick access')),
          const SizedBox(height: 12),
          padded(
            LayoutBuilder(
              builder: (context, box) {
                final diary = QuickAccessCard(
                  icon: MoonIconName.document,
                  title: 'My Diary',
                  onTap: () => context.push(Routes.diary),
                );
                final shopping = QuickAccessCard(
                  icon: MoonIconName.basket,
                  title: 'Shopping List',
                  onTap: () => context.go(Routes.shopping),
                );
                // Narrow screens and large text stack the two cards.
                final stacked =
                    box.maxWidth < 340 ||
                    MediaQuery.textScalerOf(context).scale(14) > 18;
                return stacked
                    ? Column(
                        children: [diary, const SizedBox(height: 10), shopping],
                      )
                    : Row(
                        children: [
                          Expanded(child: diary),
                          const SizedBox(width: 10),
                          Expanded(child: shopping),
                        ],
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The day's plant to picture: the first with a curated photo, else the first.
Food? _featured(List<Food> plants) {
  for (final f in plants) {
    if (plantPhotos.containsKey(f.id)) return f;
  }
  return plants.isEmpty ? null : plants.first;
}
