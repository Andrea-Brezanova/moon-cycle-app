import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_calculator.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_lengths.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_profile.dart';
import 'package:moon_cycle/features/home/presentation/widgets/home_hero.dart';
import 'package:moon_cycle/features/home/presentation/widgets/home_sections.dart';

void main() {
  final start = LocalDate(2025, 9, 28);
  final lengths = CycleLengths.fromProfile(
    const CycleProfile(typicalCycleLength: 28, typicalPeriodLength: 5),
  );
  final state7 = calculateCycleState(
    lastPeriodStart: start,
    lengths: lengths,
    today: start.addDays(6),
  );

  test('hero lines, as on the canvas', () {
    expect(
      homeHeroMeta(state7),
      'Day 2 of 6 in phase · Day 7 of 28 in cycle\nOvulatory in 5 days',
    );
    final luteal = calculateCycleState(
      lastPeriodStart: start,
      lengths: lengths,
      today: start.addDays(20),
    );
    expect(homeHeroMeta(luteal), endsWith('\nPeriod in 8 days'));
    final late = calculateCycleState(
      lastPeriodStart: start,
      lengths: lengths,
      today: start.addDays(31),
    );
    expect(homeHeroMeta(late), 'Period 4 days late · Day 32 in cycle');
  });

  test('preview lines', () {
    expect(homePreviewMeta(state7, 14), 'Previewing day 14 · in 7 days');
    expect(homePreviewMeta(state7, 8), 'Previewing day 8 · in 1 day');
    expect(homePreviewMeta(state7, 3), 'Previewing day 3 · 4 days ago');
  });

  test('the tagline’s last word is italic', () {
    expect(
      italicLastWord('Fresh, light and energising'),
      'Fresh, light and *energising*',
    );
    expect(italicLastWord('Rest'), '*Rest*');
  });
}
