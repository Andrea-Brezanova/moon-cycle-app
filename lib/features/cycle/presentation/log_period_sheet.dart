import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/month_calendar.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/number_stepper.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/format/dates.dart';
import '../../../core/time/today.dart';
import '../application/cycle_providers.dart';
import '../data/cycle_repository.dart';
import '../domain/cycle_history.dart';
import '../domain/cycle_rules.dart';
import '../domain/period_log.dart';
import '../domain/period_start_check.dart';

/// "Log a period" (`22-log-period-sheet`), from Home's late card and
/// Settings › My Cycle. Today is preselected.
///
/// With [editing], the same sheet changes a logged period (My Cycle ›
/// History, or "Last period started"): its start, how many days it lasted,
/// and "Delete this period" when it isn't the only one. That variant isn't
/// drawn (docs/design-deviations.md).
Future<void> showLogPeriodSheet(BuildContext context, {PeriodLog? editing}) =>
    showMoonSheet<void>(
      context,
      builder: (_) => _LogPeriodSheet(editing: editing),
    );

class _LogPeriodSheet extends ConsumerStatefulWidget {
  const _LogPeriodSheet({this.editing});

  final PeriodLog? editing;

  @override
  ConsumerState<_LogPeriodSheet> createState() => _LogPeriodSheetState();
}

class _LogPeriodSheetState extends ConsumerState<_LogPeriodSheet> {
  LocalDate? _selected;
  LocalDate? _month;
  int? _days;
  bool _saving = false;

  Future<void> _save(LocalDate start, int days) async {
    setState(() => _saving = true);
    final repository = ref.read(cycleRepositoryProvider);
    final editing = widget.editing;
    if (editing == null) {
      await repository.logPeriod(start);
    } else {
      await repository.updatePeriodLog(
        editing.id,
        start: start,
        end: periodEnd(start, days),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    setState(() => _saving = true);
    await ref.read(cycleRepositoryProvider).deletePeriodLog(widget.editing!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final today = ref.watch(todayProvider);
    final logs = ref.watch(periodLogsProvider).value ?? const [];
    final editing = widget.editing;
    final selected = _selected ?? editing?.start ?? today;
    final month = _month ?? selected;
    final problem = checkPeriodStart(
      selected,
      existing: logs,
      today: today,
      editingId: editing?.id,
    );
    final days =
        _days ??
        (editing == null ? null : periodDays(editing)) ??
        ref.watch(cycleProfileProvider).value?.typicalPeriodLength ??
        CycleRules.defaultPeriodLength;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Overline(editing == null ? 'Log a period' : 'Edit period'),
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
          if (editing != null) ...[
            const SizedBox(height: 18),
            NumberStepper(
              label: 'Period length',
              value: days.clamp(
                CycleRules.minPeriodLength,
                CycleRules.maxPeriodLength,
              ),
              min: CycleRules.minPeriodLength,
              max: CycleRules.maxPeriodLength,
              onChanged: (v) => setState(() => _days = v),
            ),
          ],
          const SizedBox(height: 18),
          MoonButton(
            'Save',
            variant: MoonButtonVariant.secondary,
            onPressed: problem != null || _saving
                ? null
                : () => _save(selected, days),
          ),
          if (editing != null && logs.length > 1) ...[
            const SizedBox(height: 18),
            Center(
              child: TextLink(
                'Delete this period',
                color: c.destructive,
                onTap: _saving ? null : _delete,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
