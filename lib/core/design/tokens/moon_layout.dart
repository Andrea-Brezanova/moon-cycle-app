/// Spacing (`design/code/theme.ts` › `space`, spec §5).
abstract final class MoonSpace {
  static const double gutter = 24;
  static const double gutterOnboarding = 26;
  static const double sectionGap = 48;
  static const double foodsSectionGap = 34;
  static const double headerGap = 18;
  static const double chipGap = 8;
  static const double gridGap = 14;
}

/// Corner radii (`theme.ts` › `radius`, spec §5).
abstract final class MoonRadius {
  static const double pill = 999;
  static const double recipeFeature = 30;
  static const double shopBlock = 30;
  static const double sheet = 32;
  static const double calendar = 28;
  static const double lateCard = 28;
  static const double recipeCard = 26;
  static const double gridCard = 24;
  static const double infoNote = 20;
  static const double toast = 20;
  static const double foodRowPressed = 14;
}

/// Component sizes (`theme.ts` › `sizes`).
abstract final class MoonSize {
  static const double button = 56;
  static const double chip = 42;
  static const double dietPill = 44;
  static const double phaseSegment = 40;
  static const double foodRow = 52;
  static const double shopRow = 60;
  static const double settingsRow = 64;
  static const double checkbox = 26;
  static const double roundIconButton = 52;
  static const double iconButton = 44;
  static const double input = 52;
  static const double tabBar = 88;
  static const double tabIcon = 23;
  static const double activeDot = 5;
  static const double homeHero = 300;
  static const double onListMark = 22;
  static const double recipeCountIcon = 14;
  static const double toggleWidth = 51;
  static const double toggleHeight = 31;
}

/// Animation durations in milliseconds (`theme.ts` › `motion`).
abstract final class MoonMotion {
  static const Duration theme = Duration(milliseconds: 250);
  static const Duration orbit = Duration(milliseconds: 250);
  static const Duration sheet = Duration(milliseconds: 300);
}
