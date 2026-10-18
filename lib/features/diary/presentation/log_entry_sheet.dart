import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_chip.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/time/today.dart';
import '../data/diary_repository.dart';
import '../domain/diary_entry.dart';

/// Adds an item to the diary, or edits an entry: which meal, which day and how
/// much. Returns true once something was saved or deleted.
Future<bool?> showLogEntrySheet(
  BuildContext context, {
  DiaryDraft? draft,
  DiaryEntry? editing,
}) {
  assert((draft == null) != (editing == null));
  return showMoonSheet<bool>(
    context,
    builder: (_) => _LogEntry(draft: draft, editing: editing),
  );
}

/// A starting draft for logging [itemId] now.
DiaryDraft draftFor({
  required DiaryItemKind kind,
  required String itemId,
  required String title,
  required LocalDate today,
  required DateTime now,
}) => DiaryDraft(
  date: today,
  meal: DiaryMeal.forHour(now.hour),
  kind: kind,
  itemId: itemId,
  title: title,
  amount: 1,
  unit: DiaryUnit.serving,
);

class _LogEntry extends ConsumerStatefulWidget {
  const _LogEntry({this.draft, this.editing});

  final DiaryDraft? draft;
  final DiaryEntry? editing;

  @override
  ConsumerState<_LogEntry> createState() => _LogEntryState();
}

class _LogEntryState extends ConsumerState<_LogEntry> {
  late DiaryMeal _meal;
  late LocalDate _date;
  late double _amount;
  late DiaryUnit _unit;
  late final DiaryItemKind _kind;
  late final String _title;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    final d = widget.draft;
    _meal = e?.meal ?? d!.meal;
    _date = e?.date ?? d!.date;
    _amount = e?.amount ?? d!.amount;
    _unit = e?.unit ?? d!.unit;
    _kind = e?.kind ?? d!.kind;
    _title = e?.title ?? d!.title;
  }

  bool get _isRecipe => _kind == DiaryItemKind.recipe;

  Future<void> _save() async {
    final repo = ref.read(diaryRepositoryProvider);
    final e = widget.editing;
    if (e != null) {
      await repo.update(
        e.id,
        amount: _amount,
        meal: _meal,
        date: _date,
        unit: _unit,
      );
    } else {
      final d = widget.draft!;
      await repo.add(
        DiaryDraft(
          date: _date,
          meal: _meal,
          kind: d.kind,
          itemId: d.itemId,
          title: d.title,
          amount: _amount,
          unit: _unit,
        ),
      );
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    await ref.read(diaryRepositoryProvider).delete(widget.editing!.id);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _pickDate() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_date.year, _date.month, _date.day),
      firstDate: DateTime(today.year - 2),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (picked != null) setState(() => _date = LocalDate.fromDateTime(picked));
  }

  void _setUnit(DiaryUnit unit) => setState(() {
    _unit = unit;
    _amount = unit.defaultAmount;
  });

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final today = ref.watch(todayProvider);
    final yesterday = today.addDays(-1);
    final editing = widget.editing != null;
    final units = _isRecipe ? const [DiaryUnit.serving] : DiaryUnit.values;

    Widget stepper() => Row(
      children: [
        RoundIconButton(
          MoonIconName.minus,
          semanticLabel: 'Less',
          onPressed: _amount > _unit.step
              ? () => setState(() => _amount -= _unit.step)
              : null,
        ),
        Expanded(
          child: Semantics(
            label: 'Amount, ${_unit.format(_amount)}',
            excludeSemantics: true,
            child: Text(
              _unit.format(_amount),
              key: const ValueKey('diary-amount'),
              textAlign: TextAlign.center,
              style: fraunces(26, height: 1.1, color: c.text),
            ),
          ),
        ),
        RoundIconButton(
          MoonIconName.plus,
          semanticLabel: 'More',
          onPressed: _amount < 9999
              ? () => setState(() => _amount += _unit.step)
              : null,
        ),
      ],
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              editing ? 'Edit entry' : 'Add to your diary',
              style: fraunces(28, height: 1.1, color: c.text),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _title,
            style: dmSans(16, weight: FontWeight.w500, color: c.textMuted),
          ),
          const SizedBox(height: 20),
          const Overline('Meal'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in DiaryMeal.values)
                MoonChip(
                  m.label,
                  state: m == _meal
                      ? MoonChipState.selected
                      : MoonChipState.normal,
                  onTap: () => setState(() => _meal = m),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Overline('Day'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MoonChip(
                'Today',
                state: _date == today
                    ? MoonChipState.selected
                    : MoonChipState.normal,
                onTap: () => setState(() => _date = today),
              ),
              MoonChip(
                'Yesterday',
                state: _date == yesterday
                    ? MoonChipState.selected
                    : MoonChipState.normal,
                onTap: () => setState(() => _date = yesterday),
              ),
              MoonChip(
                _date == today || _date == yesterday
                    ? 'Another day'
                    : '${_date.day}/${_date.month}/${_date.year}',
                state: _date == today || _date == yesterday
                    ? MoonChipState.normal
                    : MoonChipState.selected,
                onTap: _pickDate,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Overline('How much'),
          const SizedBox(height: 8),
          if (units.length > 1) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final u in units)
                  MoonChip(
                    u == DiaryUnit.serving ? 'Servings' : u.id,
                    state: u == _unit
                        ? MoonChipState.selected
                        : MoonChipState.normal,
                    onTap: () => _setUnit(u),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          stepper(),
          const SizedBox(height: 24),
          MoonButton(
            editing ? 'Save changes' : 'Add to diary',
            onPressed: _save,
          ),
          if (editing) ...[
            const SizedBox(height: 12),
            Center(child: TextLink('Delete this entry', onTap: _delete)),
          ],
        ],
      ),
    );
  }
}

/// The clock for sheets that need "now".
final diaryNowProvider = Provider<DateTime>((ref) => ref.read(clockProvider)());
