import 'dart:io';

import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/storage/ui_prefs.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/collections/application/collections_providers.dart';
import 'package:moon_cycle/features/privacy/data/local_data_wiper.dart';
import 'package:moon_cycle/features/reminders/application/reminder_providers.dart';

import '../../helpers/fake_reminders.dart';
import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

const _keys = ['recipes', 'workouts', 'spa', 'routines'];

void main() {
  group('the order', () {
    test('normalise: unknown and repeated keys go, missing ones return', () {
      expect(normaliseCollectionOrder(const []), _keys);
      expect(normaliseCollectionOrder(['spa', 'spa', 'nope']), [
        'spa',
        'recipes',
        'workouts',
        'routines',
      ]);
      expect(normaliseCollectionOrder([..._keys.reversed]), [
        'routines',
        'spa',
        'workouts',
        'recipes',
      ]);
    });

    test('move puts a tile where it was dropped', () {
      expect(moveCollectionTile(_keys, 'recipes', 2), [
        'workouts',
        'spa',
        'recipes',
        'routines',
      ]);
      expect(moveCollectionTile(_keys, 'routines', 0), [
        'routines',
        'recipes',
        'workouts',
        'spa',
      ]);
      expect(moveCollectionTile(_keys, 'spa', 9), [
        'recipes',
        'workouts',
        'routines',
        'spa',
      ]);
      expect(moveCollectionTile(_keys, 'unknown', 1), _keys);
    });
  });

  group('the settings file', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('ui_prefs_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('round-trips; a damaged file means defaults', () async {
      final store = FileUiPrefsStore(dir);
      expect((await store.load()).collectionOrder, isEmpty);
      await store.save(
        const UiPrefs(collectionOrder: ['spa', 'recipes'], meHero: 'custom'),
      );
      final back = await FileUiPrefsStore(dir).load();
      expect(back.collectionOrder, ['spa', 'recipes']);
      expect(back.meHero, 'custom');
      File('${dir.path}/${FileUiPrefsStore.fileName}').writeAsStringSync('{{{');
      expect((await store.load()).collectionOrder, isEmpty);
    });

    test('deleteAll removes the file and the personal image', () async {
      final store = FileUiPrefsStore(dir);
      await store.save(const UiPrefs(collectionOrder: ['spa']));
      store.heroFile.writeAsBytesSync([1, 2, 3]);
      await store.deleteAll();
      expect(dir.listSync(), isEmpty);
    });

    test('Delete my data clears them (a wipe step)', () async {
      final store = MemoryUiPrefsStore(
        const UiPrefs(collectionOrder: ['spa'], meHero: 'custom'),
      );
      final c = ProviderContainer(
        overrides: [
          uiPrefsStoreProvider.overrideWithValue(store),
          reminderSchedulerProvider.overrideWithValue(FakeReminderScheduler()),
        ],
      );
      addTearDown(c.dispose);
      for (final step in c.read(wipeStepsProvider)) {
        await step();
      }
      expect(store.deletes, 1);
      expect(store.prefs.collectionOrder, isEmpty);
      expect(store.prefs.meHero, isNull);
    });
  });

  Future<ProviderContainer> pumpCollections(
    WidgetTester tester,
    MemoryUiPrefsStore store,
  ) async {
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
        uiPrefsStoreProvider.overrideWithValue(store),
        initialUiPrefsProvider.overrideWithValue(await store.load()),
      ],
    );
    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('me-collections')));
    await tester.pumpAndSettle();
    return c;
  }

  Finder tile(String k) => find.byKey(ValueKey('collection-$k'));

  /// Tile keys by position: top to bottom, left to right.
  List<String> onScreen(WidgetTester tester) {
    final r = {for (final k in _keys) k: tester.getTopLeft(tile(k))};
    return [..._keys]..sort((a, b) {
      final dy = r[a]!.dy.compareTo(r[b]!.dy);
      return dy != 0 ? dy : r[a]!.dx.compareTo(r[b]!.dx);
    });
  }

  Future<void> drag(WidgetTester tester, String from, String to) async {
    final g = await tester.startGesture(tester.getCenter(tile(from)));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await g.moveTo(tester.getCenter(tile(to)));
    await tester.pump(const Duration(milliseconds: 100));
    await g.up();
    await tester.pumpAndSettle();
  }

  testWidgets('long-press and drag reorders the 2 × 2 grid; the order '
      'survives a restart; no collection changes', (tester) async {
    final store = MemoryUiPrefsStore();
    var c = await pumpCollections(tester, store);
    expect(onScreen(tester), _keys); // the default order
    final before = tester.getSize(tile('recipes'));

    await drag(tester, 'recipes', 'spa');
    expect(onScreen(tester), ['workouts', 'spa', 'recipes', 'routines']);
    // Still two per row, the same size.
    expect(
      tester.getTopLeft(tile('workouts')).dy,
      tester.getTopLeft(tile('spa')).dy,
    );
    expect(
      tester.getTopLeft(tile('recipes')).dy,
      tester.getTopLeft(tile('routines')).dy,
    );
    expect(tester.getSize(tile('recipes')), before);
    expect(store.prefs.collectionOrder, [
      'workouts',
      'spa',
      'recipes',
      'routines',
    ]);
    expect(c.read(collectionSummaryProvider).total, 0);

    // "Restart": a brand-new app over the same stored settings.
    await tester.pumpWidget(const SizedBox());
    c = await pumpCollections(tester, store);
    expect(onScreen(tester), ['workouts', 'spa', 'recipes', 'routines']);
  });

  testWidgets('a tap still opens the tile; a long press alone changes '
      'nothing', (tester) async {
    final store = MemoryUiPrefsStore();
    await pumpCollections(tester, store);
    final g = await tester.startGesture(tester.getCenter(tile('spa')));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await g.up();
    await tester.pumpAndSettle();
    expect(onScreen(tester), _keys);
    expect(store.prefs.collectionOrder, isEmpty);
    await tester.tap(tile('routines'));
    await tester.pumpAndSettle();
    expect(find.text('No routines yet'), findsOneWidget);
  });

  testWidgets('screen readers get Move earlier and Move later', (tester) async {
    final handle = tester.ensureSemantics();
    final store = MemoryUiPrefsStore();
    await pumpCollections(tester, store);

    Set<String> actions(String key) {
      final node = tester.getSemantics(find.byKey(ValueKey('cell-$key')));
      return {
        for (final id
            in node.getSemanticsData().customSemanticsActionIds ?? <int>[])
          CustomSemanticsAction.getAction(id)!.label!,
      };
    }

    expect(actions('recipes'), {'Move later'}); // first: nothing earlier
    expect(actions('workouts'), {'Move earlier', 'Move later'});
    expect(actions('routines'), {'Move earlier'}); // last: nothing later

    final node = tester.getSemantics(find.byKey(const ValueKey('cell-spa')));
    final later = [
      for (final id
          in node.getSemanticsData().customSemanticsActionIds ?? <int>[])
        if (CustomSemanticsAction.getAction(id)!.label == 'Move earlier') id,
    ].single;
    node.owner!.performAction(node.id, SemanticsAction.customAction, later);
    await tester.pumpAndSettle();
    expect(onScreen(tester), ['recipes', 'spa', 'workouts', 'routines']);
    expect(store.prefs.collectionOrder, [
      'recipes',
      'spa',
      'workouts',
      'routines',
    ]);
    handle.dispose();
  });
}
