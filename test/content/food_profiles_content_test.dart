import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/foods/application/food_providers.dart';
import 'package:moon_cycle/features/foods/presentation/food_detail_page.dart';

import '../features/foods/food_profile_test.dart' show bundledProfiles;
import '../helpers/golden_screen.dart';
import '../helpers/test_catalogue.dart';

/// The only foods with a profile, and the exact USDA record and preparation each
/// one was reviewed against.
const _reviewed = {
  'spinach': (168463, 'cooked, boiled, drained, no salt'),
  'green-lentil': (172421, 'cooked, boiled, no salt'),
  'pumpkin-seeds': (170556, 'dried edible kernels (hulled), unsalted'),
  'broccoli': (169967, 'cooked, boiled, drained, no salt'),
  'orange': (746771, 'raw, flesh only'),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final json = jsonDecode(
    File('assets/content/food_profiles.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final raw = json['profiles']! as Map<String, Object?>;

  test('exactly the five reviewed foods are bundled, all existing catalogue '
      'foods', () {
    expect(raw.keys.toSet(), _reviewed.keys.toSet());
    for (final id in raw.keys) {
      expect(testCatalogue.food(id), isNotNull, reason: id);
    }
    expect(bundledProfiles().keys.toSet(), _reviewed.keys.toSet());
  });

  test('each profile keeps its exact USDA record and preparation', () {
    for (final MapEntry(key: id, value: v) in _reviewed.entries) {
      final source =
          (raw[id]! as Map<String, Object?>)['source']! as Map<String, Object?>;
      expect(source['usdaFdcId'], v.$1, reason: id);
      expect(source['preparationState'], v.$2, reason: id);
      expect(source['portionGrams'], isA<num>(), reason: id);
      expect(source['portion'], isNotEmpty, reason: id);
    }
  });

  test('every displayed amount equals the USDA per-100 g value times the '
      'serving, and no percentage is wrong', () {
    const keyOf = {
      'Iron': 'iron',
      'Folate': 'folate',
      'Vitamin K': 'vitk',
      'Magnesium': 'mg',
      'Zinc': 'zn',
      'Potassium': 'k',
      'Vitamin A': 'vita',
      'Vitamin C': 'vitc',
    };
    for (final MapEntry(key: id, value: p) in raw.entries) {
      final profile = p! as Map<String, Object?>;
      final source = profile['source']! as Map<String, Object?>;
      final per100 = source['per100g']! as Map<String, Object?>;
      final grams = (source['portionGrams']! as num).toDouble();
      final serving = profile['perServing']! as Map<String, Object?>;
      expect(
        serving['energyKcal'],
        ((per100['kcal']! as num) * grams / 100).round(),
        reason: '$id kcal',
      );
      for (final n in serving['keyNutrients']! as List<Object?>) {
        final nut = n! as Map<String, Object?>;
        final per = (per100[keyOf[nut['name']]]! as num).toDouble();
        final amount = per * grams / 100;
        expect(
          (nut['amount']! as num).toDouble(),
          closeTo(amount, amount < 10 ? 0.06 : 0.6),
          reason: '$id ${nut['name']}',
        );
        for (final r in (nut['reference'] as List<Object?>? ?? const [])) {
          final ref = r! as Map<String, Object?>;
          expect(
            ref['percent'],
            (amount * 100 / (ref['value']! as num)).round(),
            reason: '$id ${nut['name']} ${ref['group']}',
          );
        }
      }
    }
  });

  test(
    'vitamin K never shows a percentage; magnesium shows both age groups',
    () {
      for (final p in bundledProfiles().values) {
        for (final n in p.nutrients) {
          if (n.name == 'Vitamin K') expect(n.references, isEmpty);
          if (n.name == 'Magnesium') {
            expect(n.references.map((r) => r.value), [310, 320]);
          }
        }
      }
    },
  );

  test('copy makes no hormone, treatment or clinical-review claims', () {
    final banned = RegExp(
      r'balanc|detox|\bcure|\btreat|prevent|\bpms\b|cramp|clinically '
      r'(reviewed|proven|tested)|proven|\bheal(s|ing|ed)?\b',
      caseSensitive: false,
    );
    for (final p in bundledProfiles().values) {
      for (final text in [
        p.whatItOffers,
        p.practicalServing,
        p.howToEatIt,
        p.cycleRelevance,
      ]) {
        // "not clinically reviewed" is the label, not a claim.
        expect(banned.hasMatch(text), isFalse, reason: '${p.foodId}: $text');
      }
      expect(p.reviewLabel, contains('not clinically reviewed'));
      // Cycle relevance never invents a phase benefit.
      expect(
        p.cycleRelevance,
        isNot(
          matches(RegExp(r'(menstrual|follicular|ovulatory|luteal) phase')),
        ),
        reason: p.foodId,
      );
    }
  });

  test('phase assignments and food ids are untouched by the profiles', () {
    final phases =
        (jsonDecode(File('assets/content/phases.json').readAsStringSync())
                as Map<String, Object?>)['phases']!
            as List<Object?>;
    final menstrual = phases.cast<Map<String, Object?>>().firstWhere(
      (p) => p['id'] == 'menstrual',
    );
    final featured = {
      for (final c in (menstrual['categories']! as List<Object?>))
        ...((c! as Map<String, Object?>)['foods']! as List<Object?>)
            .cast<String>(),
    };
    for (final id in _reviewed.keys) {
      expect(featured, contains(id), reason: '$id stays in its phase list');
    }
  });

  group('Food Detail with the bundled profiles', () {
    Future<void> pump(WidgetTester tester, String id) async {
      await pumpScreen(
        tester,
        FoodDetailPage(foodId: id, phase: Phase.menstrual),
        dark: false,
        height: 3000,
        overrides: [foodProfilesProvider.overrideWithValue(bundledProfiles())],
      );
      await tester.pumpAndSettle();
    }

    for (final id in _reviewed.keys) {
      testWidgets('$id shows the five sections and its actions', (
        tester,
      ) async {
        await pump(tester, id);
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
          expect(find.text(t), findsOneWidget, reason: '$id $t');
        }
        expect(find.text('WHY THIS FOOD?'), findsOneWidget);
        expect(find.textContaining('not clinically reviewed'), findsOneWidget);
        expect(find.textContaining('SYMPTOMS'), findsNothing);
        expect(find.textContaining('HORMONES'), findsNothing);
        await tester.scrollUntilVisible(
          find.textContaining('Add to shopping list'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.textContaining('Build a Meal'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a food without a profile looks exactly as before', (
      tester,
    ) async {
      await pump(tester, 'kale');
      expect(find.byKey(const ValueKey('food-profile')), findsNothing);
    });
  });
}
