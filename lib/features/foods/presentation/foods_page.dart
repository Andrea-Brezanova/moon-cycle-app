import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/shell/tab_scroll.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_colors.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_segmented.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/domain/browse_scope.dart';
import '../../../core/time/today.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../content/domain/text_match.dart';
import '../../cycle/application/viewing_phase.dart';
import '../../cycle/domain/phase_guidance.dart';
import '../../cycle/presentation/phase_header.dart';
import '../../shopping/application/shopping_summary.dart';
import '../application/browse_scope.dart';
import '../application/food_providers.dart';
import '../application/todays_food.dart';
import 'widgets/food_chip.dart';
import 'widgets/todays_food_card.dart';

/// The Foods tab (`07-foods`, `34-foods-browsing-other-phase`): the viewing
/// phase's foods by category, in the stored order, or every recommended food
/// A–Z by category with search ("All foods"). Avoided foods are hidden,
/// and a category with none left is hidden too (spec §7.3).
class FoodsPage extends ConsumerStatefulWidget {
  const FoodsPage({super.key});

  @override
  ConsumerState<FoodsPage> createState() => _FoodsPageState();
}

class _FoodsPageState extends ConsumerState<FoodsPage> {
  String? _openFoodId;

  /// Opens the food's page. From "This phase" it explains the food for the
  /// viewing phase; from "All foods" it opens without phase context. The page
  /// is pushed on top, so Back returns here with the same filter.
  Future<void> _open(Food food, String category) async {
    setState(() => _openFoodId = food.id);
    final all = ref.read(foodsScopeProvider) == BrowseScope.all;
    await context.push<void>(
      Routes.food(food.id, phase: ref.read(viewingPhaseProvider), general: all),
    );
    if (mounted) setState(() => _openFoodId = null);
  }

  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _search.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final phase = ref.watch(viewingPhaseProvider);
    final actual = ref.watch(actualPhaseProvider);
    final todays = ref.watch(todaysFoodProvider);
    final scope = ref.watch(foodsScopeProvider);
    final all = scope == BrowseScope.all;
    final palette = c.phase(phase);
    final catalogue = ref.watch(catalogueProvider);
    final filter = ref.watch(foodFilterProvider);
    final content = catalogue.phase(phase);
    final onList = ref.watch(shoppingSummaryProvider).onListFoodIds;
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
    final categories = [
      for (final (category, foods) in groups)
        if (foods
                .where((f) => filter.allowsFood(f) && (!all || matches(f)))
                .toList()
            case final shown when shown.isNotEmpty)
          (category.name, shown),
    ];

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          controller: ref.watch(tabScrollProvider).of(AppTab.foods),
          padding: const EdgeInsets.only(bottom: 42),
          children: [
            const PhaseHeader(title: 'Foods'),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MoonSpace.gutter,
                18,
                MoonSpace.gutter,
                0,
              ),
              child: MoonSegmented<BrowseScope>(
                semanticLabel: 'Show',
                options: const [
                  (BrowseScope.phase, 'This phase'),
                  (BrowseScope.all, 'All foods'),
                ],
                selected: scope,
                onChanged: ref.read(foodsScopeProvider.notifier).set,
              ),
            ),
            if (all)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  MoonSpace.gutter,
                  18,
                  MoonSpace.gutter,
                  0,
                ),
                child: MoonTextField(
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
              )
            else ...[
              if (todays != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    MoonSpace.gutter,
                    22,
                    MoonSpace.gutter,
                    0,
                  ),
                  child: TodaysFoodCard(
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
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  MoonSpace.gutter,
                  26,
                  MoonSpace.gutter,
                  0,
                ),
                child: _PhaseFoodsHeader(palette: palette),
              ),
            ],
            if (all && categories.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  MoonSpace.gutter,
                  24,
                  MoonSpace.gutter,
                  0,
                ),
                child: Text(
                  'No foods match "${_query.trim()}".',
                  style: dmSans(15, height: 1.5, color: c.textMuted),
                ),
              ),
            for (final (i, (name, foods)) in categories.indexed) ...[
              SizedBox(height: i == 0 ? 30 : MoonSpace.foodsSectionGap),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MoonSpace.gutter,
                ),
                child: _Category(
                  name: name,
                  foods: foods,
                  onList: onList,
                  palette: palette,
                  openFoodId: _openFoodId,
                  onFood: _open,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Your foods for this phase" and the hint: tap a food for its page; the
/// check marks foods on the shopping list.
class _PhaseFoodsHeader extends StatelessWidget {
  const _PhaseFoodsHeader({required this.palette});

  final PhasePalette palette;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final style = dmSans(
      13,
      weight: FontWeight.w500,
      height: 1,
      color: c.textMuted,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Overline('Your foods for this phase'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 18),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.line)),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(foodsHintText, style: style),
              ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // A miniature of an on-list chip: phase tint with the check.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: ShapeDecoration(
                        color: palette.tint,
                        shape: const StadiumBorder(),
                      ),
                      child: MoonIcon(
                        MoonIconName.check,
                        size: 12,
                        color: palette.text,
                        strokeWidth: 2.4,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('on your list', style: style),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Category extends StatelessWidget {
  const _Category({
    required this.name,
    required this.foods,
    required this.onList,
    required this.palette,
    required this.openFoodId,
    required this.onFood,
  });

  final String name;
  final List<Food> foods;
  final Set<String> onList;
  final PhasePalette palette;
  final String? openFoodId;
  final void Function(Food food, String category) onFood;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // Long category names ("Dairy & alternatives") wrap, not overflow.
              Flexible(
                child: Text(
                  name,
                  style: MoonType.categoryHead.copyWith(color: c.text),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${foods.length}',
                style: dmSans(
                  13,
                  weight: FontWeight.w500,
                  height: 1,
                  color: c.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Compact chips that wrap onto as many lines as they need; a long
        // name wraps inside its chip rather than scrolling sideways.
        Wrap(
          spacing: MoonSpace.chipGap,
          runSpacing: MoonSpace.chipGap,
          children: [
            for (final food in foods)
              FoodChip(
                food: food,
                onList: onList.contains(food.id),
                palette: palette,
                open: food.id == openFoodId,
                onTap: () => onFood(food, name),
              ),
          ],
        ),
      ],
    );
  }
}
