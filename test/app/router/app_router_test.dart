import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moon_cycle/app/config/app_config.dart';
import 'package:moon_cycle/app/router/app_router.dart';
import 'package:moon_cycle/app/router/routes.dart';
import 'package:moon_cycle/core/design/debug/component_gallery.dart';
import 'package:moon_cycle/core/design/moon_theme.dart';

import '../../helpers/pump_app.dart';

final homeRoot = find.text(
  'Placeholder. The real screen arrives in Milestone 8.',
);
final onboardingPage = find.text(
  'Placeholder. The onboarding screens arrive in Milestone 7.',
);

GoRouter routerOf(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));

void main() {
  group('onboarding gate', () {
    testWidgets('completed: the app opens on Home', (tester) async {
      await pumpApp(tester);
      expect(homeRoot, findsOneWidget);
      expect(onboardingPage, findsNothing);
    });

    testWidgets('completed: /onboarding goes to Home', (tester) async {
      await pumpApp(tester);
      routerOf(tester).go(Routes.onboarding);
      await tester.pumpAndSettle();
      expect(homeRoot, findsOneWidget);
    });

    testWidgets('not completed: every route goes to onboarding', (
      tester,
    ) async {
      await pumpApp(tester, onboarded: false);
      expect(onboardingPage, findsOneWidget);
      for (final path in [
        Routes.home,
        AppTab.recipes.path,
        Routes.recipe('sample'),
        Routes.settings(SettingsPage.myCycle),
      ]) {
        routerOf(tester).go(path);
        await tester.pumpAndSettle();
        expect(onboardingPage, findsOneWidget, reason: path);
      }
    });

    testWidgets('completing onboarding opens Home', (tester) async {
      await pumpApp(tester, onboarded: false);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(homeRoot, findsOneWidget);
    });
  });

  testWidgets('unknown paths go Home', (tester) async {
    await pumpApp(tester);
    routerOf(tester).go('/not-a-page');
    await tester.pumpAndSettle();
    expect(homeRoot, findsOneWidget);
  });

  group('debug component gallery', () {
    Future<void> pumpRouter(
      WidgetTester tester, {
      required bool includeDebugRoutes,
    }) async {
      final router = buildAppRouter(
        isOnboarded: () => true,
        refresh: ValueNotifier(true),
        includeDebugRoutes: includeDebugRoutes,
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(
              const AppConfig(flavor: Flavor.dev),
            ),
          ],
          child: _App(router: router),
        ),
      );
      await tester.pumpAndSettle();
      router.go(Routes.debugGallery);
      await tester.pumpAndSettle();
    }

    testWidgets('reachable in debug builds', (tester) async {
      await pumpRouter(tester, includeDebugRoutes: true);
      expect(find.byType(ComponentGallery), findsOneWidget);
    });

    testWidgets('not a route at all without debug routes (release)', (
      tester,
    ) async {
      await pumpRouter(tester, includeDebugRoutes: false);
      expect(find.byType(ComponentGallery), findsNothing);
      expect(homeRoot, findsOneWidget);
    });
  });
}

class _App extends StatelessWidget {
  const _App({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    theme: moonTheme(Brightness.light),
    routerConfig: router,
  );
}
