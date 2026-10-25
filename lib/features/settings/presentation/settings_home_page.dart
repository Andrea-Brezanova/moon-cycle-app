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
import '../../../core/design/widgets/pressable.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../../core/domain/phase.dart';
import '../../collections/presentation/collections_card.dart';
import '../../entitlements/application/entitlement_providers.dart';
import '../../reminders/application/reminder_providers.dart';
import '../../shopping/application/shopping_summary.dart';

/// The Settings tab, v1 local-only variant (`25-settings-v1-local`): no
/// Account row; "Delete my data" removes everything on the phone.
class SettingsHomePage extends ConsumerWidget {
  const SettingsHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final toBuy = ref.watch(shoppingSummaryProvider).toBuy;
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
      const CollectionsCard(),
      _MeRows(
        rows: [
          _MeRow(
            key: const ValueKey('me-diary'),
            label: 'My Diary',
            subtitle: 'What you ate, did and felt',
            icon: MoonIconName.document,
            tint: c.phase(Phase.follicular).tint,
            onTap: () => context.push(Routes.diary),
          ),
          _MeRow(
            key: const ValueKey('me-shopping'),
            label: 'Shopping list',
            subtitle: toBuy == 0 ? 'Nothing to buy' : '$toBuy to buy',
            icon: MoonIconName.shop,
            tint: c.phase(Phase.ovulatory).tint,
            onTap: () => context.push(Routes.shopping),
          ),
          _MeRow(
            key: const ValueKey('me-settings'),
            label: 'Settings',
            subtitle: 'Cycle, food preferences, notifications',
            icon: MoonIconName.settings,
            tint: c.phase(Phase.luteal).tint,
            onTap: () => context.push(Routes.meSettings),
          ),
          _MeRow(
            key: const ValueKey('me-account'),
            label: 'Account & Plus',
            subtitle: 'Subscription, privacy and data',
            icon: MoonIconName.account,
            tint: c.phase(Phase.menstrual).tint,
            onTap: () => context.push(Routes.meAccount),
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

/// The four rows under My Collections, in one rounded card with hairlines
/// between them.
class _MeRows extends StatelessWidget {
  const _MeRows({required this.rows});

  final List<_MeRow> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.raised,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          for (final (i, r) in rows.indexed) ...[
            if (i > 0) Divider(height: 1, color: c.line),
            r,
          ],
        ],
      ),
    );
  }
}

class _MeRow extends StatelessWidget {
  const _MeRow({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final MoonIconName icon;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Pressable(
      onTap: onTap,
      semanticLabel: '$label. $subtitle',
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ExcludeSemantics(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                child: Center(
                  child: MoonIcon(
                    icon,
                    size: 20,
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
                      style: fraunces(17.5, height: 1.15, color: c.text),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: dmSans(12.5, height: 1.3, color: c.textMuted),
                    ),
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
