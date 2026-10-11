import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
class PhaseRingMark extends StatelessWidget {
  const PhaseRingMark({super.key, required this.size, this.onPlum = false});

  final double size;

  /// Cream marker for plum backgrounds.
  final bool onPlum;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    onPlum
        ? 'assets/mark/phase-ring-on-plum.svg'
        : 'assets/mark/phase-ring.svg',
    width: size,
    height: size,
    excludeFromSemantics: true,
  );
}
