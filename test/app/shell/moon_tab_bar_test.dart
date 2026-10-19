import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/router/routes.dart';
import 'package:moon_cycle/app/shell/moon_tab_bar.dart';
import 'package:moon_cycle/core/design/moon_theme.dart';

Future<void> pumpBar(
  WidgetTester tester, {
  AppTab current = AppTab.home,
  double bottomInset = 0,
  ValueChanged<AppTab>? onSelect,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: moonTheme(Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          padding: EdgeInsets.only(bottom: bottomInset),
        ),
        child: Scaffold(
          bottomNavigationBar: MoonTabBar(
            current: current,
            onSelect: onSelect ?? (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('five tabs in order', (tester) async {
    await pumpBar(tester);
    final xs = [
      for (final t in AppTab.values)
        tester.getCenter(find.byKey(ValueKey('tab-${t.name}'))).dx,
    ];
    expect(xs, orderedEquals([...xs]..sort()));
    expect(AppTab.values.map((t) => t.label), [
      'Home',
      'Eat',
      'Move',
      'Relax',
      'More',
    ]);
  });

  testWidgets('only the active tab has the dot, SemiBold and selected', (
    tester,
  ) async {
    await pumpBar(tester, current: AppTab.eat);
    final dot = find.byKey(const ValueKey('tab-active-dot'));
    expect(dot, findsOneWidget);
    expect(
      find.descendant(of: find.byKey(const ValueKey('tab-eat')), matching: dot),
      findsOneWidget,
    );
    final active = tester.widget<Text>(find.text('Eat'));
    final inactive = tester.widget<Text>(find.text('Move'));
    expect(active.style!.fontWeight, FontWeight.w600);
    expect(inactive.style!.fontWeight, FontWeight.w500);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('tab-eat'))),
      isSemantics(
        label: 'Eat',
        isSelected: true,
        isButton: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('reports the tapped tab', (tester) async {
    AppTab? tapped;
    await pumpBar(tester, onSelect: (t) => tapped = t);
    await tester.tap(find.byKey(const ValueKey('tab-more')));
    expect(tapped, AppTab.more);
  });

  testWidgets('88 pt including the home indicator; taller for larger insets', (
    tester,
  ) async {
    for (final (inset, height) in [(0.0, 88.0), (34.0, 88.0), (48.0, 102.0)]) {
      await pumpBar(tester, bottomInset: inset);
      expect(
        tester.getSize(find.byType(MoonTabBar)).height,
        height,
        reason: 'inset $inset',
      );
    }
  });
}
