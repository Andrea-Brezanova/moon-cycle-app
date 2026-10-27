import '../../core/design/widgets/moon_icon.dart';
import '../../core/domain/local_date.dart';
import '../../core/domain/phase.dart';
import '../../features/diary/domain/diary_entry.dart';

/// The five tabs, in their fixed order: Home, Eat (Foods and Recipes), Move,
/// Relax (both "coming soon" for now) and Me (My Collections, diary,
/// shopping list and settings; the route stays `/more`).
enum AppTab {
  home('/home', 'Home', MoonIconName.home),
  eat('/eat', 'Eat', MoonIconName.recipes),
  move('/move', 'Move', MoonIconName.move),
  relax('/relax', 'Relax', MoonIconName.relax),
  more('/more', 'Me', MoonIconName.account);

  const AppTab(this.path, this.label, this.icon);

  /// The tab's first screen.
  final String path;
  final String label;
  final MoonIconName icon;
}

/// Settings sub-pages in v1 (no Account page until accounts arrive).
enum SettingsPage {
  myCycle('my-cycle', 'My Cycle'),
  foodPreferences('food-preferences', 'Food Preferences'),
  allergies('allergies', 'Allergies & foods to avoid'),
  notifications('notifications', 'Notifications'),
  appearance('appearance', 'Appearance'),
  subscription('subscription', 'Subscription'),
  privacy('privacy', 'Privacy & Data'),
  help('help', 'Help'),
  deleteData('delete-data', 'Delete my data');

  const SettingsPage(this.segment, this.title);

  final String segment;
  final String title;
}

/// Every route path in one place.
abstract final class Routes {
  static const String onboarding = '/onboarding';
  static const String onboardingLastPeriod = '/onboarding/last-period';
  static const String onboardingCycleLength = '/onboarding/cycle-length';
  static const String onboardingFoodPreferences =
      '/onboarding/food-preferences';
  static const String onboardingYourPhase = '/onboarding/your-phase';
  static const String home = '/home';

  /// Debug builds only; see `app_router.dart`.
  static const String debugGallery = '/debug/gallery';

  /// Foods › "Learn more" about the viewing phase.
  static const String learnMore = '/eat/learn';

  /// The Foods and Recipes browsing pages, opened from the Eat hub.
  static const String eatFoods = '/eat/foods';
  static const String eatRecipes = '/eat/recipes';

  /// Foods › the meal builder (free).
  /// With [foodId] the builder opens with that food already chosen.
  static String mealBuilder({String? foodId}) =>
      '/eat/meal-builder${foodId == null ? '' : '?food=$foodId'}';

  /// A food's page. [phase] is the phase whose "Why this food?" it shows;
  /// [general] opens it without phase context (a suggestion from outside the
  /// phase), so no phase rationale is shown.
  static String food(String id, {Phase? phase, bool general = false}) {
    final query = [
      if (phase != null) 'phase=${phase.name}',
      if (general) 'general=1',
    ].join('&');
    return '/eat/food/$id${query.isEmpty ? '' : '?$query'}';
  }

  /// More › My Diary › entries: the history by day. [date] opens that day;
  /// [symptoms] opens the Symptoms tab.
  static String diaryOn({LocalDate? date, bool symptoms = false}) {
    final q = [
      if (date != null) 'date=$date',
      if (symptoms) 'tab=symptoms',
    ].join('&');
    return '$diaryEntries${q.isEmpty ? '' : '?$q'}';
  }

  /// More › My Diary: the landing hub.
  static const String diary = '/more/diary';

  /// The diary history (Meals and Symptoms by day).
  static const String diaryEntries = '/more/diary/entries';

  /// The activities: the list, a new activity (on [date], today if null) and
  /// one to read and edit. The editor covers the tab bar, so it opens on the
  /// root navigator.
  static const String diaryActivities = '/more/diary/activities';
  static String diaryActivityNew({LocalDate? date}) =>
      '$diaryActivities/new${date == null ? '' : '?date=$date'}';
  static String diaryActivity(String id) => '$diaryActivities/$id';

  /// The diary notes: the list, a new note (on [date], today if null) and one
  /// note to read and edit. Writing covers the tab bar, so the editor opens on
  /// the root navigator.
  static const String diaryNotes = '/more/diary/notes';
  static String diaryNoteNew({LocalDate? date}) =>
      '$diaryNotes/new${date == null ? '' : '?date=$date'}';
  static String diaryNote(String id) => '$diaryNotes/$id';

  /// The Log a meal form (a full screen over the tab bar). Pass what to add
  /// ([kind], [itemId], [title]), a [meal] and [date] to preselect, or
  /// [editId] to edit an entry. [from] (`food` or `recipe`) says which page it
  /// was opened from.
  static String logMeal({
    DiaryMeal? meal,
    DiaryItemKind? kind,
    String? itemId,
    String? title,
    LocalDate? date,
    String? editId,
    String? from,
  }) => Uri(
    path: '/more/diary/log-meal',
    queryParameters: {
      'meal': ?meal?.name,
      'kind': ?kind?.name,
      'item': ?itemId,
      'title': ?title,
      'date': ?date?.toString(),
      'edit': ?editId,
      'from': ?from,
    },
  ).toString();

  /// The Log symptoms form for [date] (today when null).
  static String logSymptoms({LocalDate? date}) => Uri(
    path: '/more/diary/log-symptoms',
    queryParameters: {'date': ?date?.toString()},
  ).toString();

  /// Foods tab stack › 3 Plants a Day (opened from Home).
  static const String threePlants = '/eat/three-plants';

  /// Recipes › the user's own generated recipes.
  static const String myRecipes = '/eat/my-recipes';

  /// Write your own recipe, and edit one (on the root navigator: writing
  /// covers the tab bar).
  static const String addRecipe = '/eat/my-recipes/add';
  static String editRecipe(String id) => '/eat/my-recipes/edit/$id';

  /// Foods › the recipes that match the foods chosen in the meal builder.
  /// The chosen foods travel as ids in the query.
  ///
  /// [fromPlants] marks a search started from 3 Plants a Day, which is free
  /// (Build a meal is free too).
  static String mealResults(List<String> foodIds, {bool fromPlants = false}) =>
      '/eat/meal-builder/results?foods=${foodIds.join(',')}'
      '${fromPlants ? '&from=plants' : ''}';

  /// Foods › creating a new recipe for the same choice (the fallback).
  static String mealCreate({
    required String protein,
    required String base,
    required List<String> plants,
  }) =>
      '/eat/meal-builder/create?protein=$protein&base=$base'
      '&plants=${plants.join(',')}';

  static String recipe(String id) => '/eat/recipe/$id';

  /// More › the shopping list.
  static const String shopping = '/more/shopping-list';

  /// Me › My App, and My App › About.
  static const String myApp = '/more/my-app';
  static const String meAbout = '/more/about';

  /// Me › My Collections, and its Workouts and Spa pages (My Recipes is the
  /// existing [myRecipes]).
  static const String collections = '/more/collections';
  static const String collectionWorkouts = '/more/collections/workouts';
  static const String collectionSpa = '/more/collections/spa';
  static const String collectionRoutines = '/more/collections/routines';

  /// A saved link: add one (in [category], a `LinkCategory` name), open one's
  /// details, or edit it. The form covers the tab bar.
  static String collectionLinkNew({String? category}) =>
      '/more/collections/link/new${category == null ? '' : '?category=$category'}';
  static String collectionLink(String id) => '/more/collections/link/$id';
  static String collectionLinkEdit(String id) =>
      '/more/collections/link/$id/edit';

  /// Move › Build Your Workout.
  static const String buildWorkout = '/move/build-workout';

  /// The Move and Relax libraries (by [kind], a `HubKind` name) and one item.
  static String hubLibrary(AppTab tab, String kind) =>
      '${tab.path}/library/$kind';
  static String hubItem(AppTab tab, String id) => '${tab.path}/item/$id';

  /// More › Credits & Sources.
  static const String credits = '/more/credits';
  static String settings(SettingsPage page) =>
      '${AppTab.more.path}/${page.segment}';
}
