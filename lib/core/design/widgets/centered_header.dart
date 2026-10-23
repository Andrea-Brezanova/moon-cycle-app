import 'package:flutter/material.dart';

import '../moon_theme.dart';
import '../tokens/moon_typography.dart';
import 'moon_icon.dart';
import 'pressable.dart';
import 'tap_target.dart';

/// The V2 sub-screen header: a back chevron, a centred Fraunces title and an
/// optional icon button on the right (search). Both buttons are 44 × 44.
class CenteredHeader extends StatelessWidget {
  const CenteredHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.backLabel = 'Back',
    this.trailingIcon,
    this.trailingLabel,
    this.trailingKey,
    this.trailingSelected,
    this.onTrailing,
  });

  final String title;
  final VoidCallback onBack;

  /// The spoken label of the back button ("Back to Eat").
  final String backLabel;
  final MoonIconName? trailingIcon;
  final String? trailingLabel;
  final Key? trailingKey;
  final bool? trailingSelected;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    Widget button(
      MoonIconName icon,
      String label,
      VoidCallback? onTap, {
      Key? key,
      bool? selected,
    }) => Pressable(
      key: key,
      onTap: onTap,
      selected: selected,
      semanticLabel: label,
      child: SizedBox(
        width: minTapTarget,
        height: minTapTarget,
        child: Center(
          child: MoonIcon(icon, size: 22, color: c.text, strokeWidth: 2),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
      child: Row(
        children: [
          button(MoonIconName.back, backLabel, onBack),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: fraunces(26, height: 1.2, color: c.text),
              ),
            ),
          ),
          if (trailingIcon != null)
            button(
              trailingIcon!,
              trailingLabel ?? '',
              onTrailing,
              key: trailingKey,
              selected: trailingSelected,
            )
          else
            const SizedBox(width: minTapTarget),
        ],
      ),
    );
  }
}
