/// Where a recipe shown for a meal came from, in the order they are tried.
enum RecipeSource {
  /// Moon Cycle's own bundled library (the 112 reviewed recipes).
  internal,

  /// An approved external recipe provider (none is configured yet).
  externalApi,

  /// Generated for this user by the recipe-generation fallback.
  aiGenerated,
}

/// What may legally be done with a recipe, carried with it so no screen has to
/// guess. Internal recipes are Moon Cycle's own; external and generated ones
/// carry whatever their provider's terms allow.
final class RecipeRights {
  const RecipeRights({
    required this.license,
    this.attribution,
    this.sourceUrl,
    this.mayDisplayFull = true,
    this.mayStore = true,
    this.requiresLinkBack = false,
    this.mayPublish = false,
  });

  /// Moon Cycle's reviewed recipes: displayed in full, stored offline, and
  /// eligible to be shared.
  static const moonCycle = RecipeRights(
    license: 'moon-cycle',
    mayPublish: true,
  );

  /// Generated recipes belong to the user who made them; publishing needs
  /// editorial approval (Stage 5), never automatic.
  static const generated = RecipeRights(license: 'generated-for-user');

  /// A short id for the licence or terms (`moon-cycle`, a provider's name).
  final String license;

  /// Text that must be shown with the recipe, if the terms require it.
  final String? attribution;
  final String? sourceUrl;

  /// Whether the full ingredients and method may be shown (some providers
  /// allow only a summary and a link).
  final bool mayDisplayFull;

  /// Whether the recipe may be saved on the phone or the server.
  final bool mayStore;
  final bool requiresLinkBack;

  /// Whether it may enter the shared Moon Cycle library. Only ever true for
  /// recipes Moon Cycle owns; anything else needs an explicit editorial step.
  final bool mayPublish;
}
