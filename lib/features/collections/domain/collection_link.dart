/// Which of My Collections' three categories a link belongs to.
enum LinkCategory {
  recipes('Recipes'),
  workouts('Workouts'),
  sounds('Sounds');

  const LinkCategory(this.label);

  final String label;

  static LinkCategory? fromKey(String key) {
    for (final c in values) {
      if (c.name == key) return c;
    }
    return null;
  }
}

/// Where a link points, worked out from its address only (nothing is fetched).
enum LinkPlatform {
  youtube('YouTube'),
  instagram('Instagram'),
  tiktok('TikTok'),
  pinterest('Pinterest'),
  website('Website');

  const LinkPlatform(this.label);

  final String label;

  static LinkPlatform fromKey(String key) {
    for (final p in values) {
      if (p.name == key) return p;
    }
    return website;
  }
}

/// The longest address kept.
const maxLinkLength = 2048;

/// A link the user saved: the address they gave, a title, an optional creator
/// and note, and the category. A recipe link is only a link: it is not a
/// recipe, has no ingredients and takes no part in any recipe search.
final class CollectionLink {
  const CollectionLink({
    required this.id,
    required this.category,
    required this.url,
    required this.title,
    required this.platform,
    required this.createdAt,
    required this.updatedAt,
    this.creator,
    this.note,
  });

  final String id;
  final LinkCategory category;
  final Uri url;
  final String title;
  final LinkPlatform platform;
  final String? creator;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// "YouTube", or the site's host for a website: shown under the title.
  String get source =>
      platform == LinkPlatform.website ? url.host : platform.label;
}

/// A link address the app accepts: `http` or `https` with a host, no
/// credentials, within [maxLinkLength]. A bare "example.com/x" gets `https://`.
/// Returns null when it can't be used safely (other schemes such as
/// `javascript:`, `file:` or `tel:`, no host, or user:password@).
Uri? parseLinkAddress(String input) {
  final text = input.trim();
  if (text.isEmpty || text.length > maxLinkLength) return null;
  if (RegExp(r'\s').hasMatch(text)) return null;
  final withScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(text)
      ? text
      : 'https://$text';
  final uri = Uri.tryParse(withScheme);
  if (uri == null) return null;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return null;
  if (!uri.hasAuthority || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
    return null;
  }
  // A host needs a dot (or be localhost-free): "https://x" is not a page.
  if (!uri.host.contains('.')) return null;
  return uri;
}

/// The platform for [url], from its host.
LinkPlatform platformOf(Uri url) {
  final host = url.host.toLowerCase();
  bool is_(String domain) => host == domain || host.endsWith('.$domain');
  if (is_('youtube.com') || is_('youtu.be')) return LinkPlatform.youtube;
  if (is_('instagram.com')) return LinkPlatform.instagram;
  if (is_('tiktok.com')) return LinkPlatform.tiktok;
  if (is_('pinterest.com') || is_('pin.it')) return LinkPlatform.pinterest;
  return LinkPlatform.website;
}
