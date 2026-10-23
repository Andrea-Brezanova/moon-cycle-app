import '../../../core/domain/local_date.dart';

/// What kind of movement. A fixed list plus "Other" (which may carry a name).
enum ActivityType {
  walk('Walk'),
  run('Run'),
  cycle('Cycle'),
  swim('Swim'),
  hike('Hike'),
  yoga('Yoga'),
  pilates('Pilates'),
  strength('Strength'),
  dance('Dance'),
  stretching('Stretching'),
  other('Other');

  const ActivityType(this.label);

  final String label;

  static ActivityType? fromKey(String key) {
    for (final t in values) {
      if (t.name == key) return t;
    }
    return null;
  }
}

/// How it felt, if the user wants to say. Not a target or a score.
enum ActivityIntensity {
  light('Light'),
  moderate('Moderate'),
  vigorous('Vigorous');

  const ActivityIntensity(this.label);

  final String label;

  static ActivityIntensity? fromKey(String? key) {
    for (final i in values) {
      if (i.name == key) return i;
    }
    return null;
  }
}

/// The longest duration accepted, in minutes (a full day).
const maxActivityMinutes = 1440;

/// A movement the user noted: what, when, and optionally for how long, how it
/// felt and a note. Private to this phone. Nothing is estimated or interpreted
/// (no calories, no targets, no hormonal claims).
final class DiaryActivity {
  const DiaryActivity({
    required this.id,
    required this.date,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.customName,
    this.minutes,
    this.intensity,
    this.note,
  });

  final String id;
  final LocalDate date;
  final ActivityType type;

  /// A name for [ActivityType.other].
  final String? customName;
  final int? minutes;
  final ActivityIntensity? intensity;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// "Walk", or the custom name for Other.
  String get heading {
    final n = customName?.trim();
    return type == ActivityType.other && n != null && n.isNotEmpty
        ? n
        : type.label;
  }

  /// "30 min · Moderate", or empty when neither was given.
  String get summary => [
    if (minutes != null) durationText(minutes!),
    if (intensity != null) intensity!.label,
  ].join(' · ');
}

/// "45 min", or "1 h 30 min" from 60 up.
String durationText(int minutes) {
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}

/// The minutes in [text], or null when it is empty or not a whole number from
/// 1 to [maxActivityMinutes].
int? parseMinutes(String text) {
  final n = int.tryParse(text.trim());
  return n == null || n < 1 || n > maxActivityMinutes ? null : n;
}
