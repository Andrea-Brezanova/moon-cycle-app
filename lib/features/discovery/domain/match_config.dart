/// Every number the recipe matcher uses, in one place so it can be read,
/// tested and changed on purpose. Nothing in the matcher is hard-coded.
final class MatchConfig {
  const MatchConfig({
    this.proteinWeight = 3,
    this.baseWeight = 3,
    this.plantWeight = 2,
    this.goodPartialMinCoverage = 0.6,
    this.partialMinMatched = 2,
    this.partialNeedsProteinOrBase = true,
    this.phaseBonus = 8,
    this.completeMinSteps = 3,
    this.qualityBonus = 4,
    this.extraFoodPenalty = 0.5,
    this.maxSuggestions = 5,
  });

  /// How much each selected food counts towards coverage, by role.
  final double proteinWeight;
  final double baseWeight;
  final double plantWeight;

  /// A recipe that does not use every selected food is a *good partial* match
  /// only if it covers at least this share of the weighted selection…
  final double goodPartialMinCoverage;

  /// …and uses at least this many of the selected foods…
  final int partialMinMatched;

  /// …and (when true) includes the protein or the base, so a recipe sharing
  /// only a garnish is never offered.
  final bool partialNeedsProteinOrBase;

  /// Added to the score of a recipe written for the phase being viewed. It
  /// only orders results; it never decides whether a recipe matches.
  final double phaseBonus;

  /// A recipe with fewer steps than this has an incomplete method and gets no
  /// [qualityBonus].
  final int completeMinSteps;
  final double qualityBonus;

  /// Subtracted per recipe food the user did not choose, so of two complete
  /// matches the simpler one ranks first. Supporting ingredients are allowed;
  /// this only breaks ties.
  final double extraFoodPenalty;

  /// How many partial suggestions are offered.
  final int maxSuggestions;

  static const defaults = MatchConfig();
}
