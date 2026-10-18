import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/local_date.dart';
import '../../../core/time/today.dart';
import '../data/diary_repository.dart';
import '../domain/diary_entry.dart';

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
