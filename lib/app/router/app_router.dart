import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/debug/component_gallery.dart';
import '../../core/design/widgets/moon_icon.dart';
import '../../core/domain/local_date.dart';
import '../../core/domain/phase.dart';
import '../../features/collections/application/collections_providers.dart';
import '../../features/collections/domain/collection_link.dart';
import '../../features/collections/presentation/collection_category_page.dart';
import '../../features/collections/presentation/collection_link_detail_page.dart';
import '../../features/collections/presentation/collection_link_page.dart';
import '../../features/collections/presentation/collections_page.dart';
import '../../features/credits/presentation/credits_page.dart';
import '../../features/diary/domain/diary_entry.dart';
import '../../features/diary/presentation/diary_activities_page.dart';
import '../../features/diary/presentation/diary_activity_editor_page.dart';
import '../../features/diary/presentation/diary_hub_page.dart';
import '../../features/diary/presentation/diary_note_editor_page.dart';
import '../../features/diary/presentation/diary_notes_page.dart';
import '../../features/diary/presentation/diary_page.dart';
import '../../features/diary/presentation/log_meal_page.dart';
import '../../features/diary/presentation/log_symptoms_page.dart';
import '../../features/discovery/domain/recipe_matcher.dart';
import '../../features/discovery/presentation/meal_results_page.dart';
import '../../features/eat/application/eat_segment.dart';
import '../../features/eat/presentation/eat_browse_page.dart';
import '../../features/eat/presentation/eat_page.dart';
import '../../features/foods/presentation/food_detail_page.dart';
import '../../features/foods/presentation/learn_more_page.dart';
import '../../features/foods/presentation/meal_builder_page.dart';
import '../../features/generation/domain/balanced_selection.dart';
import '../../features/generation/presentation/add_recipe_page.dart';
import '../../features/generation/presentation/create_recipe_page.dart';
import '../../features/generation/presentation/my_recipes_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/onboarding/application/onboarding_status.dart';
import '../../features/onboarding/presentation/cycle_length_page.dart';
import '../../features/onboarding/presentation/food_preferences_page.dart';
import '../../features/onboarding/presentation/last_period_page.dart';
import '../../features/onboarding/presentation/phase_reveal_page.dart';
import '../../features/onboarding/presentation/welcome_page.dart';
import '../../features/placeholders/presentation/coming_soon_page.dart';
import '../../features/plants/presentation/three_plants_page.dart';
import '../../features/recipes/presentation/recipe_detail_page.dart';
import '../../features/settings/presentation/account_plus_page.dart';
import '../../features/settings/presentation/allergies_page.dart';
import '../../features/settings/presentation/appearance_page.dart';
import '../../features/settings/presentation/delete_data_page.dart';
import '../../features/settings/presentation/food_preferences_page.dart';
import '../../features/settings/presentation/help_page.dart';
import '../../features/settings/presentation/my_cycle_page.dart';
import '../../features/settings/presentation/notifications_page.dart';
import '../../features/settings/presentation/privacy_data_page.dart';
import '../../features/settings/presentation/settings_home_page.dart';
import '../../features/settings/presentation/settings_hub_page.dart';
import '../../features/settings/presentation/subscription_page.dart';
import '../../features/shopping/presentation/shop_page.dart';
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
      final atOnboarding = state.matchedLocation.startsWith(Routes.onboarding);
      if (!isOnboarded()) return atOnboarding ? null : Routes.onboarding;
      if (atOnboarding) return Routes.home;
      return null;
    },
    // Unknown paths (and the gallery path in release builds) go Home.
    onException: (context, state, router) => router.go(Routes.home),
    routes: [
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (context, state) => _page(state, const WelcomePage()),
        routes: [
          GoRoute(
            path: 'last-period',
            pageBuilder: (context, state) =>
                _page(state, const LastPeriodPage()),
          ),
          GoRoute(
            path: 'cycle-length',
            pageBuilder: (context, state) =>
                _page(state, const CycleLengthPage()),
          ),
          GoRoute(
            path: 'food-preferences',
            pageBuilder: (context, state) =>
                _page(state, const FoodPreferencesPage()),
          ),
          GoRoute(
            path: 'your-phase',
            pageBuilder: (context, state) =>
                _page(state, const PhaseRevealPage()),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          for (final tab in AppTab.values)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: tab.path,
                  pageBuilder: (context, state) => _page(state, switch (tab) {
                    AppTab.home => const HomePage(),
                    AppTab.eat => const EatPage(),
                    AppTab.move => const ComingSoonPage(
                      title: 'Move',
                      icon: MoonIconName.move,
                    ),
                    AppTab.relax => const ComingSoonPage(
                      title: 'Relax',
                      icon: MoonIconName.relax,
                    ),
                    AppTab.more => const SettingsHomePage(),
                  }),
                  routes: switch (tab) {
                    AppTab.eat => [
                      GoRoute(
                        path: 'foods',
                        pageBuilder: (context, state) => _page(
                          state,
                          const EatBrowsePage(segment: EatSegment.foods),
                        ),
                      ),
                      GoRoute(
                        path: 'recipes',
                        pageBuilder: (context, state) => _page(
                          state,
                          const EatBrowsePage(segment: EatSegment.recipes),
                        ),
                      ),
                      GoRoute(
                        path: 'my-recipes',
                        pageBuilder: (context, state) =>
                            _page(state, const MyRecipesPage()),
                        routes: [
                          GoRoute(
                            path: 'add',
                            parentNavigatorKey: rootKey,
                            pageBuilder: (context, state) =>
                                _page(state, const AddRecipePage()),
                          ),
                          GoRoute(
                            path: 'edit/:recipeId',
                            parentNavigatorKey: rootKey,
                            pageBuilder: (context, state) => _page(
                              state,
                              AddRecipePage(
                                recipeId: state.pathParameters['recipeId'],
                              ),
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'recipe/:recipeId',
                        pageBuilder: (context, state) => _page(
                          state,
                          RecipeDetailPage(
                            recipeId: state.pathParameters['recipeId']!,
                          ),
                        ),
                      ),

                      GoRoute(
                        path: 'learn',
                        pageBuilder: (context, state) =>
                            _page(state, const LearnMorePage()),
                      ),
                      GoRoute(
                        path: 'meal-builder',
                        pageBuilder: (context, state) => _page(
                          state,
                          MealBuilderPage(
                            foodId: state.uri.queryParameters['food'],
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'three-plants',
                        pageBuilder: (context, state) =>
                            _page(state, const ThreePlantsPage()),
                      ),
                      GoRoute(
                        path: 'meal-builder/results',
                        pageBuilder: (context, state) => _page(
                          state,
                          MealResultsPage(
                            choice: _choiceOf(state),
                            fromPlants:
                                state.uri.queryParameters['from'] == 'plants',
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'meal-builder/create',
                        pageBuilder: (context, state) => _page(
                          state,
                          CreateRecipePage(choice: _balancedOf(state)),
                        ),
                      ),
                      GoRoute(
                        path: 'food/:foodId',
                        pageBuilder: (context, state) => _page(
                          state,
                          FoodDetailPage(
                            foodId: state.pathParameters['foodId']!,
                            phase: Phase.values
                                .where(
                                  (p) =>
                                      p.name ==
                                      state.uri.queryParameters['phase'],
                                )
                                .firstOrNull,
                            general:
                                state.uri.queryParameters['general'] == '1',
                          ),
                        ),
                      ),
                    ],
                    AppTab.more => [
                      GoRoute(
                        path: 'diary',
                        pageBuilder: (context, state) =>
                            _page(state, const DiaryHubPage()),
                        routes: [
                          GoRoute(
                            path: 'entries',
                            pageBuilder: (context, state) => _page(
                              state,
                              DiaryPage(
                                initialDate: _dateOf(state),
                                initialSymptoms:
                                    state.uri.queryParameters['tab'] ==
                                    'symptoms',
                              ),
                            ),
                          ),
                          GoRoute(
                            path: 'activities',
                            pageBuilder: (context, state) =>
                                _page(state, const DiaryActivitiesPage()),
                            routes: [
                              GoRoute(
                                path: 'new',
                                parentNavigatorKey: rootKey,
                                pageBuilder: (context, state) => _page(
                                  state,
                                  DiaryActivityEditorPage(date: _dateOf(state)),
                                ),
                              ),
                              GoRoute(
                                path: ':activityId',
                                parentNavigatorKey: rootKey,
                                pageBuilder: (context, state) => _page(
                                  state,
                                  DiaryActivityEditorPage(
                                    activityId:
                                        state.pathParameters['activityId'],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          GoRoute(
                            path: 'notes',
                            pageBuilder: (context, state) =>
                                _page(state, const DiaryNotesPage()),
                            routes: [
                              // Writing covers the tab bar, so the editor
                              // opens on the root navigator.
                              GoRoute(
                                path: 'new',
                                parentNavigatorKey: rootKey,
                                pageBuilder: (context, state) => _page(
                                  state,
                                  DiaryNoteEditorPage(date: _dateOf(state)),
                                ),
                              ),
                              GoRoute(
                                path: ':noteId',
                                parentNavigatorKey: rootKey,
                                pageBuilder: (context, state) => _page(
                                  state,
                                  DiaryNoteEditorPage(
                                    noteId: state.pathParameters['noteId'],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // The forms cover the tab bar, so they open on the
                          // root navigator, above the shell.
                          GoRoute(
                            path: 'log-meal',
                            parentNavigatorKey: rootKey,
                            pageBuilder: (context, state) {
                              final q = state.uri.queryParameters;
                              return _page(
                                state,
                                LogMealPage(
                                  meal: DiaryMeal.values
                                      .where((m) => m.name == q['meal'])
                                      .firstOrNull,
                                  kind: DiaryItemKind.values
                                      .where((k) => k.name == q['kind'])
                                      .firstOrNull,
                                  itemId: q['item'],
                                  title: q['title'],
                                  date: _dateOf(state),
                                  editId: q['edit'],
                                  from: q['from'],
                                ),
                              );
                            },
                          ),
                          GoRoute(
                            path: 'log-symptoms',
                            parentNavigatorKey: rootKey,
                            pageBuilder: (context, state) => _page(
                              state,
                              LogSymptomsPage(date: _dateOf(state)),
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'collections',
                        pageBuilder: (context, state) =>
                            _page(state, const CollectionsPage()),
                        routes: [
                          GoRoute(
                            path: 'link/new',
                            parentNavigatorKey: rootKey,
                            pageBuilder: (context, state) => _page(
                              state,
                              CollectionLinkPage(
                                category: LinkCategory.fromKey(
                                  state.uri.queryParameters['category'] ?? '',
                                ),
                              ),
                            ),
                          ),
                          GoRoute(
                            path: 'link/:id',
                            pageBuilder: (context, state) => _page(
                              state,
                              CollectionLinkDetailPage(
                                linkId: state.pathParameters['id']!,
                              ),
                            ),
                            routes: [
                              GoRoute(
                                path: 'edit',
                                parentNavigatorKey: rootKey,
                                pageBuilder: (context, state) => _page(
                                  state,
                                  CollectionLinkPage(
                                    linkId: state.pathParameters['id'],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          for (final category in [
                            CollectionCategory.workouts,
                            CollectionCategory.spa,
                          ])
                            GoRoute(
                              path: category.name,
                              pageBuilder: (context, state) => _page(
                                state,
                                CollectionCategoryPage(category: category),
                              ),
                            ),
                        ],
                      ),
                      GoRoute(
                        path: 'shopping-list',
                        pageBuilder: (context, state) =>
                            _page(state, const ShopPage()),
                      ),
                      GoRoute(
                        path: 'credits',
                        pageBuilder: (context, state) =>
                            _page(state, const CreditsPage()),
                      ),
                      GoRoute(
                        path: 'settings',
                        pageBuilder: (context, state) =>
                            _page(state, const SettingsHubPage()),
                      ),
                      GoRoute(
                        path: 'account',
                        pageBuilder: (context, state) =>
                            _page(state, const AccountPlusPage()),
                      ),
                      for (final page in SettingsPage.values)
                        GoRoute(
                          path: page.segment,
                          parentNavigatorKey: page == SettingsPage.deleteData
                              ? rootKey
                              : null,
                          pageBuilder: (context, state) => _page(
                            state,
                            switch (page) {
                              SettingsPage.myCycle => const MyCyclePage(),
                              SettingsPage.foodPreferences =>
                                const FoodPreferencesSettingsPage(),
                              SettingsPage.allergies => const AllergiesPage(),
                              SettingsPage.notifications =>
                                const NotificationsPage(),
                              SettingsPage.appearance => const AppearancePage(),
                              SettingsPage.subscription =>
                                const SubscriptionPage(),
                              SettingsPage.privacy => const PrivacyDataPage(),
                              SettingsPage.help => const HelpPage(),
                              SettingsPage.deleteData => const DeleteDataPage(),
                            },
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

/// The `date=YYYY-MM-DD` query parameter, or null.
LocalDate? _dateOf(GoRouterState state) {
  final parts = state.uri.queryParameters['date']?.split('-');
  if (parts == null || parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  try {
    return LocalDate(y, m, d);
  } on ArgumentError {
    return null;
  }
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

/// The foods chosen for a meal, from the route's query (ids only).
MealChoice _choiceOf(GoRouterState state) => MealChoice([
  for (final id in (state.uri.queryParameters['foods'] ?? '').split(','))
    if (id.isNotEmpty) id,
]);

/// The structured input of the (currently unlinked) generation flow.
BalancedSelection _balancedOf(GoRouterState state) {
  final q = state.uri.queryParameters;
  return BalancedSelection(
    proteinId: q['protein'],
    baseId: q['base'],
    plantIds: [
      for (final id in (q['plants'] ?? '').split(','))
        if (id.isNotEmpty) id,
    ],
  );
}
