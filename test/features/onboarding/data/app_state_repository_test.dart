import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/features/onboarding/data/app_state_repository.dart';

void main() {
  test(
    'onboarding: not complete until marked, and marking twice is fine',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = AppStateRepository(db);
      expect(await repo.isOnboardingComplete(), isFalse);
      await repo.markOnboardingComplete();
      await repo.markOnboardingComplete();
      expect(await repo.isOnboardingComplete(), isTrue);
      expect(await db.select(db.appStates).get(), hasLength(1));
    },
  );
}
