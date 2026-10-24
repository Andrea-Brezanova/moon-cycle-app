import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../content/application/content_providers.dart';
import '../../cycle/application/viewing_phase.dart' show actualPhaseProvider;
import '../data/personal_recipe_repository.dart';
import '../domain/generation_result.dart';
import '../domain/manual_recipe.dart';
import '../domain/personal_recipe.dart';

/// Saves and edits recipes the user typed. They are stored privately on the
/// phone under the local owner, never sent anywhere and never suggested to
/// anyone.
class ManualRecipeService {
  ManualRecipeService(this._ref);

  final Ref _ref;

  static const _uuid = Uuid();

  /// Saves a new recipe and returns it.
  Future<PersonalRecipe> create(ManualRecipeInput input) {
    final id = '$personalRecipePrefix${_uuid.v4()}';
    final recipe = buildManualRecipe(
      id: id,
      input: input,
      phase: _ref.read(actualPhaseProvider),
      foods: _ref.read(catalogueProvider).foods,
    );
    return _ref
        .read(personalRecipeRepositoryProvider)
        .save(
          PersonalRecipe(
            recipe: recipe,
            ownerId: localRecipeOwnerId,
            idempotencyKey: _uuid.v4(),
            fingerprint: '',
            provenance: const Provenance(
              origin: GenerationOrigin.manual,
              provider: 'user',
              model: 'manual',
            ),
            createdAt: DateTime.now(),
          ),
        );
  }

  /// Replaces what [existing] says with [input].
  Future<void> update(PersonalRecipe existing, ManualRecipeInput input) {
    final recipe = buildManualRecipe(
      id: existing.id,
      input: input,
      phase: existing.recipe.phase,
      foods: _ref.read(catalogueProvider).foods,
    );
    return _ref
        .read(personalRecipeRepositoryProvider)
        .updateRecipe(existing.ownerId, existing.id, recipe);
  }
}

final manualRecipeServiceProvider = Provider<ManualRecipeService>(
  ManualRecipeService.new,
);
