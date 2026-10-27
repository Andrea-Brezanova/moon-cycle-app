import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One exercise in the workout being built. [libraryId] is set for an exercise
/// taken from the Exercises library, null for one the user typed.
final class DraftExercise {
  const DraftExercise({required this.key, required this.name, this.libraryId});

  /// Unique within the draft (the same exercise can appear twice).
  final int key;
  final String name;
  final String? libraryId;
}

/// The workout being built in Move › Build Your Workout: an ordered list of
/// exercises. Kept in memory only until it can be saved to My Workouts (the
/// storage for that is a pending, unapproved change; see the PR notes), and
/// dropped when the page is left.
final workoutDraftProvider =
    NotifierProvider.autoDispose<WorkoutDraft, List<DraftExercise>>(
      WorkoutDraft.new,
    );

class WorkoutDraft extends Notifier<List<DraftExercise>> {
  int _next = 0;

  @override
  List<DraftExercise> build() => const [];

  /// Adds an exercise you typed. Blank names are ignored.
  void addCustom(String name) {
    final n = name.trim();
    if (n.isEmpty) return;
    state = [...state, DraftExercise(key: _next++, name: n)];
  }

  /// Adds an exercise from the library (it can be added more than once).
  void addLibrary(String id, String name) => state = [
    ...state,
    DraftExercise(key: _next++, name: name, libraryId: id),
  ];

  void remove(int key) => state = [
    for (final e in state)
      if (e.key != key) e,
  ];

  /// Moves the exercise at [oldIndex] so it ends up at [newIndex] (the
  /// `ReorderableListView.onReorderItem` index, already adjusted for the
  /// removal).
  void move(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.length) return;
    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex.clamp(0, list.length), item);
    state = list;
  }

  void clear() => state = const [];
}
