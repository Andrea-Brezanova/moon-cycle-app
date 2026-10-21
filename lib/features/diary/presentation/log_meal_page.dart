import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_colors.dart';
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
import '../../content/domain/catalogue.dart';
import '../../content/domain/food.dart';
import '../../content/domain/text_match.dart';
import '../../entitlements/application/entitlement_providers.dart';
import '../../entitlements/domain/entitlements.dart';
import '../../foods/application/food_providers.dart';
import '../../generation/application/generation_providers.dart';
import '../../generation/domain/personal_recipe.dart';
import '../application/diary_providers.dart';
import '../data/diary_repository.dart';
import '../domain/diary_entry.dart';
import '../domain/diary_search.dart';
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

  bool _has(_Item r) =>
      _items.any((i) => i.kind == r.kind && i.itemId == r.itemId);

  /// A choice as a form item. A typed meal gets a stable stand-in id here (its
  /// own row id is made when it is saved).
  static _Item _itemOf(DiaryChoice c) => _Item(
    c.kind,
    c.kind == DiaryItemKind.custom
        ? 'custom-${normaliseName(c.title)}'
        : c.itemId,
    c.title,
    switch (c.kind) {
      DiaryItemKind.food => 'Food',
      DiaryItemKind.recipe => 'Recipe',
      DiaryItemKind.custom => 'Your own meal',
    },
  );

  /// The item to offer for a recent choice, or null when it can no longer be
  /// logged (its food or recipe is no longer in the catalogue).
  static _Item? _resolve(
    DiaryChoice r,
    Catalogue catalogue,
    List<PersonalRecipe> mine,
  ) => switch (r.kind) {
    DiaryItemKind.food => catalogue.food(r.itemId) == null ? null : _itemOf(r),
    DiaryItemKind.recipe =>
      catalogue.recipe(r.itemId) != null || mine.any((p) => p.id == r.itemId)
          ? _itemOf(r)
          : null,
    DiaryItemKind.custom => _itemOf(r),
  };

  static String _kindLabel(DiaryChoice c, bool recent) {
    final base = switch (c.kind) {
      DiaryItemKind.food => 'Food',
      DiaryItemKind.recipe => 'Recipe',
      DiaryItemKind.custom => 'Your own meal',
    };
    return recent ? '$base · logged before' : base;
  }

  void _close([bool saved = false]) =>
      context.canPop() ? context.pop(saved) : context.go(Routes.diary);

  void _add(_Item item) {
    if (_has(item)) return;
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

    final recents = ref.watch(recentChoicesProvider).value ?? const [];
    final recentKeys = {for (final r in recents) r.key};
    // Everything searchable: the whole catalogue (every phase), internal recipes,
    // the user's own recipes, and meals typed before.
    final pool = <DiaryChoice>[
      for (final f in catalogue.foods)
        DiaryChoice(
          DiaryItemKind.food,
          f.id,
          f.displayName,
          alternateNames: [f.name, ...f.synonyms],
        ),
      for (final r in catalogue.recipes)
        DiaryChoice(DiaryItemKind.recipe, r.id, r.title),
      for (final p in mine)
        DiaryChoice(DiaryItemKind.recipe, p.id, p.recipe.title),
      for (final r in recents)
        if (r.kind == DiaryItemKind.custom) r,
    ];
    final suggestions = q.isEmpty
        ? const <DiaryChoice>[]
        : rankChoices(_query, pool, recentKeys: recentKeys);
    // Recently logged, only what can still be logged: a food or recipe that has
    // left the catalogue is skipped, never an error.
    final recentItems = <_Item>[
      for (final r in recents) ?_resolve(r, catalogue, mine),
    ].take(10).toList();

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
                                      subtitle: _kindLabel(
                                        s,
                                        recentKeys.contains(s.key),
                                      ),
                                      onTap: () => _add(_itemOf(s)),
                                    ),
                                  // An explicit alternative, never the default.
                                  _SuggestionRow(
                                    title:
                                        'Or add “${_query.trim()}” as your own meal',
                                    subtitle: 'Your own meal',
                                    onTap: () => _add(
                                      _itemOf(
                                        DiaryChoice(
                                          DiaryItemKind.custom,
                                          '',
                                          _query.trim(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                        if (!_isEdit && recentItems.isNotEmpty) ...[
                          const SizedBox(height: 26),
                          DiarySection(
                            title: 'Recently logged',
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                for (final r in recentItems)
                                  MoonChip(
                                    r.title,
                                    onTap: () => _add(r),
                                    state: _has(r)
                                        ? MoonChipState.onList
                                        : MoonChipState.normal,
                                    palette: c.phase(
                                      label?.phase ?? Phase.follicular,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
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
                        if (!_isEdit) ...[
                          const SizedBox(height: 18),
                          _BrowseAllFoods(
                            palette: c.phase(label?.phase ?? Phase.follicular),
                            isAdded: (id) => _items.any(
                              (i) =>
                                  i.kind == DiaryItemKind.food &&
                                  i.itemId == id,
                            ),
                            onFood: (f) => _add(
                              _Item(
                                DiaryItemKind.food,
                                f.id,
                                f.displayName,
                                'Food',
                              ),
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

/// "Browse all foods": every food in the catalogue, from all four phases, by
/// the catalogue's own categories, with search. Phase suggestions are guidance;
/// this never restricts what can be logged. Collapsed until opened.
class _BrowseAllFoods extends ConsumerStatefulWidget {
  const _BrowseAllFoods({
    required this.palette,
    required this.isAdded,
    required this.onFood,
  });

  final PhasePalette palette;
  final bool Function(String foodId) isAdded;
  final void Function(Food food) onFood;

  @override
  ConsumerState<_BrowseAllFoods> createState() => _BrowseAllFoodsState();
}

class _BrowseAllFoodsState extends ConsumerState<_BrowseAllFoods> {
  var _open = false;
  var _query = '';
  final _search = TextEditingController();
  final _openCategories = <String>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final groups = ref.watch(allFoodsByCategoryProvider);
    final q = normaliseName(_query);
    final shown = [
      for (final (category, foods) in groups)
        if ([
              for (final f in foods)
                if (q.isEmpty ||
                    searchScore(
                          _query,
                          f.displayName,
                          alternates: [f.name, ...f.synonyms],
                        ) !=
                        null)
                  f,
            ]
            case final list when list.isNotEmpty)
          (category, list),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Pressable(
          onTap: () => setState(() => _open = !_open),
          expanded: _open,
          semanticLabel: 'Browse all foods',
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Browse all foods',
                    style: dmSans(
                      16,
                      weight: FontWeight.w600,
                      height: 1.3,
                      color: c.text,
                    ),
                  ),
                ),
                RotatedBox(
                  quarterTurns: _open ? 2 : 0,
                  child: MoonIcon(MoonIconName.down, size: 18, color: c.text),
                ),
              ],
            ),
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 12),
          MoonTextField(
            hint: 'Search all foods',
            leadingIcon: MoonIconName.search,
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 8),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'No foods match “${_query.trim()}”.',
                style: dmSans(15, height: 1.4, color: c.textMuted),
              ),
            ),
          for (final (category, foods) in shown)
            _CategoryBlock(
              name: category.name,
              count: foods.length,
              // A search opens every category that has a match.
              open: q.isNotEmpty || _openCategories.contains(category.id),
              onToggle: () => setState(
                () => _openCategories.contains(category.id)
                    ? _openCategories.remove(category.id)
                    : _openCategories.add(category.id),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final f in foods)
                    MoonChip(
                      f.displayName,
                      palette: widget.palette,
                      state: widget.isAdded(f.id)
                          ? MoonChipState.onList
                          : MoonChipState.normal,
                      onTap: () => widget.onFood(f),
                    ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _CategoryBlock extends StatelessWidget {
  const _CategoryBlock({
    required this.name,
    required this.count,
    required this.open,
    required this.onToggle,
    required this.child,
  });

  final String name;
  final int count;
  final bool open;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Pressable(
          onTap: onToggle,
          expanded: open,
          semanticLabel: '$name, $count foods',
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: fraunces(19, height: 1.2, color: c.text),
                  ),
                ),
                Text('$count', style: dmSans(13, color: c.textMuted)),
                const SizedBox(width: 10),
                RotatedBox(
                  quarterTurns: open ? 2 : 0,
                  child: MoonIcon(
                    MoonIconName.down,
                    size: 16,
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (open)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: child),
      ],
    );
  }
}
