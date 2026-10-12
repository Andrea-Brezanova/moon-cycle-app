import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/widgets/moon_controls.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../preferences/application/preference_providers.dart';
import '../../preferences/data/preferences_repository.dart';
import '../../preferences/domain/reminder_settings.dart';
import '../../reminders/application/reminder_providers.dart';
import 'widgets/settings_widgets.dart';

/// Settings › Notifications (`29-settings-notifications`). The switches are
/// saved straight away and the reminders are rescheduled on the phone
/// (`reminderSyncProvider`).
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(reminderSettingsProvider).value ?? const ReminderSettings();
    final repository = ref.read(preferencesRepositoryProvider);

    Widget toggle({
      required String label,
      required String subtitle,
      required bool value,
      required ValueChanged<bool>? onChanged,
    }) => GestureDetector(
      // The whole row toggles; the switch carries the screen-reader state.
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: onChanged == null ? null : () => onChanged(!value),
      child: MoonListRow(
        label: label,
        subtitle: subtitle,
        trailing: MoonToggle(
          value: value,
          semanticLabel: label,
          onChanged: onChanged,
        ),
      ),
    );

    return SettingsSubScaffold(
      title: 'Notifications',
      children: [
        MoonListGroup(
          children: [
            toggle(
              label: 'Reminders',
              subtitle: 'Phase and period reminders',
              value: settings.enabled,
              onChanged: (v) async {
                // Turning reminders on asks for the system permission first.
                if (v &&
                    !await ref
                        .read(reminderSchedulerProvider)
                        .requestPermission()) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Notifications are off for Moon Cycle. You can '
                          'turn them on in your phone’s settings.',
                        ),
                      ),
                    );
                  }
                  return;
                }
                await repository.saveReminders(settings.copyWith(enabled: v));
              },
            ),
            // The detail switches only apply while reminders are on.
            toggle(
              label: 'When a new phase starts',
              subtitle: 'On the morning of each new phase',
              value: settings.phaseChange,
              onChanged: settings.enabled
                  ? (v) => repository.saveReminders(
                      settings.copyWith(phaseChange: v),
                    )
                  : null,
            ),
            toggle(
              label: 'Before your period',
              subtitle: 'Two days before it’s due',
              value: settings.beforePeriod,
              onChanged: settings.enabled
                  ? (v) => repository.saveReminders(
                      settings.copyWith(beforePeriod: v),
                    )
                  : null,
            ),
          ],
        ),
        const SettingsFootnote(
          'Reminders are worked out on this phone. Your dates aren’t sent '
          'anywhere to deliver them.',
        ),
      ],
    );
  }
}
