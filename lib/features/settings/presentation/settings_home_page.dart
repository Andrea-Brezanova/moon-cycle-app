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
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../collections/application/collections_providers.dart';
import '../../entitlements/application/entitlement_providers.dart';
import '../../reminders/application/reminder_providers.dart';
import '../../shopping/application/shopping_summary.dart';

/// The Me tab: four sections (Your space, Your app, Your account, Support),
/// each a compact group of rows.
class SettingsHomePage extends ConsumerWidget {
  const SettingsHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final toBuy = ref.watch(shoppingSummaryProvider).toBuy;
    final collections = ref.watch(collectionSummaryProvider).total;
    void open(SettingsPage page) => context.push(Routes.settings(page));

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
      _MeSection(
        title: 'Your space',
        rows: [
          _MeRow(
            key: const ValueKey('me-collections'),
            label: 'My Collections',
            subtitle: collections == 0
                ? 'Recipes, workouts and spa'
                : '$collections saved',
            icon: MoonIconName.bookmark,
            onTap: () => context.push(Routes.collections),
          ),
          _MeRow(
            key: const ValueKey('me-diary'),
            label: 'My Diary',
            subtitle: 'What you ate, did and felt',
            icon: MoonIconName.document,
            onTap: () => context.push(Routes.diary),
          ),
          _MeRow(
            key: const ValueKey('me-shopping'),
            label: 'Shopping List',
            subtitle: toBuy == 0 ? 'Nothing to buy' : '$toBuy to buy',
            icon: MoonIconName.shop,
            onTap: () => context.push(Routes.shopping),
          ),
        ],
      ),
      _MeSection(
        title: 'Your app',
        rows: [
          _MeRow(
            key: const ValueKey('me-personalization'),
            label: 'Personalization',
            subtitle: 'My Cycle, food preferences, allergies',
            icon: MoonIconName.cycle,
            onTap: () => open(SettingsPage.personalization),
          ),
          _MeRow(
            key: const ValueKey('me-appearance'),
            label: 'Appearance',
            icon: MoonIconName.settings,
            onTap: () => open(SettingsPage.appearance),
          ),
          _MeRow(
            key: const ValueKey('me-notifications'),
            label: 'Notifications',
            icon: MoonIconName.bell,
            onTap: () => open(SettingsPage.notifications),
          ),
        ],
      ),
      _MeSection(
        title: 'Your account',
        rows: [
          _MeRow(
            key: const ValueKey('me-subscription'),
            label: 'Subscription',
            subtitle: 'Free at launch',
            icon: MoonIconName.card,
            onTap: () => open(SettingsPage.subscription),
          ),
          _MeRow(
            key: const ValueKey('me-privacy'),
            label: 'Privacy & Data',
            subtitle: 'Export or delete your data',
            icon: MoonIconName.lock,
            onTap: () => open(SettingsPage.privacy),
          ),
        ],
      ),
      _MeSection(
        title: 'Support',
        rows: [
          _MeRow(
            key: const ValueKey('me-help'),
            label: 'Help',
            icon: MoonIconName.help,
            onTap: () => open(SettingsPage.help),
          ),
          _MeRow(
            key: const ValueKey('me-credits'),
            label: 'Credits & Sources',
            icon: MoonIconName.book,
            onTap: () => context.push(Routes.credits),
          ),
          _MeRow(
            key: const ValueKey('me-about'),
            label: 'About',
            subtitle: 'Version and build',
            icon: MoonIconName.compass,
            onTap: () => context.push(Routes.meAbout),
          ),
        ],
      ),
      _Footer(
        version: ref.watch(appVersionProvider),
        flavor: ref.watch(appConfigProvider).flavor,
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
              if (i > 0) SizedBox(height: i < 5 ? 24 : 34),
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

/// A restrained overline heading and one rounded card of compact rows with
/// hairlines between them.
class _MeSection extends StatelessWidget {
  const _MeSection({required this.title, required this.rows});

  final String title;
  final List<_MeRow> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Overline(title),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: c.raised,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              for (final (i, r) in rows.indexed) ...[
                if (i > 0) Divider(height: 1, color: c.line),
                r,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MeRow extends StatelessWidget {
  const _MeRow({
    super.key,
    required this.label,
    this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String? subtitle;
  final MoonIconName icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Pressable(
      onTap: onTap,
      semanticLabel: subtitle == null ? label : '$label. $subtitle',
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: ExcludeSemantics(
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.line),
                ),
                child: Center(
                  child: MoonIcon(
                    icon,
                    size: 18,
                    color: c.text,
                    strokeWidth: 1.7,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: fraunces(17, height: 1.15, color: c.text),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: dmSans(12.5, height: 1.3, color: c.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              MoonIcon(
                MoonIconName.chev,
                size: 18,
                color: c.chevron,
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
