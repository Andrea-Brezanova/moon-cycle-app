import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens/moon_colors.dart';
import 'tokens/moon_typography.dart';

/// The app theme for [brightness]. Editorial widgets read their colours from
/// the [MoonColors] extension (`context.moon`); the Material parts are set
/// only so that any stock widget still looks at home.
ThemeData moonTheme(Brightness brightness) {
  final c = brightness == Brightness.light ? MoonColors.light : MoonColors.dark;
  return ThemeData(
    brightness: brightness,
    useMaterial3: true,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    fontFamily: MoonFonts.dmSans,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.inverseBg,
      onPrimary: c.inverseText,
      secondary: c.ochre,
      onSecondary: c.onOchre,
      error: c.destructive,
      onError: c.onDestructive,
      surface: c.bg,
      onSurface: c.text,
    ),
    textTheme: TextTheme(
      bodyMedium: MoonType.body.copyWith(color: c.text),
      bodyLarge: MoonType.bodyL.copyWith(color: c.text),
    ),
    // The design has no ink ripples; pressed states are drawn explicitly.
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    extensions: [c],
  );
}

extension MoonThemeContext on BuildContext {
  /// The Editorial colours for the current theme.
  MoonColors get moon => Theme.of(this).extension<MoonColors>()!;
}

/// Status bar and navigation bar styling for a page of [brightness]:
/// transparent bars (edge to edge), dark icons on light pages and light icons
/// on dark ones (spec §10).
SystemUiOverlayStyle moonStatusBar(Brightness brightness) =>
    (brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark)
        .copyWith(
          statusBarColor: const Color(0x00000000),
          systemNavigationBarColor: const Color(0x00000000),
          systemNavigationBarContrastEnforced: false,
        );
