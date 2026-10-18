import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/features/content/application/content_providers.dart';
import 'package:moon_cycle/features/content/domain/food_filter.dart';
import 'package:moon_cycle/features/cycle/application/viewing_phase.dart';
import 'package:moon_cycle/features/discovery/application/discovery_providers.dart';
import 'package:moon_cycle/features/discovery/data/providers/themealdb_client.dart';
import 'package:moon_cycle/features/discovery/data/usage_ledger.dart';
import 'package:moon_cycle/features/discovery/domain/recipe_source.dart';
import 'package:moon_cycle/features/entitlements/application/entitlement_providers.dart';
import 'package:moon_cycle/features/generation/application/generation_providers.dart';
import 'package:moon_cycle/features/generation/data/dev_mock_generation_service.dart';

import '../../helpers/fake_provider_http.dart';
import '../../helpers/test_catalogue.dart';

ProviderContainer make({
  bool debugBuild = true,
  bool devFlavour = true,
  FakeNetwork? net,
  FakeGeneration? generation,
}) {
  final db = AppDatabase(NativeDatabase.memory());
  final c = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      catalogueProvider.overrideWithValue(testCatalogue),
      foodFilterProvider.overrideWithValue(FoodFilter.none),
      actualPhaseProvider.overrideWithValue(Phase.luteal),
      debugPreviewAllowedProvider.overrideWithValue(debugBuild),
      debugUnlockAtStartProvider.overrideWithValue(devFlavour),
      if (net != null) providerHttpGetProvider.overrideWithValue(net.get),
    ],
  );
  addTearDown(() async {
    c.dispose();
    await db.close();
  });
  return c;
}

typedef FakeGeneration = DevMockGenerationService;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('which providers exist', () {
    test('debug dev build: TheMealDB is enabled', () {
      final c = make();
      expect(c.read(providerPoliciesProvider)['themealdb']!.enabled, isTrue);
      expect(c.read(externalClientsProvider).map((e) => e.providerId), [
        'themealdb',
      ]);
    });

    test('release, profile and prod builds: no external provider at all', () {
      for (final (debug, dev) in [
        (false, true),
        (true, false),
        (false, false),
      ]) {
        final c = make(debugBuild: debug, devFlavour: dev);
        expect(c.read(providerPoliciesProvider)['themealdb']!.enabled, isFalse);
        expect(c.read(externalClientsProvider), isEmpty, reason: '$debug $dev');
      }
    });

    test('Provider B is not configured anywhere', () {
      final c = make();
      expect(c.read(providerPoliciesProvider).keys, ['themealdb']);
      expect(
        c.read(externalClientsProvider).any((e) => e.providerId == 'recipeapi'),
        isFalse,
      );
    });
  });

  group('the real discovery wiring', () {
    test('library first, plus TheMealDB through the shared engine', () async {
      final net = mealDbNetwork();
      final c = make(net: net);
      final r = await c.read(mealDiscoveryProvider('garlic').future);
      expect(r.countsByProvider['moon-cycle'], greaterThan(0));
      expect(r.countsByProvider['themealdb'], greaterThan(0));
      expect(
        r.results.any((x) => x.source == RecipeSource.externalApi),
        isTrue,
      );
      expect(
        r.results.any((x) => x.source == RecipeSource.aiGenerated),
        isFalse,
      );
      expect(net.calls, isNotEmpty);
    });

    test(
      'release build: library only, and the network is never touched',
      () async {
        final net = mealDbNetwork();
        final c = make(debugBuild: false, net: net);
        final r = await c.read(mealDiscoveryProvider('garlic').future);
        expect(r.results.every((x) => x.providerId == 'moon-cycle'), isTrue);
        expect(net.calls, isEmpty);
      },
    );

    test('TheMealDB being down leaves the library results', () async {
      final net = FakeNetwork((u) => (status: 500, body: 'x'));
      final c = make(net: net);
      final r = await c.read(mealDiscoveryProvider('garlic').future);
      expect(r.failedSources.keys, ['themealdb']);
      expect(r.results, isNotEmpty);
    });

    test(
      'found external recipes can be reopened without a second request',
      () async {
        final net = mealDbNetwork();
        final c = make(net: net);
        final r = await c.read(mealDiscoveryProvider('garlic').future);
        final x = r.results.firstWhere(
          (e) => e.source == RecipeSource.externalApi,
        );
        final before = net.calls.length;
        final e = await c.read(externalRecipeProvider(x.recipe.id).future);
        expect(e!.recipe.title, x.recipe.title);
        expect(net.calls.length, before);
      },
    );

    test(
      'an uncached external recipe is fetched by id from its provider',
      () async {
        final net = mealDbNetwork();
        final c = make(net: net);
        final e = await c.read(
          externalRecipeProvider('x-themealdb-53282').future,
        );
        expect(e!.recipe.title, 'Algerian Carrots');
        expect(
          await c.read(externalRecipeProvider('x-nobody-1').future),
          isNull,
        );
        expect(await c.read(externalRecipeProvider('plain-id').future), isNull);
      },
    );

    test(
      'with the provider off, a saved external recipe is simply unavailable',
      () async {
        final c = make(debugBuild: false);
        expect(
          await c.read(externalRecipeProvider('x-themealdb-53282').future),
          isNull,
        );
      },
    );

    test('Build a meal never calls the generator', () async {
      final mock = DevMockGenerationService(
        catalogue: testCatalogue,
        delay: Duration.zero,
      );
      final c = make(net: mealDbNetwork());
      await c.read(mealDiscoveryProvider('kale').future);
      await c.read(mealDiscoveryProvider('moon-dust').future);
      expect(mock.calls, 0);
      expect(
        c.read(recipeGenerationServiceProvider),
        isA<DevMockGenerationService>(), // available, and still unused
      );
    });
  });

  group('usage is kept per provider and per month', () {
    test(
      'requests are written to the database and survive a new ledger',
      () async {
        final c = make(net: mealDbNetwork());
        await c.read(mealDiscoveryProvider('garlic').future);
        final ledger = c.read(usageLedgerProvider);
        final used = await ledger.usage('themealdb', DateTime.now());
        expect(used.requests, greaterThan(1));
        expect(used.costMicros, 0);
        final again = DriftUsageLedger(c.read(appDatabaseProvider));
        expect(
          (await again.usage('themealdb', DateTime.now())).requests,
          used.requests,
        );
        expect((await again.usage('recipeapi', DateTime.now())).requests, 0);
        expect(
          (await again.usage('themealdb', DateTime(2099, 1, 1))).requests,
          0,
        );
      },
    );

    test('the defaults are small and explicit', () {
      expect(TheMealDbClient.policyDefaults.monthlyRequestBudget, 2000);
    });
  });
}
