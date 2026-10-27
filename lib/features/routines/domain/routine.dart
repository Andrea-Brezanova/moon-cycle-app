/// One step of a routine: a saved link by id, or the user's own text.
final class RoutineStep {
  const RoutineStep({
    required this.id,
    required this.position,
    this.linkId,
    this.text,
  });

  final String id;
  final int position;

  /// The saved link this step points at (never a copy), or null.
  final String? linkId;

  /// The user's own words, or null for a link step.
  final String? text;
}

/// A reusable ordered sequence of steps the user made in My Routines.
final class Routine {
  const Routine({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.steps = const [],
  });

  final String id;
  final String title;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RoutineStep> steps;
}
