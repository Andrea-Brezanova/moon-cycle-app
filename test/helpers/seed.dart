import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/features/cycle/data/cycle_repository.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_profile.dart';
import 'package:moon_cycle/features/onboarding/data/app_state_repository.dart';

/// Stores a cycle (as onboarding would) before the app is pumped. Runs with
/// real async, because widget tests run in fake time.
Future<void> seedCycle(
  WidgetTester tester,
  AppDatabase db, {
  required LocalDate start,
  int cycleLength = 28,
  int periodLength = 5,
  Future<void> Function()? more,
}) => tester.runAsync(() async {
  final cycles = CycleRepository(db);
  await cycles.saveProfile(
    CycleProfile(
      typicalCycleLength: cycleLength,
      typicalPeriodLength: periodLength,
    ),
  );
  await cycles.logPeriod(start);
  await AppStateRepository(db).markOnboardingComplete();
  await more?.call();
});

/// The design's sample: day 7 of 28 on Saturday 4 October 2025.
final sampleStart = LocalDate(2025, 9, 28);
