/// Settings › Appearance. [system] follows the phone's light or dark setting
/// and is the default; [light] and [dark] always use that Moon Cycle theme.
enum AppearanceMode {
  system('System', 'Match your phone'),
  light('Light', 'Always light'),
  dark('Dark', 'Always dark');

  const AppearanceMode(this.label, this.summary);

  final String label;
  final String summary;

  /// The stored value for [name], or [system] if it is missing or unknown.
  static AppearanceMode fromName(String? name) => AppearanceMode.values
      .firstWhere((m) => m.name == name, orElse: () => AppearanceMode.system);
}
