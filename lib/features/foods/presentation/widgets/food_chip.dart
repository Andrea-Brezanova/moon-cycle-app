import 'package:flutter/widgets.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_colors.dart';
import '../../../../core/design/tokens/moon_layout.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/moon_icon.dart';
import '../../../../core/design/widgets/pressable.dart';
import '../../../../core/design/widgets/tap_target.dart';
import '../../../content/domain/food.dart';

/// A food on the Foods page: the [MoonChip] look (sand; phase tint with a
/// check when it's on the list; plum while its sheet is open), but the name
/// wraps instead of ending in "…", so long names and large text stay
/// readable. Drawn 42 tall on one line; the touch target is 44.
///
/// The meal builder uses the same chip so both screens look alike: [featured]
/// gives the phase tint without a check (a food of the user's current phase),
/// [selected] is the chosen state (plum with a check), and a null [onTap]
/// dims it (the selection limit is reached). The Foods page uses none of these.
class FoodChip extends StatelessWidget {
  const FoodChip({
    super.key,
    required this.food,
    required this.palette,
    required this.onTap,
    this.onList = false,
    this.open = false,
    this.featured = false,
    this.selected = false,
    this.semanticLabelOverride,
  });

  final Food food;
  final bool onList;
  final PhasePalette palette;
  final VoidCallback? onTap;

  /// Tinted as a food of the user's current phase (no check).
  final bool featured;

  /// Chosen in the meal builder: plum with a check.
  final bool selected;

  /// Replaces the spoken label (the builder says "chosen", "featured…").
  final String? semanticLabelOverride;

  /// Its ingredient sheet is open: shown like a pressed chip.
  final bool open;

  /// "Lemon, on your shopping list".
  String get semanticLabel =>
      semanticLabelOverride ??
      [food.displayName, if (onList) 'on your shopping list'].join(', ');

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final checked = onList || selected;
    final (Color bg, Color fg, FontWeight weight) = open || selected
        ? (c.inverseBg, c.inverseText, FontWeight.w600)
        : onList || featured
        ? (palette.tint, c.text, FontWeight.w600)
        : (c.sand, c.text, FontWeight.w500);
    final slop = tapTargetSlop(height: MoonSize.chip);
    return ExpandedTapTarget(
      extra: slop,
      child: Pressable(
        onTap: onTap,
        selected: open || onList || selected,
        semanticLabel: semanticLabel,
        child: Padding(
          padding: slop,
          child: Opacity(
            opacity: onTap == null && !selected ? 0.4 : 1,
            child: Container(
              constraints: const BoxConstraints(minHeight: MoonSize.chip),
              // 12 + 18 (15 pt at 1.2) + 12 = 42 on one line; taller when the
              // name wraps or the text is larger.
              padding: EdgeInsets.fromLTRB(18, 12, checked ? 14 : 18, 12),
              decoration: ShapeDecoration(
                color: bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MoonSize.chip / 2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      food.displayName,
                      style: dmSans(15, weight: weight, height: 1.2, color: fg),
                    ),
                  ),
                  if (checked) ...[
                    const SizedBox(width: 6),
                    MoonIcon(
                      MoonIconName.check,
                      size: 15,
                      color: open || selected ? fg : palette.text,
                      strokeWidth: 2.4,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
