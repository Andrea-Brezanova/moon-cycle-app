import 'package:flutter/widgets.dart';

import '../moon_theme.dart';
import '../tokens/moon_typography.dart';
import 'pressable.dart';

/// A two-or-more way pill control (Foods: "This phase" | "All foods"). Same
/// pill language as the phase selector: equal segments, the selected one on
/// the sand tint.
class MoonSegmented<T> extends StatelessWidget {
  const MoonSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.semanticLabel,
  });

  /// Value and label, in order.
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final String? semanticLabel;

  /// Segments are 44 pt tall (the minimum touch target) inside a 1 pt border and 2 pt padding.
  static const double _height = 50;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Semantics(
      label: semanticLabel,
      child: Container(
        // 50 pt, growing only when a label has to wrap (large text, narrow
        // phones) so no label is cut off.
        constraints: const BoxConstraints(minHeight: _height),
        padding: const EdgeInsets.all(2),
        decoration: ShapeDecoration(
          color: c.bg,
          shape: StadiumBorder(side: BorderSide(color: c.line)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (value, label) in options)
                Expanded(
                  child: Pressable(
                    onTap: () => onChanged(value),
                    selected: value == selected,
                    semanticLabel: label,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      constraints: const BoxConstraints(minHeight: 44),
                      decoration: ShapeDecoration(
                        color: value == selected ? c.sand : null,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        label,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: dmSans(
                          14,
                          weight: value == selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          height: 1.15,
                          color: value == selected ? c.text : c.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
