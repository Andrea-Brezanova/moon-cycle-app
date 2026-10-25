import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../content/application/content_providers.dart';
import '../../cycle/application/cycle_providers.dart';
import '../../preferences/application/preference_providers.dart';
import '../application/settings_copy.dart';
import 'widgets/settings_widgets.dart';

/// Me › Settings: the personal settings and app preferences, with Help and
/// Credits. (Account & Plus has its own page.)
class SettingsHubPage extends ConsumerWidget {
  const SettingsHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return SettingsSubScaffold(
      title: 'Settings',
      backLabel: 'Me',
      children: [
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
          title: 'Support',
          children: [
            row(SettingsPage.help, MoonIconName.help),
            MoonListRow(
              label: 'Credits & Sources',
              icon: MoonIconName.book,
              onTap: () => context.push(Routes.credits),
            ),
            MoonListRow(
              key: const ValueKey('settings-about'),
              label: 'About',
              icon: MoonIconName.help,
              subtitle: 'Version and build',
              onTap: () => context.push(Routes.meAbout),
            ),
          ],
        ),
      ],
    );
  }
}
