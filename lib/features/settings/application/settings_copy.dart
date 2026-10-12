import '../../../core/domain/local_date.dart';
import '../../../core/domain/phase.dart';
import '../../../core/format/dates.dart';
import '../../content/domain/catalogue.dart';
import '../../cycle/domain/cycle_history.dart';
import '../../cycle/domain/cycle_state.dart';
import '../../preferences/domain/food_avoidance.dart';

String _capitalised(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Settings › My Cycle row: "28-day cycle · 5-day period · Next period
/// 26 Oct". A late period leaves out the date that has passed.
String myCycleSummary(CycleState? state) {
  if (state == null) return '';
  return [
    '${state.lengths.cycleLength}-day cycle',
    '${state.lengths.periodLength}-day period',
    if (!state.isLate)
      'Next period ${DateText.shortDayMonth(state.estimatedNextPeriodDate)}',
  ].join(' · ');
}

/// Settings › Allergies row: "Peanuts, shellfish", or "None".
String avoidancesSummary(List<FoodAvoidance> avoidances, Catalogue catalogue) {
  final names = [
    for (final a in avoidances)
      ?switch (a) {
        AllergenAvoidance(:final allergenId) =>
          catalogue.allergens
              .where((x) => x.id == allergenId)
              .firstOrNull
              ?.label,
        FoodItemAvoidance(:final foodId) => catalogue.food(foodId)?.displayName,
        CustomAvoidance(:final label) => label,
      },
  ];
  if (names.isEmpty) return 'None';
  return [for (final (i, n) in names.indexed) i == 0 ? n : n.toLowerCase()]
      .join(', ');
}

/// My Cycle › Next period: "In 22 days · Ovulatory in 5 days". The phase
/// part is left out when the next phase is the period itself.
String nextPeriodLine(CycleState state) {
  if (state.isLate) return '${DateText.days(state.daysLate)} late';
  return [
    'In ${DateText.days(state.daysUntilNextPeriod)}',
    if (state.nextPhase != Phase.menstrual)
      '${_capitalised(state.nextPhase.name)} in '
          '${DateText.days(state.daysToNextPhase)}',
  ].join(' · ');
}

/// My Cycle › History title: "28 Sep – 2 Oct", or "28 Sep" with no end.
String historyTitle(PeriodHistoryEntry entry) {
  final start = DateText.shortDayMonth(entry.log.start);
  final end = entry.log.end;
  return end == null ? start : '$start – ${DateText.shortDayMonth(end)}';
}

/// My Cycle › History subtitle: "5 days · 28-day cycle" or "5 days ·
/// current cycle". The days are left out when no end is logged.
String historySubtitle(PeriodHistoryEntry entry) => [
  if (entry.periodDays case final days?) DateText.days(days),
  if (entry.cycleLength case final length?)
    '$length-day cycle'
  else
    'current cycle',
].join(' · ');

/// "31 January 2027", for the launch-free end date.
String longDate(LocalDate d) => '${DateText.dayMonth(d)} ${d.year}';
