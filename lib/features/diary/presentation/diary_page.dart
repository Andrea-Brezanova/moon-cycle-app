import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_colors.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/domain/phase.dart';
import '../../../core/time/today.dart';
import '../../cycle/application/viewing_phase.dart' show actualPhaseProvider;
import '../../entitlements/application/entitlement_providers.dart';
import '../../entitlements/domain/entitlements.dart';
import '../application/diary_providers.dart';
import '../domain/diary_entry.dart';
import '../domain/symptoms.dart';
import 'diary_format.dart';
import 'diary_widgets.dart';

enum DiaryTab { meals, symptoms }

/// My Diary: meals and a simple daily check-in, by day. Entries stay on this
/// phone. No scores, no interpretation, no medical claims.
class DiaryPage extends ConsumerStatefulWidget {
  const DiaryPage({super.key, this.initialDate, this.initialSymptoms = false});

  /// Opens on this day instead of today.
  final LocalDate? initialDate;

  /// Opens on the Symptoms tab.
  final bool initialSymptoms;

  @override
  ConsumerState<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends ConsumerState<DiaryPage> {
  late DiaryTab _tab = widget.initialSymptoms
      ? DiaryTab.symptoms
      : DiaryTab.meals;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDate;
    if (d != null) {
      Future.microtask(() {
        if (mounted) ref.read(diaryDateProvider.notifier).show(d);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final allowed = ref.watch(featureGateProvider).canUse(Feature.logDiary);
    final today = ref.watch(todayProvider);
    final date = ref.watch(diaryDateProvider);
    final controller = ref.read(diaryDateProvider.notifier);
    final entries = ref.watch(diaryDayProvider(date)).value ?? const [];
    final symptomDay = ref.watch(symptomDayProvider(date)).value;
    final label = ref.watch(phaseDayLabelProvider(date));
    final actual = ref.watch(actualPhaseProvider);
    final phase = label?.phase ?? actual;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            MoonSpace.gutter,
            10,
            MoonSpace.gutter,
            42 + 76,
          ),
          children: [
            if (GoRouter.maybeOf(context)?.canPop() ?? false)
              Align(
                alignment: Alignment.centerLeft,
                child: Pressable(
                  onTap: context.pop,
                  semanticLabel: 'Back',
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    alignment: Alignment.centerLeft,
                    child: MoonIcon(MoonIconName.back, size: 20, color: c.text),
                  ),
                ),
              ),
            Semantics(
              header: true,
              child: Text(
                'My Diary',
                style: fraunces(
                  44,
                  weight: FontWeight.w400,
                  height: 1.05,
                  color: c.text,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'A little space to remember how you felt and what you ate.',
              style: dmSans(16, height: 1.5, color: c.textMuted),
            ),
            if (!allowed) ...[
              const SizedBox(height: 24),
              Text(
                'Log Diary is part of Moon Cycle Premium.',
                style: MoonType.body.copyWith(color: c.text),
              ),
            ] else ...[
              const SizedBox(height: 18),
              DiaryDateBar(
                date: date,
                onPrevious: controller.previous,
                onNext: controller.next,
              ),
              const SizedBox(height: 18),
              _TabSwitch(
                selected: _tab,
                hasMeals: entries.isNotEmpty,
                hasSymptoms: symptomDay != null,
                onChanged: (t) => setState(() => _tab = t),
              ),
              const SizedBox(height: 22),
              if (_tab == DiaryTab.meals)
                _MealsTab(date: date, phase: phase, entries: entries)
              else
                _SymptomsTab(
                  date: date,
                  today: today,
                  phase: phase,
                  day: symptomDay,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Meals | Symptoms, with a small tick on a tab that has entries.
class _TabSwitch extends StatelessWidget {
  const _TabSwitch({
    required this.selected,
    required this.hasMeals,
    required this.hasSymptoms,
    required this.onChanged,
  });

  final DiaryTab selected;
  final bool hasMeals;
  final bool hasSymptoms;
  final ValueChanged<DiaryTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    Widget seg(DiaryTab tab, String text, bool has) {
      final on = tab == selected;
      return Expanded(
        child: Pressable(
          onTap: () => onChanged(tab),
          selected: on,
          semanticLabel: has ? '$text, has entries' : text,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: on ? c.sand : null,
              shape: const StadiumBorder(),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: dmSans(
                    15,
                    weight: on ? FontWeight.w600 : FontWeight.w500,
                    height: 1.2,
                    color: on ? c.text : c.textMuted,
                  ),
                ),
                if (has) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.phase(Phase.follicular).tint,
                      shape: BoxShape.circle,
                    ),
                    child: MoonIcon(
                      MoonIconName.check,
                      size: 11,
                      strokeWidth: 2.6,
                      color: c.phase(Phase.follicular).text,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: ShapeDecoration(
        shape: StadiumBorder(side: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          seg(DiaryTab.meals, 'Meals', hasMeals),
          seg(DiaryTab.symptoms, 'Symptoms', hasSymptoms),
        ],
      ),
    );
  }
}

const _mealIcons = {
  DiaryMeal.breakfast: MoonIconName.cup,
  DiaryMeal.lunch: MoonIconName.recipes,
  DiaryMeal.dinner: MoonIconName.utensils,
  DiaryMeal.snack: MoonIconName.apple,
};

class _MealsTab extends ConsumerWidget {
  const _MealsTab({
    required this.date,
    required this.phase,
    required this.entries,
  });

  final LocalDate date;
  final Phase phase;
  final List<DiaryEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    void log([DiaryMeal? meal]) =>
        context.push(Routes.logMeal(meal: meal, date: date));

    final logButton = MoonButton('+ Log a meal', onPressed: log);

    if (entries.isEmpty) {
      return _EmptyCard(
        key: const ValueKey('diary-empty'),
        phase: phase,
        icon: MoonIconName.recipes,
        title: 'Nothing logged for this day',
        body:
            'Add what you ate whenever you like. Breakfast, lunch, dinner and '
            'snacks will appear here.',
        button: logButton,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, meal) in DiaryMeal.values.indexed) ...[
          if (i > 0) const SizedBox(height: 22),
          Row(
            children: [
              MoonIcon(_mealIcons[meal]!, size: 20, color: c.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    meal.label,
                    style: fraunces(22, height: 1.15, color: c.text),
                  ),
                ),
              ),
              Pressable(
                onTap: () => log(meal),
                semanticLabel: 'Add to ${meal.label.toLowerCase()}',
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 44,
                    minWidth: 56,
                  ),
                  alignment: Alignment.centerRight,
                  child: Text(
                    '+ Add',
                    style: dmSans(
                      14,
                      weight: FontWeight.w600,
                      height: 1,
                      color: c.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (entries.any((e) => e.meal == meal))
            for (final (j, e) in entries.where((e) => e.meal == meal).indexed)
              Padding(
                padding: EdgeInsets.only(top: j == 0 ? 0 : 8),
                child: _EntryCard(
                  entry: e,
                  phase: phase,
                  onTap: () =>
                      context.push(Routes.logMeal(editId: e.id, date: e.date)),
                ),
              )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                meal == DiaryMeal.snack
                    ? 'No snacks logged yet'
                    : 'No meal logged yet',
                style: dmSans(15, height: 1.3, color: c.textMuted),
              ),
            ),
        ],
        const SizedBox(height: 26),
        logButton,
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.phase,
    required this.onTap,
  });

  final DiaryEntry entry;
  final Phase phase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final kind = switch (entry.kind) {
      DiaryItemKind.recipe => 'Recipe',
      DiaryItemKind.custom => 'Your own meal',
      DiaryItemKind.food => 'Food',
    };
    return Pressable(
      onTap: onTap,
      semanticLabel: '${entry.title}, $kind. Edit',
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: diarySurfaceFor(context, phase),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: dmSans(
                      16,
                      weight: FontWeight.w600,
                      height: 1.3,
                      color: c.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    kind,
                    style: dmSans(
                      13,
                      weight: FontWeight.w500,
                      height: 1.3,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            MoonIcon(MoonIconName.chev, size: 18, color: c.chevron),
          ],
        ),
      ),
    );
  }
}

/// A centred card for a day with nothing yet.
class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    super.key,
    required this.phase,
    required this.icon,
    required this.title,
    required this.body,
    required this.button,
  });

  final Phase phase;
  final MoonIconName icon;
  final String title;
  final String body;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        color: diarySurfaceFor(context, phase),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.raised,
                shape: BoxShape.circle,
              ),
              child: ExcludeSemantics(
                child: MoonIcon(icon, size: 28, color: c.text),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Semantics(
            header: true,
            child: EditorialHeading(
              title,
              textAlign: TextAlign.center,
              style: fraunces(26, height: 1.15),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: TextAlign.center,
            style: dmSans(15, height: 1.5, color: c.textMuted),
          ),
          const SizedBox(height: 22),
          button,
        ],
      ),
    );
  }
}

class _SymptomsTab extends ConsumerWidget {
  const _SymptomsTab({
    required this.date,
    required this.today,
    required this.phase,
    required this.day,
  });

  final LocalDate date;
  final LocalDate today;
  final Phase phase;
  final SymptomDay? day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final history = ref.watch(symptomHistoryProvider).value ?? const [];
    final earlier = [
      for (final d in history)
        if (d.date != date &&
            d.date.isBefore(date.addDays(1)) &&
            d.date.isAfter(date.addDays(-8)))
          d,
    ];
    void edit() => context.push(Routes.logSymptoms(date: date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (day == null)
          _EmptyCard(
            key: const ValueKey('symptoms-empty'),
            phase: phase,
            icon: MoonIconName.heart,
            title: date == today
                ? 'How are you feeling *today?*'
                : 'How were you feeling?',
            body:
                'Nothing recorded yet. Tap a few things that fit, whenever '
                'you like.',
            button: MoonButton('+ Log symptoms', onPressed: edit),
          )
        else
          _CheckInCard(
            day: day!,
            title: date == today ? 'Today’s check-in' : 'Check-in',
            onEdit: edit,
          ),
        if (earlier.isNotEmpty) ...[
          const SizedBox(height: 28),
          Semantics(header: true, child: const Overline('Earlier this week')),
          const SizedBox(height: 6),
          for (final d in earlier)
            _HistoryRow(
              day: d,
              today: today,
              onTap: () => ref.read(diaryDateProvider.notifier).show(d.date),
            ),
        ],
        const SizedBox(height: 26),
        Text(
          'Your diary is just for you. Moon Cycle doesn’t interpret symptoms '
          'or link them to a diagnosis.',
          style: dmSans(13, height: 1.5, color: c.removeIcon),
        ),
      ],
    );
  }
}

class _CheckInCard extends StatelessWidget {
  const _CheckInCard({
    required this.day,
    required this.title,
    required this.onEdit,
  });

  final SymptomDay day;
  final String title;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final rows = <(String, Widget)>[
      if (day.energy != null) ('Energy', _value(c, day.energy!.label)),
      if (day.moods.isNotEmpty)
        ('Mood', _pills(context, [for (final m in day.moods) m.label])),
      if (day.body.isNotEmpty)
        (
          'Body',
          _pills(context, [
            for (final e in day.body.entries)
              SymptomDay.bodyText(e.key, e.value),
          ]),
        ),
      if (day.sleep != null) ('Sleep', _value(c, day.sleep!.label)),
      if (day.note != null && day.note!.trim().isNotEmpty)
        (
          'Note',
          Text(
            day.note!,
            style: dmSans(
              15,
              weight: FontWeight.w500,
              height: 1.4,
              color: c.textMuted,
            ),
          ),
        ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: c.raised,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: fraunces(22, height: 1.15, color: c.text),
                  ),
                ),
              ),
              Pressable(
                onTap: onEdit,
                semanticLabel: 'Edit check-in',
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 44,
                    minWidth: 56,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MoonIcon(MoonIconName.pencil, size: 15, color: c.text),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: c.ochre, width: 2),
                          ),
                        ),
                        child: Text(
                          'Edit',
                          style: dmSans(
                            14,
                            weight: FontWeight.w600,
                            height: 1.1,
                            color: c.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          for (final (label, value) in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 62,
                    child: Text(
                      label,
                      style: dmSans(
                        13,
                        weight: FontWeight.w600,
                        height: 1.5,
                        color: c.textMuted,
                      ),
                    ),
                  ),
                  Expanded(child: value),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _value(MoonColors c, String text) => Text(
    text,
    style: dmSans(15, weight: FontWeight.w500, height: 1.4, color: c.text),
  );

  Widget _pills(BuildContext context, List<String> labels) {
    final c = context.moon;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final l in labels)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: ShapeDecoration(
              color: c.phase(Phase.follicular).tint,
              shape: const StadiumBorder(),
            ),
            child: Text(
              l,
              style: dmSans(
                13,
                weight: FontWeight.w500,
                height: 1.2,
                color: c.text,
              ),
            ),
          ),
      ],
    );
  }
}

class _HistoryRow extends ConsumerWidget {
  const _HistoryRow({
    required this.day,
    required this.today,
    required this.onTap,
  });

  final SymptomDay day;
  final LocalDate today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final label = ref.watch(phaseDayLabelProvider(day.date));
    final title = historyDay(day.date, today);
    return Pressable(
      onTap: onTap,
      semanticLabel: '$title. ${day.summary}',
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    children: [
                      Text(
                        title,
                        style: dmSans(
                          15,
                          weight: FontWeight.w600,
                          height: 1.3,
                          color: c.text,
                        ),
                      ),
                      if (label != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: c.phase(label.phase).accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              label.text,
                              style: dmSans(
                                12.5,
                                height: 1.3,
                                color: c.textMuted,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    day.summary,
                    style: dmSans(14, height: 1.4, color: c.textMuted),
                  ),
                ],
              ),
            ),
            MoonIcon(MoonIconName.chev, size: 18, color: c.chevron),
          ],
        ),
      ),
    );
  }
}
