import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/preferences_repository.dart';
import '../domain/appearance.dart';
import '../domain/diet.dart';
import '../domain/food_avoidance.dart';
import '../domain/reminder_settings.dart';

final dietProvider = StreamProvider<Diet>(
  (ref) => ref.watch(preferencesRepositoryProvider).watchDiet(),
);

final avoidancesProvider = StreamProvider<List<FoodAvoidance>>(
  (ref) => ref.watch(preferencesRepositoryProvider).watchAvoidances(),
);

final reminderSettingsProvider = StreamProvider<ReminderSettings>(
  (ref) => ref.watch(preferencesRepositoryProvider).watchReminders(),
);

/// The Appearance saved when the app started. Read from the database in
/// `main()` before the first frame, so the theme is right from the start (no
/// flash of the wrong one).
final initialAppearanceProvider = Provider<AppearanceMode>(
  (ref) => AppearanceMode.system,
);

/// The chosen Appearance. Changing it updates the app at once and saves it.
class AppearanceController extends Notifier<AppearanceMode> {
  @override
  AppearanceMode build() => ref.read(initialAppearanceProvider);

  Future<void> set(AppearanceMode mode) async {
    state = mode;
    await ref.read(preferencesRepositoryProvider).saveAppearance(mode);
  }
}

final appearanceProvider =
    NotifierProvider<AppearanceController, AppearanceMode>(
      AppearanceController.new,
    );
