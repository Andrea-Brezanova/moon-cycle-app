import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../../domain/phase.dart';
import '../tokens/hero_tokens.dart';

/// One phase's segment of the orbit, in cycle days (e.g. follicular 6–11).
class OrbitSegment {
  const OrbitSegment(this.phase, this.firstDay, this.lastDay);

  final Phase phase;
  final int firstDay;
  final int lastDay;
}

/// What the orbit shows. Built by the screen from the cycle state; the design
/// system itself knows nothing about cycle rules.
class MoonOrbitSpec {
  const MoonOrbitSpec({
    required this.segments,
    required this.cycleLength,
    required this.activePhase,
    required this.markerDay,
    required this.dayNumber,
  });

  /// The four phase segments in cycle order.
  final List<OrbitSegment> segments;
  final int cycleLength;

  /// Drawn in its accent colour; the others in their tints.
  final Phase activePhase;

  /// The day the today dot sits on (never past [cycleLength]).
  final int markerDay;

  /// The number in the moon. Can exceed [cycleLength] when a period is late.
  final int dayNumber;
}

/// Orbit maths in the 300 × 300 design space. Angles are fractions of a full
/// turn, clockwise from 12 o'clock.
abstract final class OrbitMath {
  /// Start and end of a segment, trimmed by [OrbitGeometry.gap] at each end so
  /// neighbouring segments almost touch.
  static (double, double) segmentFractions(OrbitSegment s, int cycleLength) => (
    (s.firstDay - 1) / cycleLength + OrbitGeometry.gap,
    s.lastDay / cycleLength - OrbitGeometry.gap,
  );

  /// The today dot sits in the middle of its day.
  static double markerFraction(int day, int cycleLength) =>
      (day - 0.5) / cycleLength;

  /// The point on a circle of [radius] at [fraction] of a turn.
  static Offset pointAt(
    double fraction, {
    double radius = OrbitGeometry.radius,
    double centre = OrbitGeometry.centre,
  }) {
    final a = fraction * 2 * math.pi;
    return Offset(centre + radius * math.sin(a), centre - radius * math.cos(a));
  }

  /// The cycle day under [point] (design space), for dragging the orbit.
  static int dayAt(Offset point, int cycleLength) {
    final dx = point.dx - OrbitGeometry.centre;
    final dy = point.dy - OrbitGeometry.centre;
    var turn = math.atan2(dx, -dy) / (2 * math.pi);
    if (turn < 0) turn += 1;
    return (turn * cycleLength).floor().clamp(0, cycleLength - 1) + 1;
  }
}
