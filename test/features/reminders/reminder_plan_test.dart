import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_lengths.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_profile.dart';
import 'package:moon_cycle/features/preferences/domain/reminder_settings.dart';
import 'package:moon_cycle/features/reminders/domain/reminder_copy.dart';
import 'package:moon_cycle/features/reminders/domain/reminder_plan.dart';

void main() {
  final start = LocalDate(2025, 9, 28); // day 7 on 4 October
  final today = LocalDate(2025, 10, 4);
  final lengths = CycleLengths.fromProfile(
    const CycleProfile(typicalCycleLength: 28, typicalPeriodLength: 5),
  );
  const on = ReminderSettings(enabled: true);

  List<PlannedReminder> plan({
    ReminderSettings settings = on,
    LocalDate? on_,
    CycleLengths? l,
  }) => planReminders(
    lastPeriodStart: start,
    lengths: l ?? lengths,
    today: on_ ?? today,
    settings: settings,
  );

  test('reminders off: nothing', () {
    expect(plan(settings: const ReminderSettings()), isEmpty);
  });

  test('28/5 on day 7: the next phase starts and the period, in order', () {
    final p = plan();
    expect(p.take(6).map((r) => (r.date, r.kind, r.phase)), [
      (LocalDate(2025, 10, 9), ReminderKind.phaseStart, Phase.ovulatory),
      (LocalDate(2025, 10, 13), ReminderKind.phaseStart, Phase.luteal),
      (LocalDate(2025, 10, 24), ReminderKind.periodSoon, Phase.menstrual),
      (LocalDate(2025, 10, 26), ReminderKind.phaseStart, Phase.menstrual),
      (LocalDate(2025, 10, 31), ReminderKind.phaseStart, Phase.follicular),
      (LocalDate(2025, 11, 6), ReminderKind.phaseStart, Phase.ovulatory),
    ]);
    expect(p[2].periodDue, LocalDate(2025, 10, 26));
  });

  test('the current cycle and three more; only future days', () {
    final p = plan();
    // 4 cycles × (4 phases + 1 period) minus the two already past.
    expect(p, hasLength(18));
    expect(p.every((r) => r.date.isAfter(today)), isTrue);
    expect(p.last.date, LocalDate(2026, 1, 16)); // 2 days before the 4th period
  });

  test('a reminder for today is not scheduled (it would be in the past)', () {
    final p = plan(on_: LocalDate(2025, 10, 9)); // ovulatory starts today
    expect(p.first.date, LocalDate(2025, 10, 13));
  });

  test('each switch on its own', () {
    final phases = plan(
      settings: const ReminderSettings(enabled: true, beforePeriod: false),
    );
    expect(phases.every((r) => r.kind == ReminderKind.phaseStart), isTrue);
    final period = plan(
      settings: const ReminderSettings(enabled: true, phaseChange: false),
    );
    expect(period.map((r) => r.date), [
      LocalDate(2025, 10, 24),
      LocalDate(2025, 11, 21),
      LocalDate(2025, 12, 19),
      LocalDate(2026, 1, 16),
    ]);
  });

  test('a late period: nothing until a new one is logged', () {
    expect(plan(on_: start.addDays(28)), isEmpty); // day 29 of 28
    expect(plan(on_: start.addDays(27)), isNotEmpty); // day 28
  });

  test('other lengths follow the phase ranges (35/7)', () {
    final l = CycleLengths.fromProfile(
      const CycleProfile(typicalCycleLength: 35, typicalPeriodLength: 7),
    );
    final p = plan(l: l, on_: start);
    // 35/7: follicular 8, ovulatory 19, luteal 23; next period day 36.
    expect(p.take(4).map((r) => r.date), [
      start.addDays(7),
      start.addDays(18),
      start.addDays(22),
      start.addDays(33),
    ]);
  });

  test('ids are unique and stable', () {
    final p = plan();
    expect(p.map((r) => r.id).toSet(), hasLength(p.length));
    expect(plan().map((r) => r.id), p.map((r) => r.id));
    expect(p.every((r) => r.id > 0 && r.id < 0x7fffffff), isTrue);
  });

  test('copy says "estimated"', () {
    final p = plan();
    expect(reminderText(p.first), (
      title: 'Your ovulatory phase',
      body:
          'It’s estimated to start today. See the foods for this phase in '
          'Moon Cycle.',
    ));
    expect(reminderText(p[2]), (
      title: 'Period due in 2 days',
      body: 'Estimated for Sunday 26 October, based on your dates.',
    ));
  });
}
