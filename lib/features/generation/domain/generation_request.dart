import '../../../core/domain/phase.dart';

/// What is being made.
enum GenerationKind {
  /// Build a Meal: one protein, one base and 2–3 plants.
  meal,

  /// Try Something New: three foods, and a different dish for each variant.
  tryNew,
}

/// What the user asks to be generated, by food id, for a phase. Nothing else
/// leaves the device: no free text and no cycle dates.
final class GenerationRequest {
  GenerationRequest({
    required this.idempotencyKey,
    required this.phase,
    required String this.proteinId,
    required String this.baseId,
    required List<String> plantIds,
    this.category,
  }) : kind = GenerationKind.meal,
       variant = 0,
       plantIds = List.unmodifiable(plantIds),
       _tryNewFoodIds = const [];

  /// Three foods, one recipe that uses all of them. [variant] (0–2) asks for a
  /// different kind of dish, so three requests give three different recipes.
  GenerationRequest.tryNew({
    required this.idempotencyKey,
    required this.phase,
    required List<String> foodIds,
    required this.variant,
    this.category,
  }) : kind = GenerationKind.tryNew,
       proteinId = null,
       baseId = null,
       plantIds = const [],
       _tryNewFoodIds = List.unmodifiable(foodIds);

  /// Created once per tap of "Create" and reused by every retry of it, so a
  /// repeated request is the same job, never a second recipe.
  final String idempotencyKey;
  final Phase phase;
  final GenerationKind kind;

  // Build a Meal (null for Try Something New).
  final String? proteinId;
  final String? baseId;
  final List<String> plantIds;

  /// Try Something New: which dish (0–2).
  final int variant;
  final List<String> _tryNewFoodIds;

  /// The meal the recipe is for (`breakfast`, `lunch`, `dinner`, `snack`), if
  /// the user chose one; otherwise the generator decides.
  final String? category;

  /// Every selected food id, in order.
  List<String> get foodIds => kind == GenerationKind.tryNew
      ? _tryNewFoodIds
      : [proteinId!, baseId!, ...plantIds];

  /// Identifies the *selection*: the same foods give the same fingerprint
  /// however they were ordered. Used to offer "open your saved version" instead
  /// of making a near-copy. The backend computes the same text.
  String get fingerprint {
    if (kind == GenerationKind.tryNew) {
      final ids = [..._tryNewFoodIds]..sort();
      return 'try_new|${phase.name}|${ids.join(',')}|$variant';
    }
    final plants = [...plantIds]..sort();
    return '${phase.name}|$proteinId|$baseId|${plants.join(',')}';
  }

  /// The same request under a new idempotency key ("Make another version").
  GenerationRequest withKey(String key) => kind == GenerationKind.tryNew
      ? GenerationRequest.tryNew(
          idempotencyKey: key,
          phase: phase,
          foodIds: _tryNewFoodIds,
          variant: variant,
          category: category,
        )
      : GenerationRequest(
          idempotencyKey: key,
          phase: phase,
          proteinId: proteinId!,
          baseId: baseId!,
          plantIds: plantIds,
          category: category,
        );

  Map<String, Object?> toJson() => kind == GenerationKind.tryNew
      ? {
          'idempotency_key': idempotencyKey,
          'phase': phase.name,
          'kind': 'try_new',
          'food_ids': _tryNewFoodIds,
          'variant': variant,
          'category': ?category,
        }
      : {
          'idempotency_key': idempotencyKey,
          'phase': phase.name,
          'protein_id': proteinId,
          'base_id': baseId,
          'plant_ids': plantIds,
          'category': ?category,
        };
}
