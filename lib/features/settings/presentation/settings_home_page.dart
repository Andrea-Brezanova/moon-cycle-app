import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/app_config.dart';
import '../../../app/config/app_version.dart';
import '../../../app/router/routes.dart';
import '../../../app/shell/tab_scroll.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/brand.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../content/application/content_providers.dart';
import '../../cycle/application/cycle_providers.dart';
import '../../entitlements/application/entitlement_providers.dart';
import '../../preferences/application/preference_providers.dart';
import '../../reminders/application/reminder_providers.dart';
import '../application/settings_copy.dart';

/// The Settings tab, v1 local-only variant (`25-settings-v1-local`): no
/// Account row; "Delete my data" removes everything on the phone.
class SettingsHomePage extends ConsumerWidget {
  const SettingsHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final catalogue = ref.watch(catalogueProvider);
    final cycle = ref.watch(cycleStateProvider).value;
    final diet = ref.watch(dietProvider).value;
    final avoidances = ref.watch(avoidancesProvider).value ?? const [];
    final reminders = ref.watch(reminderSettingsProvider).value;

    void open(SettingsPage page) => context.push(Routes.settings(page));

    MoonListRow row(
      SettingsPage page,
      MoonIconName icon, {
      String? label,
      String? subtitle,
    }) => MoonListRow(
      label: label ?? page.title,
      icon: icon,
      subtitle: subtitle == null || subtitle.isEmpty ? null : subtitle,
      onTap: () => open(page),
    );

    final sections = <Widget>[
      Semantics(
        header: true,
        child: Text('More', style: MoonType.h1.copyWith(color: c.text)),
      ),
      MoonListGroup(
        title: 'Your space',
        children: [
          MoonListRow(
            label: 'My Diary',
            icon: MoonIconName.document,
            subtitle: 'Your meals, by day',
            onTap: () => context.push(Routes.diary),
          ),
          MoonListRow(
            label: 'Shopping list',
            icon: MoonIconName.shop,
            subtitle: 'Plan what you need',
            onTap: () => context.push(Routes.shopping),
          ),
        ],
      ),
      MoonListGroup(
        title: 'Personalisation',
        children: [
          row(
            SettingsPage.myCycle,
            MoonIconName.cycle,
            subtitle: myCycleSummary(cycle),
          ),
          row(
            SettingsPage.foodPreferences,
            MoonIconName.foods,
            subtitle: diet?.label,
          ),
          row(
            SettingsPage.allergies,
            MoonIconName.avoid,
            label: 'Allergies / Foods to Avoid',
            subtitle: avoidancesSummary(avoidances, catalogue),
          ),
        ],
      ),
      MoonListGroup(
        title: 'App',
        children: [
          row(
            SettingsPage.notifications,
            MoonIconName.bell,
            subtitle: reminders == null
                ? null
                : (reminders.enabled ? 'On' : 'Off'),
          ),
          row(
            SettingsPage.appearance,
            MoonIconName.settings,
            subtitle: ref.watch(appearanceProvider).label,
          ),
        ],
      ),
      MoonListGroup(
        title: 'Account',
        children: [
          row(
            SettingsPage.subscription,
            MoonIconName.card,
            subtitle: 'Free at launch',
          ),
          row(SettingsPage.privacy, MoonIconName.lock),
        ],
      ),
      MoonListGroup(
        title: 'Support',
        children: [
          row(SettingsPage.help, MoonIconName.help),
          MoonListRow(
            label: 'Credits & Sources',
            icon: MoonIconName.book,
            onTap: () => context.push(Routes.credits),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          children: [
            Pressable(
              onTap: () => open(SettingsPage.deleteData),
              semanticLabel: 'Delete my data',
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                child: Text(
                  'Delete my data',
                  style: dmSans(
                    16,
                    weight: FontWeight.w600,
                    height: 1,
                    color: c.destructive,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                'Permanently removes your cycle history, preferences and '
                'list from this phone.',
                textAlign: TextAlign.center,
                style: dmSans(13, height: 1.4, color: c.textMuted),
              ),
            ),
          ],
        ),
      ),
      _Footer(
        version: ref.watch(appVersionProvider),
        flavor: ref.watch(appConfigProvider).flavor,
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
              if (i > 0) const SizedBox(height: 34),
              s,
            ],
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.version, required this.flavor});

  final String version;
  final Flavor flavor;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Opacity(
        opacity: 0.9,
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PhaseRingMark(size: 16),
                const SizedBox(width: 4),
                // 26.1 pt in the design; the Home header's 34.8 pt is
                // x-height 12.
                Wordmark(xHeight: 9, color: c.text),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              [
                'Version $version',
                if (flavor != Flavor.prod) flavor.name,
              ].join(' · '),
              style: dmSans(12, height: 1, color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
