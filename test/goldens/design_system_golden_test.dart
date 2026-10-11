@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/design/debug/component_gallery.dart';
import 'package:moon_cycle/core/design/moon_theme.dart';
import 'package:moon_cycle/core/design/tokens/hero_tokens.dart';
import 'package:moon_cycle/core/design/widgets/moon_orbit.dart';
import 'package:moon_cycle/core/domain/phase.dart';

import '../helpers/moon_fonts.dart';

/// Screenshots of the design system, rendered with the real fonts.
///
/// They are made on macOS and are skipped in CI (tag `golden`), because font
/// rasterisation differs slightly between platforms. Regenerate after an
/// intentional visual change with:
///   flutter test --tags golden --update-goldens
const sections = [
  'header',
  'colours',
  'type',
  'buttons',
  'selection',
  'controls',
  'subscreen',
  'stepper',
  'calendar',
  'inputs',
  'states',
  'sheet',
  'hero',
  'brand',
];

void main() {
  setUpAll(loadMoonFonts);

  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';

    testWidgets('gallery sections, $theme', (tester) async {
      tester.view.physicalSize = const Size(390, 9000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: moonTheme(dark ? Brightness.dark : Brightness.light),
          home: Scaffold(body: GalleryContent(dark: dark, scrollable: false)),
        ),
      );
      await tester.pumpAndSettle();
      for (final s in sections) {
        await expectLater(
          find.byKey(ValueKey('gallery-$s')),
          matchesGoldenFile('goldens/${theme}_$s.png'),
        );
      }
    });

    testWidgets('moon in every phase, and late, $theme', (tester) async {
      tester.view.physicalSize = const Size(1600, 340);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const segments = [
        OrbitSegment(Phase.menstrual, 1, 5),
        OrbitSegment(Phase.follicular, 6, 11),
        OrbitSegment(Phase.ovulatory, 12, 15),
        OrbitSegment(Phase.luteal, 16, 28),
      ];
      const cases = [
        (Phase.menstrual, 2, 2),
        (Phase.follicular, 7, 7),
        (Phase.ovulatory, 13, 13),
        (Phase.luteal, 21, 21),
        (
          Phase.luteal,
          28,
          32,
        ), // 4 days late: dot pinned, number keeps counting
      ];
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: moonTheme(dark ? Brightness.dark : Brightness.light),
          home: Builder(
            builder: (context) => RepaintBoundary(
              key: const ValueKey('moons'),
              child: ColoredBox(
                color: context.moon.bg,
                child: Row(
                  children: [
                    for (final (phase, marker, number) in cases)
                      ColoredBox(
                        color: dark
                            ? HeroTokens.darkSolid
                            : HeroTokens.lightWash[phase]!,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: MoonOrbit(
                            dark: dark,
                            haloColor: dark
                                ? HeroTokens.darkSolid
                                : HeroTokens.lightWash[phase]!,
                            spec: MoonOrbitSpec(
                              segments: segments,
                              cycleLength: 28,
                              activePhase: phase,
                              markerDay: marker,
                              dayNumber: number,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('moons')),
        matchesGoldenFile('goldens/${theme}_moons.png'),
      );
    });
  }
}
