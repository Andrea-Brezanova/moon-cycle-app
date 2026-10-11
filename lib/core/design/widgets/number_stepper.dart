import 'package:flutter/widgets.dart';

import '../moon_theme.dart';
import '../tokens/moon_typography.dart';
import 'editorial_text.dart';
import 'moon_button.dart';
import 'moon_icon.dart';

/// The onboarding / My Cycle stepper (spec §7.1): an overline, the value in
/// Fraunces Light 72 between round − and + buttons, and a hint. Sits under a
/// hairline.
class NumberStepper extends StatelessWidget {
  const NumberStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.unit = 'days',
    this.hint,
  });

  /// e.g. "Cycle length"; also used for the buttons' screen-reader labels.
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String unit;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Overline(label),
          const SizedBox(height: 14),
          Row(
            children: [
              RoundIconButton(
                MoonIconName.minus,
                semanticLabel: 'Decrease ${label.toLowerCase()}',
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              Expanded(
                child: Semantics(
                  label: '$label, $value $unit',
                  excludeSemantics: true,
                  // Exact size at the design width; shrinks only on very
                  // narrow screens or at large text sizes.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$value',
                          style: MoonType.stepperValue.copyWith(color: c.text),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          unit,
                          style: dmSans(
                            16,
                            weight: FontWeight.w500,
                            height: 1,
                            color: c.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              RoundIconButton(
                MoonIconName.plus,
                semanticLabel: 'Increase ${label.toLowerCase()}',
                onPressed: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 14),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: dmSans(14, color: c.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
