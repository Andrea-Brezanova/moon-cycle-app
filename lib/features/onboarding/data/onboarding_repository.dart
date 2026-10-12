import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../cycle/data/cycle_repository.dart';
import '../../cycle/domain/cycle_profile.dart';
import '../../cycle/domain/period_log.dart';
import '../../preferences/data/preferences_repository.dart';
import '../domain/onboarding_answers.dart';
import 'app_state_repository.dart';

/// Saves onboarding in one transaction: the period, the profile, diet and
/// avoidances, and "onboarding complete". Either all of it is saved or
/// none, so a killed app never resumes half-onboarded.
class OnboardingRepository {
  OnboardingRepository(
    this._db, {
    required this.cycles,
    required this.preferences,
    required this.appState,
  });

  final AppDatabase _db;
  final CycleRepository cycles;
  final PreferencesRepository preferences;
  final AppStateRepository appState;

  Future<void> save(OnboardingAnswers answers) => _db.transaction(() async {
    await cycles.saveProfile(
      CycleProfile(
        typicalCycleLength: answers.cycleLength,
        typicalPeriodLength: answers.periodLength,
      ),
    );
    await cycles.logPeriod(
      answers.lastPeriodStart!,
      source: PeriodLogSource.onboarding,
      isEstimated: answers.startIsEstimated,
    );
    await preferences.saveDiet(answers.diet);
    for (final id in answers.allergenIds) {
      await preferences.avoidAllergen(id);
    }
    for (final id in answers.foodIds) {
      await preferences.avoidFood(id);
    }
    for (final label in answers.customAvoidances) {
      await preferences.avoidCustom(label);
    }
    await appState.markOnboardingComplete();
  });
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(
    ref.watch(appDatabaseProvider),
    cycles: ref.watch(cycleRepositoryProvider),
    preferences: ref.watch(preferencesRepositoryProvider),
    appState: AppStateRepository(ref.watch(appDatabaseProvider)),
  ),
);
