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
import '../data/diary_note_repository.dart';
import '../domain/diary_note.dart';
import 'diary_format.dart';

/// Notes: every diary note, newest first and grouped by day, with a way to
/// write a new one. The writing is private to this phone.
class DiaryNotesPage extends ConsumerWidget {
  const DiaryNotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final today = ref.watch(todayProvider);
    final async = ref.watch(diaryNotesProvider);
    final notes = async.value ?? const <DiaryNote>[];
    final byDay = <LocalDate, List<DiaryNote>>{};
    for (final n in notes) {
      byDay.putIfAbsent(n.date, () => []).add(n);
    }
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CenteredHeader(
              title: 'Notes',
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
                    'A private space for your thoughts, reflections and '
                    'memories. It stays on this phone.',
                    textAlign: TextAlign.center,
                    style: dmSans(14, height: 1.5, color: c.textMuted),
                  ),
                  const SizedBox(height: 18),
                  MoonButton(
                    'Write a note',
                    onPressed: () =>
                        context.push(Routes.diaryNoteNew(date: today)),
                  ),
                  const SizedBox(height: 22),
                  if (async.hasError)
                    Text(
                      'We couldn’t load your notes. They are still on this '
                      'phone.',
                      style: dmSans(15, height: 1.5, color: c.textMuted),
                    )
                  else if (async.isLoading && notes.isEmpty)
                    const SizedBox.shrink()
                  else if (notes.isEmpty)
                    const _Empty(phase: Phase.menstrual)
                  else
                    for (final e in byDay.entries) ...[
                      Semantics(
                        header: true,
                        child: Overline(historyDay(e.key, today)),
                      ),
                      const SizedBox(height: 8),
                      for (final n in e.value) ...[
                        _NoteCard(
                          note: n,
                          onTap: () => context.push(Routes.diaryNote(n.id)),
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
  const _Empty({required this.phase});

  final Phase phase;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final p = c.phase(phase);
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
                child: MoonIcon(MoonIconName.pencil, size: 26, color: p.text),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            textAlign: TextAlign.center,
            style: fraunces(24, height: 1.15, color: c.text),
          ),
          const SizedBox(height: 8),
          Text(
            'Write whatever you like, whenever you like. There’s no right '
            'way to do it.',
            textAlign: TextAlign.center,
            style: dmSans(15, height: 1.5, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

/// One note in the list: its heading, the start of the writing, and the time.
class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onTap});

  final DiaryNote note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final hasTitle = (note.title ?? '').trim().isNotEmpty;
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Note: ${note.heading}',
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
                    note.heading,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: fraunces(19, height: 1.2, color: c.text),
                  ),
                  if (hasTitle && note.body.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      note.preview(110),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
