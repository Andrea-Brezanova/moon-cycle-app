import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/local_date.dart';
import '../../../core/time/today.dart';
import '../data/diary_activity_repository.dart';
import '../data/diary_note_repository.dart';
import '../data/diary_repository.dart';
import '../data/symptom_repository.dart';
import '../domain/diary_entry.dart';
import '../domain/diary_search.dart';
import '../domain/symptoms.dart';

/// One day's entries.
final diaryDayProvider = StreamProvider.autoDispose
    .family<List<DiaryEntry>, LocalDate>(
      (ref, date) => ref.watch(diaryRepositoryProvider).watchDay(date),
    );

/// Every day that has entries, newest first.
final diaryHistoryProvider = StreamProvider.autoDispose<List<DiaryDay>>(
  (ref) => ref.watch(diaryRepositoryProvider).watchHistory(),
);

/// The day the diary is showing. Starts on today; never in the future.
final diaryDateProvider = NotifierProvider.autoDispose<DiaryDate, LocalDate>(
  DiaryDate.new,
);

class DiaryDate extends Notifier<LocalDate> {
  @override
  LocalDate build() => ref.read(todayProvider);

  void show(LocalDate date) {
    final today = ref.read(todayProvider);
    state = date.isAfter(today) ? today : date;
  }

  void previous() => state = state.addDays(-1);

  void next() => show(state.addDays(1));

  void today() => state = ref.read(todayProvider);
}

/// One day's symptom check-in, or null.
final symptomDayProvider = StreamProvider.autoDispose
    .family<SymptomDay?, LocalDate>(
      (ref, date) => ref.watch(symptomRepositoryProvider).watchDay(date),
    );

/// Every day with a check-in, newest first.
final symptomHistoryProvider = StreamProvider.autoDispose<List<SymptomDay>>(
  (ref) => ref.watch(symptomRepositoryProvider).watchHistory(),
);

/// Foods, recipes and typed meals logged before, newest first and without
/// repeats: the "Recently logged" source and a ranking boost for search.
final recentChoicesProvider = StreamProvider.autoDispose<List<DiaryChoice>>(
  (ref) => ref
      .watch(diaryRepositoryProvider)
      .watchNewest()
      .map((entries) => recentDistinct(entries, limit: 60)),
);

/// How many diary entries are recorded for today's date (the local calendar
/// day), for Home's My Diary card: each meal entry, the day's symptom check-in
/// (one, however many answers it has), each activity and each note. Deleted
/// entries and unsaved drafts aren't there to be counted. It follows the
/// diary's own streams, so it changes when something is saved, deleted or moved
/// to another date, and when the day rolls over.
final todayDiaryEntryCountProvider = Provider.autoDispose<int>((ref) {
  final today = ref.watch(todayProvider);
  final meals = ref.watch(diaryDayProvider(today)).value?.length ?? 0;
  final symptoms = ref.watch(symptomDayProvider(today)).value == null ? 0 : 1;
  final activities =
      ref.watch(diaryActivitiesOnProvider(today)).value?.length ?? 0;
  final notes = ref.watch(diaryNotesOnProvider(today)).value?.length ?? 0;
  return meals + symptoms + activities + notes;
});
