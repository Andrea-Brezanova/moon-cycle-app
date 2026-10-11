import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/design/debug/component_gallery.dart';
import 'package:moon_cycle/core/design/moon_theme.dart';

/// Renders every component in both themes, at the design width (390), the
/// smallest supported width (320) and the largest text size (1.5×). Any
/// layout overflow or exception fails the test.
void main() {
  for (final dark in [false, true]) {
    for (final (width, scale) in [(390.0, 1.0), (320.0, 1.0), (390.0, 1.5)]) {
      testWidgets('${dark ? 'dark' : 'light'}, $width pt wide, text ×$scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 16000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: moonTheme(dark ? Brightness.dark : Brightness.light),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 16000),
                textScaler: TextScaler.linear(scale),
              ),
              child: Scaffold(
                body: GalleryContent(dark: dark, scrollable: false),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Cycle length'), findsWidgets);
      });
    }
  }
}
