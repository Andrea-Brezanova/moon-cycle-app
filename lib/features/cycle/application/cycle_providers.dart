import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/today.dart';
import '../data/cycle_repository.dart';
import '../domain/cycle_calculator.dart';
import '../domain/cycle_lengths.dart';
import '../domain/cycle_profile.dart';
import '../domain/cycle_state.dart';
import '../domain/period_log.dart';

final cycleProfileProvider = StreamProvider<CycleProfile?>(
  (ref) => ref.watch(cycleRepositoryProvider).watchProfile(),
);

/// Every logged period, newest first.
final periodLogsProvider = StreamProvider<List<PeriodLog>>(
  (ref) => ref.watch(cycleRepositoryProvider).watchPeriodLogs(),
);

/// Where the user is in their cycle today. `null` before onboarding has
/// saved a profile and a period. Updates when the data changes and at
/// midnight.
final cycleStateProvider = Provider<AsyncValue<CycleState?>>((ref) {
  final profile = ref.watch(cycleProfileProvider);
  final logs = ref.watch(periodLogsProvider);
  final today = ref.watch(todayProvider);
  if (profile case AsyncError(:final error, :final stackTrace)) {
    return AsyncError(error, stackTrace);
  }
  if (logs case AsyncError(:final error, :final stackTrace)) {
    return AsyncError(error, stackTrace);
  }
  final (p, l) = (profile.value, logs.value);
  if ((p == null && profile.isLoading) || (l == null && logs.isLoading)) {
    return const AsyncLoading();
  }
  if (p == null || l == null || l.isEmpty) return const AsyncData(null);
  // A start "in the future" can only come from the phone's clock moving
  // back; count it as today rather than failing.
  final start = l.first.start.isAfter(today) ? today : l.first.start;
  return AsyncData(
    calculateCycleState(
      lastPeriodStart: start,
      lengths: CycleLengths.fromProfile(p),
      today: today,
    ),
  );
});
