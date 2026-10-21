import '../../../core/format/dates.dart';
import 'reminder_plan.dart';

/// What a reminder says. Phases and the period are estimates, so the copy
/// says "estimated" and never presents them as certain.
// TODO(open-question): notification copy needs content review.
({String title, String body}) reminderText(PlannedReminder r) =>
    switch (r.kind) {
      // Short titles: banners show one line.
      ReminderKind.phaseStart => (
        title: 'Your ${r.phase.name} phase',
        body:
            'It’s estimated to start today. See the foods for this phase in '
            'Moon Cycle.',
      ),
      ReminderKind.periodSoon => (
        title: 'Period due in ${DateText.days(periodReminderDaysBefore)}',
        body:
            'Estimated for ${DateText.weekdayDayMonth(r.periodDue)}, based '
            'on your dates.',
      ),
    };
