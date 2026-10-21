import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/features/cycle/data/cycle_repository.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_profile.dart';
import 'package:moon_cycle/features/cycle/domain/period_log.dart';

import '../../../helpers/fake_stamp.dart';

void main() {
  late AppDatabase db;
  late CycleRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = CycleRepository(db, fakeStamp());
  });
  tearDown(() => db.close());

  group('profile', () {
    test('none until saved', () async {
      expect(await repo.profile(), isNull);
    });

    test('saved, then updated in place (one row)', () async {
      const first = CycleProfile(
        typicalCycleLength: 28,
        typicalPeriodLength: 5,
      );
      await repo.saveProfile(first);
      expect(await repo.profile(), first);

      final second = first.copyWith(typicalCycleLength: 31);
      await repo.saveProfile(second);
      expect(await repo.profile(), second);
      expect(await db.select(db.cycleProfiles).get(), hasLength(1));
    });

    test('watch emits changes', () async {
      final values = repo.watchProfile();
      final expectation = expectLater(
        values,
        emitsInOrder([
          isNull,
          const CycleProfile(typicalCycleLength: 30, typicalPeriodLength: 4),
        ]),
      );
      await Future<void>.delayed(Duration.zero);
      await repo.saveProfile(
        const CycleProfile(typicalCycleLength: 30, typicalPeriodLength: 4),
      );
      await expectation;
    });
  });

  group('period logs', () {
    final sep28 = LocalDate(2026, 9, 28);
    final aug31 = LocalDate(2026, 8, 31);

    test('newest first', () async {
      await repo.logPeriod(aug31, source: PeriodLogSource.onboarding);
      await repo.logPeriod(sep28);
      final logs = await repo.periodLogs();
      expect(logs.map((l) => l.start), [sep28, aug31]);
      expect(logs.last.source, PeriodLogSource.onboarding);
    });

    test(
      'logging the same start date updates instead of duplicating',
      () async {
        await repo.logPeriod(sep28, isEstimated: true);
        await repo.logPeriod(sep28, end: LocalDate(2026, 10, 2));
        final logs = await repo.periodLogs();
        expect(logs, hasLength(1));
        expect(logs.single.end, LocalDate(2026, 10, 2));
        expect(logs.single.isEstimated, isFalse);
      },
    );

    test('an estimated start is kept as estimated', () async {
      await repo.logPeriod(sep28, isEstimated: true);
      expect((await repo.periodLogs()).single.isEstimated, isTrue);
    });

    test('update changes the dates and clears the estimate', () async {
      final log = await repo.logPeriod(sep28, isEstimated: true);
      await repo.updatePeriodLog(
        log.id,
        start: LocalDate(2026, 9, 27),
        end: LocalDate(2026, 10, 1),
      );
      final updated = (await repo.periodLogs()).single;
      expect(updated.start, LocalDate(2026, 9, 27));
      expect(updated.end, LocalDate(2026, 10, 1));
      expect(updated.isEstimated, isFalse);
    });

    test('delete leaves a tombstone; the date can be logged again', () async {
      final log = await repo.logPeriod(sep28);
      await repo.deletePeriodLog(log.id);
      expect(await repo.periodLogs(), isEmpty);
      final rows = await db.select(db.periodLogs).get();
      expect(rows.single.deletedAt, isNotNull);

      await repo.logPeriod(sep28);
      expect(await repo.periodLogs(), hasLength(1));
    });
  });
}
