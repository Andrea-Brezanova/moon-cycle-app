import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/design/widgets/hub_hero.dart';
import 'package:moon_cycle/core/storage/ui_prefs.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/settings/application/me_hero.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

/// A picker that returns what the test says: bytes, null (cancelled), or an
/// error.
class FakePicker implements HeroImagePicker {
  Object? next;
  final calls = <HeroPickSource>[];

  @override
  Future<Uint8List?> pick(HeroPickSource source) async {
    calls.add(source);
    final n = next;
    if (n is Exception) throw n;
    return n as Uint8List?;
  }
}

// One-pixel JPEG-ish bytes are enough: the fake store hands them to MemoryImage.
final _photo = Uint8List.fromList(List.generate(32, (i) => i));
final _photo2 = Uint8List.fromList(List.generate(48, (i) => i + 1));

void main() {
  Future<ProviderContainer> pumpMe(
    WidgetTester tester,
    MemoryUiPrefsStore store,
    FakePicker picker, {
    double width = 390,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 1200) * 3;
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
        uiPrefsStoreProvider.overrideWithValue(store),
        initialUiPrefsProvider.overrideWithValue(await store.load()),
        heroImagePickerProvider.overrideWithValue(picker),
      ],
    );
    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    return c;
  }

  ImageProvider shown(WidgetTester tester) =>
      tester.widget<Image>(find.byKey(const ValueKey('me-hero-image'))).image;

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('me-hero-edit')));
    await tester.pumpAndSettle();
  }

  testWidgets('the default hero sits above exactly four destinations, with '
      'the same shape as the Eat hero', (tester) async {
    await pumpMe(tester, MemoryUiPrefsStore(), FakePicker());
    final hero = tester.getRect(find.byKey(const ValueKey('me-hero')));
    expect(shown(tester), isA<AssetImage>());
    final first = tester.getTopLeft(
      find.byKey(const ValueKey('me-collections')),
    );
    expect(hero.bottom, lessThan(first.dy));
    for (final k in ['me-collections', 'me-diary', 'me-shopping', 'me-app']) {
      expect(find.byKey(ValueKey(k)), findsOneWidget);
    }
    // Not stretched: cover-cropped at the shared 1.86 proportion.
    final image = tester.widget<Image>(
      find.byKey(const ValueKey('me-hero-image')),
    );
    expect(image.fit, BoxFit.cover);
    final box = tester.getSize(
      find.descendant(
        of: find.byKey(const ValueKey('me-hero')),
        matching: find.byType(AspectRatio),
      ),
    );
    expect(box.width / box.height, closeTo(HubHero.aspectRatio, 0.01));

    // The Eat hero has the same left edge and width.
    await tester.tap(find.byKey(const ValueKey('tab-eat')));
    await tester.pumpAndSettle();
    final eat = tester.getRect(find.byType(HubHero));
    expect(hero.left, closeTo(eat.left, 0.5));
    expect(hero.width, closeTo(eat.width, 0.5));
  });

  testWidgets('choose a MoonCycle picture; it persists across a restart and '
      'can be restored', (tester) async {
    final store = MemoryUiPrefsStore();
    await pumpMe(tester, store, FakePicker());
    await open(tester);
    expect(find.byKey(const ValueKey('hero-restore')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('hero-bundled')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bundled-yoga')));
    await tester.pumpAndSettle();
    expect(
      (shown(tester) as AssetImage).assetName,
      'assets/images/home/home_move_yoga_mat.jpg',
    );
    expect(store.prefs.meHero, 'bundled:yoga');

    // Restart.
    await tester.pumpWidget(const SizedBox());
    await pumpMe(tester, store, FakePicker());
    expect(
      (shown(tester) as AssetImage).assetName,
      'assets/images/home/home_move_yoga_mat.jpg',
    );

    await open(tester);
    await tester.tap(find.byKey(const ValueKey('hero-restore')));
    await tester.pumpAndSettle();
    expect(store.prefs.meHero, isNull);
    expect(
      (shown(tester) as AssetImage).assetName,
      'assets/images/home/home_relax_tea.jpg',
    );
  });

  for (final (key, source) in [
    ('hero-gallery', HeroPickSource.gallery),
    ('hero-camera', HeroPickSource.camera),
  ]) {
    testWidgets('${source.name}: a photo becomes the hero, is kept, replaced '
        'and removed', (tester) async {
      final store = MemoryUiPrefsStore();
      final picker = FakePicker()..next = _photo;
      await pumpMe(tester, store, picker);
      await open(tester);
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
      expect(picker.calls, [source]);
      expect(shown(tester), isA<MemoryImage>());
      expect((shown(tester) as MemoryImage).bytes, _photo);
      expect(store.prefs.meHero, startsWith('custom:'));
      expect(store.images, hasLength(1));

      // Restart: still the same photo.
      await tester.pumpWidget(const SizedBox());
      await pumpMe(tester, store, picker);
      expect((shown(tester) as MemoryImage).bytes, _photo);

      // Replace it: the old file is gone, not kept alongside.
      picker.next = _photo2;
      await open(tester);
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
      expect((shown(tester) as MemoryImage).bytes, _photo2);
      expect(store.images, hasLength(1));

      // Remove: back to the default and no personal image is left.
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('hero-restore')));
      await tester.pumpAndSettle();
      expect(store.images, isEmpty);
      expect(shown(tester), isA<AssetImage>());
    });

    testWidgets('${source.name}: cancelling changes nothing', (tester) async {
      final store = MemoryUiPrefsStore();
      final picker = FakePicker()..next = null;
      await pumpMe(tester, store, picker);
      await open(tester);
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
      expect(store.prefs.meHero, isNull);
      expect(shown(tester), isA<AssetImage>());
      expect(find.byKey(const ValueKey('hero-denied')), findsNothing);
    });

    testWidgets('${source.name}: permission denied is explained, nothing '
        'changes, and the app carries on', (tester) async {
      final store = MemoryUiPrefsStore();
      final picker = FakePicker()..next = HeroPermissionDenied(source);
      await pumpMe(tester, store, picker);
      await open(tester);
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('hero-denied')), findsOneWidget);
      expect(
        find.textContaining(
          source == HeroPickSource.camera ? 'the camera' : 'your photos',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('hero-open-settings')), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(store.prefs.meHero, isNull);
      expect(shown(tester), isA<AssetImage>());
      // The bundled pictures still work.
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('hero-bundled')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bundled-tea')));
      await tester.pumpAndSettle();
      expect(store.prefs.meHero, 'bundled:tea');
    });
  }

  testWidgets('an unexpected picker error gets a calm message and changes '
      'nothing', (tester) async {
    final store = MemoryUiPrefsStore();
    final picker = FakePicker()..next = Exception('boom');
    await pumpMe(tester, store, picker);
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('hero-gallery')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hero-failed')), findsOneWidget);
    expect(store.prefs.meHero, isNull);
  });

  testWidgets('a personal image that has gone missing falls back to the '
      'default', (tester) async {
    final store = MemoryUiPrefsStore(
      const UiPrefs(meHero: 'custom:me_hero_gone.jpg'),
    );
    await pumpMe(tester, store, FakePicker());
    expect(shown(tester), isA<AssetImage>());
  });

  testWidgets('Delete my data would clear the choice and the image (the wipe '
      'step is deleteAll)', (tester) async {
    final store = MemoryUiPrefsStore();
    final picker = FakePicker()..next = _photo;
    await pumpMe(tester, store, picker);
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('hero-gallery')));
    await tester.pumpAndSettle();
    expect(store.images, isNotEmpty);
    await store.deleteAll();
    expect(store.images, isEmpty);
    expect(store.prefs.meHero, isNull);
  });

  for (final (width, scale) in [(320.0, 1.5), (390.0, 2.0)]) {
    testWidgets('the Me hero fits at ${width}pt, $scale× text', (tester) async {
      await pumpMe(
        tester,
        MemoryUiPrefsStore(),
        FakePicker(),
        width: width,
        scale: scale,
      );
      expect(tester.takeException(), isNull);
      await open(tester);
      expect(find.byKey(const ValueKey('hero-camera')), findsOneWidget);
      expect(tester.takeException(), isNull);
      final edit = tester.getSize(find.byKey(const ValueKey('me-hero-edit')));
      expect(edit.width, greaterThanOrEqualTo(44));
      expect(edit.height, greaterThanOrEqualTo(44));
    });
  }
}
