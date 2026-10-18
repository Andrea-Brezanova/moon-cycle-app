import 'package:flutter/widgets.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_colors.dart';
import '../../../../core/design/tokens/moon_layout.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/moon_icon.dart';
import '../../../../core/design/widgets/pressable.dart';
import '../../../../core/design/widgets/tap_target.dart';
import '../../../content/domain/food.dart';

/// A food in a meal-builder step. Foods featured in the viewed phase wear the
/// phase's tint (and say so to screen readers); a chosen food is plum with a
/// check, so selection never relies on colour alone. [onTap] null disables it.
class MealOptionChip extends StatelessWidget {
  const MealOptionChip({
    super.key,
    required this.food,
    required this.featured,
    required this.selected,
    required this.palette,
    required this.phaseName,
    required this.onTap,
  });

  final Food food;
  final bool featured;
  final bool selected;
  final PhasePalette palette;
  final String phaseName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final (Color bg, Color fg) = selected
        ? (c.inverseBg, c.inverseText)
        : featured
        ? (palette.tint, c.text)
        : (c.sand, c.text);
    final slop = tapTargetSlop(height: MoonSize.chip);
    return ExpandedTapTarget(
      extra: slop,
      child: Pressable(
        onTap: onTap,
        selected: selected,
        semanticLabel: [
          food.displayName,
          if (featured) 'featured in your $phaseName phase',
          if (selected) 'chosen',
        ].join(', '),
        child: Padding(
          padding: slop,
          child: Opacity(
            opacity: onTap == null && !selected ? 0.4 : 1,
            child: Container(
              constraints: const BoxConstraints(minHeight: MoonSize.chip),
              padding: EdgeInsets.fromLTRB(18, 12, selected ? 14 : 18, 12),
              decoration: ShapeDecoration(
                color: bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MoonSize.chip / 2),
                ),
              ),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        food.displayName,
                        style: dmSans(
                          15,
                          weight: selected || featured
                              ? FontWeight.w600
                              : FontWeight.w500,
                          height: 1.2,
                          color: fg,
                        ),
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: 6),
                      MoonIcon(
                        MoonIconName.check,
                        size: 15,
                        color: fg,
                        strokeWidth: 2.4,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
