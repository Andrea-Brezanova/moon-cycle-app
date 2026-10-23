import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/centered_header.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pill_choice.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/time/today.dart';
import '../data/diary_activity_repository.dart';
import '../domain/diary_activity.dart';
import 'diary_confirm_sheet.dart';
import 'diary_toast.dart';
import 'diary_widgets.dart';

/// Note or edit one activity: what, when, and (all optional) how long, how it
/// felt and a note. Nothing is saved until Save; leaving with unsaved changes
/// asks first. Stays on this phone; nothing is estimated or interpreted.
class DiaryActivityEditorPage extends ConsumerStatefulWidget {
  const DiaryActivityEditorPage({super.key, this.activityId, this.date});

  /// The activity to edit; null starts a new one.
  final String? activityId;

  /// The day a new activity starts on (today if null).
  final LocalDate? date;

  @override
  ConsumerState<DiaryActivityEditorPage> createState() =>
      _DiaryActivityEditorPageState();
}

class _DiaryActivityEditorPageState
    extends ConsumerState<DiaryActivityEditorPage> {
  final _name = TextEditingController();
  final _minutes = TextEditingController();
  final _note = TextEditingController();
  late LocalDate _date = widget.date ?? ref.read(todayProvider);
  ActivityType? _type;
  ActivityIntensity? _intensity;

  DiaryActivity? _existing;
  bool _loading = false;
  bool _missing = false;
  bool _saving = false;

  // What the page started with, to tell whether anything changed.
  late LocalDate _startDate = _date;
  ActivityType? _startType;
  ActivityIntensity? _startIntensity;
  String _startName = '';
  String _startMinutes = '';
  String _startNote = '';

  @override
  void initState() {
    super.initState();
    final id = widget.activityId;
    if (id == null) return;
    _loading = true;
    ref.read(diaryActivityRepositoryProvider).byId(id).then((a) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (a == null) {
          _missing = true;
          return;
        }
        _existing = a;
        _date = _startDate = a.date;
        _type = _startType = a.type;
        _intensity = _startIntensity = a.intensity;
        _startName = a.customName ?? '';
        _startMinutes = a.minutes?.toString() ?? '';
        _startNote = a.note ?? '';
        _name.text = _startName;
        _minutes.text = _startMinutes;
        _note.text = _startNote;
      });
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _minutes.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _date != _startDate ||
      _type != _startType ||
      _intensity != _startIntensity ||
      _name.text != _startName ||
      _minutes.text != _startMinutes ||
      _note.text != _startNote;

  /// A duration was typed but isn't 1 to 1440.
  bool get _minutesInvalid =>
      _minutes.text.trim().isNotEmpty && parseMinutes(_minutes.text) == null;

  bool get _canSave => _type != null && !_minutesInvalid;

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
    if (_dirty && !(_existing == null && _type == null)) {
      final discard = await _confirm(
        title: 'Discard your changes?',
        body: 'This activity hasn’t been saved yet.',
        yes: 'Discard',
        no: 'Keep editing',
      );
      if (!discard || !mounted) return;
    }
    if (mounted) _leave();
  }

  void _leave([bool saved = false]) => context.canPop()
      ? context.pop(saved)
      : context.go(Routes.diaryActivities);

  void _markClean() {
    _startDate = _date;
    _startType = _type;
    _startIntensity = _intensity;
    _startName = _name.text;
    _startMinutes = _minutes.text;
    _startNote = _note.text;
  }

  Future<void> _save() async {
    final type = _type;
    if (_saving || type == null || !_canSave) return;
    setState(() => _saving = true);
    final repo = ref.read(diaryActivityRepositoryProvider);
    final existing = _existing;
    final minutes = parseMinutes(_minutes.text);
    if (existing != null) {
      await repo.update(
        existing.id,
        date: _date,
        type: type,
        customName: _name.text,
        minutes: minutes,
        intensity: _intensity,
        note: _note.text,
      );
    } else {
      await repo.add(
        date: _date,
        type: type,
        customName: _name.text,
        minutes: minutes,
        intensity: _intensity,
        note: _note.text,
      );
    }
    if (!mounted) return;
    showDiaryToast(context, 'Activity saved');
    _markClean();
    _leave(true);
  }

  Future<void> _delete() async {
    final existing = _existing;
    if (existing == null) return;
    final yes = await _confirm(
      title: 'Delete this activity?',
      body: 'It will be removed from this phone. This can’t be undone.',
      yes: 'Delete activity',
      no: 'Keep activity',
    );
    if (!yes || !mounted) return;
    await ref.read(diaryActivityRepositoryProvider).delete(existing.id);
    if (!mounted) return;
    showDiaryToast(context, 'Activity deleted');
    _markClean();
    _leave(true);
  }

  Widget _field(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    int minLines = 1,
    Key? key,
    String? suffix,
  }) {
    final c = context.moon;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: c.raised,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(minLines > 1 ? 22 : 28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              key: key,
              controller: controller,
              onChanged: (_) => setState(() {}),
              keyboardType: keyboardType,
              inputFormatters: formatters,
              textCapitalization: TextCapitalization.sentences,
              minLines: minLines,
              maxLines: minLines > 1 ? null : 1,
              style: dmSans(16, height: 1.5, color: c.text),
              cursorColor: c.ochre,
              decoration: InputDecoration.collapsed(
                hintText: hint,
                hintStyle: dmSans(16, height: 1.5, color: c.textMuted),
              ),
            ),
          ),
          if (suffix != null) ...[
            const SizedBox(width: 8),
            Text(suffix, style: dmSans(15, height: 1.5, color: c.textMuted)),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final editing = widget.activityId != null;
    return PopScope(
      canPop: !(_dirty && !(_existing == null && _type == null)),
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
                title: editing ? 'Activity' : 'New activity',
                onBack: _back,
              ),
              Expanded(
                child: _loading
                    ? const SizedBox.shrink()
                    : _missing
                    ? Padding(
                        padding: const EdgeInsets.all(MoonSpace.gutter),
                        child: Text(
                          'We couldn’t find that activity.',
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
                          const SizedBox(height: 22),
                          const Overline('What did you do?'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              for (final t in ActivityType.values)
                                PillChoice(
                                  label: t.label,
                                  selected: _type == t,
                                  onTap: () => setState(() => _type = t),
                                ),
                            ],
                          ),
                          if (_type == ActivityType.other) ...[
                            const SizedBox(height: 12),
                            _field(
                              context,
                              key: const ValueKey('activity-name'),
                              controller: _name,
                              hint: 'Name (optional)',
                            ),
                          ],
                          const SizedBox(height: 22),
                          const Overline('How long? (optional)'),
                          const SizedBox(height: 8),
                          _field(
                            context,
                            key: const ValueKey('activity-minutes'),
                            controller: _minutes,
                            hint: 'Minutes',
                            suffix: 'min',
                            keyboardType: TextInputType.number,
                            formatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                          ),
                          if (_minutesInvalid) ...[
                            const SizedBox(height: 6),
                            Text(
                              key: const ValueKey('minutes-error'),
                              'Enter a number of minutes from 1 to '
                              '$maxActivityMinutes, or leave it empty.',
                              style: dmSans(
                                13,
                                height: 1.4,
                                color: c.destructive,
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          const Overline('How did it feel? (optional)'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              for (final i in ActivityIntensity.values)
                                PillChoice(
                                  label: i.label,
                                  selected: _intensity == i,
                                  // Tap again to take it back.
                                  onTap: () => setState(
                                    () =>
                                        _intensity = _intensity == i ? null : i,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          const Overline('A note (optional)'),
                          const SizedBox(height: 8),
                          _field(
                            context,
                            key: const ValueKey('activity-note'),
                            controller: _note,
                            hint: 'Anything you’d like to remember',
                            minLines: 3,
                            keyboardType: TextInputType.multiline,
                          ),
                          const SizedBox(height: 26),
                          MoonButton(
                            'Save activity',
                            onPressed: _canSave && !_saving ? _save : null,
                          ),
                          if (editing) ...[
                            const SizedBox(height: 8),
                            Pressable(
                              onTap: _delete,
                              semanticLabel: 'Delete activity',
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: 48,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Delete activity',
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
