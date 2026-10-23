import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_colors.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/centered_header.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/design/widgets/tap_target.dart';
import '../../../core/domain/browse_scope.dart';
import '../../../core/time/today.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../content/domain/text_match.dart';
import '../../cycle/application/viewing_phase.dart';
import '../../eat/presentation/phase_pill.dart';
import '../../home/presentation/widgets/plant_photos.dart';
import '../../shopping/application/shopping_controller.dart';
import '../../shopping/application/shopping_summary.dart';
import '../../shopping/domain/shopping_item.dart';
import '../application/browse_scope.dart';
import '../application/food_providers.dart';
import '../application/todays_food.dart';
import 'food_emoji.dart';
import 'widgets/todays_food_card.dart';

/// The Foods screen (V2): a centred title with back and search, the phase
/// selector, category chips, today's food, then the foods as a list. The
/// viewing phase's foods (stored order is not used: the list is A–Z), or every
/// recommended food with "All phases". Avoided foods are hidden. Choosing a
/// category shows only its foods and hides today's food.
class FoodsPage extends ConsumerStatefulWidget {
  const FoodsPage({super.key});

  @override
  ConsumerState<FoodsPage> createState() => _FoodsPageState();
}

class _FoodsPageState extends ConsumerState<FoodsPage> {
  String? _openFoodId;

  /// The chosen category's name; null shows every category.
  String? _category;

  /// The search field is shown ("All phases" always shows it).
  bool _searching = false;

  final _search = TextEditingController();
  String _query = '';

  /// Opens the food's page. From "This phase" it explains the food for the
  /// viewing phase; from "All foods" it opens without phase context. The page
  /// is pushed on top, so Back returns here with the same filter.
  Future<void> _open(Food food) async {
    setState(() => _openFoodId = food.id);
    final all = ref.read(foodsScopeProvider) == BrowseScope.all;
    await context.push<void>(
      Routes.food(food.id, phase: ref.read(viewingPhaseProvider), general: all),
    );
    if (mounted) setState(() => _openFoodId = null);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _search.clear();
    setState(() => _query = '');
  }

  void _toggleSearch() {
    setState(() => _searching = !_searching);
    if (!_searching) _clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final phase = ref.watch(viewingPhaseProvider);
    final actual = ref.watch(actualPhaseProvider);
    final todays = ref.watch(todaysFoodProvider);
    final all = ref.watch(foodsScopeProvider) == BrowseScope.all;
    final palette = c.phase(phase);
    final catalogue = ref.watch(catalogueProvider);
    final filter = ref.watch(foodFilterProvider);
    final content = catalogue.phase(phase);
    final listed = <String, ShoppingItem>{
      for (final i
          in ref.watch(shoppingItemsProvider).value ?? const <ShoppingItem>[])
        if (i.foodId != null) i.foodId!: i,
    };
    final q = normaliseName(_query);
    bool matches(Food f) =>
        q.isEmpty ||
        normaliseName(f.name).contains(q) ||
        f.synonyms.any((s) => normaliseName(s).contains(q));

    final groups = all
        ? ref.watch(allFoodsByCategoryProvider)
        : [
            for (final category in content.categories)
              (
                category.category,
                [for (final id in category.foodIds) ?catalogue.food(id)],
              ),
          ];
    // Only the foods the user's preferences allow; a category with none left
    // has no chip.
    final allowed = [
      for (final (category, foods) in groups)
        (
          category.name,
          [
            for (final f in foods)
              if (filter.allowsFood(f)) f,
          ],
        ),
    ].where((g) => g.$2.isNotEmpty).toList();
    final chips = [for (final (name, _) in allowed) name];
    // A category the phase doesn't have falls back to "All".
    final category = chips.contains(_category) ? _category : null;
    final shown =
        [
          for (final (name, foods) in allowed)
            if (category == null || name == category)
              for (final f in foods)
                if (matches(f)) (f, name),
        ]..sort(
          (a, b) => a.$1.displayName.toLowerCase().compareTo(
            b.$1.displayName.toLowerCase(),
          ),
        );
    final showSearch = all || _searching;
    final phaseName = all ? 'All phases' : content.name;
    final countLabel = all
        ? '${shown.length} ${shown.length == 1 ? 'food' : 'foods'}'
        : '${shown.length} for your phase';

    Widget gutter(Widget child, {double top = 0}) => Padding(
      padding: EdgeInsets.fromLTRB(MoonSpace.gutter, top, MoonSpace.gutter, 0),
      child: child,
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CenteredHeader(
              title: 'Foods',
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(AppTab.eat.path),
              trailingIcon: MoonIconName.search,
              trailingLabel: 'Search foods',
              trailingKey: const ValueKey('foods-search'),
              trailingSelected: showSearch,
              onTrailing: _toggleSearch,
            ),
            gutter(
              Align(
                alignment: Alignment.centerLeft,
                child: PhasePill(label: phaseName, all: all),
              ),
              top: 6,
            ),
            if (showSearch)
              gutter(
                MoonTextField(
                  hint: 'Search foods',
                  leadingIcon: MoonIconName.search,
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  trailing: _query.isEmpty
                      ? null
                      : Pressable(
                          onTap: _clearSearch,
                          semanticLabel: 'Clear search',
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: MoonIcon(
                              MoonIconName.close,
                              size: 16,
                              color: c.textMuted,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                ),
                top: 14,
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 42 + 76),
                children: [
                  gutter(
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _CategoryChip(
                          label: 'All',
                          selected: category == null,
                          onTap: () => setState(() => _category = null),
                        ),
                        for (final name in chips)
                          _CategoryChip(
                            label: name,
                            selected: category == name,
                            onTap: () => setState(() => _category = name),
                          ),
                      ],
                    ),
                    top: 14,
                  ),
                  // Today's food: only unfiltered, for the phase, not searching.
                  if (!all && category == null && q.isEmpty && todays != null)
                    gutter(
                      TodaysFoodCard(
                        food: todays,
                        headline: todaysFoodHeadline(
                          todaysFoodHeadlines[stableHash(
                                'headline|${ref.watch(todayProvider)}|${todays.id}',
                              ) %
                              todaysFoodHeadlines.length],
                          todays.displayName,
                        ),
                        intro: todays.why[actual]?.short,
                        palette: c.phase(actual),
                        onOpen: () =>
                            context.push(Routes.food(todays.id, phase: actual)),
                      ),
                      top: 18,
                    ),
                  gutter(
                    _ListHead(
                      title: category ?? 'All foods',
                      count: countLabel,
                    ),
                    top: 24,
                  ),
                  if (shown.isEmpty)
                    gutter(
                      Text(
                        q.isEmpty
                            ? 'No foods here yet.'
                            : 'No foods match "${_query.trim()}".',
                        style: dmSans(15, height: 1.5, color: c.textMuted),
                      ),
                      top: 14,
                    )
                  else
                    gutter(
                      Container(
                        decoration: BoxDecoration(
                          color: c.raised,
                          border: Border.all(color: c.line),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            for (final (i, (food, name)) in shown.indexed) ...[
                              if (i > 0) Divider(height: 1, color: c.line),
                              _FoodRow(
                                food: food,
                                category: name,
                                palette: palette,
                                open: food.id == _openFoodId,
                                onList: listed.containsKey(food.id),
                                onOpen: () => _open(food),
                                onToggleList: () {
                                  final controller = ref.read(
                                    shoppingControllerProvider.notifier,
                                  );
                                  final item = listed[food.id];
                                  if (item != null) {
                                    controller.remove(item);
                                  } else {
                                    controller.addFood(food, phase);
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      top: 12,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A category filter: plum when chosen, sand otherwise. Drawn 34 tall, with a
/// 44 touch target.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final slop = tapTargetSlop(height: 34);
    return ExpandedTapTarget(
      extra: slop,
      child: Pressable(
        onTap: onTap,
        selected: selected,
        semanticLabel: label,
        child: Padding(
          padding: slop,
          child: Container(
            constraints: const BoxConstraints(minHeight: 34),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: ShapeDecoration(
              color: selected ? c.inverseBg : c.sand,
              shape: const StadiumBorder(),
            ),
            child: Text(
              label,
              style: dmSans(
                13.5,
                weight: selected ? FontWeight.w700 : FontWeight.w500,
                height: 1.2,
                color: selected ? c.inverseText : c.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "ALL FOODS" or the chosen category, with how many foods it lists.
class _ListHead extends StatelessWidget {
  const _ListHead({required this.title, required this.count});

  final String title;
  final String count;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Semantics(
      header: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: Overline(title)),
          const SizedBox(width: 12),
          Text(
            count,
            style: dmSans(
              12.5,
              weight: FontWeight.w500,
              height: 1.2,
              color: c.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// One food: thumbnail, name, category and the shopping list button. Tapping
/// the row opens the food; the button adds or removes it from the list.
class _FoodRow extends StatelessWidget {
  const _FoodRow({
    required this.food,
    required this.category,
    required this.palette,
    required this.open,
    required this.onList,
    required this.onOpen,
    required this.onToggleList,
  });

  final Food food;
  final String category;
  final PhasePalette palette;
  final bool open;
  final bool onList;
  final VoidCallback onOpen;
  final VoidCallback onToggleList;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final photo = plantPhotos[food.id];
    final name = food.displayName;
    return Container(
      color: open ? c.sand : null,
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              onTap: onOpen,
              semanticLabel: '$name, $category',
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: photo != null
                              ? Image.asset(
                                  photo.asset,
                                  fit: BoxFit.cover,
                                  alignment: photo.alignment,
                                )
                              : ColoredBox(
                                  color: c.sand,
                                  child: Center(
                                    child: Text(
                                      foodEmoji(food),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: fraunces(18, height: 1.2, color: c.text),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            category,
                            style: dmSans(
                              12.5,
                              height: 1.3,
                              color: c.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Pressable(
            onTap: onToggleList,
            checked: onList,
            semanticLabel: onList
                ? 'Remove $name from shopping list'
                : 'Add $name to shopping list',
            child: SizedBox(
              width: minTapTarget + 8,
              height: minTapTarget + 8,
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: onList ? palette.tint : null,
                    border: onList ? null : Border.all(color: c.line),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: MoonIcon(
                      onList ? MoonIconName.check : MoonIconName.plus,
                      size: 16,
                      color: onList ? palette.text : c.textMuted,
                      strokeWidth: 2.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
