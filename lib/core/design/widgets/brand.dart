import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/phase.dart';
import '../moon_theme.dart';

/// The "mooncycle" script wordmark (outlined Gwendolyn Bold; spec §4),
/// sized by its x-height. 12 is the Home header size, 15 the welcome screen.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, required this.xHeight, required this.color});

  final double xHeight;
  final Color color;

  // Size of assets/logo/wordmark-header-plum.svg, drawn at x-height 12.
  static const double _width = 122.33;
  static const double _height = 30.78;

  @override
  Widget build(BuildContext context) {
    final k = xHeight / 12;
    return SvgPicture.asset(
      'assets/logo/wordmark-header-plum.svg',
      width: _width * k,
      height: _height * k,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: 'mooncycle',
    );
  }
}

/// The phase-ring mark with the wordmark (Settings footer, brand uses).
class Lockup extends StatelessWidget {
  const Lockup({super.key, required this.height, this.onPlum = false});

  final double height;

  /// The cream version for plum backgrounds.
  final bool onPlum;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    onPlum
        ? 'assets/logo/lockup-on-plum.svg'
        : 'assets/logo/lockup-primary.svg',
    height: height,
    semanticsLabel: 'mooncycle',
  );
}

/// The four-colour phase-ring mark (onboarding welcome; spec §7.1).
///
/// On plum it is drawn in the theme's phase accents (the dark theme's are
/// brighter), with the marker cut out of the ring.
class PhaseRingMark extends StatelessWidget {
  const PhaseRingMark({super.key, required this.size, this.onPlum = false});

  final double size;

  /// Cream marker for plum backgrounds.
  final bool onPlum;

  @override
  Widget build(BuildContext context) {
    if (!onPlum) {
      return SvgPicture.asset(
        'assets/mark/phase-ring.svg',
        width: size,
        height: size,
        excludeFromSemantics: true,
      );
    }
    final c = context.moon;
    String hex(Color color) =>
        '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    // The paths of `design/assets/mark/phase-ring-on-plum.svg`.
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">'
        '<mask id="ko" maskUnits="userSpaceOnUse" x="-50" y="-50" '
        'width="300" height="300"><rect x="-50" y="-50" width="300" '
        'height="300" fill="#fff"/><circle cx="155.86" cy="73.1" r="28" '
        'fill="#000"/></mask><g mask="url(#ko)">'
        '<path d="M 102.16 38.04 A 62 62 0 0 1 154.89 71.17" fill="none" '
        'stroke="${hex(c.phase(Phase.menstrual).accent)}" stroke-width="30"/>'
        '<path d="M 156.76 75.07 A 62 62 0 0 1 140.32 147.09" fill="none" '
        'stroke="${hex(c.phase(Phase.follicular).accent)}" stroke-width="30"/>'
        '<path d="M 136.94 149.79 A 62 62 0 0 1 88.32 160.89" fill="none" '
        'stroke="${hex(c.phase(Phase.ovulatory).accent)}" stroke-width="30"/>'
        '<path d="M 84.10 159.93 A 62 62 0 0 1 97.84 38.04" fill="none" '
        'stroke="${hex(c.phase(Phase.luteal).accent)}" stroke-width="30"/>'
        '</g><circle cx="155.86" cy="73.1" r="22" '
        'fill="${hex(c.welcomeText)}"/></svg>';
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      excludeFromSemantics: true,
    );
  }
}
