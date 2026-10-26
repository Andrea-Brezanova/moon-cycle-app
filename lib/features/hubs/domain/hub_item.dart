import 'dart:convert';

/// What a Move or Relax library holds.
enum HubKind {
  exercise('exercise', 'Exercises'),
  workout('workout', 'Workouts'),
  meditation('meditation', 'Meditations'),
  sound('sound', 'Sounds'),
  ritual('ritual', 'Spa');

  const HubKind(this.json, this.label);

  final String json;
  final String label;

  static HubKind? fromJson(Object? v) {
    for (final k in values) {
      if (k.json == v) return k;
    }
    return null;
  }

  /// Movement items need a safety note; the rest are relaxation content.
  bool get isMovement => this == exercise || this == workout;
}

/// One reviewed library entry: written by Moon Cycle (steps) or a verified
/// external link (sourceUrl). Only items an editor has approved are ever
/// shown; the parser drops the rest.
final class HubItem {
  const HubItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.summary,
    required this.reviewedBy,
    required this.reviewedOn,
    this.category,
    this.durationMinutes,
    this.intensity,
    this.equipment = const [],
    this.steps = const [],
    this.safetyNote,
    this.sourceName,
    this.sourceUrl,
    this.creator,
    this.rights,
  });

  final String id;
  final HubKind kind;
  final String title;
  final String summary;

  /// A practical grouping ("Walking", "Breathing"); never a cycle phase.
  final String? category;
  final int? durationMinutes;

  /// "gentle", "easy" or "moderate": general effort, not a prescription.
  final String? intensity;
  final List<String> equipment;
  final List<String> steps;
  final String? safetyNote;
  final String? sourceName;
  final Uri? sourceUrl;
  final String? creator;

  /// For audio: who owns it and under what licence. Required for sounds.
  final String? rights;
  final String reviewedBy;
  final String reviewedOn;
}

/// Reads the content file and returns only the approved items. An approved
/// item missing what the review requires is a build error, not something to
/// show quietly: a reviewer, a date, and for movement a safety note; for a
/// sound, its rights; for a link, an http(s) address.
List<HubItem> parseHubItems(String source) {
  final root = jsonDecode(source) as Map<String, dynamic>;
  final out = <HubItem>[];
  final ids = <String>{};
  for (final raw in (root['items'] as List? ?? const [])) {
    final m = raw as Map<String, dynamic>;
    if (m['reviewStatus'] != 'approved') continue;
    final id = m['id'] as String?;
    final kind = HubKind.fromJson(m['kind']);
    String need(String key) {
      final v = m[key];
      if (v is! String || v.trim().isEmpty) {
        throw FormatException('Approved item "$id" is missing "$key".');
      }
      return v;
    }

    if (id == null || kind == null) {
      throw FormatException('Approved item without a valid id and kind: $m');
    }
    if (!ids.add(id)) throw FormatException('Duplicate id "$id".');
    final url = m['sourceUrl'] as String?;
    Uri? uri;
    if (url != null) {
      uri = Uri.tryParse(url);
      if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http')) {
        throw FormatException('Item "$id" has a source that is not http(s).');
      }
    }
    final steps = [for (final s in (m['steps'] as List? ?? const [])) '$s'];
    if (steps.isEmpty && uri == null) {
      throw FormatException('Item "$id" has neither steps nor a source link.');
    }
    if (kind.isMovement) need('safetyNote');
    if (kind == HubKind.sound) need('rights');
    out.add(
      HubItem(
        id: id,
        kind: kind,
        title: need('title'),
        summary: need('summary'),
        reviewedBy: need('reviewedBy'),
        reviewedOn: need('reviewedOn'),
        category: m['category'] as String?,
        durationMinutes: m['durationMinutes'] as int?,
        intensity: m['intensity'] as String?,
        equipment: [
          for (final e in (m['equipment'] as List? ?? const [])) '$e',
        ],
        steps: steps,
        safetyNote: m['safetyNote'] as String?,
        sourceName: m['sourceName'] as String?,
        sourceUrl: uri,
        creator: m['creator'] as String?,
        rights: m['rights'] as String?,
      ),
    );
  }
  return out;
}
