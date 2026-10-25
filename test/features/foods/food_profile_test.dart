import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/foods/application/food_providers.dart';
import 'package:moon_cycle/features/foods/domain/food_profile.dart';
import 'package:moon_cycle/features/foods/presentation/food_detail_page.dart';

import '../../helpers/golden_screen.dart';

/// The five reference profiles from the review document, read as they are.
Map<String, FoodProfile> loadProfiles({bool? publishable}) {
  final json = jsonDecode(
    File('docs/food-profiles/reference-profiles.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final label = json['_reviewLabel']! as String;
  final profiles = json['profiles']! as Map<String, Object?>;
  return {
    for (final e in profiles.entries)
      e.key: FoodProfile.fromJson(
        e.value! as Map<String, Object?>,
        reviewLabel: label,
        publishable: publishable,
      ),
  };
}

/// The profiles bundled with the app, as the app loads them.
Map<String, FoodProfile> bundledProfiles() => parseFoodProfiles(
  jsonDecode(File('assets/content/food_profiles.json').readAsStringSync())
      as Map<String, Object?>,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the reference profiles parse, and none is publishable as written', () {
    final profiles = loadProfiles();
    expect(profiles.keys, [
      'spinach',
      'green-lentil',
      'pumpkin-seeds',
      'broccoli',
      'orange',
    ]);
    for (final p in profiles.values) {
      expect(p.publishable, isFalse, reason: p.foodId);
      expect(p.reviewLabel, contains('not clinically reviewed'));
      expect(p.whatItOffers, isNotEmpty);
      expect(p.cycleRelevance.split('. ').length, lessThanOrEqualTo(3));
    }
  });

  test('vitamin K has no percentage; magnesium shows both age groups', () {
    final profiles = loadProfiles();
    final k = profiles['spinach']!.nutrients.firstWhere(
      (n) => n.name == 'Vitamin K',
    );
    expect(k.references, isEmpty);
    final mg = profiles['pumpkin-seeds']!.nutrients.firstWhere(
      (n) => n.name == 'Magnesium',
    );
    expect(mg.references.map((r) => r.group), ['19–30 y', '31–50 y']);
    expect(mg.references.map((r) => r.value), [310, 320]);
  });

  Future<void> pump(
    WidgetTester tester, {
    FoodProfile? profile,
    String id = 'spinach',
    double scale = 1,
  }) async {
    await pumpScreen(
      tester,
      FoodDetailPage(foodId: id, phase: Phase.menstrual),
      dark: false,
      height: 2200,
      textScale: scale,
      overrides: [foodProfileProvider(id).overrideWithValue(profile)],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('without a profile the page is exactly as before', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byKey(const ValueKey('food-profile')), findsNothing);
    expect(find.text('WHY THIS FOOD?'), findsOneWidget);
    expect(find.textContaining('High in oxalate'), findsOneWidget);
  });

  testWidgets('a profile that is not publishable is never shown', (
    tester,
  ) async {
    await pump(tester, profile: loadProfiles()['spinach']);
    expect(find.byKey(const ValueKey('food-profile')), findsNothing);
  });

  testWidgets('a publishable profile adds the five sections, keeps the rest '
      'of the page, and shows its sourced cautions', (tester) async {
    final profile = loadProfiles(publishable: true)['spinach']!;
    await pump(tester, profile: profile);
    for (final t in [
      'WHAT THIS FOOD OFFERS',
      'KEY NUTRIENTS',
      'A PRACTICAL SERVING',
      'HOW TO EAT IT',
      'CYCLE RELEVANCE',
    ]) {
      await tester.scrollUntilVisible(
        find.text(t),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.text('WHY THIS FOOD?'), findsOneWidget); // still there
    expect(find.textContaining('not clinically reviewed'), findsOneWidget);
    // No Symptoms or Hormones section.
    expect(find.textContaining('SYMPTOMS'), findsNothing);
    expect(find.textContaining('HORMONES'), findsNothing);
    // Vitamin K: an amount, no percentage; the cautions are the sourced ones.
    expect(find.textContaining('445 µg'), findsOneWidget);
    expect(find.textContaining('oxalate'), findsOneWidget);
    expect(find.textContaining('blood thinner'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('it fits 320 pt with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 2600) * 3;
    await pump(
      tester,
      profile: loadProfiles(publishable: true)['pumpkin-seeds'],
      id: 'pumpkin-seeds',
      scale: 1.5,
    );
    expect(tester.takeException(), isNull);
  });
}
