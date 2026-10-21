import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/app_state_repository.dart';

/// Whether onboarding was complete when the app started. Read from the
/// database in `main()` before the first frame, so the router's first
/// redirect is already right.
final initialOnboardingCompletedProvider = Provider<bool>(
  (ref) => throw UnimplementedError('set in main()'),
);

final appStateRepositoryProvider = Provider<AppStateRepository>(
  (ref) => AppStateRepository(ref.watch(appDatabaseProvider)),
);

/// Whether onboarding has been completed. The router's gate listens to it.
class OnboardingStatus extends Notifier<bool> {
  @override
  bool build() => ref.read(initialOnboardingCompletedProvider);

  /// Records completion, then opens the gate.
  Future<void> complete() async {
    await ref.read(appStateRepositoryProvider).markOnboardingComplete();
    state = true;
  }
}

final onboardingCompletedProvider = NotifierProvider<OnboardingStatus, bool>(
  OnboardingStatus.new,
);
