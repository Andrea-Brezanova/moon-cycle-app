import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/debug/component_gallery.dart';
import '../../features/onboarding/application/onboarding_status.dart';
import '../placeholders/placeholder_pages.dart';
import '../shell/main_shell.dart';
import 'routes.dart';

/// The app's router.
///
/// - The five tabs are a `StatefulShellRoute.indexedStack`: each tab keeps
///   its own stack, and switching tabs is instant.
/// - Recipe detail is inside the Recipes stack; Settings sub-pages inside the
///   Settings stack. "Delete my data" covers the tab bar (spec: no tab bar),
///   so it opens on the root navigator, above the shell.
/// - While onboarding isn't complete, every route goes to `/onboarding`.
/// - [includeDebugRoutes] adds the component gallery. It is `kDebugMode` in
///   the app, so release and profile builds never contain the route (or the
///   gallery code, which the compiler then drops).
GoRouter buildAppRouter({
  required bool Function() isOnboarded,
  required Listenable refresh,
  required bool includeDebugRoutes,
}) {
  final rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: Routes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final atOnboarding = state.matchedLocation == Routes.onboarding;
      if (!isOnboarded()) return atOnboarding ? null : Routes.onboarding;
      if (atOnboarding) return Routes.home;
      return null;
    },
    // Unknown paths (and the gallery path in release builds) go Home.
    onException: (context, state, router) => router.go(Routes.home),
    routes: [
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (context, state) =>
            _page(state, const PlaceholderOnboardingPage()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          for (final tab in AppTab.values)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: tab.path,
                  pageBuilder: (context, state) =>
                      _page(state, PlaceholderTabPage(tab: tab)),
                  routes: switch (tab) {
                    AppTab.recipes => [
                      GoRoute(
                        path: ':recipeId',
                        pageBuilder: (context, state) => _page(
                          state,
                          const PlaceholderSubPage(
                            title: 'Recipe',
                            backLabel: 'Recipes',
                            milestone: 11,
                          ),
                        ),
                      ),
                    ],
                    AppTab.settings => [
                      for (final page in SettingsPage.values)
                        GoRoute(
                          path: page.segment,
                          parentNavigatorKey: page == SettingsPage.deleteData
                              ? rootKey
                              : null,
                          pageBuilder: (context, state) => _page(
                            state,
                            PlaceholderSubPage(
                              title: page.title,
                              backLabel: 'Settings',
                              milestone: 13,
                            ),
                          ),
                        ),
                    ],
                    _ => const [],
                  },
                ),
              ],
            ),
        ],
      ),
      // `kDebugMode` is a compile-time constant: in release and profile
      // builds this branch, the route and the gallery code are removed.
      if (kDebugMode && includeDebugRoutes)
        GoRoute(
          path: Routes.debugGallery,
          pageBuilder: (context, state) => _page(
            state,
            ComponentGallery(
              initialDark: Theme.of(context).brightness == Brightness.dark,
            ),
          ),
        ),
    ],
  );
}

/// Every route uses a Material page explicitly, which gives the platform's
/// standard transitions: the iOS slide with swipe-back, and Android's
/// default. (go_router 18 otherwise looks for the `material_ui` package's
/// MaterialApp, which this app doesn't use, and would fall back to pages
/// without those transitions.)
Page<void> _page(GoRouterState state, Widget child) =>
    MaterialPage<void>(key: state.pageKey, name: state.name, child: child);

/// The router, kept in sync with the onboarding status.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<bool>(ref.read(onboardingCompletedProvider));
  ref.listen(onboardingCompletedProvider, (_, next) => refresh.value = next);
  final router = buildAppRouter(
    isOnboarded: () => ref.read(onboardingCompletedProvider),
    refresh: refresh,
    includeDebugRoutes: kDebugMode,
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
