import 'package:flutter/widgets.dart';

import '../moon_theme.dart';
import '../tokens/moon_typography.dart';
import 'text_link.dart';

/// A Fraunces heading where words between `*asterisks*` are set in italic,
/// e.g. `'Fresh, light and *energising*'` (spec §4: one italic accent per
/// heading at most).
///
/// Headings grow with the system text size up to 1.3× (spec §10).
class EditorialHeading extends StatelessWidget {
  const EditorialHeading(
    this.text, {
    super.key,
    required this.style,
    this.color,
    this.italicColor,
    this.textAlign,
  });

  final String text;

  /// A Fraunces style from `MoonType` (or `fraunces(...)`).
  final TextStyle style;

  /// Defaults to the theme's text colour.
  final Color? color;

  /// For the welcome headline, where the italic word is ochre.
  final Color? italicColor;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final base = style.copyWith(color: color ?? context.moon.text);
    final parts = text.split('*');
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          for (var i = 0; i < parts.length; i++)
            if (parts[i].isNotEmpty)
              TextSpan(
                text: parts[i],
                style: i.isOdd
                    ? TextStyle(
                        fontStyle: FontStyle.italic,
                        color: italicColor ?? base.color,
                      )
                    : null,
              ),
        ],
      ),
      textAlign: textAlign,
      textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
    );
  }
}

/// A small upper-case label: DM Sans 12 SemiBold, +14% tracking, muted.
class Overline extends StatelessWidget {
  const Overline(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: MoonType.overline.copyWith(color: color ?? context.moon.textMuted),
  );
}

/// "Foods for today" with an optional "All foods" link on the right.
class SectionHead extends StatelessWidget {
  const SectionHead(this.title, {super.key, this.linkLabel, this.onLink});

  final String title;
  final String? linkLabel;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final heading = Semantics(
      header: true,
      child: Text(title, style: MoonType.h3.copyWith(color: context.moon.text)),
    );
    if (linkLabel == null) return heading;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: heading),
        TextLink(linkLabel!, onTap: onLink, size: 14),
      ],
    );
  }
}
