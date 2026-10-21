import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../../core/format/dates.dart';
import '../../cycle/application/cycle_providers.dart';
import '../../cycle/domain/cycle_history.dart';
import '../../cycle/presentation/log_period_sheet.dart';
import '../application/settings_copy.dart';
import 'cycle_lengths_sheet.dart';
import 'widgets/settings_widgets.dart';

/// Settings › My Cycle (`26-settings-my-cycle`): the next period, the values
/// the phases are worked out from, and the logged periods.
class MyCyclePage extends ConsumerWidget {
  const MyCyclePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final state = ref.watch(cycleStateProvider).value;
    final profile = ref.watch(cycleProfileProvider).value;
    final logs = ref.watch(periodLogsProvider).value ?? const [];
    final averages = ref.watch(historyAveragesProvider);
    final history = periodHistory(logs);
    final useAverages = profile?.useHistoryAverages ?? false;

    String? averageNote(int used, String what) =>
        useAverages && used > 0 ? 'Average of your last $used $what' : null;

    return SettingsSubScaffold(
      title: 'My Cycle',
      top: 22,
      gap: 34,
      children: [
        if (state != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Overline('Next period'),
              const SizedBox(height: 6),
              Text(
                DateText.weekdayDayMonth(state.estimatedNextPeriodDate),
                style: fraunces(34, height: 1.1, color: c.text),
              ),
              const SizedBox(height: 6),
              Text(
                nextPeriodLine(state),
                style: dmSans(
                  15,
                  weight: FontWeight.w500,
                  height: 1.4,
                  color: c.textMuted,
                ),
              ),
            ],
          ),
        MoonListGroup(
          title: 'Your cycle',
          children: [
            MoonListRow(
              label: 'Last period started',
              value: logs.isEmpty ? null : DateText.short(logs.first.start),
              onTap: logs.isEmpty
                  ? null
                  : () => showLogPeriodSheet(context, editing: logs.first),
            ),
            MoonListRow(
              label: 'Cycle length',
              subtitle: averageNote(averages.cyclesUsed, 'cycles'),
              value: state == null
                  ? null
                  : DateText.days(state.lengths.cycleLength),
              onTap: () => showCycleLengthsSheet(context),
            ),
            MoonListRow(
              label: 'Period length',
              subtitle: averageNote(averages.periodsUsed, 'periods'),
              value: state == null
                  ? null
                  : DateText.days(state.lengths.periodLength),
              onTap: () => showCycleLengthsSheet(context),
            ),
          ],
        ),
        if (history.isNotEmpty)
          MoonListGroup(
            title: 'History',
            children: [
              for (final entry in history)
                MoonListRow(
                  label: historyTitle(entry),
                  subtitle: historySubtitle(entry),
                  onTap: () => showLogPeriodSheet(context, editing: entry.log),
                ),
            ],
          ),
        MoonButton(
          'Log a period',
          variant: MoonButtonVariant.secondary,
          onPressed: () => showLogPeriodSheet(context),
        ),
        const SettingsFootnote(
          'Phases are estimates based on your dates. Moon Cycle isn’t a '
          'contraceptive or a fertility tool.',
        ),
      ],
    );
  }
}
