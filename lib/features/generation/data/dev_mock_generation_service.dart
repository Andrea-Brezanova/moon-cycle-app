import '../../../core/domain/phase.dart';
import '../../content/domain/catalogue.dart';
import '../../content/domain/food.dart';
import '../../content/domain/recipe.dart';
import '../../foods/application/food_providers.dart'
    show ProteinFamily, proteinFamilyOf;
import '../domain/generated_recipe.dart';
import '../domain/generation_failure.dart';
import '../domain/generation_request.dart';
import '../domain/generation_result.dart';
import '../domain/recipe_generation_service.dart';
import '../domain/recipe_image_service.dart';
import '../domain/recipe_validator.dart';

/// **Development mock. Not an AI.** Builds a plain, deterministic recipe from
/// templates so the whole flow (progress, validation, saving, detail page) can
/// be built and tested without a provider, credentials or spend.
///
/// The app only ever creates this in a debug build of the dev flavour (see
/// `devGenerationAllowedProvider`), and everything it makes carries
/// `GenerationOrigin.devMock`, which the recipe page labels as a sample.
class DevMockGenerationService implements RecipeGenerationService {
  DevMockGenerationService({
    required this.catalogue,
    this.delay = const Duration(milliseconds: 700),
    List<GenerationFailure> failures = const [],
    this.invalidAttempts = 0,
  }) : _failures = [...failures];

  static const provider = 'dev-mock';
  static const model = 'template-v1';

  final Catalogue catalogue;
  final Duration delay;

  /// Thrown one per call, in order, before any result (for tests).
  final List<GenerationFailure> _failures;

  /// How many calls return a recipe that fails validation first (for tests of
  /// the repair retry).
  final int invalidAttempts;

  int calls = 0;

  @override
  Future<GenerationResult> generate(
    GenerationRequest request, {
    List<ValidationIssue> repair = const [],
  }) async {
    calls++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (_failures.isNotEmpty) throw _failures.removeAt(0);
    final broken = calls <= invalidAttempts;
    return GenerationResult(
      recipe: _build(request, broken: broken),
      provenance: const Provenance(
        origin: GenerationOrigin.devMock,
        provider: provider,
        model: model,
      ),
    );
  }

  GeneratedRecipe _build(GenerationRequest request, {required bool broken}) {
    final protein = catalogue.food(request.proteinId)!;
    final base = catalogue.food(request.baseId)!;
    final plants = [for (final id in request.plantIds) catalogue.food(id)!];
    String name(Food f) => f.displayName.toLowerCase();
    String title(Food f) {
      final n = f.displayName;
      return n[0].toUpperCase() + n.substring(1);
    }

    final plantNames = [for (final p in plants) name(p)];
    final plantList = plantNames.length < 2
        ? plantNames.join()
        : '${plantNames.sublist(0, plantNames.length - 1).join(', ')} and '
              '${plantNames.last}';
    final family = proteinFamilyOf(protein);

    final (proteinAmount, proteinUnit) = switch (family) {
      ProteinFamily.egg => (4.0, 'piece'),
      ProteinFamily.nuts => (40.0, 'g'),
      ProteinFamily.dairy => (100.0, 'g'),
      ProteinFamily.meat || ProteinFamily.seafood => (200.0, 'g'),
      _ => (150.0, 'g'),
    };

    final proteinStep = _proteinStep(protein, family);
    return GeneratedRecipe(
      title: '${title(protein)} & ${title(base)} Bowl',
      intro: broken
          ? 'A bowl that can balance your hormones and boost energy.'
          : 'A simple bowl of ${name(protein)} and ${name(base)} with '
                '$plantList.',
      category: RecipeCategory.values.byName(request.category ?? 'dinner'),
      minutes: 30,
      serves: 2,
      ingredients: [
        GeneratedIngredient(
          label: protein.displayName,
          foodId: protein.id,
          amount: proteinAmount,
          unit: proteinUnit,
        ),
        GeneratedIngredient(
          label: base.displayName,
          foodId: base.id,
          amount: 90,
          unit: 'g',
        ),
        for (final p in plants)
          GeneratedIngredient(
            label: p.displayName,
            foodId: p.id,
            amount: 100,
            unit: 'g',
          ),
        const GeneratedIngredient(
          label: 'Olive oil',
          foodId: 'olive-oil',
          amount: 1,
          unit: 'tbsp',
        ),
        const GeneratedIngredient(
          label: 'Salt and black pepper',
          amount: 1,
          unit: 'pinch',
        ),
      ],
      steps: [
        'Cook the ${name(base)} until tender, or warm it through if it is '
            'already cooked, then keep it warm.',
        proteinStep,
        'Chop the $plantList. Sauté any firm ones in the oil for 5 minutes '
            'until tender and add soft or leafy ones at the end.',
        'Serve the ${name(protein)} and vegetables over the ${name(base)}, '
            'seasoned with salt and pepper.',
      ],
    );
  }

  String _proteinStep(Food protein, ProteinFamily? family) {
    final n = protein.displayName.toLowerCase();
    if (protein.id == 'kidney-bean') {
      return 'Drain the soaked kidney beans, boil them hard for 10 minutes, '
          'then simmer until soft.';
    }
    return switch (family) {
      ProteinFamily.meat
          when const {
            'chicken',
            'turkey',
            'duck',
            'pork',
            'bacon',
          }.contains(protein.id) =>
        'Roast or pan-fry the $n for 20–25 minutes until cooked through with '
            'no pink inside, then slice.',
      ProteinFamily.meat =>
        'Pan-fry the $n for 8–10 minutes until browned and cooked through, '
            'then slice.',
      ProteinFamily.egg =>
        'Boil the eggs for 8 minutes until the yolks are firm, then peel and '
            'halve them.',
      ProteinFamily.seafood =>
        'Cook the $n in a hot pan for 3–4 minutes each side until it is '
            'opaque and flakes easily.',
      ProteinFamily.nuts =>
        'Toast the $n in a dry pan for 2 minutes until fragrant.',
      _ => 'Warm the $n through in a pan for 5 minutes.',
    };
  }
}

/// The image step for local development: no provider, no cost. Returns the
/// built-in placeholder so loading, storage reference and failure handling can
/// be exercised.
class PlaceholderRecipeImageService implements RecipeImageService {
  PlaceholderRecipeImageService({
    this.delay = const Duration(milliseconds: 400),
    this.failTimes = 0,
  });

  final Duration delay;

  /// The first [failTimes] calls fail (for tests of image recovery).
  int failTimes;

  @override
  Future<RecipeImageRef> generate({
    required String recipeId,
    required GeneratedRecipe recipe,
    required Phase phase,
  }) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (failTimes > 0) {
      failTimes--;
      throw const GenerationFailure(GenerationFailureKind.timeout, 'image');
    }
    return RecipeImageRef.placeholder;
  }
}

/// The services of a build that has no generator configured: production
/// today. Every call says so, honestly.
class UnavailableGenerationService implements RecipeGenerationService {
  const UnavailableGenerationService();

  @override
  Future<GenerationResult> generate(
    GenerationRequest request, {
    List<ValidationIssue> repair = const [],
  }) =>
      Future.error(const GenerationFailure(GenerationFailureKind.unavailable));
}

class UnavailableImageService implements RecipeImageService {
  const UnavailableImageService();

  @override
  Future<RecipeImageRef> generate({
    required String recipeId,
    required GeneratedRecipe recipe,
    required Phase phase,
  }) =>
      Future.error(const GenerationFailure(GenerationFailureKind.unavailable));
}
