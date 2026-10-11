import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';

void main() {
  test('phases are in cycle order', () {
    expect(Phase.values, [
      Phase.menstrual,
      Phase.follicular,
      Phase.ovulatory,
      Phase.luteal,
    ]);
  });

  test('next follows the cycle and wraps from luteal to menstrual', () {
    expect(Phase.menstrual.next, Phase.follicular);
    expect(Phase.follicular.next, Phase.ovulatory);
    expect(Phase.ovulatory.next, Phase.luteal);
    expect(Phase.luteal.next, Phase.menstrual);
  });
}
