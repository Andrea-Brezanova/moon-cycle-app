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

/// Home's cycle ring (v2): a thick segmented ring, the day number alone in its
/// centre (no "DAY" label), and an ivory pearl with a fine plum outline marking
/// the day. The centre is the page colour. Everything is drawn from the same
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
  static const double thickness = 32;
  static const double radius = 150 - thickness / 2 - 2; // 132
  static const double pearl = 14;
  static const double outline = 1.75;
  static const double gap = 0.006;

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
                Text(
                  '${spec.dayNumber}',
                  style: MoonType.dayNumber.copyWith(
                    color: dark ? HeroTokens.darkText : HeroTokens.moonNumber,
                  ),
                  textScaler: TextScaler.noScaling,
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
    canvas.drawCircle(
      dot,
      HomeRing.pearl,
      Paint()..color = const Color(0xFFFFFDF8),
    );
    canvas.drawCircle(
      dot,
      HomeRing.pearl,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = HomeRing.outline
        ..color = const Color(0xFF37255C),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.spec != spec || old.dark != dark || old.phases != phases;
}
