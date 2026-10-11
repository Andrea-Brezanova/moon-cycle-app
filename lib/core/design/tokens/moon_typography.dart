import 'package:flutter/painting.dart';

/// Font family names, as registered in pubspec.yaml.
abstract final class MoonFonts {
  /// Fraunces optical size 72: use at 40 pt and up (Light, Regular, Italic).
  static const String fraunces72 = 'Fraunces72';

  /// Fraunces optical size 24: below 40 pt (Regular, Medium and italics).
  static const String fraunces24 = 'Fraunces24';

  static const String dmSans = 'DMSans';

  /// Only for the "mooncycle" wordmark; prefer the outlined SVG.
  static const String gwendolyn = 'Gwendolyn';
}

/// A Fraunces style. Picks the optical cut by size, as the design does.
///
/// [height] is a CSS-style line-height multiplier; [tracking] is in em.
/// Half the extra leading goes above the text and half below, as in CSS.
/// No decoration, so text never inherits Flutter's debug underline.
TextStyle fraunces(
  double size, {
  FontWeight weight = FontWeight.w400,
  bool italic = false,
  double height = 1.08,
  double tracking = -0.02,
  Color? color,
}) {
  final display = size >= 40;
  assert(
    display
        ? (italic ? weight == FontWeight.w400 : weight.value <= 400)
        : (weight == FontWeight.w400 || weight == FontWeight.w500),
    'Fraunces ${display ? '72pt' : '24pt'} cut has no ${weight.value}'
    '${italic ? ' italic' : ''}',
  );
  return TextStyle(
    fontFamily: display ? MoonFonts.fraunces72 : MoonFonts.fraunces24,
    fontSize: size,
    fontWeight: weight,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    height: height,
    letterSpacing: size * tracking,
    leadingDistribution: TextLeadingDistribution.even,
    decoration: TextDecoration.none,
    color: color,
  );
}

/// A DM Sans style. [height] is a CSS-style line-height multiplier.
TextStyle dmSans(
  double size, {
  FontWeight weight = FontWeight.w400,
  double height = 1.5,
  double tracking = 0,
  Color? color,
}) => TextStyle(
  fontFamily: MoonFonts.dmSans,
  fontSize: size,
  fontWeight: weight,
  height: height,
  letterSpacing: size * tracking,
  leadingDistribution: TextLeadingDistribution.even,
  decoration: TextDecoration.none,
  color: color,
);

/// The Editorial type scale (`design/code/theme.ts` › `type`, spec §4).
/// Colours are applied by the widget using the style.
abstract final class MoonType {
  static final TextStyle dayNumber = fraunces(
    100,
    weight: FontWeight.w300,
    height: 1,
    tracking: -0.035,
  );
  static final TextStyle shopCount = fraunces(
    72,
    weight: FontWeight.w300,
    height: 0.9,
    tracking: -0.04,
  );
  static final TextStyle stepperValue = fraunces(
    72,
    weight: FontWeight.w300,
    height: 1,
    tracking: -0.03,
  );
  static final TextStyle h1Reveal = fraunces(54, height: 1);
  static final TextStyle phaseName = fraunces(48, height: 1);
  static final TextStyle h1 = fraunces(44, height: 1);
  static final TextStyle h1Welcome = fraunces(44, height: 1.04);
  static final TextStyle subScreenTitle = fraunces(40, height: 1.04);
  static final TextStyle h2 = fraunces(36);
  static final TextStyle h3 = fraunces(26, weight: FontWeight.w500);
  static final TextStyle categoryHead = fraunces(22, weight: FontWeight.w500);
  static final TextStyle cardTitle = fraunces(
    21,
    weight: FontWeight.w500,
    height: 1.2,
  );
  static final TextStyle season = fraunces(18, italic: true);
  static final TextStyle bodyL = dmSans(17);
  static final TextStyle body = dmSans(16, height: 1.55);
  static final TextStyle rowLabel = dmSans(
    17,
    weight: FontWeight.w500,
    height: 1.25,
  );
  static final TextStyle button = dmSans(
    16,
    weight: FontWeight.w600,
    height: 1,
  );
  static final TextStyle ui = dmSans(15, weight: FontWeight.w500, height: 1.3);
  static final TextStyle small = dmSans(
    13,
    weight: FontWeight.w500,
    height: 1.4,
  );
  static final TextStyle micro = dmSans(
    12,
    weight: FontWeight.w500,
    height: 1.3,
  );
  static final TextStyle tab = dmSans(11, weight: FontWeight.w500, height: 1);

  /// Shown in upper case by the `Overline` widget.
  static final TextStyle overline = dmSans(
    12,
    weight: FontWeight.w600,
    height: 1.2,
    tracking: 0.14,
  );
}
