import 'package:flutter/material.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_layout.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/moon_controls.dart';
import '../../../../core/design/widgets/moon_icon.dart';
import '../../../../core/design/widgets/pressable.dart';
import '../../../../core/design/widgets/tap_target.dart';
import '../../../../core/domain/phase.dart';
import '../../domain/shopping_item.dart';

/// A shopping-list row (spec §7.5): the round checkbox, the name, where it
/// came from, a "Merged" tag when combined, and ×.
class ShopRow extends StatelessWidget {
  const ShopRow({
    super.key,
    required this.item,
    required this.divider,
    required this.fallbackPhase,
    required this.recipeTitle,
    required this.onToggle,
    required this.onRemove,
  });

  final ShoppingItem item;
  final bool divider;

  /// The dot colour for typed items, which have no phase of their own.
  final Phase fallbackPhase;
  final String? Function(String recipeId) recipeTitle;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final staplePhase = item.sources
        .where((s) => s.type == SourceType.phaseFood)
        .map((s) => s.phase)
        .whereType<Phase>()
        .firstOrNull;
    // Ochre for recipes and merged items; the phase accent for staples.
    final dot = item.hasRecipeSource || item.isMerged
        ? c.ochre
        : c.phase(staplePhase ?? fallbackPhase).accent;
    final source = sourceLine(item, recipeTitle);
    return Container(
      constraints: BoxConstraints(
        minHeight: divider ? MoonSize.shopRow + 1 : MoonSize.shopRow,
      ),
      decoration: BoxDecoration(
        border: divider ? Border(top: BorderSide(color: c.line)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              onTap: onToggle,
              isButton: false,
              checked: item.done,
              semanticLabel: [
                item.name,
                if (source.isNotEmpty) source,
                if (item.isMerged) 'merged',
              ].join(', '),
              child: Row(
                children: [
                  RoundCheckMark(checked: item.done),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: dmSans(
                              17,
                              weight: FontWeight.w500,
                              height: 1.2,
                              color: item.done ? c.textMuted : c.text,
                            ),
                          ),
                          if (source.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: dot,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    source,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: dmSans(
                                      12,
                                      height: 1.3,
                                      color: c.textMuted,
                                    ),
                                  ),
                                ),
                                if (item.isMerged) ...[
                                  const SizedBox(width: 6),
                                  _MergedTag(),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(10, 0),
            // Drawn 40 pt; the touch target is 44.
            child: ExpandedTapTarget(
              extra: const EdgeInsets.all(2),
              child: Pressable(
                onTap: onRemove,
                semanticLabel: 'Remove ${item.name}',
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: SizedBox.square(
                    dimension: 40,
                    child: Center(
                      child: MoonIcon(
                        MoonIconName.close,
                        size: 18,
                        color: c.removeIcon,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Phase staple", a recipe's title, "Added by you", joined with " + ".
String sourceLine(
  ShoppingItem item,
  String? Function(String recipeId) recipeTitle,
) {
  final labels = <String>[];
  for (final s in item.sources) {
    final label = switch (s.type) {
      SourceType.phaseFood => 'Phase staple',
      SourceType.recipe => recipeTitle(s.recipeId ?? '') ?? 'A recipe',
      SourceType.manual => 'Added by you',
    };
    if (!labels.contains(label)) labels.add(label);
  }
  return labels.join(' + ');
}

class _MergedTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.moon.phase(Phase.ovulatory);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: ShapeDecoration(color: p.tint, shape: const StadiumBorder()),
      child: Text(
        'Merged',
        style: dmSans(11, weight: FontWeight.w700, height: 1, color: p.text),
      ),
    );
  }
}
