import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/centered_header.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/domain/phase.dart';
import '../../../core/time/today.dart';
import '../data/diary_activity_repository.dart';
import '../domain/diary_activity.dart';
import 'diary_format.dart';

/// Activities: the movement you chose to note, newest day first and grouped
/// by day, with a way to add one. Private to this phone; nothing is estimated,
/// scored or compared.
class DiaryActivitiesPage extends ConsumerWidget {
  const DiaryActivitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final today = ref.watch(todayProvider);
    final async = ref.watch(diaryActivitiesProvider);
    final items = async.value ?? const <DiaryActivity>[];
    final byDay = <LocalDate, List<DiaryActivity>>{};
    for (final a in items) {
      byDay.putIfAbsent(a.date, () => []).add(a);
    }
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CenteredHeader(
              title: 'Activities',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(Routes.diary),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  MoonSpace.gutter,
                  6,
                  MoonSpace.gutter,
                  42 + 76,
                ),
                children: [
                  Text(
                    'Note movement, exercise or walks if you’d like to. '
                    'It stays on this phone.',
                    textAlign: TextAlign.center,
                    style: dmSans(14, height: 1.5, color: c.textMuted),
                  ),
                  const SizedBox(height: 18),
                  MoonButton(
                    'Log an activity',
                    onPressed: () =>
                        context.push(Routes.diaryActivityNew(date: today)),
                  ),
                  const SizedBox(height: 22),
                  if (async.hasError)
                    Text(
                      'We couldn’t load your activities. They are still on '
                      'this phone.',
                      style: dmSans(15, height: 1.5, color: c.textMuted),
                    )
                  else if (async.isLoading && items.isEmpty)
                    const SizedBox.shrink()
                  else if (items.isEmpty)
                    const _Empty()
                  else
                    for (final e in byDay.entries) ...[
                      Semantics(
                        header: true,
                        child: Overline(historyDay(e.key, today)),
                      ),
                      const SizedBox(height: 8),
                      for (final a in e.value) ...[
                        _ActivityCard(
                          activity: a,
                          onTap: () => context.push(Routes.diaryActivity(a.id)),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 10),
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

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final p = c.phase(Phase.ovulatory);
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: p.tint, shape: BoxShape.circle),
              child: Center(
                child: MoonIcon(MoonIconName.move, size: 26, color: p.text),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No activities yet',
            textAlign: TextAlign.center,
            style: fraunces(24, height: 1.15, color: c.text),
          ),
          const SizedBox(height: 8),
          Text(
            'Add one whenever you like. There are no goals here, just a '
            'place to remember.',
            textAlign: TextAlign.center,
            style: dmSans(15, height: 1.5, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.onTap});

  final DiaryActivity activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final summary = activity.summary;
    return Pressable(
      onTap: onTap,
      semanticLabel:
          'Activity: ${activity.heading}${summary.isEmpty ? '' : ', $summary'}',
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
        decoration: BoxDecoration(
          color: c.raised,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.heading,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: fraunces(19, height: 1.2, color: c.text),
                  ),
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      summary,
                      style: dmSans(14, height: 1.4, color: c.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            MoonIcon(MoonIconName.chev, size: 18, color: c.chevron),
          ],
        ),
      ),
    );
  }
}
