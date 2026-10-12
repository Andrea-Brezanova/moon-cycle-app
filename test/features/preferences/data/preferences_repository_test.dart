import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/features/preferences/data/preferences_repository.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';
import 'package:moon_cycle/features/preferences/domain/reminder_settings.dart';

import '../../../helpers/fake_stamp.dart';

void main() {
  late AppDatabase db;
  late PreferencesRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = PreferencesRepository(db, fakeStamp());
  });
  tearDown(() => db.close());

  test('diet: omnivore until chosen, then saved', () async {
    expect(await repo.watchDiet().first, Diet.omnivore);
    await repo.saveDiet(Diet.vegan);
    expect(await repo.watchDiet().first, Diet.vegan);
    await repo.saveDiet(Diet.pescatarian);
    expect(await repo.watchDiet().first, Diet.pescatarian);
    expect(await db.select(db.userPreferences).get(), hasLength(1));
  });

  test('reminders: off by default; saving keeps the diet', () async {
    expect(await repo.watchReminders().first, const ReminderSettings());
    await repo.saveDiet(Diet.vegetarian);
    const on = ReminderSettings(enabled: true, beforePeriod: false);
    await repo.saveReminders(on);
    expect(await repo.watchReminders().first, on);
    expect(await repo.watchDiet().first, Diet.vegetarian);
  });

  group('avoidances', () {
    test('each kind round-trips, oldest first', () async {
      await repo.avoidAllergen('peanut');
      await repo.avoidFood('cilantro');
      await repo.avoidCustom('  Coriander seeds ');
      expect(await repo.avoidances(), [
        const AllergenAvoidance(id: 'id-1', allergenId: 'peanut'),
        const FoodItemAvoidance(id: 'id-2', foodId: 'cilantro'),
        const CustomAvoidance(id: 'id-3', label: 'Coriander seeds'),
      ]);
    });

    test('adding the same thing twice keeps one', () async {
      await repo.avoidAllergen('peanut');
      await repo.avoidAllergen('peanut');
      await repo.avoidCustom('Okra');
      await repo.avoidCustom('okra');
      expect(await repo.avoidances(), hasLength(2));
    });

    test('blank custom labels are ignored', () async {
      await repo.avoidCustom('   ');
      expect(await repo.avoidances(), isEmpty);
    });

    test('remove leaves a tombstone; it can be added again', () async {
      await repo.avoidAllergen('sesame');
      final id = (await repo.avoidances()).single.id;
      await repo.removeAvoidance(id);
      expect(await repo.avoidances(), isEmpty);
      await repo.avoidAllergen('sesame');
      expect(await repo.avoidances(), hasLength(1));
      expect(await db.select(db.foodAvoidances).get(), hasLength(2));
    });
  });
}
