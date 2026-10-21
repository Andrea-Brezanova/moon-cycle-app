import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/database/app_database.dart';
import 'package:moon_cycle/core/design/moon_theme.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/content/application/content_providers.dart';
import 'package:moon_cycle/features/discovery/application/discovery_providers.dart';

import 'package:moon_cycle/features/discovery/data/providers/provider_http.dart';

import 'offline_network.dart';
import 'pump_app.dart';
import 'test_catalogue.dart';

/// Saturday 4 October 2025, the design's sample day.
DateTime designNow() => DateTime(2025, 10, 4, 9);

/// Pumps [screen] in the design frame: 390 × 844 pt with the iPhone status
/// bar (47) and home indicator (34), in light or dark. [width] and
/// [textScale] check narrow phones and large text.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  required bool dark,
  List<Override> overrides = const [],
  AppDatabase? database,
  double height = 844,
  double width = 390,
  double textScale = 1,
  HttpGet providerHttp = offlineGet,
}) async {
  tester.view.physicalSize = Size(width, height) * 2;
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
        providerHttpGetProvider.overrideWithValue(providerHttp),
        ...overrides,
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: moonTheme(dark ? Brightness.dark : Brightness.light),
        builder: textScale == 1
            ? null
            : (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await settleImages(tester);
}

/// Decodes every image on screen (recipe photos are bundled assets) so a
/// golden never captures a half-loaded frame.
Future<void> settleImages(WidgetTester tester) async {
  final images = tester.widgetList<Image>(find.byType(Image)).toList();
  if (images.isEmpty) return;
  final context = tester.element(find.byType(Image).first);
  await tester.runAsync(() async {
    for (final image in images) {
      await precacheImage(image.image, context, onError: (_, _) {});
    }
  });
  await tester.pumpAndSettle();
}

/// Both themes, as `light` / `dark`.
const themes = {'light': false, 'dark': true};
