import 'package:flutter/painting.dart';

import '../../domain/phase.dart';

/// Home hero and onboarding reveal: backgrounds, moon and orbit
/// (`design/code/theme.ts`, spec §3.3 and §6).
///
/// The orbit's segment colours are the theme's phase palettes (accent for the
/// current phase, tint for the others); the values are identical.
abstract final class HeroTokens {
  /// Light mode: off-white with a faint wash of the phase colour (7%; 8% for
  /// ovulatory because yellow reads lighter).
  static const Map<Phase, Color> lightWash = {
    Phase.menstrual: Color(0xFFFAF2EC),
    Phase.follicular: Color(0xFFF0F2EC),
    Phase.ovulatory: Color(0xFFFAF4E4),
    Phase.luteal: Color(0xFFF3EFF1),
  };

  /// Light-mode hero text: plum title and summary, muted meta line. The
  /// season label uses the phase's light `text` colour.
  static const Color lightText = Color(0xFF37255C);
  static const Color lightMuted = Color(0xFF5F527A);

  /// Dark mode: one night-plum background for every phase.
  static const Color darkTop = Color(0xFF37255C);
  static const Color darkSolid = Color(0xFF2E2150);
  static const Color darkEnd = Color(0xFF1B152E);
  static const Color darkText = Color(0xFFFFFDF8);
  static const Color darkSub = Color(0xFFEDE7F2);
  static const Color darkMuted = Color(0xFFC8C1D3);

  /// The background is solid until this far above the bottom, then fades
  /// into the page.
  static const double fadeHeight = 64;

  /// Moon gradient: two tints of the theme's ochre.
  static const Color moonLightInner = Color(0xFFF7EACB);
  static const Color moonLightOuter = Color(0xFFF2D99D);
  static const Color moonDarkInner = Color(0xFFFAEDCB);
  static const Color moonDarkOuter = Color(0xFFF7DE9C);

  /// "DAY" and the day number sit on the pale moon, so they stay plum in
  /// both themes.
  static const Color moonLabel = Color(0xFF5F527A);
  static const Color moonNumber = Color(0xFF37255C);

  /// Today dot: plum in light mode; cream with a phase-accent ring in dark.
  static const Color dotLight = Color(0xFF37255C);
  static const Color dotDark = Color(0xFFFFFDF8);
}

/// Moon and orbit geometry, in a 300 × 300 design space.
abstract final class OrbitGeometry {
  static const double viewBox = 300;
  static const double centre = 150;
  static const double radius = 136;
  static const double stroke = 12;

  /// Fraction of a full turn trimmed from each end of each segment, so the
  /// segments almost touch (like the logo).
  static const double gap = 0.0035;

  static const double moonRadius = 108;
  static const double dotHalo = stroke * 0.95; // 11.4
  static const double dot = stroke * 0.72; // 8.64
  static const double markerRingWidth = 2.6;

  /// Dark-mode glow: the phase accent at 30% opacity out to 68% of the
  /// radius, fading to nothing at [glowRadius].
  static const double glowRadius = 150;
  static const double glowInnerStop = 0.68;
  static const double glowOpacity = 0.30;

  /// Moon gradient centre and radius, relative to the moon (SVG cx 40%,
  /// cy 36%, r 70%).
  static const Alignment moonGradientCentre = Alignment(-0.2, -0.28);
  static const double moonGradientRadius = 0.7;
}
