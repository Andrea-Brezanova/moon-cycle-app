/// A recipe saved to My recipes by reference. For a Moon Cycle recipe that is
/// its id; for an external recipe only its provider id, title and source link,
/// because the provider's terms do not let us keep its ingredients or method.
final class SavedRecipeRef {
  const SavedRecipeRef({
    required this.id,
    required this.providerId,
    required this.refId,
    required this.title,
    required this.savedAt,
    this.externalId,
    this.sourceUrl,
  });

  final String id;
  final String providerId;

  /// The id the app opens (`x-themealdb-52772`, or a library recipe id).
  final String refId;
  final String? externalId;
  final String title;
  final String? sourceUrl;
  final DateTime savedAt;

  bool get isExternal => externalId != null;
}
