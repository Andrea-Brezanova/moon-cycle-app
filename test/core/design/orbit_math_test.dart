import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/design/tokens/hero_tokens.dart';
import 'package:moon_cycle/core/design/widgets/moon_orbit_geometry.dart';
import 'package:moon_cycle/core/domain/phase.dart';

void main() {
  const segments = [
    OrbitSegment(Phase.menstrual, 1, 5),
    OrbitSegment(Phase.follicular, 6, 11),
    OrbitSegment(Phase.ovulatory, 12, 15),
    OrbitSegment(Phase.luteal, 16, 28),
  ];

  test('segments start at 12 o’clock and almost touch', () {
    final (s0, e0) = OrbitMath.segmentFractions(segments[0], 28);
    final (s1, _) = OrbitMath.segmentFractions(segments[1], 28);
    final (_, e3) = OrbitMath.segmentFractions(segments[3], 28);
    expect(s0, closeTo(OrbitGeometry.gap, 1e-12));
    expect(e0, closeTo(5 / 28 - OrbitGeometry.gap, 1e-12));
    expect(s1 - e0, closeTo(2 * OrbitGeometry.gap, 1e-12)); // a tiny gap
    expect(e3, closeTo(1 - OrbitGeometry.gap, 1e-12));
  });

  test('the today dot sits in the middle of its day', () {
    expect(OrbitMath.markerFraction(1, 28), closeTo(0.5 / 28, 1e-12));
    expect(OrbitMath.markerFraction(7, 28), closeTo(6.5 / 28, 1e-12));
    expect(OrbitMath.markerFraction(28, 28), closeTo(27.5 / 28, 1e-12));
  });

  test('points: 12, 3, 6 and 9 o’clock', () {
    expectOffset(OrbitMath.pointAt(0), const Offset(150, 14));
    expectOffset(OrbitMath.pointAt(0.25), const Offset(286, 150));
    expectOffset(OrbitMath.pointAt(0.5), const Offset(150, 286));
    expectOffset(OrbitMath.pointAt(0.75), const Offset(14, 150));
  });

  test('dayAt is the inverse of the marker position, every day', () {
    for (final length in [21, 28, 45]) {
      for (var day = 1; day <= length; day++) {
        final p = OrbitMath.pointAt(OrbitMath.markerFraction(day, length));
        expect(OrbitMath.dayAt(p, length), day, reason: '$day of $length');
      }
    }
  });

  test('dayAt works anywhere on the circle, including the centre', () {
    expect(OrbitMath.dayAt(const Offset(151, 0), 28), 1); // just past 12
    expect(OrbitMath.dayAt(const Offset(149, 0), 28), 28); // just before 12
    expect(
      OrbitMath.dayAt(const Offset(150, 150), 28),
      inInclusiveRange(1, 28),
    );
  });
}

void expectOffset(Offset actual, Offset expected) {
  expect(actual.dx, closeTo(expected.dx, 1e-9));
  expect(actual.dy, closeTo(expected.dy, 1e-9));
}
