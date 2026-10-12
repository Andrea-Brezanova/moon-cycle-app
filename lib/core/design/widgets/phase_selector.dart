import 'package:flutter/widgets.dart';

import '../../domain/phase.dart';
import '../moon_theme.dart';
import '../tokens/moon_layout.dart';
import '../tokens/moon_typography.dart';
import 'pressable.dart';
import 'tap_target.dart';

/// The shared phase selector on Foods, Recipes and Shop (spec §6): four
/// equal pills with an accent dot; the selected one is tinted.
class PhaseSelector extends StatelessWidget {
  const PhaseSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Phase selected;
  final ValueChanged<Phase>? onChanged;

  static const _labels = {
    Phase.menstrual: 'Menstrual',
    Phase.follicular: 'Follicular',
    Phase.ovulatory: 'Ovulatory',
    Phase.luteal: 'Luteal',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Semantics(
      label: 'Phase',
      // The pills are 40 pt as drawn; each one's touch target is 44.
      child: ExpandedTapTarget(
        extra: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            for (final p in Phase.values) ...[
              if (p != Phase.menstrual) const SizedBox(width: 4),
              Expanded(
                child: Pressable(
                  onTap: onChanged == null ? null : () => onChanged!(p),
                  selected: p == selected,
                  child: Container(
                    height: MoonSize.phaseSegment + 4,
                    alignment: Alignment.center,
                    child: Container(
                      height: MoonSize.phaseSegment,
                      decoration: ShapeDecoration(
                        color: p == selected ? c.phase(p).tint : null,
                        shape: const StadiumBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: c.phase(p).accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _labels[p]!,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: dmSans(
                                13,
                                weight: p == selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                height: 1,
                                color: p == selected ? c.text : c.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
