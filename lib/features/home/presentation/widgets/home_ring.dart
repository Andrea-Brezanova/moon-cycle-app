import 'dart:math' as math;

import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/hero_tokens.dart';
import '../../../../core/design/tokens/moon_colors.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/moon_orbit.dart'
    show MoonOrbitSpec, OrbitMath;
import '../../../../core/domain/phase.dart';

/// Home's cycle ring (V1 refinement): the logo ring at 1.5× (centre radius 105,
/// stroke 30, flat ends, about 3° between segments) inside a 300-unit box, a
/// small "DAY" label over a large day number in the centre, and a white dot with
/// a fine dark outline marking the day, sitting directly on the ring. The centre
/// is the page colour. Everything is drawn from the same
/// [MoonOrbitSpec] and [OrbitMath] as before, so the ring's segments, order and
/// today marker are driven by the real cycle data.
///
/// The design space is 300 x 300 and scales with [size].
class HomeRing extends StatelessWidget {
  const HomeRing({super.key, required this.spec, required this.size});

  final MoonOrbitSpec spec;
  final double size;

  /// Ring geometry in the 300-unit design space.
  static const double viewBox = 300;
  static const double centre = 150;
  static const double thickness = 30;
  static const double radius = 105;
  static const double pearl = 15;
  static const double outline = 1;

  /// Half of the gap between two segments, as a fraction of the cycle (1.5°).
  static const double gap = 1.5 / 360;

  /// The band where a drag counts as previewing a day.
  static bool onRing(Offset local, double size) {
    final d =
        (local * (viewBox / size) - const Offset(centre, centre)).distance;
    return d > radius - thickness && d < radius + thickness;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.moon;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Cycle day ${spec.dayNumber}',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: FittedBox(
          child: SizedBox.square(
            dimension: viewBox,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(viewBox),
                  painter: _RingPainter(
                    spec: spec,
                    phases: colors.phases,
                    dark: dark,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'DAY',
                      style: dmSans(
                        11,
                        weight: FontWeight.w600,
                        height: 1.2,
                        tracking: 0.14,
                        color: dark
                            ? HeroTokens.darkMuted
                            : HeroTokens.lightMuted,
                      ),
                      textScaler: TextScaler.noScaling,
                    ),
                    Text(
                      '${spec.dayNumber}',
                      style: MoonType.dayNumber.copyWith(
                        color: dark
                            ? HeroTokens.darkText
                            : HeroTokens.moonNumber,
                      ),
                      textScaler: TextScaler.noScaling,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.spec, required this.phases, required this.dark});

  final MoonOrbitSpec spec;
  final Map<Phase, PhasePalette> phases;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / HomeRing.viewBox);
    const c = Offset(HomeRing.centre, HomeRing.centre);
    final ring = Rect.fromCircle(center: c, radius: HomeRing.radius);

    for (final s in spec.segments) {
      final f0 = (s.firstDay - 1) / spec.cycleLength + HomeRing.gap;
      final f1 = s.lastDay / spec.cycleLength - HomeRing.gap;
      final palette = phases[s.phase]!;
      canvas.drawArc(
        ring,
        -math.pi / 2 + f0 * 2 * math.pi,
        (f1 - f0) * 2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = HomeRing.thickness
          ..strokeCap = StrokeCap.butt
          // All four phases in their own colour, as in the approved design.
          ..color = palette.accent,
      );
    }

    final dot = OrbitMath.pointAt(
      OrbitMath.markerFraction(spec.markerDay, spec.cycleLength),
      radius: HomeRing.radius,
    );
    // A plain white dot with a 1 pt dark outline, directly on the ring.
    canvas.drawCircle(
      dot,
      HomeRing.pearl,
      Paint()..color = const Color(0xFFFFFFFF),
    );
    canvas.drawCircle(
      dot,
      HomeRing.pearl,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = HomeRing.outline
        ..color = const Color(0xFF1F1D2B),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.spec != spec || old.dark != dark || old.phases != phases;
}
