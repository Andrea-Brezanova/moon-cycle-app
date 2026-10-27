import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/design/moon_theme.dart';
import 'package:moon_cycle/core/design/widgets/hub_card.dart';
import 'package:moon_cycle/core/design/widgets/hub_hero.dart';
import 'package:moon_cycle/core/domain/phase.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/collections/application/collections_providers.dart';
import 'package:moon_cycle/features/collections/presentation/collection_link_page.dart';
import 'package:moon_cycle/features/cycle/application/viewing_phase.dart';
import 'package:moon_cycle/features/hubs/application/hub_providers.dart';
import 'package:moon_cycle/features/hubs/domain/hub_item.dart';
import 'package:moon_cycle/features/hubs/presentation/build_workout_page.dart';
import 'package:moon_cycle/features/hubs/presentation/hub_item_page.dart';
import 'package:moon_cycle/features/hubs/presentation/hub_library_page.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

Map<String, Object?> _item({
  String id = 'walk',
  String kind = 'workout',
  String status = 'approved',
  Map<String, Object?> more = const {},
}) => {
  'id': id,
  'kind': kind,
  'title': 'Easy walk',
  'summary': 'A relaxed walk.',
  'steps': ['Walk at a comfortable pace.'],
  'safetyNote': 'Stop if anything hurts; this is not medical advice.',
  'reviewStatus': status,
  'reviewedBy': 'Editor',
  'reviewedOn': '2026-10-01',
  ...more,
};

String _file(List<Map<String, Object?>> items) => jsonEncode({'items': items});

void main() {
  group('the content file', () {
    test('the bundled file ships no unapproved item and parses', () {
      final text = File('assets/content/hub_content.json').readAsStringSync();
      final all = (jsonDecode(text) as Map)['items'] as List;
      for (final i in all) {
        expect((i as Map)['reviewStatus'], 'approved');
      }
      parseHubItems(text);
    });

    test('only approved items are returned; drafts are dropped', () {
      final items = parseHubItems(
        _file([_item(), _item(id: 'draft', status: 'draft')]),
      );
      expect(items.map((i) => i.id), ['walk']);
    });

    test('an approved item must carry what the review requires', () {
      for (final bad in [
        _item(more: {'reviewedBy': ''}),
        _item(more: {'reviewedOn': null}),
        _item(more: {'safetyNote': null}),
        _item(more: {'steps': <String>[]}),
        _item(more: {'sourceUrl': 'ftp://example.com/x'}),
        _item(kind: 'sound', more: {'sourceUrl': 'https://example.com/a'}),
      ]) {
        expect(
          () => parseHubItems(_file([bad])),
          throwsFormatException,
          reason: '$bad',
        );
      }
      expect(
        () => parseHubItems(_file([_item(), _item()])),
        throwsFormatException,
        reason: 'duplicate id',
      );
    });

    test('a sound needs its rights; a meditation needs no safety note', () {
      expect(
        parseHubItems(
          _file([
            _item(
              id: 's',
              kind: 'sound',
              more: {
                'sourceUrl': 'https://example.com/a',
                'rights': 'Owned by Moon Cycle',
              },
            ),
            _item(id: 'm', kind: 'meditation', more: {'safetyNote': null}),
          ]),
        ),
        hasLength(2),
      );
    });
  });

  Future<ProviderContainer> pumpTab(
    WidgetTester tester,
    String tab, {
    List<HubItem> items = const [],
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
      overrides: [
        clockProvider.overrideWithValue(designNow),
        hubItemsProvider.overrideWith((ref) => items),
      ],
    );
    await tester.tap(find.byKey(ValueKey('tab-$tab')));
    await tester.pumpAndSettle();
    return c;
  }

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel(RegExp('^Back')).first);
    await tester.pumpAndSettle();
  }

  testWidgets('Move: four sections, each opens a real screen', (tester) async {
    await pumpTab(tester, 'move');
    for (final t in [
      'Exercises',
      'Workouts',
      'Build Your Workout',
      'My Workouts',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.text('Being prepared and reviewed'), findsNWidgets(2));

    for (final (key, page) in [
      ('hub-move-exercises', find.byType(HubLibraryPage)),
      ('hub-move-workouts', find.byType(HubLibraryPage)),
      ('hub-move-build', find.byType(BuildWorkoutPage)),
    ]) {
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
      expect(page, findsOneWidget, reason: key);
      await back(tester);
    }
    await tester.tap(find.byKey(const ValueKey('hub-move-mine')));
    await tester.pumpAndSettle();
    expect(find.text('My Workouts'), findsWidgets);
  });

  testWidgets('Relax: Meditations, Sounds, Spa and My Spa', (tester) async {
    await pumpTab(tester, 'relax');
    for (final t in ['Meditations', 'Sounds', 'Spa', 'My Spa']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    await tester.tap(find.byKey(const ValueKey('hub-relax-sounds')));
    await tester.pumpAndSettle();
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.textContaining('confirmed rights'), findsOneWidget);
  });

  testWidgets('an empty library says so and offers saving a link, with no '
      'sample content', (tester) async {
    await pumpTab(tester, 'move');
    await tester.tap(find.byKey(const ValueKey('hub-move-workouts')));
    await tester.pumpAndSettle();
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.byKey(const ValueKey('hub-item-walk')), findsNothing);
    await tester.tap(find.text('Save a workout link'));
    await tester.pumpAndSettle();
    expect(find.byType(CollectionLinkPage), findsOneWidget);
  });

  testWidgets('an approved item is listed and opens with steps and its '
      'safety note', (tester) async {
    final items = parseHubItems(_file([_item()]));
    await pumpTab(tester, 'move', items: items);
    expect(find.text('1 to browse'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('hub-move-workouts')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hub-item-walk')));
    await tester.pumpAndSettle();
    expect(find.byType(HubItemPage), findsOneWidget);
    expect(find.text('1. Walk at a comfortable pace.'), findsOneWidget);
    expect(find.byKey(const ValueKey('hub-safety-note')), findsOneWidget);
    expect(find.byKey(const ValueKey('hub-save')), findsNothing); // no link
  });

  testWidgets('an approved item with a verified link can be saved to My '
      'Workouts once', (tester) async {
    final items = parseHubItems(
      _file([
        _item(
          more: {
            'sourceUrl': 'https://example.com/walk',
            'sourceName': 'Example Studio',
          },
        ),
      ]),
    );
    final c = await pumpTab(tester, 'move', items: items);
    await tester.tap(find.byKey(const ValueKey('hub-move-workouts')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hub-item-walk')));
    await tester.pumpAndSettle();
    expect(find.text('Source: Example Studio'), findsOneWidget);
    expect(find.text('Save to My Workouts'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('hub-save')));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
    expect(c.read(collectionSummaryProvider).workoutLinks, 1);
  });

  group('Eat, Move and Relax look like one app', () {
    Future<Rect> heroRect(WidgetTester tester, String tab) async {
      await tester.tap(find.byKey(ValueKey('tab-$tab')));
      await tester.pumpAndSettle();
      return tester.getRect(find.byType(HubHero));
    }

    testWidgets('the three hero cards share width, left edge and image '
        'proportions', (tester) async {
      await pumpTab(tester, 'eat');
      final eat = tester.getRect(find.byType(HubHero));
      final eatImage = tester.getSize(
        find.descendant(
          of: find.byType(HubHero),
          matching: find.byType(AspectRatio),
        ),
      );
      for (final tab in ['move', 'relax']) {
        final r = await heroRect(tester, tab);
        expect(r.left, closeTo(eat.left, 0.5), reason: tab);
        expect(r.width, closeTo(eat.width, 0.5), reason: tab);
        final image = tester.getSize(
          find.descendant(
            of: find.byType(HubHero),
            matching: find.byType(AspectRatio),
          ),
        );
        expect(image.width / image.height, closeTo(1.86, 0.01), reason: tab);
        expect(eatImage.width / eatImage.height, closeTo(1.86, 0.01));
        // The hero sits above the first section card.
        final firstCard = tester.getTopLeft(
          find.byKey(
            ValueKey('hub-$tab-${tab == 'move' ? 'exercises' : 'meditations'}'),
          ),
        );
        expect(r.bottom, lessThan(firstCard.dy));
      }
    });

    for (final tab in ['eat', 'move', 'relax']) {
      testWidgets('$tab: card icons wear the viewed phase and follow it', (
        tester,
      ) async {
        final c = await pumpTab(tester, tab);
        Color? disc() {
          final deco = tester
              .widgetList<Container>(
                find.descendant(
                  of: find.byType(HubCard).first,
                  matching: find.byType(Container),
                ),
              )
              .map((e) => e.decoration)
              .whereType<BoxDecoration>()
              .firstWhere((d) => d.shape == BoxShape.circle);
          return deco.color;
        }

        final context = tester.element(find.byType(HubCard).first);
        for (final phase in Phase.values) {
          c.read(viewingPhaseProvider.notifier).choose(phase);
          await tester.pumpAndSettle();
          expect(disc(), context.moon.phase(phase).tint, reason: phase.name);
        }
      });
    }
  });

  for (final (width, scale) in [(320.0, 1.5), (390.0, 2.0)]) {
    testWidgets('Move and Relax fit at ${width}pt, $scale× text', (
      tester,
    ) async {
      await pumpTab(tester, 'move', width: width, scale: scale);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('tab-relax')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
