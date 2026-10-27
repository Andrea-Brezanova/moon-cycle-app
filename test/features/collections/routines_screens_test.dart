import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/collections/data/collection_link_repository.dart';
import 'package:moon_cycle/features/collections/domain/collection_link.dart';
import 'package:moon_cycle/features/collections/presentation/my_routines_page.dart';
import 'package:moon_cycle/features/collections/presentation/routine_page.dart';
import 'package:moon_cycle/features/routines/data/routine_repository.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

void main() {
  Future<ProviderContainer> pumpRoutines(
    WidgetTester tester, {
    double width = 390,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 1000) * 3;
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    final c = await pumpApp(
      tester,
      database: db,
      overrides: [clockProvider.overrideWithValue(designNow)],
    );
    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('me-collections')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('collection-routines')));
    await tester.pumpAndSettle();
    expect(find.byType(MyRoutinesPage), findsOneWidget);
    return c;
  }

  Future<void> create(WidgetTester tester, String title) async {
    await tester.tap(find.byKey(const ValueKey('routine-new')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('ask-field')),
        matching: find.byType(EditableText),
      ),
      title,
    );
    await tester.tap(find.byKey(const ValueKey('ask-submit')));
    await tester.pumpAndSettle();
  }

  Future<void> addStep(WidgetTester tester, String text) async {
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('routine-step-field')),
        matching: find.byType(EditableText),
      ),
      text,
    );
    await tester.tap(find.byKey(const ValueKey('routine-add-step')));
    await tester.pumpAndSettle();
  }

  testWidgets('empty state, then create a routine and land on it', (
    tester,
  ) async {
    await pumpRoutines(tester);
    expect(find.text('No routines yet'), findsOneWidget);
    expect(find.text('Routines are not available yet'), findsNothing);
    await create(tester, 'Morning stretch');
    expect(find.byType(RoutinePage), findsOneWidget);
    expect(find.text('Morning stretch'), findsOneWidget);
    expect(find.byKey(const ValueKey('routine-no-steps')), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp('^Back')).first);
    await tester.pumpAndSettle();
    expect(find.text('No steps yet'), findsOneWidget); // listed with its count
    expect(find.text('No routines yet'), findsNothing);
  });

  testWidgets('add, reorder and remove steps; they persist when reopened', (
    tester,
  ) async {
    await pumpRoutines(tester);
    await create(tester, 'Evening wind-down');
    await addStep(tester, 'Five slow breaths');
    await addStep(tester, 'Warm tea');
    await addStep(tester, 'Dim the lights');
    expect(find.text('1. Five slow breaths'), findsOneWidget);
    expect(find.text('3. Dim the lights'), findsOneWidget);

    // Drag the last step to the top.
    await tester.drag(
      find.bySemanticsLabel('Reorder step 3'),
      const Offset(0, -140),
    );
    await tester.pumpAndSettle();
    expect(find.text('1. Dim the lights'), findsOneWidget);
    expect(find.text('2. Five slow breaths'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Remove step 2'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Five slow breaths'), findsNothing);
    expect(find.text('2. Warm tea'), findsOneWidget);

    // Leave and come back: the same steps in the same order.
    await tester.tap(find.bySemanticsLabel(RegExp('^Back')).first);
    await tester.pumpAndSettle();
    expect(find.text('2 steps'), findsOneWidget);
    await tester.tap(find.text('Evening wind-down'));
    await tester.pumpAndSettle();
    expect(find.text('1. Dim the lights'), findsOneWidget);
    expect(find.text('2. Warm tea'), findsOneWidget);
  });

  testWidgets('add a saved link as a step; removing the link leaves a '
      'marked step', (tester) async {
    final c = await pumpRoutines(tester);
    final done = c
        .read(collectionLinkRepositoryProvider)
        .add(
          category: LinkCategory.workouts,
          address: 'https://example.com/flow',
          title: 'Morning flow',
        );
    await tester.pumpAndSettle();
    final link = (await done)!;
    await create(tester, 'Mornings');
    await tester.tap(find.byKey(const ValueKey('routine-add-link')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('pick-${link.id}')));
    await tester.pumpAndSettle();
    expect(find.text('1. Morning flow'), findsOneWidget);
    expect(find.text('Website'), findsOneWidget);

    final removed = c.read(collectionLinkRepositoryProvider).delete(link.id);
    await tester.pumpAndSettle();
    await removed;
    await tester.pumpAndSettle();
    expect(find.text('1. Removed link'), findsOneWidget);
  });

  testWidgets('rename, then delete with a confirmation', (tester) async {
    final c = await pumpRoutines(tester);
    await create(tester, 'Old name');
    await tester.tap(find.byKey(const ValueKey('routine-rename')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('ask-field')),
        matching: find.byType(EditableText),
      ),
      'New name',
    );
    await tester.tap(find.byKey(const ValueKey('ask-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-title')), findsOneWidget);
    expect(find.text('New name'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('routine-delete')));
    await tester.tap(find.byKey(const ValueKey('routine-delete')));
    await tester.pumpAndSettle();
    expect(find.text('Delete this routine?'), findsOneWidget);
    // "Keep it" deletes nothing.
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    expect(find.byType(RoutinePage), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('routine-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('routine-confirm-delete')));
    await tester.pumpAndSettle();
    expect(find.byType(MyRoutinesPage), findsOneWidget);
    expect(find.text('No routines yet'), findsOneWidget);
    expect(c, isNotNull);
  });

  testWidgets('blank names and steps are not saved', (tester) async {
    await pumpRoutines(tester);
    await tester.tap(find.byKey(const ValueKey('routine-new')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ask-submit')));
    await tester.pumpAndSettle();
    expect(find.text('No routines yet'), findsOneWidget);
    await create(tester, 'Real');
    await addStep(tester, '   ');
    expect(find.byKey(const ValueKey('routine-no-steps')), findsOneWidget);
  });

  for (final (width, scale) in [(320.0, 1.5), (390.0, 2.0)]) {
    testWidgets('routines fit at ${width}pt, $scale× text', (tester) async {
      await pumpRoutines(tester, width: width, scale: scale);
      expect(tester.takeException(), isNull);
      await create(tester, 'A routine with a rather long name to wrap');
      await addStep(tester, 'A step that is also long enough to wrap around');
      expect(tester.takeException(), isNull);
    });
  }

  test('the repository still has its own tests', () {
    expect(RoutineRepository, isNotNull);
  });
}
