import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether onboarding has been completed.
///
/// Milestone 4 stub: kept in memory and `true` by default, so development
/// builds open on the tabs. Milestone 7 replaces it with the stored value.
class OnboardingStatus extends Notifier<bool> {
  @override
  bool build() => true;

  void complete() => state = true;
}

final onboardingCompletedProvider = NotifierProvider<OnboardingStatus, bool>(
  OnboardingStatus.new,
);
