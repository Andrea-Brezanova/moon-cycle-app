@Tags(['golden'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/foods/application/food_providers.dart';
import 'package:moon_cycle/features/foods/domain/food_profile.dart';
import 'package:moon_cycle/features/foods/presentation/food_detail_page.dart';

import '../goldens/screens/home_golden_test.dart' show stateOnDay;
import '../helpers/golden_screen.dart';
import '../helpers/moon_fonts.dart';
import '../helpers/test_catalogue.dart';

/// Renders the real Food Detail page with the PROPOSED Wave 1 wording and the
/// proposed heading, for the owner's approval. Nothing is published: the
/// profiles come from `wave-1-candidate.json` (publishable: false), are made
/// displayable only inside this test, and the app's own data is untouched.
///
/// Skipped unless `WAVE1_SCREENS=1`. To refresh the pictures:
///   WAVE1_SCREENS=1 flutter test test/tool/wave1_screens_test.dart --update-goldens
void main() {
  final candidate = jsonDecode(
    File('docs/food-profiles/wave-1-candidate.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final heading = candidate['cycleHeading']! as String;
  final profiles = (candidate['profiles']! as Map).cast<String, Object?>();
  const shown = ['beef', 'kale', 'almond', 'arugula', 'sardine', 'strawberry'];
  final skip = Platform.environment['WAVE1_SCREENS'] != '1'
      ? 'set WAVE1_SCREENS=1 to render the approval previews'
      : null;

  for (final id in shown) {
    testWidgets('Food Detail preview: $id', (tester) async {
      await loadMoonFonts();
      final profile = FoodProfile.fromJson(
        profiles[id]! as Map<String, Object?>,
        reviewLabel:
            'Nutrition values checked against USDA and NIH sources; not '
            'clinically reviewed.',
        publishable: true, // preview only; the file itself says false
      );
      final food = testCatalogue.food(id)!;
      await pumpScreen(
        tester,
        FoodDetailPage(foodId: id, phase: food.why.keys.first, general: false),
        dark: false,
        height: 2150,
        overrides: [
          cycleStateProvider.overrideWithValue(stateOnDay(7)),
          foodProfilesProvider.overrideWithValue({id: profile}),
          profileCycleHeadingProvider.overrideWithValue(heading),
          phaseBadgeTemplateProvider.overrideWithValue(
            'Featured for variety in the {phase} phase',
          ),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text(heading.toUpperCase()), findsOneWidget);
      expect(find.text('CYCLE RELEVANCE'), findsNothing);
      expect(find.textContaining('Recommended for your'), findsNothing);
      expect(
        find.textContaining('Featured for variety in the'),
        findsOneWidget,
      );
      await expectLater(
        find.byType(FoodDetailPage),
        matchesGoldenFile('../../docs/food-profiles/wave-1-screens/$id.png'),
      );
    }, skip: skip != null);
  }
}
