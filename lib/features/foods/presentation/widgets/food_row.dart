import 'package:flutter/material.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_colors.dart';
import '../../../../core/design/tokens/moon_layout.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/moon_icon.dart';
import '../../../../core/design/widgets/moon_surfaces.dart';
import '../../../../core/design/widgets/pressable.dart';
import '../../../content/domain/food.dart';

/// A food in the Foods grid (spec §6): the name (and its parenthetical as a
/// second line), the recipe count or a chevron, and the on-list mark.
class FoodRow extends StatelessWidget {
  const FoodRow({
    super.key,
    required this.food,
    required this.recipeCount,
    required this.onList,
    required this.palette,
    required this.onTap,
    this.open = false,
  });

  final Food food;
  final int recipeCount;
  final bool onList;
  final PhasePalette palette;
  final VoidCallback onTap;

  /// Its ingredient sheet is open: shown like the pressed state.
  final bool open;

  /// "Lemon, 2 recipes, on your list".
  String get semanticLabel => [
    food.displayName,
    if (recipeCount > 0)
      '$recipeCount ${recipeCount == 1 ? 'recipe' : 'recipes'}',
    if (onList) 'on your list',
  ].join(', ');

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final qualifier = food.qualifier;
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: Container(
        constraints: const BoxConstraints(minHeight: MoonSize.foodRow),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: open
            ? BoxDecoration(
                color: c.sand,
                borderRadius: BorderRadius.circular(MoonRadius.foodRowPressed),
              )
            : BoxDecoration(
                border: Border(bottom: BorderSide(color: c.line)),
              ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.displayName,
                    style: dmSans(
                      16,
                      weight: onList || open
                          ? FontWeight.w600
                          : FontWeight.w500,
                      height: 1.25,
                      color: c.text,
                    ),
                  ),
                  if (qualifier != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      qualifier,
                      style: dmSans(12, height: 1.3, color: c.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (recipeCount > 0)
              RecipeCountBadge(recipeCount)
            else
              MoonIcon(
                MoonIconName.chev,
                size: 14,
                color: c.chevron,
                strokeWidth: 2,
              ),
            if (onList) ...[
              const SizedBox(width: 8),
              OnListMark(palette: palette),
            ],
          ],
        ),
      ),
    );
  }
}
