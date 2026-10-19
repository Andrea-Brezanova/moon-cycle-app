import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/moon_chip.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/domain/phase.dart';
import '../../../core/time/today.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../content/domain/text_match.dart';
import '../../entitlements/application/entitlement_providers.dart';
import '../../entitlements/domain/entitlements.dart';
import '../../generation/application/generation_providers.dart';
import '../application/diary_providers.dart';
import '../data/diary_repository.dart';
import '../domain/diary_entry.dart';
import 'diary_toast.dart';
import 'diary_widgets.dart';

/// Log a meal (or edit one): a full-screen form over the tab bar.
///
/// Several items can go into one meal; each is saved as its own entry with the
/// shared note. Amounts and units are not asked for (a new entry is one
/// serving); editing an entry keeps its amount and unit as they were.
class LogMealPage extends ConsumerStatefulWidget {
  const LogMealPage({
    super.key,
    this.meal,
    this.kind,
    this.itemId,
    this.title,
    this.date,
    this.editId,
    this.from,
  });

  final DiaryMeal? meal;
  final DiaryItemKind? kind;
  final String? itemId;
  final String? title;
  final LocalDate? date;
  final String? editId;

  /// `food` or `recipe`: the page this was opened from, if any.
  final String? from;

  @override
  ConsumerState<LogMealPage> createState() => _LogMealPageState();
}

class _Item {
  const _Item(this.kind, this.itemId, this.title, this.subtitle);
  final DiaryItemKind kind;
  final String itemId;
  final String title;
  final String subtitle;
}

class _LogMealPageState extends ConsumerState<LogMealPage> {
  late LocalDate _date;
  late DiaryMeal _meal;
  final _items = <_Item>[];
  final _note = TextEditingController();
  final _search = TextEditingController();
  var _query = '';
  DiaryEntry? _editing;
  var _loading = false;
  var _saving = false;

  bool get _isEdit => widget.editId != null;

  @override
  void initState() {
    super.initState();
    _date = widget.date ?? ref.read(todayProvider);
    _meal = widget.meal ?? DiaryMeal.forHour(ref.read(clockProvider)().hour);
    if (widget.itemId != null && widget.kind != null && widget.title != null) {
      _items.add(
        _Item(
          widget.kind!,
          widget.itemId!,
          widget.title!,
          _subtitle(widget.kind!, widget.from),
        ),
      );
    }
    if (_isEdit) {
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    final e = await ref.read(diaryRepositoryProvider).entry(widget.editId!);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _editing = e;
      if (e != null) {
        _date = e.date;
        _meal = e.meal;
        _note.text = e.note ?? '';
        _items.add(_Item(e.kind, e.itemId, e.title, _subtitle(e.kind, null)));
      }
    });
  }

  static String _subtitle(DiaryItemKind kind, String? from) => switch (kind) {
    DiaryItemKind.recipe =>
      from == 'recipe' ? 'Recipe · added from the recipe page' : 'Recipe',
    DiaryItemKind.custom => 'Your own meal',
    DiaryItemKind.food =>
      from == 'food' ? 'Food · added from the food page' : 'Food',
  };

  @override
  void dispose() {
    _note.dispose();
    _search.dispose();
    super.dispose();
  }

  void _close([bool saved = false]) =>
      context.canPop() ? context.pop(saved) : context.go(Routes.diary);

  void _add(_Item item) {
    if (_items.any((i) => i.kind == item.kind && i.itemId == item.itemId)) {
      return;
    }
    setState(() {
      _items.add(item);
      _search.clear();
      _query = '';
    });
  }

  Future<void> _save() async {
    if (_saving || _items.isEmpty) return;
    setState(() => _saving = true);
    final repo = ref.read(diaryRepositoryProvider);
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final e = _editing;
    if (e != null) {
      await repo.update(
        e.id,
        meal: _meal,
        date: _date,
        note: Value(note),
        title: e.kind == DiaryItemKind.custom ? _items.first.title : null,
      );
    } else {
      for (final i in _items) {
        await repo.add(
          DiaryDraft(
            date: _date,
            meal: _meal,
            kind: i.kind,
            itemId: i.kind == DiaryItemKind.custom ? '' : i.itemId,
            title: i.title,
            amount: 1,
            unit: DiaryUnit.serving,
            note: note,
          ),
        );
      }
    }
    if (!mounted) return;
    ref.read(diaryDateProvider.notifier).show(_date);
    final router = GoRouter.of(context);
    final date = _date;
    showDiaryToast(
      context,
      e != null ? 'Diary updated' : 'Added to your diary',
      actionLabel: widget.from != null ? 'View' : null,
      onAction: () => router.go(Routes.diaryOn(date: date)),
    );
    _close(true);
  }

  Future<void> _delete() async {
    final e = _editing;
    if (e == null) return;
    final yes = await showMoonSheet<bool>(
      context,
      builder: (ctx) => _ConfirmDelete(title: e.title),
    );
    if (yes != true || !mounted) return;
    await ref.read(diaryRepositoryProvider).delete(e.id);
    if (!mounted) return;
    showDiaryToast(context, 'Entry deleted');
    _close(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final allowed = ref.watch(featureGateProvider).canUse(Feature.logDiary);
    final today = ref.watch(todayProvider);
    final label = ref.watch(phaseDayLabelProvider(_date));
    final catalogue = ref.watch(catalogueProvider);
    final filter = ref.watch(foodFilterProvider);
    final mine = ref.watch(personalRecipesProvider).value ?? const [];
    final q = normaliseName(_query);

    final suggestions = <_Item>[
      if (q.isNotEmpty) ...[
        for (final f in catalogue.foods)
          if (normaliseName(f.displayName).contains(q))
            _Item(DiaryItemKind.food, f.id, f.displayName, 'Food'),
        for (final r in catalogue.recipes)
          if (normaliseName(r.title).contains(q))
            _Item(DiaryItemKind.recipe, r.id, r.title, 'Recipe'),
        for (final p in mine)
          if (normaliseName(p.recipe.title).contains(q))
            _Item(DiaryItemKind.recipe, p.id, p.recipe.title, 'Recipe'),
      ],
    ].take(6).toList();

    final phaseFoods = label == null
        ? const <Food>[]
        : [
            for (final f in catalogue.foodsFor(label.phase))
              if (filter.allowsFood(f)) f,
          ].take(10).toList();

    return Scaffold(
      backgroundColor: c.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: DiaryFormHeader(
                title: _isEdit ? 'Edit meal' : 'Log a meal',
                onCancel: _close,
              ),
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
                  : _loading
                  ? const SizedBox()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        DiaryDateBar(
                          date: _date,
                          onPrevious: () =>
                              setState(() => _date = _date.addDays(-1)),
                          onNext: () => setState(() {
                            final n = _date.addDays(1);
                            _date = n.isAfter(today) ? today : n;
                          }),
                        ),
                        const SizedBox(height: 26),
                        DiarySection(
                          title: 'Meal',
                          child: _MealTiles(
                            selected: _meal,
                            onChanged: (m) => setState(() => _meal = m),
                          ),
                        ),
                        const SizedBox(height: 26),
                        DiarySection(
                          title: _isEdit ? 'What you ate' : 'What did you eat?',
                          hint: _items.isEmpty
                              ? null
                              : '${_items.length} ${_items.length == 1 ? 'item' : 'items'}',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final (i, item) in _items.indexed)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _ItemRow(
                                    item: item,
                                    phase: label?.phase,
                                    onRemove: _isEdit
                                        ? null
                                        : () => setState(
                                            () => _items.removeAt(i),
                                          ),
                                  ),
                                ),
                              if (!_isEdit) ...[
                                _SearchField(
                                  controller: _search,
                                  onChanged: (v) => setState(() => _query = v),
                                ),
                                if (q.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  for (final s in suggestions)
                                    _SuggestionRow(
                                      title: s.title,
                                      subtitle: s.subtitle,
                                      onTap: () => _add(s),
                                    ),
                                  _SuggestionRow(
                                    title:
                                        'Add “${_query.trim()}” as your own meal',
                                    subtitle: 'Your own meal',
                                    onTap: () => _add(
                                      _Item(
                                        DiaryItemKind.custom,
                                        'custom-${_items.length}-${_query.trim()}',
                                        _query.trim(),
                                        'Your own meal',
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                        if (!_isEdit && phaseFoods.isNotEmpty) ...[
                          const SizedBox(height: 26),
                          DiarySection(
                            title: 'From your phase foods',
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                for (final f in phaseFoods)
                                  MoonChip(
                                    f.displayName,
                                    onTap: () => _add(
                                      _Item(
                                        DiaryItemKind.food,
                                        f.id,
                                        f.displayName,
                                        'Food',
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 26),
                        DiarySection(
                          title: 'Note · optional',
                          child: DiaryNoteField(
                            controller: _note,
                            hint: 'How was it? Anything to remember…',
                            semanticLabel: 'Note, optional',
                          ),
                        ),
                        if (_isEdit) ...[
                          const SizedBox(height: 22),
                          Center(
                            child: TextLink(
                              'Delete entry',
                              onTap: _delete,
                              color: c.destructive,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            if (allowed && !_loading)
              DiarySaveBar(
                label: _isEdit ? 'Save changes' : 'Save to diary',
                onPressed: _items.isEmpty || _saving ? null : _save,
              ),
          ],
        ),
      ),
    );
  }
}

class _MealTiles extends StatelessWidget {
  const _MealTiles({required this.selected, required this.onChanged});

  final DiaryMeal selected;
  final ValueChanged<DiaryMeal> onChanged;

  static const _icons = {
    DiaryMeal.breakfast: MoonIconName.cup,
    DiaryMeal.lunch: MoonIconName.recipes,
    DiaryMeal.dinner: MoonIconName.utensils,
    DiaryMeal.snack: MoonIconName.apple,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Row(
      children: [
        for (final (i, m) in DiaryMeal.values.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Pressable(
              onTap: () => onChanged(m),
              selected: m == selected,
              semanticLabel: m.label,
              child: Container(
                constraints: const BoxConstraints(minHeight: 74),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: m == selected ? c.inverseBg : c.raised,
                  border: m == selected ? null : Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MoonIcon(
                      _icons[m]!,
                      size: 24,
                      color: m == selected ? c.inverseText : c.text,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      m.label,
                      style: dmSans(
                        13,
                        weight: FontWeight.w600,
                        height: 1.2,
                        color: m == selected ? c.inverseText : c.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.phase, this.onRemove});

  final _Item item;
  final Phase? phase;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6),
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: switch (phase) {
          final Phase p => diarySurfaceFor(context, p),
          null => c.sand,
        },
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: dmSans(
                    16,
                    weight: FontWeight.w600,
                    height: 1.3,
                    color: c.text,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: dmSans(13, height: 1.3, color: c.textMuted),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            Pressable(
              onTap: onRemove,
              semanticLabel: 'Remove ${item.title}',
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: MoonIcon(
                  MoonIconName.close,
                  size: 16,
                  strokeWidth: 2,
                  color: c.textMuted,
                ),
              ),
            )
          else
            const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => MoonTextField(
    hint: 'Add a food or recipe',
    leadingIcon: MoonIconName.search,
    controller: controller,
    onChanged: onChanged,
  );
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Pressable(
      onTap: onTap,
      semanticLabel: '$title, $subtitle',
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
                title,
                style: dmSans(
                  16,
                  weight: FontWeight.w500,
                  height: 1.3,
                  color: c.text,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(subtitle, style: dmSans(13, color: c.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _ConfirmDelete extends StatelessWidget {
  const _ConfirmDelete({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Delete this entry?',
            style: fraunces(24, height: 1.15, color: c.text),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '“$title” will be removed from your diary.',
          style: dmSans(15, height: 1.5, color: c.textMuted),
        ),
        const SizedBox(height: 22),
        Pressable(
          onTap: () => Navigator.of(context, rootNavigator: true).pop(true),
          semanticLabel: 'Delete entry',
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: c.destructive,
              shape: const StadiumBorder(),
            ),
            child: Text(
              'Delete entry',
              style: dmSans(
                16,
                weight: FontWeight.w600,
                height: 1.2,
                color: c.onDestructive,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Pressable(
          onTap: () => Navigator.of(context, rootNavigator: true).pop(false),
          semanticLabel: 'Keep entry',
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            child: Text(
              'Keep entry',
              style: dmSans(
                16,
                weight: FontWeight.w600,
                height: 1.2,
                color: c.text,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
