import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/shell/tab_scroll.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/domain/phase.dart';
import '../../content/application/content_providers.dart';
import '../../cycle/application/cycle_providers.dart';
import '../../cycle/application/viewing_phase.dart';
import '../../cycle/presentation/log_period_sheet.dart';
import '../../diary/application/diary_providers.dart';
import '../../shopping/application/shopping_summary.dart';
import 'widgets/home_hero.dart';
import 'widgets/home_photos.dart';
import 'widgets/home_sections.dart';
import 'widgets/home_v2.dart';

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
    // Read-only live counts for Quick access.
    final diaryCount = ref.watch(todayDiaryEntryCountProvider);
    final toBuy = ref.watch(shoppingSummaryProvider).toBuy;
    Widget padded(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: child,
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: ListView(
        controller: ref.watch(tabScrollProvider).of(AppTab.home),
        padding: const EdgeInsets.only(bottom: 42 + 76),
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
              body: catalogue.phase(phase).homeFocus,
              onMore: () => context.push(Routes.learnMore),
            ),
          ),
          const SizedBox(height: 28),
          padded(const HomeOverline('Today’s picks')),
          const SizedBox(height: 12),
          padded(
            Column(
              children: [
                PickBlock(
                  photoOnLeft: true,
                  asset: homePhotos.eat.asset,
                  focus: homePhotos.eat.focus,
                  label: 'EAT',
                  labelColor: c.phase(Phase.follicular).text,
                  title: '3 plants',
                  body: 'Three plants chosen for your phase today.',
                  link: 'See the plants',
                  onTap: () => context.push(Routes.threePlants),
                ),
                const SizedBox(height: 18),
                PickBlock(
                  photoOnLeft: false,
                  divider: true,
                  asset: homePhotos.move.asset,
                  focus: homePhotos.move.focus,
                  label: 'MOVE',
                  labelColor: c.phase(Phase.luteal).text,
                  title: '3 ways to move',
                  body: 'Three movement ideas. Pick what feels right.',
                  link: 'Choose a movement',
                  onTap: () => context.go(AppTab.move.path),
                ),
                const SizedBox(height: 18),
                PickBlock(
                  photoOnLeft: true,
                  divider: true,
                  asset: homePhotos.relax.asset,
                  focus: homePhotos.relax.focus,
                  label: 'RELAX',
                  labelColor: c.phase(Phase.ovulatory).text,
                  title: '3 minutes of calm',
                  body: 'A short breathing or mindfulness pause.',
                  link: 'Start a pause',
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
                  asset: 'assets/images/home/quick_my_diary.jpg',
                  title: 'My Diary',
                  subtitle: diaryEntriesToday(diaryCount),
                  onTap: () => context.push(Routes.diary),
                );
                final shopping = QuickAccessCard(
                  asset: 'assets/images/home/quick_shopping_list.jpg',
                  title: 'Shopping List',
                  subtitle: shoppingToBuy(toBuy),
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
                    : IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: diary),
                            const SizedBox(width: 10),
                            Expanded(child: shopping),
                          ],
                        ),
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}
