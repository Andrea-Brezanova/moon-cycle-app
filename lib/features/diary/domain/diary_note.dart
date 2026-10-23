import '../../../core/domain/local_date.dart';

/// A free-writing diary note: what the user wrote, on a day, with an optional
/// title. Private: stored in the encrypted local database only, never analysed
/// or sent anywhere.
final class DiaryNote {
  const DiaryNote({
    required this.id,
    required this.date,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.title,
  });

  final String id;
  final LocalDate date;
  final String? title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The title, or the start of the writing when there is none (for lists).
  String get heading {
    final t = title?.trim();
    if (t != null && t.isNotEmpty) return t;
    return preview(40).isEmpty ? 'Untitled note' : preview(40);
  }

  /// The first [max] characters of the body on one line, with "…" if cut.
  String preview(int max) {
    final flat = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length <= max ? flat : '${flat.substring(0, max).trimRight()}…';
  }
}

/// What a note needs to be saved: any text counts, but a note with neither a
/// title nor a body is empty and isn't stored.
bool isBlankNote({String? title, required String body}) =>
    body.trim().isEmpty && (title ?? '').trim().isEmpty;
