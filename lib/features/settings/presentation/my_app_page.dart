import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../content/application/content_providers.dart';
import '../../cycle/application/cycle_providers.dart';
import '../../preferences/application/preference_providers.dart';
import '../application/settings_copy.dart';
import 'widgets/app_footer.dart';
import 'widgets/settings_widgets.dart';

/// Me › My App: every setting, the account pages and support, in four groups,
/// with "Delete my data" kept quietly at the very bottom.
class MyAppPage extends ConsumerWidget {
  const MyAppPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final catalogue = ref.watch(catalogueProvider);
    final cycle = ref.watch(cycleStateProvider).value;
    final diet = ref.watch(dietProvider).value;
    final avoidances = ref.watch(avoidancesProvider).value ?? const [];
    final reminders = ref.watch(reminderSettingsProvider).value;

    MoonListRow row(
      String key,
      String label,
      MoonIconName icon,
      VoidCallback onTap, {
      String? subtitle,
    }) => MoonListRow(
      key: ValueKey(key),
      label: label,
      icon: icon,
      subtitle: subtitle == null || subtitle.isEmpty ? null : subtitle,
      compact: true,
      onTap: onTap,
    );
    MoonListRow page(
      SettingsPage p,
      MoonIconName icon, {
      String? label,
      String? subtitle,
    }) => row(
      'app-${p.segment}',
      label ?? p.title,
      icon,
      () => context.push(Routes.settings(p)),
      subtitle: subtitle,
    );

    return SettingsSubScaffold(
      title: 'My App',
      backLabel: 'Me',
      gap: 22,
      children: [
        MoonListGroup(
          title: 'Personalization',
          children: [
            page(
              SettingsPage.myCycle,
              MoonIconName.cycle,
              subtitle: myCycleSummary(cycle),
            ),
            page(
              SettingsPage.foodPreferences,
              MoonIconName.foods,
              subtitle: diet?.label,
            ),
            page(
              SettingsPage.allergies,
              MoonIconName.avoid,
              label: 'Allergies / dietary exclusions',
              subtitle: avoidancesSummary(avoidances, catalogue),
            ),
          ],
        ),
        MoonListGroup(
          title: 'App preferences',
          children: [
            page(
              SettingsPage.appearance,
              MoonIconName.settings,
              subtitle: ref.watch(appearanceProvider).label,
            ),
            page(
              SettingsPage.notifications,
              MoonIconName.bell,
              subtitle: reminders == null
                  ? null
                  : (reminders.enabled ? 'On' : 'Off'),
            ),
          ],
        ),
        MoonListGroup(
          title: 'Account',
          children: [
            page(
              SettingsPage.subscription,
              MoonIconName.card,
              subtitle: 'Free at launch',
            ),
            page(SettingsPage.privacy, MoonIconName.lock),
          ],
        ),
        MoonListGroup(
          title: 'Support',
          children: [
            page(SettingsPage.help, MoonIconName.help),
            row(
              'app-credits',
              'Credits & Sources',
              MoonIconName.book,
              () => context.push(Routes.credits),
            ),
            row(
              'app-about',
              'About',
              MoonIconName.compass,
              () => context.push(Routes.meAbout),
              subtitle: 'Version and build',
            ),
          ],
        ),
        // Quiet on purpose: it only opens the confirmation page; nothing is
        // deleted from here.
        Pressable(
          key: const ValueKey('app-delete-data'),
          onTap: () => context.push(Routes.settings(SettingsPage.deleteData)),
          semanticLabel: 'Delete my data',
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.centerLeft,
            child: Text(
              'Delete my data',
              style: dmSans(
                15,
                weight: FontWeight.w600,
                height: 1.2,
                color: c.destructive,
              ),
            ),
          ),
        ),
        // Shown once, here, below Delete my data.
        const Padding(padding: EdgeInsets.only(top: 14), child: AppFooter()),
      ],
    );
  }
}
