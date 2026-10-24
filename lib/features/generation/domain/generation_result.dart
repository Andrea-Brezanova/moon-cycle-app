import 'generated_recipe.dart';

/// Where a recipe came from. A development mock is never presented as a live
/// generated result: the app labels it, and builds that cannot use the mock
/// never create one.
enum GenerationOrigin { devMock, cloud, manual }

/// Who made a recipe, kept with it for review and for cost accounting.
final class Provenance {
  const Provenance({
    required this.origin,
    required this.provider,
    required this.model,
    this.schemaVersion = generatedRecipeSchemaVersion,
    this.costMicros,
  });

  final GenerationOrigin origin;
  final String provider;
  final String model;
  final int schemaVersion;

  /// Cost of the call in millionths of a US dollar, when the provider reports
  /// it (null for the mock).
  final int? costMicros;

  Map<String, Object?> toJson() => {
    'origin': origin.name,
    'provider': provider,
    'model': model,
    'schema_version': schemaVersion,
    'cost_micros': costMicros,
  };

  factory Provenance.fromJson(Map<String, Object?> json) => Provenance(
    origin: GenerationOrigin.values.byName(json['origin']! as String),
    provider: json['provider']! as String,
    model: json['model']! as String,
    schemaVersion: json['schema_version']! as int,
    costMicros: json['cost_micros'] as int?,
  );
}

/// What a service returns: the untrusted recipe and who made it.
final class GenerationResult {
  const GenerationResult({
    required this.recipe,
    required this.provenance,
    this.remoteId,
  });

  final GeneratedRecipe recipe;
  final Provenance provenance;

  /// The server's id for the saved recipe (null for the local mock).
  final String? remoteId;
}
