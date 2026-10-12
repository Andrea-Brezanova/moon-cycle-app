import 'package:flutter/widgets.dart';

import '../moon_theme.dart';
import '../tokens/moon_colors.dart';
import '../tokens/moon_layout.dart';
import '../tokens/moon_typography.dart';
import 'moon_icon.dart';
import 'pressable.dart';

enum MoonChipState {
  /// Sand fill.
  normal,

  /// Phase tint with a check: on the shopping list, or a chosen avoidance.
  onList,

  /// Plum fill in light mode (cream in dark): pressed or the chosen option.
  selected,
}

/// A pill chip (spec §6): Home "Foods for today", onboarding and Settings
/// choices. 42 high by default; 44 for the diet choices.
class MoonChip extends StatelessWidget {
  const MoonChip(
    this.label, {
    super.key,
    required this.onTap,
    this.state = MoonChipState.normal,
    this.palette,
    this.height = MoonSize.chip,
  });

  final String label;
  final VoidCallback? onTap;
  final MoonChipState state;

  /// The phase palette for [MoonChipState.onList] (tint and check colour).
  final PhasePalette? palette;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    assert(state != MoonChipState.onList || palette != null);
    final (Color bg, Color fg, FontWeight w) = switch (state) {
      MoonChipState.normal => (c.sand, c.text, FontWeight.w500),
      MoonChipState.onList => (palette!.tint, c.text, FontWeight.w600),
      MoonChipState.selected => (c.inverseBg, c.inverseText, FontWeight.w600),
    };
    final onList = state == MoonChipState.onList;
    return Pressable(
      onTap: onTap,
      selected: state != MoonChipState.normal,
      child: Container(
        height: height,
        padding: EdgeInsets.only(left: 18, right: onList ? 14 : 18),
        decoration: ShapeDecoration(color: bg, shape: const StadiumBorder()),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: dmSans(15, weight: w, height: 1, color: fg),
              ),
            ),
            if (onList) ...[
              const SizedBox(width: 6),
              MoonIcon(
                MoonIconName.check,
                size: 15,
                color: palette!.text,
                strokeWidth: 2.4,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The outlined "+ Add another" chip.
class MoonOutlineChip extends StatelessWidget {
  const MoonOutlineChip(
    this.label, {
    super.key,
    required this.onTap,
    this.icon = MoonIconName.plus,
  });

  final String label;
  final VoidCallback? onTap;
  final MoonIconName? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Pressable(
      onTap: onTap,
      child: Container(
        height: MoonSize.chip,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: ShapeDecoration(
          shape: StadiumBorder(side: BorderSide(color: c.line, width: 1.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              MoonIcon(icon!, size: 16, color: c.text, strokeWidth: 2),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: dmSans(
                  15,
                  weight: FontWeight.w500,
                  height: 1,
                  color: c.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tinted chip with a remove button: a chosen food to avoid ("Mushrooms ×")
/// or the active Recipes filter ("Cook with: Chicken ×").
class MoonRemovableChip extends StatelessWidget {
  const MoonRemovableChip({
    super.key,
    required this.label,
    required this.tint,
    required this.onRemove,
    required this.removeLabel,
    this.prefix,
    this.height = MoonSize.chip,
  });

  /// Shown in SemiBold.
  final String label;

  /// Shown before [label] in Medium, e.g. "Cook with: ".
  final String? prefix;
  final Color tint;
  final VoidCallback? onRemove;

  /// Screen-reader label for the × button, e.g. "Remove mushrooms".
  final String removeLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Container(
      height: height,
      padding: EdgeInsets.only(left: prefix == null ? 18 : 16, right: 6),
      decoration: ShapeDecoration(color: tint, shape: const StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  if (prefix != null)
                    TextSpan(
                      text: prefix,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  TextSpan(text: label),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: dmSans(
                15,
                weight: FontWeight.w600,
                height: 1,
                color: c.text,
              ),
            ),
          ),
          SizedBox(width: prefix == null ? 4 : 8),
          Pressable(
            onTap: onRemove,
            semanticLabel: removeLabel,
            child: SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: MoonIcon(
                  MoonIconName.close,
                  size: prefix == null ? 14 : 15,
                  color: c.text,
                  strokeWidth: 2.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small label pill, e.g. "Recommended for your follicular phase", the
/// phase and meal pills on recipe detail, "Free at launch".
class MoonPill extends StatelessWidget {
  const MoonPill(this.label, {super.key, required this.background, this.dot});

  final String label;
  final Color background;

  /// An optional 7 pt dot before the label (phase accent).
  final Color? dot;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: ShapeDecoration(
      color: background,
      shape: const StadiumBorder(),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot != null) ...[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            style: dmSans(
              13,
              weight: FontWeight.w600,
              height: 1.2,
              color: context.moon.text,
            ),
          ),
        ),
      ],
    ),
  );
}
