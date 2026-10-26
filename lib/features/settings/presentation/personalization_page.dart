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

/// Me › Personalization: what Moon Cycle knows about you to tailor food
/// suggestions, kept in one place (My Cycle, Food Preferences, and dietary
/// exclusions and allergies).
class PersonalizationPage extends ConsumerWidget {
  const PersonalizationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogue = ref.watch(catalogueProvider);
    final cycle = ref.watch(cycleStateProvider).value;
    final diet = ref.watch(dietProvider).value;
    final avoidances = ref.watch(avoidancesProvider).value ?? const [];

    MoonListRow row(
      SettingsPage page,
      MoonIconName icon, {
      String? label,
      String? subtitle,
    }) => MoonListRow(
      key: ValueKey('personalization-${page.segment}'),
      label: label ?? page.title,
      icon: icon,
      subtitle: subtitle == null || subtitle.isEmpty ? null : subtitle,
      onTap: () => context.push(Routes.settings(page)),
    );

    return SettingsSubScaffold(
      title: 'Personalization',
      children: [
        MoonListGroup(
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
      ],
    );
  }
}
