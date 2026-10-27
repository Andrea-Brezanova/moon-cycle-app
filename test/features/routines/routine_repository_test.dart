import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/features/routines/data/routine_repository.dart';

import '../../helpers/pump_app.dart';

void main() {
  late AppDatabase db;
  late RoutineRepository repo;

  setUp(() {
    db = testDatabase();
    repo = RoutineRepository(db);
  });
  tearDown(() => db.close());

  test('create, rename and list; an empty title is refused', () async {
    expect(await repo.create('   '), isNull);
    final id = (await repo.create('Morning stretch', note: ' gentle '))!;
    expect(await repo.rename(id, 'Morning stretch and meditation'), isTrue);
    expect(await repo.rename(id, ''), isFalse);
    final all = await repo.all();
    expect(all.single.title, 'Morning stretch and meditation');
    expect(all.single.note, 'gentle');
  });

  test('steps keep their order; link steps point at a link id', () async {
    final id = (await repo.create('Evening wind-down'))!;
    await repo.addTextStep(id, 'Five slow breaths');
    await repo.addLinkStep(id, 'link-1');
    await repo.addTextStep(id, 'Warm tea');
    expect(await repo.addTextStep(id, '  '), isNull);
    var steps = await repo.steps(id);
    expect(steps.map((s) => s.text ?? s.linkId), [
      'Five slow breaths',
      'link-1',
      'Warm tea',
    ]);
    await repo.moveStep(id, steps.last.id, 0);
    steps = await repo.steps(id);
    expect(steps.map((s) => s.text ?? s.linkId), [
      'Warm tea',
      'Five slow breaths',
      'link-1',
    ]);
    expect([for (final s in steps) s.position], [0, 1, 2]);
  });

  test('removing a step closes the gap and empties its text', () async {
    final id = (await repo.create('R'))!;
    final a = (await repo.addTextStep(id, 'a'))!;
    await repo.addTextStep(id, 'b');
    await repo.removeStep(id, a);
    final steps = await repo.steps(id);
    expect(steps.map((s) => s.text), ['b']);
    expect(steps.single.position, 0);
    final row = await (db.select(
      db.routineSteps,
    )..where((t) => t.id.equals(a))).getSingle();
    expect(row.deletedAt, isNotNull);
    expect(row.body, isNull);
  });

  test(
    'deleting a routine tombstones it and its steps and keeps no text',
    () async {
      final id = (await repo.create('Private', note: 'secret'))!;
      await repo.addTextStep(id, 'secret step');
      await repo.delete(id);
      expect(await repo.all(), isEmpty);
      expect(await repo.steps(id), isEmpty);
      final r = await db.select(db.routines).getSingle();
      expect(r.title, '');
      expect(r.note, isNull);
      final s = await db.select(db.routineSteps).getSingle();
      expect(s.body, isNull);
      expect(await repo.addTextStep(id, 'x'), isNull); // routine is gone
    },
  );
}
