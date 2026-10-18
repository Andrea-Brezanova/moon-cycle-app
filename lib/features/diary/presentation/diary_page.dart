import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/time/today.dart';
import '../../entitlements/application/entitlement_providers.dart';
import '../../entitlements/domain/entitlements.dart';
import '../application/diary_providers.dart';
import '../domain/diary_entry.dart';
import 'diary_item_picker.dart';
import 'log_entry_sheet.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _dayLabel(LocalDate d, LocalDate today) {
  if (d == today) return 'Today';
  if (d == today.addDays(-1)) return 'Yesterday';
  final weekday = _weekdays[DateTime.utc(d.year, d.month, d.day).weekday - 1];
  return '$weekday ${d.day} ${_months[d.month - 1]}';
}

/// The food diary: what was eaten, day by day. Entries are typed in by the
/// user and stay on this phone. No symptoms, no analysis.
class DiaryPage extends ConsumerWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final allowed = ref.watch(featureGateProvider).canUse(Feature.logDiary);
    final today = ref.watch(todayProvider);
    final date = ref.watch(diaryDateProvider);
    final controller = ref.read(diaryDateProvider.notifier);
    final entries = ref.watch(diaryDayProvider(date)).value ?? const [];
    final history = ref.watch(diaryHistoryProvider).value ?? const [];
    final earlier = [
      for (final d in history)
        if (d.date != date) d,
    ];

    Future<void> add() async {
      final pick = await showDiaryItemPicker(context);
      if (pick == null || !context.mounted) return;
      await showLogEntrySheet(
        context,
        draft: DiaryDraft(
          date: date,
          meal: DiaryMeal.forHour(ref.read(clockProvider)().hour),
          kind: pick.kind,
          itemId: pick.id,
          title: pick.title,
          amount: 1,
          unit: DiaryUnit.serving,
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 42 + 76),
          children: [
            SubScreenHeader(
              backLabel: 'Home',
              title: 'Diary',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(Routes.home),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MoonSpace.gutter,
                8,
                MoonSpace.gutter,
                0,
              ),
              child: !allowed
                  ? Text(
                      'Log Diary is part of Moon Cycle Premium.',
                      style: MoonType.body.copyWith(color: c.text),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'What you ate, saved on this phone only.',
                          style: dmSans(13, height: 1.4, color: c.textMuted),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            RoundIconButton(
                              MoonIconName.back,
                              semanticLabel: 'Previous day',
                              size: 44,
                              onPressed: controller.previous,
                            ),
                            Expanded(
                              child: Semantics(
                                header: true,
                                child: Text(
                                  _dayLabel(date, today),
                                  key: const ValueKey('diary-day'),
                                  textAlign: TextAlign.center,
                                  style: fraunces(24, color: c.text),
                                ),
                              ),
                            ),
                            RoundIconButton(
                              MoonIconName.chev,
                              semanticLabel: 'Next day',
                              size: 44,
                              onPressed: date.isBefore(today)
                                  ? controller.next
                                  : null,
                            ),
                          ],
                        ),
                        if (date != today)
                          Center(
                            child: TextLink(
                              'Back to today',
                              size: 14,
                              onTap: controller.today,
                            ),
                          ),
                        const SizedBox(height: 18),
                        if (entries.isEmpty)
                          Text(
                            'Nothing logged for this day yet.',
                            key: const ValueKey('diary-empty'),
                            style: MoonType.body.copyWith(color: c.textMuted),
                          ),
                        for (final meal in DiaryMeal.values)
                          if (entries.any((e) => e.meal == meal)) ...[
                            const SizedBox(height: 14),
                            Overline(meal.label),
                            for (final e in entries.where(
                              (e) => e.meal == meal,
                            ))
                              _EntryRow(
                                entry: e,
                                onTap: () =>
                                    showLogEntrySheet(context, editing: e),
                              ),
                          ],
                        const SizedBox(height: 22),
                        MoonButton('Add a food or recipe', onPressed: add),
                        if (earlier.isNotEmpty) ...[
                          const SizedBox(height: 30),
                          const Overline('Earlier days'),
                          for (final d in earlier)
                            Pressable(
                              onTap: () => controller.show(d.date),
                              semanticLabel:
                                  '${_dayLabel(d.date, today)}, '
                                  '${d.entries.length} '
                                  '${d.entries.length == 1 ? 'entry' : 'entries'}',
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: 48,
                                ),
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: c.line),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _dayLabel(d.date, today),
                                        style: dmSans(
                                          16,
                                          weight: FontWeight.w500,
                                          color: c.text,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${d.entries.length} '
                                      '${d.entries.length == 1 ? 'entry' : 'entries'}',
                                      style: dmSans(14, color: c.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.onTap});

  final DiaryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Pressable(
      onTap: onTap,
      semanticLabel: '${entry.title}, ${entry.quantity}. Edit',
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.title,
                style: dmSans(16, weight: FontWeight.w500, color: c.text),
              ),
            ),
            const SizedBox(width: 12),
            Text(entry.quantity, style: dmSans(14, color: c.textMuted)),
          ],
        ),
      ),
    );
  }
}
