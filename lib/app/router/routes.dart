import '../../core/design/widgets/moon_icon.dart';
import '../../core/domain/phase.dart';

/// The five tabs, in their fixed order: Home, Eat (Foods and Recipes), Move,
/// Relax (both "coming soon" for now) and More (settings and utilities).
enum AppTab {
  home('/home', 'Home', MoonIconName.home),
  eat('/eat', 'Eat', MoonIconName.recipes),
  move('/move', 'Move', MoonIconName.move),
  relax('/relax', 'Relax', MoonIconName.relax),
  more('/more', 'More', MoonIconName.more);

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

  /// Foods › the meal builder (Premium).
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

  /// Foods tab stack › the food diary (opened from Home).
  static const String diary = '/more/diary';

  /// Foods tab stack › 3 Plants a Day (opened from Home).
  static const String threePlants = '/eat/three-plants';

  /// Recipes › the user's own generated recipes.
  static const String myRecipes = '/eat/my-recipes';

  /// Foods › the recipes that match the foods chosen in the meal builder.
  /// The chosen foods travel as ids in the query.
  ///
  /// [fromPlants] marks a search started from 3 Plants a Day, which is free
  /// (Build a meal itself is Premium).
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

  /// More › Credits & Sources.
  static const String credits = '/more/credits';
  static String settings(SettingsPage page) =>
      '${AppTab.more.path}/${page.segment}';
}
