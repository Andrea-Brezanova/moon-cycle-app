import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_chip.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/time/today.dart';
import '../../cycle/application/viewing_phase.dart' show actualPhaseProvider;
import '../../entitlements/application/entitlement_providers.dart';
import '../../entitlements/domain/entitlements.dart';
import '../application/diary_providers.dart';
import '../data/symptom_repository.dart';
import '../domain/symptoms.dart';
import 'diary_toast.dart';
import 'diary_widgets.dart';

/// Log symptoms (or edit the day's check-in): a full-screen form over the tab
/// bar. Everything is optional; tap what fits and save. Nothing is scored or
/// interpreted.
class LogSymptomsPage extends ConsumerStatefulWidget {
  const LogSymptomsPage({super.key, this.date});

  final LocalDate? date;

  @override
  ConsumerState<LogSymptomsPage> createState() => _LogSymptomsPageState();
}

class _LogSymptomsPageState extends ConsumerState<LogSymptomsPage> {
  late LocalDate _date;
  EnergyLevel? _energy;
  SleepQuality? _sleep;
  final _moods = <Mood>{};
  final _body = <BodySymptom, Strength?>{};
  final _note = TextEditingController();
  var _hadAnswers = false;
  var _loading = true;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _date = widget.date ?? ref.read(todayProvider);
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// Fills the form with what is already recorded for [_date], so editing
  /// starts from the saved answers and never silently replaces them.
  Future<void> _load() async {
    final d = await ref.read(symptomRepositoryProvider).day(_date);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _hadAnswers = d != null;
      _energy = d?.energy;
      _sleep = d?.sleep;
      _moods
        ..clear()
        ..addAll(d?.moods ?? const {});
      _body
        ..clear()
        ..addAll(d?.body ?? const {});
      _note.text = d?.note ?? '';
    });
  }

  void _close() => context.canPop() ? context.pop() : context.go(Routes.diary);

  SymptomDay _current() => SymptomDay(
    date: _date,
    energy: _energy,
    sleep: _sleep,
    moods: {
      for (final m in Mood.values)
        if (_moods.contains(m)) m,
    },
    body: {
      for (final b in BodySymptom.values)
        if (_body.containsKey(b)) b: _body[b],
    },
    note: _note.text.trim().isEmpty ? null : _note.text.trim(),
  );

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final day = _current();
    final repo = ref.read(symptomRepositoryProvider);
    if (day.isEmpty) {
      if (_hadAnswers) await repo.clearDay(_date);
    } else {
      await repo.saveDay(day);
    }
    if (!mounted) return;
    ref.read(diaryDateProvider.notifier).show(_date);
    showDiaryToast(
      context,
      day.isEmpty ? 'Check-in cleared' : 'Check-in saved',
    );
    context.canPop() ? context.pop(true) : context.go(Routes.diary);
  }

  void _changeDate(LocalDate d) {
    final today = ref.read(todayProvider);
    setState(() {
      _date = d.isAfter(today) ? today : d;
      _loading = true;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final allowed = ref.watch(featureGateProvider).canUse(Feature.logDiary);
    final label = ref.watch(phaseDayLabelProvider(_date));
    final palette = c.phase(label?.phase ?? ref.watch(actualPhaseProvider));
    final today = ref.watch(todayProvider);
    final isToday = _date == today;

    return Scaffold(
      backgroundColor: c.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: DiaryFormHeader(title: 'Log symptoms', onCancel: _close),
            ),
            Expanded(
              child: !allowed
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Log Diary is part of Moon Cycle Premium.',
                        style: MoonType.body.copyWith(color: c.text),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        DiaryDateBar(
                          date: _date,
                          onPrevious: () => _changeDate(_date.addDays(-1)),
                          onNext: () => _changeDate(_date.addDays(1)),
                        ),
                        const SizedBox(height: 22),
                        Semantics(
                          header: true,
                          child: EditorialHeading(
                            isToday
                                ? 'How are you feeling *today?*'
                                : 'How were you feeling?',
                            style: fraunces(30, height: 1.1),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap anything that fits and skip the rest.',
                          style: dmSans(15, height: 1.5, color: c.textMuted),
                        ),
                        const SizedBox(height: 30),
                        DiarySection(
                          title: 'Energy',
                          child: DiaryChoiceRow<EnergyLevel>(
                            semanticLabel: 'Energy',
                            options: [
                              for (final e in EnergyLevel.values) (e, e.label),
                            ],
                            selected: _energy,
                            onChanged: (v) => setState(() => _energy = v),
                          ),
                        ),
                        const SizedBox(height: 30),
                        DiarySection(
                          title: 'Mood',
                          hint: 'Choose any',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              for (final m in Mood.values)
                                MoonChip(
                                  m.label,
                                  palette: palette,
                                  state: _moods.contains(m)
                                      ? MoonChipState.onList
                                      : MoonChipState.normal,
                                  onTap: () => setState(
                                    () => _moods.contains(m)
                                        ? _moods.remove(m)
                                        : _moods.add(m),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        DiarySection(
                          title: 'Body',
                          hint: 'Choose any',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  for (final b in BodySymptom.values)
                                    MoonChip(
                                      b.label,
                                      palette: palette,
                                      state: _body.containsKey(b)
                                          ? MoonChipState.onList
                                          : MoonChipState.normal,
                                      onTap: () => setState(() {
                                        if (_body.containsKey(b)) {
                                          _body.remove(b);
                                        } else {
                                          _body[b] = null;
                                        }
                                      }),
                                    ),
                                ],
                              ),
                              // A strength panel exists only while its symptom
                              // is chosen, in chip order.
                              for (final b in BodySymptom.values)
                                if (_body.containsKey(b))
                                  Padding(
                                    key: ValueKey('strength-${b.key}'),
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: diarySurfaceFor(
                                          context,
                                          label?.phase ??
                                              ref.watch(actualPhaseProvider),
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            '${b.label} · ${b.strengthQuestion}',
                                            style: dmSans(
                                              14,
                                              weight: FontWeight.w600,
                                              height: 1.3,
                                              color: c.text,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          DiaryChoiceRow<Strength>(
                                            semanticLabel:
                                                '${b.label} ${b.strengthQuestion}',
                                            options: [
                                              for (final s in b.strengths)
                                                (s, s.label),
                                            ],
                                            selected: _body[b],
                                            onChanged: (v) =>
                                                setState(() => _body[b] = v),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        DiarySection(
                          title: 'Sleep',
                          hint: 'Last night',
                          child: DiaryChoiceRow<SleepQuality>(
                            semanticLabel: 'Sleep',
                            options: [
                              for (final s in SleepQuality.values) (s, s.label),
                            ],
                            selected: _sleep,
                            onChanged: (v) => setState(() => _sleep = v),
                          ),
                        ),
                        const SizedBox(height: 30),
                        DiarySection(
                          title: 'Note · optional',
                          child: DiaryNoteField(
                            controller: _note,
                            hint: 'Anything you’d like to remember…',
                            semanticLabel: 'Note, optional',
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Your diary is just for you. Moon Cycle doesn’t '
                          'interpret symptoms or link them to a diagnosis.',
                          style: dmSans(13, height: 1.5, color: c.removeIcon),
                        ),
                      ],
                    ),
            ),
            if (allowed)
              DiarySaveBar(
                label: 'Save',
                onPressed: _loading || _saving ? null : _save,
              ),
          ],
        ),
      ),
    );
  }
}
