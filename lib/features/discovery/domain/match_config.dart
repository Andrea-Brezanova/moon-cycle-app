/// Every number the recipe matcher and the results list use, in one place so
/// it can be read, tested and changed on purpose.
final class MatchConfig {
  const MatchConfig({
    this.goodMinCoverage = 0.6,
    this.phaseBonus = 8,
    this.completeMinSteps = 3,
    this.qualityBonus = 4,
    this.extraFoodPenalty = 0.5,
    this.initialResults = 8,
    this.moreResults = 8,
  });

  /// A recipe that uses at least this share of the chosen foods (but not all of
  /// them) is a *good* match: two of three, three of four. Below it, one of
  /// three, one of two, two of four, it is a *partial* match. Using every
  /// chosen food is always a *complete* match.
  final double goodMinCoverage;

  /// Added to a recipe written for the user's current phase. It only orders
  /// results; it never decides whether a recipe matches.
  final double phaseBonus;

  /// A recipe with fewer steps than this has an incomplete method and gets no
  /// [qualityBonus].
  final int completeMinSteps;
  final double qualityBonus;

  /// Subtracted per recipe food the user did not choose, so of two equally
  /// relevant recipes the simpler one ranks first. Recipes may contain other
  /// ingredients; this only breaks ties.
  final double extraFoodPenalty;

  /// How many results the page shows first, and how many each "See more" adds.
  final int initialResults;
  final int moreResults;

  static const defaults = MatchConfig();
}
