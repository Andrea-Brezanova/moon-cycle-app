import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../content/application/content_providers.dart';
import '../../content/domain/recipe.dart';
import '../../cycle/application/viewing_phase.dart';
import '../../discovery/domain/recipe_source.dart';
import '../../discovery/domain/try_new_search.dart';
import '../../entitlements/application/entitlement_providers.dart';
import '../../entitlements/domain/entitlements.dart';
import '../../generation/application/generation_providers.dart';
import '../../generation/application/recipe_creator.dart';
import '../../generation/domain/generation_failure.dart';
import '../../generation/domain/generation_request.dart';
import '../../generation/domain/personal_recipe.dart';

/// One recipe in the Try Something New results.
final class TrioItem {
  const TrioItem({
    required this.recipe,
    required this.source,
    this.isDevSample = false,
  });

  final Recipe recipe;
  final RecipeSource source;

  /// Made by the development mock: labelled, never shown as live.
  final bool isDevSample;
}

sealed class TrioState {
  const TrioState();
}

final class TrioIdle extends TrioState {
  const TrioIdle();
}

final class TrioWorking extends TrioState {
  const TrioWorking({required this.done, required this.of});
  final int done;
  final int of;
}

/// [items] are what was found or made (up to three). [failure] is why the rest
/// is missing, if it is: [canRetry] says whether trying again can help, and
/// [generationOffered] whether making new recipes was possible at all.
final class TrioReady extends TrioState {
  const TrioReady({
    required this.items,
    this.failure,
    this.generationOffered = false,
    this.premiumNeeded = false,
  });

  final List<TrioItem> items;
  final GenerationFailure? failure;
  final bool generationOffered;
  final bool premiumNeeded;

  bool get complete => items.length >= 3;
  bool get canRetry => failure?.retryable ?? false;
}

final tryNewTrioProvider = NotifierProvider<TryNewTrioController, TrioState>(
  TryNewTrioController.new,
);

/// Three foods → up to three distinct recipes that each use all three.
///
/// Existing recipes come first. Only if fewer than three exist, and a
/// generation service is available and the user is entitled, new ones are made
/// (variants 0, 1, 2 give different dishes) and saved privately. Where
/// generation is unavailable the user simply sees the recipes that exist.
class TryNewTrioController extends Notifier<TrioState> {
  var _busy = false;
  List<String> _foodIds = const [];
  final _keys = <int, String>{};

  @override
  TrioState build() => const TrioIdle();

  Future<void> start(List<String> foodIds) async {
    if (_busy) return;
    _foodIds = foodIds;
    _keys.clear();
    await _run();
  }

  /// Tries again with the same idempotency keys, so nothing is made twice.
  Future<void> retry() => _run();

  Future<void> _run() async {
    if (_busy || _foodIds.length != 3) return;
    _busy = true;
    try {
      final catalogue = ref.read(catalogueProvider);
      final filter = ref.read(foodFilterProvider);
      final phase = ref.read(viewingPhaseProvider);
      state = const TrioWorking(done: 0, of: 3);

      final items = <TrioItem>[
        for (final r in recipesUsingAll(
          catalogue,
          filter,
          _foodIds,
          phase: phase,
        ))
          TrioItem(recipe: r, source: RecipeSource.internal),
      ];
      final need = 3 - items.length;
      final entitled = ref.read(featureGateProvider).canUse(Feature.buildMeal);
      final available = ref.read(generationAvailableProvider);
      if (need <= 0 || !available) {
        state = TrioReady(items: items);
        return;
      }
      if (!entitled) {
        state = TrioReady(items: items, premiumNeeded: true);
        return;
      }

      final creator = ref.read(recipeCreatorProvider);
      GenerationFailure? failure;
      for (var variant = 0; variant < need; variant++) {
        state = TrioWorking(done: items.length, of: 3);
        final request = GenerationRequest.tryNew(
          idempotencyKey: _keys.putIfAbsent(variant, const Uuid().v4),
          phase: phase,
          foodIds: _foodIds,
          variant: variant,
        );
        final outcome = await creator.create(request);
        switch (outcome) {
          case Created(:final recipe):
            items.add(_item(recipe));
            unawaited(creator.makeImage(recipe));
          case Existing(:final recipe):
            items.add(_item(recipe));
          case CreationFailed(failure: final f):
            failure = f;
        }
        if (failure != null) break;
      }
      state = TrioReady(
        items: items,
        failure: failure,
        generationOffered: true,
      );
    } finally {
      _busy = false;
    }
  }

  TrioItem _item(PersonalRecipe p) => TrioItem(
    recipe: p.recipe,
    source: RecipeSource.aiGenerated,
    isDevSample: p.isDevSample,
  );
}
