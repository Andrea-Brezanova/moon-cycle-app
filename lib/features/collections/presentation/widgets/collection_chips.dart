import 'package:flutter/material.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/pressable.dart';
import '../../../../core/design/widgets/tap_target.dart';

/// The filter pills on My Workouts and My Spa: "All 4", "YouTube 2"... The
/// chosen one is plum with light text; the others are white with a hairline.
class CollectionChips extends StatelessWidget {
  const CollectionChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  /// Label and count for each chip, the first being "All".
  final List<(String label, int count)> options;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Wrap(
      spacing: 8,
      children: [
        for (final (i, (label, count)) in options.indexed)
          Builder(
            builder: (context) {
              final active = i == selected;
              final slop = tapTargetSlop(height: 38);
              return ExpandedTapTarget(
                extra: slop,
                child: Pressable(
                  key: ValueKey('chip-$i'),
                  onTap: () => onSelected(i),
                  selected: active,
                  semanticLabel: '$label, $count',
                  child: Padding(
                    padding: slop,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 38),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: active ? c.inverseBg : c.raised,
                        border: active ? null : Border.all(color: c.line),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          '$label $count',
                          style: dmSans(
                            14,
                            weight: active ? FontWeight.w600 : FontWeight.w500,
                            height: 1.2,
                            color: active ? c.inverseText : c.text,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
