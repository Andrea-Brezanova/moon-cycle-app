@Tags(['golden'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/application/content_providers.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/cycle/application/viewing_phase.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_calculator.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_lengths.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_profile.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_state.dart';
import 'package:moon_cycle/features/home/application/home_providers.dart';
import 'package:moon_cycle/features/home/presentation/home_page.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/moon_fonts.dart';

class _Preview extends HomePreview {
  _Preview(this.day);

  final int day;

  @override
  int? build() => day;
}

class _Viewing extends ViewingPhase {
  _Viewing(this.phase);

  final Phase phase;

  @override
  Phase build() => phase;
}

/// Day [day] of a 28/5 cycle on the design's sample day.
AsyncData<CycleState?> stateOnDay(int day) {
  final today = LocalDate(2025, 10, 4);
  return AsyncData(
    calculateCycleState(
      lastPeriodStart: today.addDays(1 - day),
      lengths: CycleLengths.fromProfile(
        const CycleProfile(typicalCycleLength: 28, typicalPeriodLength: 5),
      ),
      today: today,
    ),
  );
}

void main() {
  setUpAll(loadMoonFonts);

  final cases = <String, List<Override>>{
    for (final (phase, day) in [
      (Phase.menstrual, 2),
      (Phase.follicular, 7),
      (Phase.ovulatory, 13),
      (Phase.luteal, 21),
    ])
      phase.name: [cycleStateProvider.overrideWithValue(stateOnDay(day))],
    'late': [cycleStateProvider.overrideWithValue(stateOnDay(32))],
    'preview': [
      cycleStateProvider.overrideWithValue(stateOnDay(7)),
      homePreviewProvider.overrideWith(() => _Preview(14)),
      viewingPhaseProvider.overrideWith(() => _Viewing(Phase.ovulatory)),
    ],
    'no-recipes': [
      cycleStateProvider.overrideWithValue(stateOnDay(7)),
      foodFilterProvider.overrideWithValue(
        const FoodFilter(
          avoidances: [
            AllergenAvoidance(id: 'a', allergenId: 'gluten'),
            FoodItemAvoidance(id: 'b', foodId: 'broccoli'),
          ],
        ),
      ),
    ],
  };

  for (final MapEntry(key: theme, value: dark) in themes.entries) {
    for (final MapEntry(key: name, value: overrides) in cases.entries) {
      testWidgets('home $name, $theme', (tester) async {
        await pumpScreen(
          tester,
          const HomePage(),
          dark: dark,
          height: 1800,
          overrides: overrides,
        );
        await expectLater(
          find.byType(HomePage),
          matchesGoldenFile('goldens/$theme-home-$name.png'),
        );
      });
    }
  }
}
