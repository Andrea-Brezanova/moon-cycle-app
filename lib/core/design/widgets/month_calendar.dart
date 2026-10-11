import 'package:flutter/widgets.dart';

import '../../domain/local_date.dart';
import '../../domain/phase.dart';
import '../moon_theme.dart';
import '../tokens/moon_colors.dart';
import '../tokens/moon_layout.dart';
import '../tokens/moon_typography.dart';
import 'moon_button.dart';
import 'moon_icon.dart';
import 'pressable.dart';

/// The month calendar (onboarding "last period" and "Log a period"; spec
/// §7.1): a raised card with month navigation and a Monday-first grid.
///
/// Days after [today] are disabled. [highlighted] days (the predicted period
/// after the selected start) use the Menstrual tint.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.year,
    required this.month,
    required this.today,
    required this.onSelect,
    required this.onMonthChanged,
    this.selected,
    this.highlighted = const {},
  });

  final int year;
  final int month;
  final LocalDate today;
  final LocalDate? selected;
  final Set<LocalDate> highlighted;
  final ValueChanged<LocalDate> onSelect;

  /// Called with the first day of the month to show.
  final ValueChanged<LocalDate> onMonthChanged;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July', //
    'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final first = LocalDate(year, month, 1);
    final next = LocalDate(month == 12 ? year + 1 : year, month % 12 + 1, 1);
    final previous = first.addDays(-1);
    final daysInMonth = first.daysUntil(next);
    final leading = DateTime.utc(year, month).weekday - 1; // Monday = 0
    final canGoNext = !next.isAfter(today);
    final title = '${_months[month - 1]} $year';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(MoonRadius.calendar),
      ),
      child: Semantics(
        label: title,
        container: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
              child: Row(
                children: [
                  RoundIconButton(
                    MoonIconName.back,
                    size: 40,
                    iconSize: 18,
                    semanticLabel: 'Previous month',
                    onPressed: () => onMonthChanged(
                      LocalDate(previous.year, previous.month, 1),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: fraunces(
                        20,
                        weight: FontWeight.w500,
                        color: c.text,
                      ),
                    ),
                  ),
                  RoundIconButton(
                    MoonIconName.chev,
                    size: 40,
                    iconSize: 18,
                    semanticLabel: 'Next month',
                    onPressed: canGoNext ? () => onMonthChanged(next) : null,
                  ),
                ],
              ),
            ),
            _Grid(
              children: [
                for (final w in _weekdays)
                  Center(
                    child: Text(
                      w,
                      style: dmSans(
                        12,
                        weight: FontWeight.w600,
                        height: 1,
                        color: c.textMuted,
                      ),
                    ),
                  ),
                for (var i = 0; i < leading; i++) const SizedBox(),
                for (var d = 1; d <= daysInMonth; d++)
                  _Day(
                    date: LocalDate(year, month, d),
                    today: today,
                    selected: selected,
                    highlighted: highlighted,
                    colors: c,
                    onSelect: onSelect,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 7) {
      final week = children.sublist(i, (i + 7).clamp(0, children.length));
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 4),
          child: Row(
            children: [
              for (var j = 0; j < 7; j++) ...[
                if (j > 0) const SizedBox(width: 2),
                Expanded(
                  child: SizedBox(
                    height: i == 0 ? 12 : 42,
                    child: j < week.length ? week[j] : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _Day extends StatelessWidget {
  const _Day({
    required this.date,
    required this.today,
    required this.selected,
    required this.highlighted,
    required this.colors,
    required this.onSelect,
  });

  final LocalDate date;
  final LocalDate today;
  final LocalDate? selected;
  final Set<LocalDate> highlighted;
  final MoonColors colors;
  final ValueChanged<LocalDate> onSelect;

  @override
  Widget build(BuildContext context) {
    final future = date.isAfter(today);
    final isSelected = date == selected;
    final isHighlighted = !isSelected && highlighted.contains(date);
    final bg = isSelected
        ? colors.inverseBg
        : isHighlighted
        ? colors.phase(Phase.menstrual).tint
        : null;
    final fg = isSelected
        ? colors.inverseText
        : future
        ? colors.textMuted
        : colors.text;
    return Opacity(
      opacity: future ? 0.45 : 1,
      child: Pressable(
        onTap: future ? null : () => onSelect(date),
        selected: isSelected,
        child: Container(
          decoration: ShapeDecoration(color: bg, shape: const StadiumBorder()),
          alignment: Alignment.center,
          child: Text(
            '${date.day}',
            style: dmSans(
              15,
              weight: isSelected ? FontWeight.w700 : FontWeight.w500,
              height: 1,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
