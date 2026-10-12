import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/design/moon_theme.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/content/application/content_providers.dart';

import 'pump_app.dart';
import 'test_catalogue.dart';

/// Saturday 4 October 2025, the design's sample day.
DateTime designNow() => DateTime(2025, 10, 4, 9);

/// Pumps [screen] in the design frame: 390 × 844 pt with the iPhone status
/// bar (47) and home indicator (34), in light or dark.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  required bool dark,
  List<Override> overrides = const [],
  AppDatabase? database,
  double height = 844,
}) async {
  tester.view.physicalSize = Size(390, height) * 2;
  tester.view.devicePixelRatio = 2;
  tester.view.padding = const FakeViewPadding(top: 47 * 2, bottom: 34 * 2);
  tester.view.viewPadding = const FakeViewPadding(top: 47 * 2, bottom: 34 * 2);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database ?? testDatabase()),
        catalogueProvider.overrideWithValue(testCatalogue),
        clockProvider.overrideWithValue(designNow),
        ...overrides,
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: moonTheme(dark ? Brightness.dark : Brightness.light),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Both themes, as `light` / `dark`.
const themes = {'light': false, 'dark': true};
