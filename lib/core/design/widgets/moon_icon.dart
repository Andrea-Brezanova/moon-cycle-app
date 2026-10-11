import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../icons/moon_icon_paths.dart';

export '../icons/moon_icon_paths.dart' show MoonIconName;

/// An Editorial line icon.
///
/// The design draws the same icon with different stroke weights depending on
/// where it's used (1.6 for an inactive tab, 2.4 for a check), so the stroke
/// width is a parameter rather than fixed in an SVG file.
class MoonIcon extends StatelessWidget {
  const MoonIcon(
    this.name, {
    super.key,
    this.size = 22,
    this.color,
    this.strokeWidth = 1.7,
    this.semanticLabel,
  });

  final MoonIconName name;
  final double size;

  /// Defaults to the surrounding text colour.
  final Color? color;
  final double strokeWidth;

  /// Leave null for decorative icons (the usual case: buttons carry labels).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = color ?? DefaultTextStyle.of(context).style.color;
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
        'fill="none" stroke="currentColor" stroke-width="$strokeWidth" '
        'stroke-linecap="round" stroke-linejoin="round">'
        '${moonIconPaths[name]}</svg>';
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      theme: SvgTheme(currentColor: c ?? const Color(0xFF000000)),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
