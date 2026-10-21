/// The structured input of recipe generation: one protein, one base and 2–3
/// plants. Build a Meal no longer requires it (any foods can be chosen); it is
/// only what the generator is asked to cook, if generation is ever offered
/// again as its own feature.
final class BalancedSelection {
  const BalancedSelection({
    this.proteinId,
    this.baseId,
    this.plantIds = const [],
  });

  static const maxPlants = 3;
  static const minPlants = 2;

  final String? proteinId;
  final String? baseId;
  final List<String> plantIds;

  bool get isComplete =>
      proteinId != null &&
      baseId != null &&
      plantIds.length >= minPlants &&
      plantIds.length <= maxPlants;

  List<String> get ids => [?proteinId, ?baseId, ...plantIds];
}
