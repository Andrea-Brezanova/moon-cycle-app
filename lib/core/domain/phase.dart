/// The four cycle phases, in cycle order.
///
/// Phases are calculated estimates (see `features/cycle/domain`), not
/// observations of the user's body.
enum Phase {
  menstrual,
  follicular,
  ovulatory,
  luteal;

  /// The phase that follows this one; luteal is followed by menstrual.
  Phase get next => Phase.values[(index + 1) % Phase.values.length];
}
