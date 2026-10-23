import 'package:flutter/material.dart';

import '../moon_theme.dart';
import '../tokens/moon_typography.dart';
import 'pressable.dart';
import 'tap_target.dart';

/// A choice pill: plum when chosen, sand otherwise. Drawn 34 tall with a 44
/// touch target.
class PillChoice extends StatelessWidget {
  const PillChoice({
    super.key,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: ShapeDecoration(
              color: selected ? c.inverseBg : c.sand,
              shape: const StadiumBorder(),
            ),
            child: Text(
              label,
              style: dmSans(
                14,
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
