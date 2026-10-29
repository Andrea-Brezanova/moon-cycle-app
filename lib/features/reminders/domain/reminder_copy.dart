import '../../../core/format/dates.dart';
import 'reminder_plan.dart';

/// What a reminder says when the user has not opted in to details: nothing
/// about the cycle, so nothing shows on a lock screen.
const discreetReminderText = (
  title: 'Moon Cycle',
  body: 'You have a reminder.',
);

/// What a reminder says. By default it is [discreetReminderText]. Only when
/// the user has opted in ([PlannedReminder.detailed]) does it name the phase
/// or the period; those are estimates, so the copy says "estimated" and never
/// presents them as certain.
// TODO(open-question): notification copy needs content review.
({String title, String body}) reminderText(PlannedReminder r) =>
    !r.detailed ? discreetReminderText : _detailedText(r);

({String title, String body}) _detailedText(PlannedReminder r) =>
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
