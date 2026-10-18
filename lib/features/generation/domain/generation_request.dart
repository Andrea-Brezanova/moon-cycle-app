import '../../../core/domain/phase.dart';

/// What the user asks to be generated: a protein, a base and 2–3 plants, by
/// food id, for a phase. Nothing else leaves the device: no free text and no
/// cycle dates.
final class GenerationRequest {
  GenerationRequest({
    required this.idempotencyKey,
    required this.phase,
    required this.proteinId,
    required this.baseId,
    required List<String> plantIds,
    this.category,
  }) : plantIds = List.unmodifiable(plantIds);

  /// Created once per tap of "Create" and reused by every retry of it, so a
  /// repeated request is the same job, never a second recipe.
  final String idempotencyKey;
  final Phase phase;
  final String proteinId;
  final String baseId;
  final List<String> plantIds;

  /// The meal the recipe is for (`breakfast`, `lunch`, `dinner`, `snack`), if
  /// the user chose one; otherwise the generator decides.
  final String? category;

  /// Every selected food id, in meal order.
  List<String> get foodIds => [proteinId, baseId, ...plantIds];

  /// Identifies the *selection*: the same phase, protein, base and plants give
  /// the same fingerprint however the plants were ordered. Used to offer "open
  /// your saved version" instead of making a near-copy. The same canonical
  /// string is computed by the backend.
  String get fingerprint {
    final plants = [...plantIds]..sort();
    return '${phase.name}|$proteinId|$baseId|${plants.join(',')}';
  }

  Map<String, Object?> toJson() => {
    'idempotency_key': idempotencyKey,
    'phase': phase.name,
    'protein_id': proteinId,
    'base_id': baseId,
    'plant_ids': plantIds,
    'category': ?category,
  };
}
