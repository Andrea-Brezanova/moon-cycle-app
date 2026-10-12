@Tags(['golden'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_calculator.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_lengths.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_profile.dart';
import 'package:moon_cycle/features/onboarding/application/onboarding_controller.dart';
import 'package:moon_cycle/features/onboarding/domain/onboarding_answers.dart';
import 'package:moon_cycle/features/onboarding/presentation/cycle_length_page.dart';
import 'package:moon_cycle/features/onboarding/presentation/food_preferences_page.dart';
import 'package:moon_cycle/features/onboarding/presentation/last_period_page.dart';
import 'package:moon_cycle/features/onboarding/presentation/phase_reveal_page.dart';
import 'package:moon_cycle/features/onboarding/presentation/welcome_page.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/moon_fonts.dart';

class _Answers extends OnboardingController {
  _Answers(this.initial);

  final OnboardingAnswers initial;

  @override
  OnboardingAnswers build() => initial;
}

/// The design's sample answers (`sample-content.json` › `sampleCycle`).
final sample = OnboardingAnswers(
  lastPeriodStart: LocalDate(2025, 9, 28),
  allergenIds: const {'peanut', 'shellfish'},
);

void main() {
  setUpAll(loadMoonFonts);

  final answers = onboardingControllerProvider.overrideWith(
    () => _Answers(sample),
  );

  for (final MapEntry(key: theme, value: dark) in themes.entries) {
    final screens = <String, Widget>{
      '01-welcome': const WelcomePage(),
      '02-last-period': const LastPeriodPage(),
      '03-cycle-length': const CycleLengthPage(),
      '04-food-preferences': const FoodPreferencesPage(),
    };
    for (final MapEntry(key: name, value: screen) in screens.entries) {
      testWidgets('onboarding $name, $theme', (tester) async {
        await pumpScreen(tester, screen, dark: dark, overrides: [answers]);
        await expectLater(
          find.byWidget(screen),
          matchesGoldenFile('goldens/$theme-onboarding-$name.png'),
        );
      });
    }

    for (final (phase, day) in [
      (Phase.menstrual, 2),
      (Phase.follicular, 7),
      (Phase.ovulatory, 13),
      (Phase.luteal, 21),
    ]) {
      testWidgets('onboarding reveal ${phase.name}, $theme', (tester) async {
        final start = LocalDate(2025, 10, 4).addDays(1 - day);
        final state = calculateCycleState(
          lastPeriodStart: start,
          lengths: CycleLengths.fromProfile(
            const CycleProfile(typicalCycleLength: 28, typicalPeriodLength: 5),
          ),
          today: LocalDate(2025, 10, 4),
        );
        expect(state.phase, phase);
        await pumpScreen(
          tester,
          const PhaseRevealPage(),
          dark: dark,
          overrides: [cycleStateProvider.overrideWithValue(AsyncData(state))],
        );
        await expectLater(
          find.byType(PhaseRevealPage),
          matchesGoldenFile(
            'goldens/$theme-onboarding-05-reveal-${phase.name}.png',
          ),
        );
      });
    }
  }
}
