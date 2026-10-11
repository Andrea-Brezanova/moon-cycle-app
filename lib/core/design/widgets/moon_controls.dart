import 'package:flutter/material.dart';

import '../moon_theme.dart';
import '../tokens/moon_layout.dart';
import 'moon_icon.dart';

/// The round checkbox (spec §6): 26 pt in a 44 pt touch area.
class RoundCheckbox extends StatelessWidget {
  const RoundCheckbox({
    super.key,
    required this.checked,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool checked;
  final ValueChanged<bool>? onChanged;

  /// e.g. "Avocado".
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Semantics(
      checked: checked,
      enabled: onChanged != null,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!checked),
        child: SizedBox.square(
          dimension: MoonSize.iconButton,
          child: Center(
            child: Container(
              width: MoonSize.checkbox,
              height: MoonSize.checkbox,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? c.inverseBg : null,
                border: checked
                    ? null
                    : Border.all(color: c.checkboxBorder, width: 1.8),
              ),
              child: checked
                  ? Center(
                      child: MoonIcon(
                        MoonIconName.check,
                        size: 15,
                        color: c.inverseText,
                        strokeWidth: 2.6,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// The Editorial switch (spec §6): 51 × 31. On: plum track (cream in dark)
/// with a page-coloured knob. Off: hairline track with a light knob.
class MoonToggle extends StatelessWidget {
  const MoonToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final offKnob = dark ? const Color(0xFFC8C1D3) : const Color(0xFFFFFFFF);
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: MoonSize.toggleWidth,
          height: MoonSize.toggleHeight,
          padding: const EdgeInsets.all(3),
          decoration: ShapeDecoration(
            color: value ? c.inverseBg : c.line,
            shape: const StadiumBorder(),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 150),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? c.bg : offKnob,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
