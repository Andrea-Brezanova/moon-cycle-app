import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/routes.dart';
import '../../../app/shell/tab_scroll.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_colors.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../cycle/application/viewing_phase.dart';
import '../../cycle/presentation/phase_header.dart';
import '../../shopping/application/shopping_summary.dart';
import '../application/food_providers.dart';
import 'ingredient_sheet.dart';
import 'widgets/food_row.dart';

/// The Foods tab (`07-foods`, `34-foods-browsing-other-phase`): the viewing
/// phase's foods by category, in the stored order. Avoided foods are hidden,
/// and a category with none left is hidden too (spec §7.3).
class FoodsPage extends ConsumerStatefulWidget {
  const FoodsPage({super.key});

  @override
  ConsumerState<FoodsPage> createState() => _FoodsPageState();
}

class _FoodsPageState extends ConsumerState<FoodsPage> {
  String? _openFoodId;

  Future<void> _open(Food food) async {
    setState(() => _openFoodId = food.id);
    await showIngredientSheet(
      context,
      food: food,
      phase: ref.read(viewingPhaseProvider),
    );
    if (mounted) setState(() => _openFoodId = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final phase = ref.watch(viewingPhaseProvider);
    final palette = c.phase(phase);
    final catalogue = ref.watch(catalogueProvider);
    final filter = ref.watch(foodFilterProvider);
    final content = catalogue.phase(phase);
    final counts = ref.watch(recipeCountsProvider(phase));
    final onList = ref.watch(shoppingSummaryProvider).onListFoodIds;

    final categories = [
      for (final category in content.categories)
        if ([for (final id in category.foodIds) ?catalogue.food(id)]
                .where(filter.allowsFood)
                .toList()
            case final foods when foods.isNotEmpty)
          (category.category.name, foods),
    ];

    return Scaffold(
      backgroundColor: c.bg,
      body: ListView(
        controller: ref.watch(tabScrollProvider).of(AppTab.foods),
        padding: const EdgeInsets.only(bottom: 42),
        children: [
          const PhaseHeader(title: 'Foods'),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MoonSpace.gutter,
              30,
              MoonSpace.gutter,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.season,
                  style: MoonType.season.copyWith(
                    color: palette.text,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 10),
                EditorialHeading(
                  italicLastWord(content.tagline),
                  style: fraunces(32, height: 1.1),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    content.focusBody,
                    style: MoonType.body.copyWith(color: c.text),
                  ),
                ),
                const SizedBox(height: 26),
                _HintLine(palette: palette),
              ],
            ),
          ),
          for (final (i, (name, foods)) in categories.indexed) ...[
            SizedBox(height: i == 0 ? 30 : MoonSpace.foodsSectionGap),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MoonSpace.gutter),
              child: _Category(
                name: name,
                foods: foods,
                counts: counts,
                onList: onList,
                palette: palette,
                openFoodId: _openFoodId,
                onFood: _open,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Tap a food to cook with it · [bowl] 2 recipes · [✓] on your list".
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
          Text('Tap a food to cook with it', style: style),
          ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const RecipeCountBadge(2, size: 13),
                const SizedBox(width: 4),
                Text('recipes', style: style),
              ],
            ),
          ),
          ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OnListMark(palette: palette, size: 20),
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
    required this.counts,
    required this.onList,
    required this.palette,
    required this.openFoodId,
    required this.onFood,
  });

  final String name;
  final List<Food> foods;
  final Map<String, int> counts;
  final Set<String> onList;
  final PhasePalette palette;
  final String? openFoodId;
  final ValueChanged<Food> onFood;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    Widget row(Food food) => FoodRow(
      food: food,
      recipeCount: counts[food.id] ?? 0,
      onList: onList.contains(food.id),
      palette: palette,
      open: food.id == openFoodId,
      onTap: () => onFood(food),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(name, style: MoonType.categoryHead.copyWith(color: c.text)),
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
        const SizedBox(height: 12),
        // Two columns; both rows of a pair share a height so dividers line up.
        for (var i = 0; i < foods.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 2),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: row(foods[i])),
                const SizedBox(width: MoonSpace.gridGap),
                Expanded(
                  child: i + 1 < foods.length
                      ? row(foods[i + 1])
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
