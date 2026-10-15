@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/application/content_providers.dart'
    show foodFilterProvider;
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/foods/presentation/widgets/meal_builder_section.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';

import '../goldens/screens/home_golden_test.dart' show stateOnDay;
import '../helpers/golden_screen.dart';
import '../helpers/moon_fonts.dart';

/// Preview of the "Build a balanced meal" section for owner review.
void main() {
  setUpAll(loadMoonFonts);

  for (final (name, diet, phase, open) in [
    ('omnivore-ovulatory-closed', Diet.omnivore, Phase.ovulatory, false),
    ('omnivore-ovulatory', Diet.omnivore, Phase.ovulatory, true),
    ('vegetarian-ovulatory', Diet.vegetarian, Phase.ovulatory, true),
    ('vegan-ovulatory', Diet.vegan, Phase.ovulatory, true),
    ('vegan-luteal', Diet.vegan, Phase.luteal, true),
  ]) {
    testWidgets('meal builder $name', (tester) async {
      await pumpScreen(
        tester,
        Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: MealBuilderSection(phase: phase, initiallyExpanded: open),
            ),
          ),
        ),
        dark: false,
        height: 1200,
        overrides: <Override>[
          cycleStateProvider.overrideWithValue(stateOnDay(7)),
          foodFilterProvider.overrideWithValue(FoodFilter(diet: diet)),
        ],
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/meal-builder-$name.png'),
      );
    });
  }
}
