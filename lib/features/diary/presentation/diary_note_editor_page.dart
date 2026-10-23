import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/centered_header.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/time/today.dart';
import '../data/diary_note_repository.dart';
import '../domain/diary_note.dart';
import 'diary_confirm_sheet.dart';
import 'diary_toast.dart';
import 'diary_widgets.dart';

/// Write or edit one diary note: a day, an optional title and free writing.
/// Nothing is saved until Save; going back with unsaved writing asks first.
/// The text stays on this phone (encrypted) and is never logged or sent.
class DiaryNoteEditorPage extends ConsumerStatefulWidget {
  const DiaryNoteEditorPage({super.key, this.noteId, this.date});

  /// The note to edit; null starts a new one.
  final String? noteId;

  /// The day a new note starts on (today if null).
  final LocalDate? date;

  @override
  ConsumerState<DiaryNoteEditorPage> createState() =>
      _DiaryNoteEditorPageState();
}

class _DiaryNoteEditorPageState extends ConsumerState<DiaryNoteEditorPage> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  late LocalDate _date = widget.date ?? ref.read(todayProvider);

  /// The saved note being edited, once loaded.
  DiaryNote? _existing;
  bool _loading = false;
  bool _missing = false;
  bool _saving = false;

  /// What the page started with, to tell whether anything changed.
  String _startTitle = '';
  String _startBody = '';
  late LocalDate _startDate = _date;

  @override
  void initState() {
    super.initState();
    final id = widget.noteId;
    if (id != null) {
      _loading = true;
      ref.read(diaryNoteRepositoryProvider).byId(id).then((note) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          if (note == null) {
            _missing = true;
            return;
          }
          _existing = note;
          _date = note.date;
          _startDate = note.date;
          _startTitle = note.title ?? '';
          _startBody = note.body;
          _title.text = _startTitle;
          _body.text = _startBody;
        });
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _title.text != _startTitle ||
      _body.text != _startBody ||
      _date != _startDate;

  bool get _blank => isBlankNote(title: _title.text, body: _body.text);

  Future<bool> _confirm({
    required String title,
    required String body,
    required String yes,
    required String no,
  }) async =>
      await showMoonSheet<bool>(
        context,
        builder: (_) =>
            DiaryConfirmSheet(title: title, body: body, yes: yes, no: no),
      ) ??
      false;

  Future<void> _back() async {
    if (_dirty && !_blank) {
      final discard = await _confirm(
        title: 'Discard your writing?',
        body: 'This note hasn’t been saved yet.',
        yes: 'Discard',
        no: 'Keep writing',
      );
      if (!discard || !mounted) return;
    }
    if (mounted) _leave();
  }

  void _leave([bool saved = false]) =>
      context.canPop() ? context.pop(saved) : context.go(Routes.diaryNotes);

  Future<void> _save() async {
    if (_saving || _blank) return;
    setState(() => _saving = true);
    final repo = ref.read(diaryNoteRepositoryProvider);
    final existing = _existing;
    if (existing != null) {
      await repo.update(
        existing.id,
        date: _date,
        title: _title.text,
        body: _body.text,
      );
    } else {
      await repo.add(date: _date, title: _title.text, body: _body.text);
    }
    if (!mounted) return;
    showDiaryToast(context, 'Note saved');
    // Saved: nothing left to lose, so leave without asking.
    _startTitle = _title.text;
    _startBody = _body.text;
    _startDate = _date;
    _leave(true);
  }

  Future<void> _delete() async {
    final existing = _existing;
    if (existing == null) return;
    final yes = await _confirm(
      title: 'Delete this note?',
      body: 'It will be removed from this phone. This can’t be undone.',
      yes: 'Delete note',
      no: 'Keep note',
    );
    if (!yes || !mounted) return;
    await ref.read(diaryNoteRepositoryProvider).delete(existing.id);
    if (!mounted) return;
    showDiaryToast(context, 'Note deleted');
    _startTitle = _title.text;
    _startBody = _body.text;
    _startDate = _date;
    _leave(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final editing = widget.noteId != null;
    return PopScope(
      canPop: !(_dirty && !_blank),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              CenteredHeader(
                title: editing ? 'Note' : 'New note',
                onBack: _back,
              ),
              Expanded(
                child: _loading
                    ? const SizedBox.shrink()
                    : _missing
                    ? Padding(
                        padding: const EdgeInsets.all(MoonSpace.gutter),
                        child: Text(
                          'We couldn’t find that note.',
                          style: MoonType.body.copyWith(color: c.text),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          MoonSpace.gutter,
                          8,
                          MoonSpace.gutter,
                          32,
                        ),
                        children: [
                          DiaryDateBar(
                            date: _date,
                            onPrevious: () =>
                                setState(() => _date = _date.addDays(-1)),
                            onNext: () => setState(() {
                              final today = ref.read(todayProvider);
                              final next = _date.addDays(1);
                              _date = next.isAfter(today) ? today : next;
                            }),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            key: const ValueKey('note-title'),
                            controller: _title,
                            onChanged: (_) => setState(() {}),
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: null,
                            style: fraunces(26, height: 1.2, color: c.text),
                            cursorColor: c.ochre,
                            decoration: InputDecoration.collapsed(
                              hintText: 'Title (optional)',
                              hintStyle: fraunces(
                                26,
                                height: 1.2,
                                color: c.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            key: const ValueKey('note-body'),
                            controller: _body,
                            onChanged: (_) => setState(() {}),
                            textCapitalization: TextCapitalization.sentences,
                            keyboardType: TextInputType.multiline,
                            minLines: 10,
                            maxLines: null,
                            style: dmSans(17, height: 1.65, color: c.text),
                            cursorColor: c.ochre,
                            decoration: InputDecoration.collapsed(
                              hintText: 'Write whatever you like…',
                              hintStyle: dmSans(
                                17,
                                height: 1.65,
                                color: c.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          MoonButton(
                            'Save note',
                            onPressed: _blank || _saving ? null : _save,
                          ),
                          if (editing) ...[
                            const SizedBox(height: 8),
                            Pressable(
                              onTap: _delete,
                              semanticLabel: 'Delete note',
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: 48,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Delete note',
                                  style: dmSans(
                                    15,
                                    weight: FontWeight.w600,
                                    height: 1.2,
                                    color: c.textMuted,
                                  ),
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
      ),
    );
  }
}
