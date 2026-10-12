import 'package:flutter/widgets.dart';

import '../moon_theme.dart';
import '../tokens/moon_layout.dart';
import '../tokens/moon_typography.dart';
import 'moon_icon.dart';
import 'pressable.dart';

enum MoonButtonVariant {
  /// Ochre: the single main action on a screen.
  primary,

  /// Plum in light mode, cream in dark: step actions ("Continue").
  secondary,

  /// Transparent with a 1.5 pt outline. Rare.
  ghost,

  /// Menstrual text colour: only for "Delete my data".
  destructive,
}

/// The Editorial button: 56 high, pill, DM Sans 16 SemiBold (spec §6).
///
/// A label that doesn't fit on one line (narrow screens, large text sizes)
/// wraps and the button grows taller, so an action is never cut short. At
/// large text sizes the side padding also tightens. Labels are never
/// truncated: a button can always grow to fit its label.
class MoonButton extends StatelessWidget {
  const MoonButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.variant = MoonButtonVariant.primary,
    this.trailingIcon,
    this.expand = true,
  });

  final String label;

  /// Null shows the disabled state.
  final VoidCallback? onPressed;
  final MoonButtonVariant variant;
  final MoonIconName? trailingIcon;

  /// Full width (default) or as wide as the label plus 26 pt each side.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final (Color bg, Color fg, Color? outline) = switch (variant) {
      MoonButtonVariant.primary => (c.ochre, c.onOchre, null),
      MoonButtonVariant.secondary => (c.inverseBg, c.inverseText, null),
      MoonButtonVariant.ghost => (const Color(0x00000000), c.text, c.text),
      MoonButtonVariant.destructive => (c.destructive, c.onDestructive, null),
    };
    return Pressable(
      onTap: onPressed,
      child: Opacity(
        // Disabled state: not specified in the design (logged in
        // docs/design-deviations.md).
        opacity: onPressed == null ? 0.4 : 1,
        child: _ButtonShape(
          background: bg,
          outline: outline,
          expand: expand,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: _ButtonLabel(label, color: fg)),
              if (trailingIcon != null) ...[
                const SizedBox(width: 10),
                MoonIcon(trailingIcon!, size: 20, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The confirmed state of a secondary action: a disabled sand button with a
/// check, e.g. "✓ On your list" or "✓ Added to shopping list".
class MoonDoneButton extends StatelessWidget {
  const MoonDoneButton(this.label, {super.key, required this.checkColor});

  final String label;

  /// The phase `text` colour.
  final Color checkColor;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Semantics(
      button: true,
      enabled: false,
      child: _ButtonShape(
        background: c.sand,
        expand: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MoonIcon(
              MoonIconName.check,
              size: 18,
              color: checkColor,
              strokeWidth: 2.4,
            ),
            const SizedBox(width: 8),
            Flexible(child: _ButtonLabel(label, color: c.text)),
          ],
        ),
      ),
    );
  }
}

/// The button label: centred, wrapping when it has to, never truncated.
class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel(this.label, {required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    label,
    textAlign: TextAlign.center,
    // A little line height so wrapped lines don't touch; a single line looks
    // the same because the leading is split evenly above and below.
    style: MoonType.button.copyWith(color: color, height: 1.25),
  );
}

class _ButtonShape extends StatelessWidget {
  const _ButtonShape({
    required this.background,
    required this.expand,
    required this.child,
    this.outline,
  });

  final Color background;
  final Color? outline;
  final bool expand;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // At large text sizes, tighter side padding leaves more room for the
    // label before it has to wrap.
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 16 * 1.2;
    final side = largeText ? 16.0 : (expand ? 24.0 : 26.0);
    return DecoratedBox(
      // Radius 28 = a pill at the standard 56 pt; keeps the same corners when
      // a wrapped label makes the button taller.
      decoration: ShapeDecoration(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MoonSize.button / 2),
          side: outline == null
              ? BorderSide.none
              : BorderSide(color: outline!, width: 1.5),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: MoonSize.button),
        child: Center(
          // Full width, or as wide as the label; as tall as the label needs,
          // never less than 56 pt.
          widthFactor: expand ? null : 1,
          heightFactor: 1,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: side, vertical: 12),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A round icon button: sand 40 pt (calendar arrows), 52 pt (steppers), or
/// the ochre add button.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton(
    this.icon, {
    super.key,
    required this.onPressed,
    required this.semanticLabel,
    this.size = 52,
    this.iconSize = 22,
    this.strokeWidth = 2,
    this.background,
    this.foreground,
  }) : ochre = false;

  /// The ochre "+" next to the shopping list's add field.
  const RoundIconButton.add({
    super.key,
    required this.onPressed,
    this.semanticLabel = 'Add item',
  }) : icon = MoonIconName.plus,
       size = 52,
       iconSize = 22,
       strokeWidth = 2.2,
       background = null,
       foreground = null,
       ochre = true;

  final MoonIconName icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final double size;
  final double iconSize;
  final double strokeWidth;
  final Color? background;
  final Color? foreground;

  /// Ochre fill instead of sand.
  final bool ochre;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final bg = background ?? (ochre ? c.ochre : c.sand);
    final fg = foreground ?? (ochre ? c.onOchre : c.text);
    return Pressable(
      onTap: onPressed,
      semanticLabel: semanticLabel,
      child: Opacity(
        opacity: onPressed == null ? 0.4 : 1,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: MoonIcon(
            icon,
            size: iconSize,
            color: fg,
            strokeWidth: strokeWidth,
          ),
        ),
      ),
    );
  }
}
