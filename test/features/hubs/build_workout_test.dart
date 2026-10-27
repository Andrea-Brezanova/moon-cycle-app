import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/hubs/application/hub_providers.dart';
import 'package:moon_cycle/features/hubs/application/workout_draft.dart';
import 'package:moon_cycle/features/hubs/domain/hub_item.dart';
import 'package:moon_cycle/features/hubs/presentation/build_workout_page.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

void main() {
  group('the draft', () {
    late ProviderContainer c;
    setUp(() {
      c = ProviderContainer();
      c.listen(workoutDraftProvider, (_, _) {});
    });
    tearDown(() => c.dispose());
    List<String> names() => [
      for (final e in c.read(workoutDraftProvider)) e.name,
    ];

    test('adds typed and library exercises; blanks are ignored', () {
      final n = c.read(workoutDraftProvider.notifier);
      n.addCustom('  ');
      n.addCustom('Squats');
      n.addLibrary('ex-walk', 'Easy walk');
      n.addLibrary('ex-walk', 'Easy walk'); // twice is allowed
      expect(names(), ['Squats', 'Easy walk', 'Easy walk']);
      expect(c.read(workoutDraftProvider)[1].libraryId, 'ex-walk');
    });

    test('reorders with Flutter’s adjusted indices', () {
      final n = c.read(workoutDraftProvider.notifier);
      for (final x in ['A', 'B', 'C', 'D']) {
        n.addCustom(x);
      }
      n.move(0, 2); // A after B
      expect(names(), ['B', 'C', 'A', 'D']);
      n.move(3, 0);
      expect(names(), ['D', 'B', 'C', 'A']);
      n.move(9, 0); // out of range: ignored
      expect(names(), ['D', 'B', 'C', 'A']);
    });

    test('removes one exercise by key, even when names repeat', () {
      final n = c.read(workoutDraftProvider.notifier);
      n.addCustom('Lunge');
      n.addCustom('Lunge');
      final keys = [for (final e in c.read(workoutDraftProvider)) e.key];
      n.remove(keys.first);
      expect(c.read(workoutDraftProvider), hasLength(1));
      expect(c.read(workoutDraftProvider).single.key, keys.last);
      n.clear();
      expect(c.read(workoutDraftProvider), isEmpty);
    });
  });

  Future<ProviderContainer> pumpBuilder(
    WidgetTester tester, {
    List<HubItem> library = const [],
  }) async {
    tester.view.physicalSize = const Size(390, 1000) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    final c = await pumpApp(
      tester,
      database: db,
      overrides: [
        clockProvider.overrideWithValue(designNow),
        hubItemsProvider.overrideWith((ref) => library),
      ],
    );
    await tester.tap(find.byKey(const ValueKey('tab-move')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hub-move-build')));
    await tester.pumpAndSettle();
    expect(find.byType(BuildWorkoutPage), findsOneWidget);
    return c;
  }

  testWidgets('add your own, see the numbered list, remove one', (
    tester,
  ) async {
    await pumpBuilder(tester);
    expect(find.byKey(const ValueKey('workout-library-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('workout-empty')), findsOneWidget);
    for (final name in ['Squats', 'Plank']) {
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('workout-add-field')),
          matching: find.byType(EditableText),
        ),
        name,
      );
      await tester.tap(find.byKey(const ValueKey('workout-add')));
      await tester.pumpAndSettle();
    }
    expect(find.text('1. Squats'), findsOneWidget);
    expect(find.text('2. Plank'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Remove Squats'));
    await tester.pumpAndSettle();
    expect(find.text('1. Plank'), findsOneWidget);
    expect(find.textContaining('Squats'), findsNothing);
  });

  testWidgets('approved library exercises can be added and reordered', (
    tester,
  ) async {
    final library = parseHubItems(
      '{"items":[{"id":"ex-a","kind":"exercise","title":"Easy walk",'
      '"summary":"s","steps":["x"],"safetyNote":"n","durationMinutes":10,'
      '"reviewStatus":"approved","reviewedBy":"E","reviewedOn":"2026-10-01"},'
      '{"id":"ex-b","kind":"exercise","title":"Hip stretch","summary":"s",'
      '"steps":["x"],"safetyNote":"n","reviewStatus":"approved",'
      '"reviewedBy":"E","reviewedOn":"2026-10-01"}]}',
    );
    final c = await pumpBuilder(tester, library: library);
    expect(find.byKey(const ValueKey('workout-library-empty')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('workout-lib-ex-a')));
    await tester.tap(find.byKey(const ValueKey('workout-lib-ex-b')));
    await tester.pumpAndSettle();
    expect(find.text('1. Easy walk'), findsOneWidget);
    expect(find.text('2. Hip stretch'), findsOneWidget);
    c.read(workoutDraftProvider.notifier).move(1, 0);
    await tester.pumpAndSettle();
    expect(find.text('1. Hip stretch'), findsOneWidget);
    expect(find.text('2. Easy walk'), findsOneWidget);
  });

  testWidgets('saving is honestly unavailable, not faked', (tester) async {
    await pumpBuilder(tester);
    final button = find.byKey(const ValueKey('workout-save'));
    await tester.ensureVisible(button);
    expect(find.byKey(const ValueKey('workout-save-note')), findsOneWidget);
    await tester.tap(button, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(BuildWorkoutPage), findsOneWidget);
  });
}
