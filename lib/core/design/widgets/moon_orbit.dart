import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../domain/phase.dart';
import '../moon_theme.dart';
import '../tokens/hero_tokens.dart';
import '../tokens/moon_colors.dart';
import '../tokens/moon_typography.dart';
import 'moon_orbit_geometry.dart';

export 'moon_orbit_geometry.dart';

/// The Home moon (spec §6): an ochre-tinted moon inside a 12 pt orbit of four
/// phase segments, with a today dot, drawn natively at any size.
///
/// The design space is 300 × 300; everything, including the centre text,
/// scales with [size].
class MoonOrbit extends StatelessWidget {
  const MoonOrbit({
    super.key,
    required this.spec,
    required this.dark,
    required this.haloColor,
    this.size = 300,
    this.semanticLabel,
  });

  final MoonOrbitSpec spec;

  /// Dark mode adds the phase glow and the marker ring.
  final bool dark;

  /// The hero background behind the dot (the cut-out look).
  final Color haloColor;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.moon;
    return Semantics(
      label: semanticLabel ?? 'Cycle day ${spec.dayNumber}',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: FittedBox(
          child: SizedBox.square(
            dimension: OrbitGeometry.viewBox,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(OrbitGeometry.viewBox),
                  painter: MoonOrbitPainter(
                    spec: spec,
                    phases: colors.phases,
                    dark: dark,
                    haloColor: haloColor,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'DAY',
                      style: MoonType.overline.copyWith(
                        fontSize: 11,
                        letterSpacing: 11 * 0.14,
                        color: HeroTokens.moonLabel,
                      ),
                    ),
                    Text(
                      '${spec.dayNumber}',
                      style: MoonType.dayNumber.copyWith(
                        color: HeroTokens.moonNumber,
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

/// Paints the moon, glow, orbit segments and today dot in the 300-unit
/// design space (scaled to the canvas size).
class MoonOrbitPainter extends CustomPainter {
  MoonOrbitPainter({
    required this.spec,
    required this.phases,
    required this.dark,
    required this.haloColor,
  });

  final MoonOrbitSpec spec;
  final Map<Phase, PhasePalette> phases;
  final bool dark;
  final Color haloColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / OrbitGeometry.viewBox);
    const c = Offset(OrbitGeometry.centre, OrbitGeometry.centre);
    final active = phases[spec.activePhase]!;

    // Dark mode: a faint glow of the phase accent around the moon.
    if (dark) {
      final glow = Rect.fromCircle(center: c, radius: OrbitGeometry.glowRadius);
      final a = active.accent;
      canvas.drawCircle(
        c,
        OrbitGeometry.glowRadius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              a.withValues(alpha: OrbitGeometry.glowOpacity),
              a.withValues(alpha: OrbitGeometry.glowOpacity),
              a.withValues(alpha: 0),
            ],
            stops: const [0, OrbitGeometry.glowInnerStop, 1],
          ).createShader(glow),
      );
    }

    // The moon.
    final moon = Rect.fromCircle(center: c, radius: OrbitGeometry.moonRadius);
    canvas.drawCircle(
      c,
      OrbitGeometry.moonRadius,
      Paint()
        ..shader = RadialGradient(
          center: OrbitGeometry.moonGradientCentre,
          radius: OrbitGeometry.moonGradientRadius,
          colors: dark
              ? const [HeroTokens.moonDarkInner, HeroTokens.moonDarkOuter]
              : const [HeroTokens.moonLightInner, HeroTokens.moonLightOuter],
        ).createShader(moon),
    );

    // The four phase segments: flat ends, almost touching.
    final ring = Rect.fromCircle(center: c, radius: OrbitGeometry.radius);
    for (final s in spec.segments) {
      final (f0, f1) = OrbitMath.segmentFractions(s, spec.cycleLength);
      final palette = phases[s.phase]!;
      canvas.drawArc(
        ring,
        -math.pi / 2 + f0 * 2 * math.pi,
        (f1 - f0) * 2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = OrbitGeometry.stroke
          ..strokeCap = StrokeCap.butt
          ..color = s.phase == spec.activePhase ? palette.accent : palette.tint,
      );
    }

    // The today dot, cut out of the orbit by a halo in the hero colour.
    final dot = OrbitMath.pointAt(
      OrbitMath.markerFraction(spec.markerDay, spec.cycleLength),
    );
    canvas.drawCircle(dot, OrbitGeometry.dotHalo, Paint()..color = haloColor);
    canvas.drawCircle(
      dot,
      OrbitGeometry.dot,
      Paint()..color = dark ? HeroTokens.dotDark : HeroTokens.dotLight,
    );
    if (dark) {
      canvas.drawCircle(
        dot,
        OrbitGeometry.dot,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = OrbitGeometry.markerRingWidth
          ..color = active.accent,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(MoonOrbitPainter old) =>
      old.spec != spec ||
      old.dark != dark ||
      old.haloColor != haloColor ||
      old.phases != phases;
}
