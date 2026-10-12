import 'package:flutter/widgets.dart';

import '../moon_theme.dart';
import '../tokens/moon_layout.dart';
import '../tokens/moon_typography.dart';
import 'editorial_text.dart';
import 'moon_icon.dart';
import 'pressable.dart';

/// A Settings-style list row (spec §6): optional line icon, a 17 pt label,
/// optional subtitle and value, then a chevron or a trailing control.
class MoonListRow extends StatelessWidget {
  const MoonListRow({
    super.key,
    required this.label,
    this.onTap,
    this.subtitle,
    this.value,
    this.icon,
    this.trailing,
    this.showChevron = true,
    this.labelColor,
  });

  final String label;
  final VoidCallback? onTap;
  final String? subtitle;

  /// Shown on the right in muted text, e.g. "28 days".
  final String? value;
  final MoonIconName? icon;

  /// A control instead of the chevron, e.g. a `MoonToggle`.
  final Widget? trailing;
  final bool showChevron;

  /// e.g. the destructive colour.
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: MoonSize.settingsRow),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            if (icon != null) ...[
              MoonIcon(icon!, size: 22, color: c.text, strokeWidth: 1.6),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: MoonType.rowLabel.copyWith(
                      color: labelColor ?? c.text,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: dmSans(14, height: 1.35, color: c.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 14),
              Text(value!, style: dmSans(16, height: 1.2, color: c.textMuted)),
            ],
            if (trailing != null) ...[
              const SizedBox(width: 14),
              trailing!,
            ] else if (showChevron) ...[
              const SizedBox(width: 14),
              MoonIcon(
                MoonIconName.chev,
                size: 18,
                color: c.removeIcon,
                strokeWidth: 2,
              ),
            ],
          ],
        ),
      ),
    );
    return trailing != null ? row : Pressable(onTap: onTap, child: row);
  }
}

/// A group of list rows under an optional overline, with hairlines between
/// rows (none above the first) and no card around them.
class MoonListGroup extends StatelessWidget {
  const MoonListGroup({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final line = context.moon.line;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[Overline(title!), const SizedBox(height: 6)],
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Container(height: 1, color: line),
          children[i],
        ],
      ],
    );
  }
}

/// The top of a Settings sub-screen: "‹ Settings" and the title (spec §6).
class SubScreenHeader extends StatelessWidget {
  const SubScreenHeader({
    super.key,
    required this.backLabel,
    required this.onBack,
    this.title,
    this.titleSize = 40,
  });

  final String backLabel;
  final VoidCallback? onBack;

  /// Words in `*asterisks*` are italic.
  final String? title;

  /// 40, or 36 for long titles.
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MoonSpace.gutter,
        4,
        MoonSpace.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: const Offset(-8, 0),
            child: Pressable(
              onTap: onBack,
              semanticLabel: 'Back to $backLabel',
              child: SizedBox(
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MoonIcon(
                      MoonIconName.back,
                      size: 20,
                      color: c.text,
                      strokeWidth: 2,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      backLabel,
                      style: dmSans(
                        15,
                        weight: FontWeight.w500,
                        height: 1,
                        color: c.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (title != null) ...[
            const SizedBox(height: 10),
            Semantics(
              header: true,
              child: EditorialHeading(
                title!,
                style: fraunces(titleSize, height: 1.04),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
