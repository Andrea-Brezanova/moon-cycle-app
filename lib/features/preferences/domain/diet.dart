/// How the user eats (onboarding step 4, Settings › Food Preferences).
enum Diet {
  omnivore('Omnivore', 'Everything'),
  pescatarian('Pescatarian', 'No meat'),
  vegetarian('Vegetarian', 'No meat or fish'),
  vegan('Vegan', 'No animal foods');

  const Diet(this.label, this.summary);

  final String label;

  /// One-line explanation shown in Food Preferences.
  final String summary;
}
