import '../../../core/design/widgets/moon_orbit_geometry.dart';
import '../../../core/domain/phase.dart';
import '../domain/cycle_state.dart';

/// Phase names as shown in the UI ("Follicular").
String phaseName(Phase phase) =>
    '${phase.name[0].toUpperCase()}${phase.name.substring(1)}';

/// What the moon orbit shows for [state] (Home hero, onboarding reveal).
///
/// [previewDay] (Home's drag preview) moves the marker and the number to
/// another day of the cycle, without changing anything else.
MoonOrbitSpec orbitSpecFor(CycleState state, {int? previewDay}) {
  final day = previewDay ?? state.orbitDay;
  return MoonOrbitSpec(
    segments: [
      for (final r in state.ranges.all)
        OrbitSegment(r.phase, r.firstDay, r.lastDay),
    ],
    cycleLength: state.cycleLength,
    activePhase: previewDay == null
        ? state.phase
        : state.ranges.forDay(previewDay).phase,
    markerDay: day,
    dayNumber: previewDay ?? state.cycleDay,
  );
}

/// The orbit's screen-reader label: "Cycle day 7 of 28, follicular phase,
/// day 2 of 6".
String orbitSemanticLabel(CycleState state) => state.isLate
    ? 'Cycle day ${state.cycleDay}, period ${state.daysLate} '
          '${state.daysLate == 1 ? 'day' : 'days'} late, luteal phase'
    : 'Cycle day ${state.cycleDay} of ${state.cycleLength}, '
          '${state.phase.name} phase, day ${state.phaseDay} of '
          '${state.phaseLength}';
