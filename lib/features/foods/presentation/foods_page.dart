import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_colors.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/centered_header.dart';
import '../../../core/design/widgets/dimmed_photo.dart';
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
import '../../eat/presentation/eat_filters.dart';
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
              EatFilterBar(
                all: all,
                typeLabel: category ?? 'All foods',
                typeSemantic:
                    'Showing ${category == null ? 'all foods' : category.toLowerCase()}. '
                    'Change food type',
                onType: () => showTypeSheet<String>(
                  context,
                  title: 'Food type',
                  options: [
                    TypeOption<String?>(
                      null,
                      'All foods',
                      allowed.fold<int>(0, (n, g) => n + g.$2.length),
                    ),
                    for (final (name, foods) in allowed)
                      TypeOption<String?>(name, name, foods.length),
                  ],
                  selected: category,
                  phase: phase,
                  onChosen: (v) => setState(() => _category = v),
                ),
              ),
              top: 10,
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
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        '${shown.length} ${shown.length == 1 ? 'food' : 'foods'}',
                        style: dmSans(
                          13,
                          weight: FontWeight.w500,
                          height: 1.2,
                          color: c.textMuted,
                        ),
                      ),
                    ),
                    top: 18,
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
                          borderRadius: BorderRadius.circular(24),
                        ),
                        clipBehavior: Clip.antiAlias,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
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
                      top: 10,
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

/// One food: a 64 pt thumbnail, the name, its category (and "on your shopping
/// list"), and the shopping list button. Tapping the row opens the food; the
/// button adds or removes it from the list.
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
    return Row(
      children: [
        Expanded(
          child: Pressable(
            onTap: onOpen,
            semanticLabel: onList
                ? '$name, $category, on your shopping list'
                : '$name, $category',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: photo != null
                            ? DimmedPhoto(
                                dim:
                                    Theme.of(context).brightness ==
                                    Brightness.dark,
                                child: Image.asset(
                                  photo.asset,
                                  fit: BoxFit.cover,
                                  alignment: photo.alignment,
                                ),
                              )
                            : ColoredBox(
                                color: c.sand,
                                child: Center(
                                  child: Text(
                                    foodEmoji(food),
                                    style: const TextStyle(
                                      fontSize: 30,
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
                          style: fraunces(18, height: 1.15, color: c.text),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          onList
                              ? '$category · on your shopping list'
                              : category,
                          style: dmSans(13, height: 1.3, color: c.textMuted),
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
            width: minTapTarget + 4,
            height: minTapTarget + 4,
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: onList ? palette.tint : null,
                  border: onList ? null : Border.all(color: c.line),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: MoonIcon(
                    onList ? MoonIconName.check : MoonIconName.plus,
                    size: 16,
                    color: onList ? palette.text : c.text,
                    strokeWidth: 2.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
