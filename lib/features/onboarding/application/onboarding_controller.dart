import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/local_date.dart';
import '../../../core/time/today.dart';
import '../../preferences/domain/diet.dart';
import '../data/onboarding_repository.dart';
import '../domain/onboarding_answers.dart';

/// The onboarding answers while the user moves between steps. In memory
/// only: if the app is killed mid-way, onboarding starts again (plan §7.2).
class OnboardingController extends Notifier<OnboardingAnswers> {
  @override
  OnboardingAnswers build() => const OnboardingAnswers();

  void selectStart(LocalDate date) =>
      state = state.copyWith(lastPeriodStart: date, startIsEstimated: false);

  /// "I'm not sure": a week ago, marked as an estimate.
  void notSure() => state = state.copyWith(
    lastPeriodStart: ref.read(todayProvider).addDays(-7),
    startIsEstimated: true,
  );

  void setCycleLength(int days) => state = state.copyWith(cycleLength: days);
  void setPeriodLength(int days) => state = state.copyWith(periodLength: days);
  void setDiet(Diet diet) => state = state.copyWith(diet: diet);

  void toggleAllergen(String id) =>
      state = state.copyWith(allergenIds: _toggled(state.allergenIds, id));

  void toggleFood(String id) =>
      state = state.copyWith(foodIds: _toggled(state.foodIds, id));

  void addCustom(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty ||
        state.customAvoidances.any(
          (l) => l.toLowerCase() == trimmed.toLowerCase(),
        )) {
      return;
    }
    state = state.copyWith(
      customAvoidances: [...state.customAvoidances, trimmed],
    );
  }

  void removeCustom(String label) => state = state.copyWith(
    customAvoidances: [
      for (final l in state.customAvoidances)
        if (l != label) l,
    ],
  );

  /// "Skip for now": no diet or avoidances.
  void clearPreferences() => state = state.copyWith(
    diet: Diet.omnivore,
    allergenIds: const {},
    foodIds: const {},
    customAvoidances: const [],
  );

  /// Saves everything (after step 4).
  Future<void> save() => ref.read(onboardingRepositoryProvider).save(state);

  static Set<String> _toggled(Set<String> set, String id) =>
      set.contains(id) ? ({...set}..remove(id)) : {...set, id};
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingAnswers>(
      OnboardingController.new,
    );
