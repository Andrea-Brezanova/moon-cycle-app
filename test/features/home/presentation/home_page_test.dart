import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/home/presentation/home_page.dart';
import 'package:moon_cycle/features/preferences/data/preferences_repository.dart';

import '../../../helpers/golden_screen.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

/// Scrolls Home's own list (not the horizontal recipe row) until [finder]
/// is on screen.
Future<void> scrollTo(
  WidgetTester tester,
  Finder finder, [
  double step = 200,
]) async {
  await tester.scrollUntilVisible(
    finder,
    step,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  Future<void> pumpHome(
    WidgetTester tester, {
    LocalDate? start,
    Future<void> Function(PreferencesRepository prefs)? prefs,
  }) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(
      tester,
      db,
      start: start ?? sampleStart,
      more: prefs == null ? null : () => prefs(PreferencesRepository(db)),
    );
    await pumpApp(
      tester,
      database: db,
      overrides: [clockProvider.overrideWithValue(designNow)],
    );
    expect(find.byType(HomePage), findsOneWidget);
  }

  testWidgets('the hero shows today: day 7, follicular', (tester) async {
    await pumpHome(tester);
    expect(find.text('Sat 4 Oct'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Inner spring'), findsOneWidget);
    expect(find.text('Follicular'), findsOneWidget);
    expect(find.text('DAY'), findsOneWidget);
    expect(
      find.text(
        'Day 2 of 6 in phase · Day 7 of 28 in cycle\nOvulatory in 5 days',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Cycle day 7 of 28, follicular phase, day 2 of 6'),
      findsOneWidget,
    );
  });

  testWidgets('dragging the orbit previews a day; back to today', (
    tester,
  ) async {
    await pumpHome(tester);
    final orbit = find.bySemanticsLabel(
      'Cycle day 7 of 28, follicular phase, day 2 of 6',
    );
    final centre = tester.getCenter(orbit);
    // From the bottom of the ring (half a turn: day 14 or 15 of 28) a
    // little further round.
    final ring = tester.getSize(orbit).width * 132 / 300;
    await tester.dragFrom(centre + Offset(0, ring), const Offset(-2, 0));
    await tester.pumpAndSettle();
    expect(find.textContaining('Previewing day 1'), findsOneWidget);
    expect(find.text('Ovulatory'), findsOneWidget);
    // Scroll from below the moon: a drag on the ring would preview instead.
    await tester.drag(find.text('Ovulatory'), const Offset(0, -300));
    await tester.pumpAndSettle();
    // The content below follows the phase being browsed.
    expect(find.text('TODAY’S FOCUS'), findsOneWidget);
    expect(
      find.textContaining('Bright, vibrant &', findRichText: true),
      findsOneWidget,
    );

    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0, 3000),
      4000,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to today · Day 7'));
    await tester.pumpAndSettle();
    expect(find.text('Follicular'), findsOneWidget);
    await scrollTo(tester, find.text('3 plants'));
    expect(find.text('3 plants'), findsOneWidget);
  });

  testWidgets('screen readers adjust the preview', (tester) async {
    await pumpHome(tester);
    final node = tester.getSemantics(
      find.bySemanticsLabel('Cycle day 7 of 28, follicular phase, day 2 of 6'),
    );
    expect(node.getSemanticsData().hasAction(SemanticsAction.increase), isTrue);
    node.owner!.performAction(node.id, SemanticsAction.increase);
    await tester.pumpAndSettle();
    expect(find.text('Previewing day 8 · in 1 day'), findsOneWidget);
  });

  testWidgets('late: the card, then logging a period restarts the cycle', (
    tester,
  ) async {
    // 31 days ago: day 32 of 28, four days late.
    await pumpHome(tester, start: LocalDate(2025, 9, 3));
    expect(find.text('32'), findsOneWidget);
    expect(find.text('Luteal'), findsOneWidget);
    expect(find.text('Period 4 days late · Day 32 in cycle'), findsOneWidget);
    expect(find.text('Has your period started?'), findsOneWidget);

    await scrollTo(tester, find.text('Log my period'));
    await tester.tap(find.text('Log my period'));
    await tester.pumpAndSettle();
    expect(find.text('When did it start?'), findsOneWidget);
    expect(find.text('Day 1 · Saturday 4 October'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0, 3000),
      4000,
    );
    await tester.pumpAndSettle();
    expect(find.text('Menstrual'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Has your period started?'), findsNothing);
  });

  testWidgets('one or two days late: no card yet', (tester) async {
    await pumpHome(tester, start: LocalDate(2025, 9, 5)); // day 30
    expect(find.text('Period 2 days late · Day 30 in cycle'), findsOneWidget);
    expect(find.text('Has your period started?'), findsNothing);
  });
}
