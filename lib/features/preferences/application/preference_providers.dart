import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/preferences_repository.dart';
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
