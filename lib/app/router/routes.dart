import '../../core/design/widgets/moon_icon.dart';

/// The five tabs, in their fixed order (PRD §3).
enum AppTab {
  home('/home', 'Home', MoonIconName.home),
  foods('/foods', 'Foods', MoonIconName.foods),
  recipes('/recipes', 'Recipes', MoonIconName.recipes),
  shop('/shop', 'Shop', MoonIconName.shop),
  settings('/settings', 'Settings', MoonIconName.settings);

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

  static String recipe(String id) => '${AppTab.recipes.path}/$id';
  static String settings(SettingsPage page) =>
      '${AppTab.settings.path}/${page.segment}';
}
