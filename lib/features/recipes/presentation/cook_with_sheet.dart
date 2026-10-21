import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../../core/domain/phase.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../content/domain/text_match.dart';
import '../../foods/application/food_providers.dart';

/// "Cook with…" (`13-cook-with-sheet`, `14-cook-with-no-results`): every
/// food recommended for [phase] that the user eats, by category, with its
/// recipe count. Returns the chosen food.
Future<Food?> showCookWithSheet(BuildContext context, {required Phase phase}) =>
    showMoonSheet<Food>(
      context,
      fromTop: 96,
      builder: (_) => _CookWithSheet(phase: phase),
    );

class _CookWithSheet extends ConsumerStatefulWidget {
  const _CookWithSheet({required this.phase});

  final Phase phase;

  @override
  ConsumerState<_CookWithSheet> createState() => _CookWithSheetState();
}

class _CookWithSheetState extends ConsumerState<_CookWithSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clear() {
    _search.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final catalogue = ref.watch(catalogueProvider);
    final filter = ref.watch(foodFilterProvider);
    final counts = ref.watch(recipeCountsProvider(widget.phase));
    final q = normaliseName(_query);
    bool matches(Food f) =>
        q.isEmpty ||
        normaliseName(f.name).contains(q) ||
        f.synonyms.any((s) => normaliseName(s).contains(q));
    final groups = [
      for (final category in catalogue.phase(widget.phase).categories)
        if ([for (final id in category.foodIds) ?catalogue.food(id)]
                .where((f) => filter.allowsFood(f) && matches(f))
                .toList()
            case final foods when foods.isNotEmpty)
          (category.category.name, foods),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('Cook with…', style: fraunces(30, color: c.text)),
        ),
        const SizedBox(height: 8),
        Text(
          'Foods for your ${widget.phase.name} phase',
          style: dmSans(15, height: 1.4, color: c.textMuted),
        ),
        const SizedBox(height: 16),
        MoonTextField(
          hint: 'Search foods',
          leadingIcon: MoonIconName.search,
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
          trailing: _query.isEmpty
              ? null
              : Pressable(
                  onTap: _clear,
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
        Expanded(
          child: groups.isEmpty
              ? _NoMatch(
                  phase: widget.phase,
                  query: _query.trim(),
                  onClear: _clear,
                )
              : ListView(
                  padding: const EdgeInsets.only(top: 10),
                  children: [
                    for (final (name, foods) in groups) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 2),
                        child: Overline(name),
                      ),
                      for (final (i, food) in foods.indexed)
                        _FoodLine(
                          food: food,
                          count: counts[food.id] ?? 0,
                          divider: i > 0,
                          onTap: () => Navigator.pop(context, food),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _FoodLine extends StatelessWidget {
  const _FoodLine({
    required this.food,
    required this.count,
    required this.divider,
    required this.onTap,
  });

  final Food food;
  final int count;
  final bool divider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Pressable(
      onTap: onTap,
      semanticLabel:
          '${food.displayName}, '
          '${count == 0 ? 'no recipes' : '$count ${count == 1 ? 'recipe' : 'recipes'}'}',
      child: Container(
        constraints: BoxConstraints(minHeight: divider ? 53 : 52),
        decoration: BoxDecoration(
          border: divider ? Border(top: BorderSide(color: c.line)) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                food.displayName,
                style: dmSans(
                  16,
                  weight: FontWeight.w500,
                  height: 1.25,
                  color: c.text,
                ),
              ),
            ),
            if (count > 0)
              RecipeCountBadge(count, size: 13)
            else
              MoonIcon(
                MoonIconName.chev,
                size: 14,
                color: c.chevron,
                strokeWidth: 2,
              ),
          ],
        ),
      ),
    );
  }
}

class _NoMatch extends StatelessWidget {
  const _NoMatch({
    required this.phase,
    required this.query,
    required this.onClear,
  });

  final Phase phase;
  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No ${phase.name} foods match “$query”',
            style: dmSans(
              16,
              weight: FontWeight.w500,
              height: 1.4,
              color: c.text,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Try another name, or browse the list.',
            style: dmSans(15, height: 1.5, color: c.textMuted),
          ),
          const SizedBox(height: 14),
          TextLink('Clear search', onTap: onClear),
        ],
      ),
    );
  }
}
