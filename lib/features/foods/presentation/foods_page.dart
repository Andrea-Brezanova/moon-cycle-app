import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../../../core/domain/phase.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../content/domain/phase_content.dart';
import '../../content/domain/text_match.dart';
import '../../cycle/application/viewing_phase.dart';
import '../../cycle/domain/phase_guidance.dart';
import '../../cycle/presentation/phase_header.dart';
import '../../shopping/application/shopping_summary.dart';
import '../application/browse_scope.dart';
import '../application/food_providers.dart';
import 'ingredient_sheet.dart';
import 'widgets/food_chip.dart';
import 'widgets/meal_builder_section.dart';

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

  /// From "This phase" the sheet explains the food for the viewing phase.
  /// From "All foods" there is no phase context, so it shows general
  /// information instead of a phase rationale.
  Future<void> _open(Food food, String category) async {
    setState(() => _openFoodId = food.id);
    final all = ref.read(foodsScopeProvider) == BrowseScope.all;
    await showIngredientSheet(
      context,
      food: food,
      phase: ref.read(viewingPhaseProvider),
      phaseContext: !all,
      category: category,
    );
    if (mounted) setState(() => _openFoodId = null);
  }

  /// A protein idea: a food featured in the viewing phase opens with its
  /// phase "Why this food?"; an "Also good" suggestion opens without phase
  /// context, so no phase rationale is invented for it.
  Future<void> _openIdea(Food food) async {
    final viewing = ref.read(viewingPhaseProvider);
    final featured = food.why[viewing] != null;
    await showIngredientSheet(
      context,
      food: food,
      phase: viewing,
      phaseContext: featured,
      category: ref.read(catalogueProvider).categoryFor(food).name,
    );
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
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  MoonSpace.gutter,
                  30,
                  MoonSpace.gutter,
                  0,
                ),
                child: _PhaseIntro(
                  phase: phase,
                  content: content,
                  palette: palette,
                ),
              ),
            if (!all)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  MoonSpace.gutter,
                  30,
                  MoonSpace.gutter,
                  0,
                ),
                child: MealBuilderSection(phase: phase, onFood: _openIdea),
              ),
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

/// The phase intro on "This phase": season and tagline, then the three
/// approved points (what your body may need, why these foods, how to eat this
/// phase) and the suggestions-not-rules note, each from the phase content.
class _PhaseIntro extends StatelessWidget {
  const _PhaseIntro({
    required this.phase,
    required this.content,
    required this.palette,
  });

  final Phase phase;

  final PhaseContent content;
  final PhasePalette palette;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final copy = foodsIntroCopy(phase);
    Widget block(String label, String text) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Overline(label),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(text, style: MoonType.body.copyWith(color: c.text)),
        ),
        const SizedBox(height: 18),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content.season,
          style: MoonType.season.copyWith(color: palette.text, height: 1.08),
        ),
        const SizedBox(height: 10),
        EditorialHeading(
          italicLastWord(content.tagline),
          style: fraunces(32, height: 1.1),
        ),
        const SizedBox(height: 20),
        block('What your body may need', copy.need),
        block('Why these foods', copy.why),
        block('How to eat this phase', copy.how),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            foodsUniversalNote,
            style: dmSans(14, height: 1.4, color: c.textMuted),
          ),
        ),
        const SizedBox(height: 26),
        _HintLine(palette: palette),
      ],
    );
  }
}

/// "Tap a food to see why we feature it and find recipes · [✓] on your list". Recipe counts live in
/// the ingredient sheet, not in the list.
class _HintLine extends StatelessWidget {
  const _HintLine({required this.palette});

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
    return Container(
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
