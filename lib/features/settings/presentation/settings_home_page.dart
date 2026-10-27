import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/shell/tab_scroll.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/hub_card.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../cycle/application/viewing_phase.dart';
import '../../entitlements/application/entitlement_providers.dart';
import '../../reminders/application/reminder_providers.dart';

/// The Me tab: four destinations, as hub cards like Eat, Move and Relax.
class SettingsHomePage extends ConsumerWidget {
  const SettingsHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final phase = ref.watch(viewingPhaseProvider);

    final sections = <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('Me', style: MoonType.h1.copyWith(color: c.text)),
          ),
          const SizedBox(height: 4),
          Text(
            'Your own space in Moon Cycle.',
            style: dmSans(15, height: 1.45, color: c.textMuted),
          ),
        ],
      ),
      Column(
        children: [
          HubCard(
            key: const ValueKey('me-collections'),
            icon: MoonIconName.bookmark,
            phase: phase,
            title: 'My Collections',
            body: 'Recipes, workouts, spa and routines',
            onTap: () => context.push(Routes.collections),
          ),
          const SizedBox(height: 12),
          HubCard(
            key: const ValueKey('me-diary'),
            icon: MoonIconName.document,
            phase: phase,
            title: 'My Diary',
            body: 'What you ate, did and felt',
            onTap: () => context.push(Routes.diary),
          ),
          const SizedBox(height: 12),
          HubCard(
            key: const ValueKey('me-shopping'),
            icon: MoonIconName.shop,
            phase: phase,
            title: 'My Shopping List',
            body: 'What to buy, by aisle',
            onTap: () => context.push(Routes.shopping),
          ),
          const SizedBox(height: 12),
          HubCard(
            key: const ValueKey('me-app'),
            icon: MoonIconName.settings,
            phase: phase,
            title: 'My App',
            body: 'Settings, account and support',
            onTap: () => context.push(Routes.myApp),
          ),
        ],
      ),
      // A release build of the dev flavour made with DEV_PREMIUM=true shows
      // just the Premium test switch (off until tapped).
      if (!kDebugMode && ref.watch(devPremiumSwitchAllowedProvider))
        Center(
          child: TextLink(
            ref.watch(debugPremiumPreviewProvider)
                ? 'All features unlocked (dev): on'
                : 'All features unlocked (dev): off',
            size: 14,
            onTap: ref.read(debugPremiumPreviewProvider.notifier).toggle,
          ),
        ),
      if (kDebugMode)
        Center(
          child: Column(
            children: [
              TextLink(
                'Component gallery',
                size: 14,
                onTap: () => context.push(Routes.debugGallery),
              ),
              const SizedBox(height: 16),
              // Previews Premium without touching real entitlements or the
              // Plus launch promo. Debug builds only, never saved.
              TextLink(
                ref.watch(debugPremiumPreviewProvider)
                    ? 'All features unlocked (dev): on'
                    : 'All features unlocked (dev): off',
                size: 14,
                onTap: ref.read(debugPremiumPreviewProvider.notifier).toggle,
              ),
              const SizedBox(height: 16),
              // Checks delivery on a device: the next planned reminder's
              // text, 10 seconds from now.
              TextLink(
                'Test reminder in 10 s',
                size: 14,
                onTap: () {
                  final next = ref.read(reminderPlanProvider)?.firstOrNull;
                  if (next == null) return;
                  ref
                      .read(reminderSchedulerProvider)
                      .debugShowSoon(next, const Duration(seconds: 10));
                },
              ),
            ],
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: c.bg,
      // Scrolled content is clipped below the status bar.
      body: SafeArea(
        bottom: false,
        child: ListView(
          controller: ref.watch(tabScrollProvider).of(AppTab.more),
          padding: const EdgeInsets.fromLTRB(
            MoonSpace.gutter,
            10,
            MoonSpace.gutter,
            42,
          ),
          children: [
            for (final (i, s) in sections.indexed) ...[
              if (i > 0) const SizedBox(height: 28),
              s,
            ],
          ],
        ),
      ),
    );
  }
}
