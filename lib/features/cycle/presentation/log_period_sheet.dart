import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/month_calendar.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/format/dates.dart';
import '../../../core/time/today.dart';
import '../application/cycle_providers.dart';
import '../data/cycle_repository.dart';
import '../domain/period_start_check.dart';

/// "Log a period" (`22-log-period-sheet`), from Home's late card and
/// Settings › My Cycle. Today is preselected.
Future<void> showLogPeriodSheet(BuildContext context) =>
    showMoonSheet<void>(context, builder: (_) => const _LogPeriodSheet());

class _LogPeriodSheet extends ConsumerStatefulWidget {
  const _LogPeriodSheet();

  @override
  ConsumerState<_LogPeriodSheet> createState() => _LogPeriodSheetState();
}

class _LogPeriodSheetState extends ConsumerState<_LogPeriodSheet> {
  LocalDate? _selected;
  LocalDate? _month;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final today = ref.watch(todayProvider);
    final logs = ref.watch(periodLogsProvider).value ?? const [];
    final selected = _selected ?? today;
    final month = _month ?? selected;
    final problem = checkPeriodStart(selected, existing: logs, today: today);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Overline('Log a period'),
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: EditorialHeading(
              'When did it *start?*',
              style: fraunces(32, height: 1.1),
            ),
          ),
          const SizedBox(height: 14),
          MonthCalendar(
            year: month.year,
            month: month.month,
            today: today,
            selected: selected,
            onSelect: (d) => setState(() => _selected = d),
            onMonthChanged: (d) => setState(() => _month = d),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: c.text,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Day 1 · ${DateText.weekdayDayMonth(selected)}',
                  style: dmSans(
                    14,
                    weight: FontWeight.w500,
                    height: 1.5,
                    color: c.textMuted,
                  ),
                ),
              ),
            ],
          ),
          if (problem == PeriodStartProblem.tooCloseToAnother) ...[
            const SizedBox(height: 6),
            Text(
              'That’s within $minDaysBetweenPeriodStarts days of a period you’ve '
              'already logged. Choose its first day, or another date.',
              style: dmSans(14, height: 1.5, color: c.textMuted),
            ),
          ],
          const SizedBox(height: 18),
          MoonButton(
            'Save',
            variant: MoonButtonVariant.secondary,
            onPressed: problem != null || _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    await ref.read(cycleRepositoryProvider).logPeriod(selected);
                    if (context.mounted) Navigator.pop(context);
                  },
          ),
        ],
      ),
    );
  }
}
