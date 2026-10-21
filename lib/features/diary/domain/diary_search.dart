import '../../content/domain/text_match.dart';
import 'diary_entry.dart';

/// Something the Log a meal form can add: a catalogue food, a recipe, or a
/// meal the user typed before.
final class DiaryChoice {
  const DiaryChoice(this.kind, this.itemId, this.title);

  final DiaryItemKind kind;

  /// The canonical food id or recipe id. Empty for a custom meal (it has none).
  final String itemId;
  final String title;

  /// The identity used to tell recent items apart: a catalogue id for foods and
  /// recipes, the normalised title for typed meals (each has its own row id).
  String get key => kind == DiaryItemKind.custom
      ? 'custom|${normaliseName(title)}'
      : '${kind.name}|$itemId';
}

/// The most recently logged distinct items, newest first. [newestFirst] is the
/// diary, newest entry first; an item logged many times appears once, at its
/// latest use. Nothing is stored: this is a view of the history.
List<DiaryChoice> recentDistinct(
  Iterable<DiaryEntry> newestFirst, {
  int limit = 12,
}) {
  final seen = <String>{};
  final out = <DiaryChoice>[];
  for (final e in newestFirst) {
    final c = DiaryChoice(
      e.kind,
      e.kind == DiaryItemKind.custom ? '' : e.itemId,
      e.title,
    );
    if (c.title.trim().isEmpty || !seen.add(c.key)) continue;
    out.add(c);
    if (out.length == limit) break;
  }
  return out;
}

/// How well [title] answers [query]; lower is better, null is no match.
/// 0 exact, 1 starts with, 2 a word starts with it or contains it, 3 within one
/// typo of a word (queries of 4+ letters). Case, accents' punctuation and
/// spacing are ignored ([normaliseName]).
int? searchScore(String query, String title) {
  final q = normaliseName(query);
  final t = normaliseName(title);
  if (q.isEmpty || t.isEmpty) return null;
  if (t == q) return 0;
  if (t.startsWith(q)) return 1;
  final words = t.split(' ');
  if (words.any((w) => w.startsWith(q)) || t.contains(q)) return 2;
  if (q.length >= 4) {
    final qWords = q.split(' ');
    bool near(String qw) =>
        qw.length >= 4 && words.any((w) => _withinOne(qw, w));
    if (qWords.every(near)) return 3;
  }
  return null;
}

/// Matches of [query] among [pool], best first: an exact match, then items the
/// user has logged before, then the rest by closeness and name.
List<DiaryChoice> rankChoices(
  String query,
  Iterable<DiaryChoice> pool, {
  required Set<String> recentKeys,
  int limit = 8,
}) {
  final scored = <(DiaryChoice, int)>[
    for (final c in pool)
      if (searchScore(query, c.title) case final s?) (c, s),
  ];
  scored.sort((a, b) {
    int tier((DiaryChoice, int) x) => x.$2 == 0
        ? 0
        : recentKeys.contains(x.$1.key)
        ? 1
        : 2;
    final t = tier(a).compareTo(tier(b));
    if (t != 0) return t;
    final s = a.$2.compareTo(b.$2);
    if (s != 0) return s;
    return a.$1.title.toLowerCase().compareTo(b.$1.title.toLowerCase());
  });
  return [for (final (c, _) in scored.take(limit)) c];
}

/// Whether [a] and [b] differ by at most one inserted, deleted or changed
/// letter.
bool _withinOne(String a, String b) {
  if ((a.length - b.length).abs() > 1) return false;
  if (a == b) return true;
  var i = 0;
  while (i < a.length && i < b.length && a[i] == b[i]) {
    i++;
  }
  if (a.length == b.length) return a.substring(i + 1) == b.substring(i + 1);
  if (a.length > b.length) return a.substring(i + 1) == b.substring(i);
  return b.substring(i + 1) == a.substring(i);
}
