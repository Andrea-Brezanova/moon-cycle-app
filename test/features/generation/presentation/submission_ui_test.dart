import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/router/app_router.dart';
import 'package:moon_cycle/app/router/routes.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/content/domain/recipe.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/generation/application/generation_providers.dart';
import 'package:moon_cycle/features/generation/data/personal_recipe_repository.dart';
import 'package:moon_cycle/features/generation/domain/generation_result.dart';
import 'package:moon_cycle/features/generation/domain/personal_recipe.dart';
import 'package:moon_cycle/features/generation/domain/recipe_image_service.dart';
import 'package:moon_cycle/features/generation/domain/recipe_submission_service.dart';

import '../../../helpers/golden_screen.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

class FakeSubmission implements RecipeSubmissionService {
  FakeSubmission({this.error});
  final SubmissionFailure? error;
  final sent = <String>[];

  @override
  Future<RecipeLifecycle> submit(String remoteRecipeId) async {
    sent.add(remoteRecipeId);
    if (error != null) throw SubmissionException(error!);
    return RecipeLifecycle.validated;
  }
}

PersonalRecipe recipe({required bool cloud, String id = 'u-1'}) =>
    PersonalRecipe(
      recipe: Recipe(
        id: id,
        title: 'Tofu & Farro Bowl',
        phase: Phase.luteal,
        category: RecipeCategory.dinner,
        minutes: 30,
        serves: 2,
        intro: 'A simple bowl of tofu and farro.',
        whyThisPhase: 'Made from the foods you chose: tofu and farro.',
        keyFoodIds: const ['tofu', 'farro'],
        ingredients: const [
          RecipeIngredient(
            label: 'Tofu',
            foodId: 'tofu',
            amount: 150,
            unit: 'g',
            aisleId: 'protein',
          ),
        ],
        steps: const ['Cook the farro.', 'Warm the tofu.', 'Serve.'],
      ),
      ownerId: 'dev-local-user',
      idempotencyKey: 'k-$id',
      fingerprint: 'f-$id',
      provenance: Provenance(
        origin: cloud ? GenerationOrigin.cloud : GenerationOrigin.devMock,
        provider: 'p',
        model: 'm',
      ),
      createdAt: DateTime.utc(2026, 10, 17),
      imageStatus: ImageStatus.ready,
      remoteId: cloud ? 'srv-uuid' : null,
    );

void main() {
  Future<(ProviderContainer, AppDatabase)> pump(
    WidgetTester tester,
    PersonalRecipe saved, {
    RecipeSubmissionService? submission,
  }) async {
    tester.view.physicalSize = const Size(390, 2600) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    await tester.runAsync(() => PersonalRecipeRepository(db).save(saved));
    final c = await pumpApp(
      tester,
      database: db,
      overrides: [
        clockProvider.overrideWithValue(designNow),
        debugUnlockAtStartProvider.overrideWithValue(true),
        if (submission != null)
          recipeSubmissionServiceProvider.overrideWithValue(submission),
      ],
    );
    c.read(appRouterProvider).go(Routes.recipe(saved.id));
    await tester.pumpAndSettle();
    return (c, db);
  }

  testWidgets('in builds without a backend there is no suggest control', (
    tester,
  ) async {
    await pump(tester, recipe(cloud: true));
    expect(find.text('Suggest to Moon Cycle'), findsNothing);
  });

  testWidgets('a development sample can never be suggested', (tester) async {
    await pump(tester, recipe(cloud: false), submission: FakeSubmission());
    expect(find.text('Suggest to Moon Cycle'), findsNothing);
  });

  testWidgets('suggesting needs consent, then shows it is in review, not '
      'published', (tester) async {
    final fake = FakeSubmission();
    final (c, db) = await pump(tester, recipe(cloud: true), submission: fake);
    expect(find.byKey(const ValueKey('lifecycle-line')), findsNothing);
    await tester.tap(find.text('Suggest to Moon Cycle'));
    await tester.pumpAndSettle();
    // Declining sends nothing.
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(fake.sent, isEmpty);

    await tester.tap(find.text('Suggest to Moon Cycle'));
    await tester.pumpAndSettle();
    expect(find.textContaining('nothing is published unless'), findsOneWidget);
    await tester.tap(find.text('Suggest it'));
    await tester.pumpAndSettle();
    expect(fake.sent, ['srv-uuid']);
    expect(
      find.textContaining('It stays private unless an editor approves it'),
      findsOneWidget,
    );
    expect(find.text('Suggest to Moon Cycle'), findsNothing);
    final stored = await tester.runAsync(
      () => PersonalRecipeRepository(db).byId('dev-local-user', 'u-1'),
    );
    expect(stored!.lifecycle, RecipeLifecycle.validated);
    expect(c, isNotNull);
  });

  testWidgets('a refused suggestion explains and leaves it private', (
    tester,
  ) async {
    await pump(
      tester,
      recipe(cloud: true),
      submission: FakeSubmission(error: SubmissionFailure.alreadySubmitted),
    );
    await tester.tap(find.text('Suggest to Moon Cycle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suggest it'));
    await tester.pumpAndSettle();
    expect(find.text('It has already been suggested.'), findsOneWidget);
    expect(find.byKey(const ValueKey('lifecycle-line')), findsNothing);
  });
}
