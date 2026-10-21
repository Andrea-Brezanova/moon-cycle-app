import 'package:flutter/material.dart';

import '../../domain/phase.dart';

/// Accent, text and tint colours for one phase.
///
/// - accent: the active orbit segment, phase dots.
/// - text: small coloured labels; passes 4.5:1 on the page.
/// - tint: inactive orbit segments, selected phase pill, on-list marks,
///   recipe placeholders.
@immutable
class PhasePalette {
  const PhasePalette({
    required this.accent,
    required this.text,
    required this.tint,
  });

  final Color accent;
  final Color text;
  final Color tint;

  static PhasePalette lerp(PhasePalette a, PhasePalette b, double t) =>
      PhasePalette(
        accent: Color.lerp(a.accent, b.accent, t)!,
        text: Color.lerp(a.text, b.text, t)!,
        tint: Color.lerp(a.tint, b.tint, t)!,
      );
}

/// The Editorial semantic colours (`design/code/theme.ts`, spec §3).
///
/// Widgets read these with `context.moon` and never use raw hex values.
@immutable
class MoonColors extends ThemeExtension<MoonColors> {
  const MoonColors({
    required this.bg,
    required this.raised,
    required this.sand,
    required this.line,
    required this.text,
    required this.textMuted,
    required this.inverseBg,
    required this.inverseText,
    required this.shopBlockBg,
    required this.shopBlockText,
    required this.shopBlockSub,
    required this.ochre,
    required this.onOchre,
    required this.checkboxBorder,
    required this.chevron,
    required this.removeIcon,
    required this.welcomeBg,
    required this.welcomeText,
    required this.welcomeBody,
    required this.destructive,
    required this.onDestructive,
    required this.scrim,
    required this.phases,
  });

  /// Page background.
  final Color bg;

  /// Inputs, tab bar, calendar card, info notes.
  final Color raised;

  /// Chips, round icon buttons, pressed rows, count pills.
  final Color sand;

  /// Hairline dividers, progress track.
  final Color line;

  /// Headings, body text, icons.
  final Color text;

  /// Secondary text, overlines, inactive tabs.
  final Color textMuted;

  /// Secondary button, pressed chip, selected date, checked checkbox.
  final Color inverseBg;
  final Color inverseText;

  /// "Your shopping list" block on Home.
  final Color shopBlockBg;
  final Color shopBlockText;
  final Color shopBlockSub;

  /// The one primary action, active-tab dot, progress, link underline.
  final Color ochre;
  final Color onOchre;

  final Color checkboxBorder;

  /// Chevron on food rows with no recipes.
  final Color chevron;

  /// × on shopping rows, Settings chevrons.
  final Color removeIcon;

  /// Onboarding welcome screen.
  final Color welcomeBg;
  final Color welcomeText;

  /// The welcome screen's body text (#E9E2F2 in both themes).
  final Color welcomeBody;

  /// The destructive button (Delete my data): Menstrual text colour.
  final Color destructive;
  final Color onDestructive;

  /// Behind bottom sheets.
  final Color scrim;

  final Map<Phase, PhasePalette> phases;

  PhasePalette phase(Phase p) => phases[p]!;

  static const light = MoonColors(
    bg: Color(0xFFFCFAF5),
    raised: Color(0xFFFFFFFF),
    sand: Color(0xFFECE3D2),
    line: Color(0xFFE3D9C8),
    text: Color(0xFF37255C),
    textMuted: Color(0xFF5F527A),
    inverseBg: Color(0xFF37255C),
    inverseText: Color(0xFFFCFAF5),
    shopBlockBg: Color(0xFF37255C),
    shopBlockText: Color(0xFFFCFAF5),
    shopBlockSub: Color(0xFFD9D0E6),
    ochre: Color(0xFFE4AC24),
    onOchre: Color(0xFF37255C),
    checkboxBorder: Color(0xFFB9AEC9),
    chevron: Color(0xFFC9C0D3),
    removeIcon: Color(0xFF9A8FAD),
    welcomeBg: Color(0xFF37255C),
    welcomeText: Color(0xFFFCFAF5),
    welcomeBody: Color(0xFFE9E2F2),
    destructive: Color(0xFFA0513D),
    onDestructive: Color(0xFFFCFAF5),
    scrim: Color(0x6B1B152E), // rgba(27, 21, 46, 0.42)
    phases: {
      Phase.menstrual: PhasePalette(
        accent: Color(0xFFE58E73),
        text: Color(0xFFA0513D),
        tint: Color(0xFFF3DCCD),
      ),
      Phase.follicular: PhasePalette(
        accent: Color(0xFF4F8A72),
        text: Color(0xFF3D6E5B),
        tint: Color(0xFFDCE4D5),
      ),
      Phase.ovulatory: PhasePalette(
        accent: Color(0xFFE4AC24),
        text: Color(0xFF86621A),
        tint: Color(0xFFF2E2BE),
      ),
      Phase.luteal: PhasePalette(
        accent: Color(0xFF7A63B8),
        text: Color(0xFF6550A6),
        tint: Color(0xFFE6DEEE),
      ),
    },
  );

  /// Dark mode is built on the onboarding purple.
  static const dark = MoonColors(
    bg: Color(0xFF1B152E),
    raised: Color(0xFF2A1F47),
    sand: Color(0xFF332650),
    line: Color(0xFF4A3C63),
    text: Color(0xFFFFFDF8),
    textMuted: Color(0xFFC8C1D3),
    inverseBg: Color(0xFFFFFDF8),
    inverseText: Color(0xFF1B152E),
    shopBlockBg: Color(0xFF2A1F47),
    shopBlockText: Color(0xFFFFFDF8),
    shopBlockSub: Color(0xFFC8C1D3),
    ochre: Color(0xFFF1B821),
    onOchre: Color(0xFF1B152E),
    checkboxBorder: Color(0xFF7A6D96),
    chevron: Color(0xFF6B5E87),
    removeIcon: Color(0xFF9A8FAD),
    welcomeBg: Color(0xFF2A1F47),
    welcomeText: Color(0xFFFFFDF8),
    welcomeBody: Color(0xFFE9E2F2),
    destructive: Color(0xFFF4B19C),
    onDestructive: Color(0xFF1B152E),
    scrim: Color(0x9E080512), // rgba(8, 5, 18, 0.62)
    phases: {
      Phase.menstrual: PhasePalette(
        accent: Color(0xFFEE9A80),
        text: Color(0xFFF4B19C),
        tint: Color(0xFF523843),
      ),
      Phase.follicular: PhasePalette(
        accent: Color(0xFF6FAA8F),
        text: Color(0xFFA3D3BC),
        tint: Color(0xFF313C47),
      ),
      Phase.ovulatory: PhasePalette(
        accent: Color(0xFFF1B821),
        text: Color(0xFFF6CC5E),
        tint: Color(0xFF533F2B),
      ),
      Phase.luteal: PhasePalette(
        accent: Color(0xFF9A86DA),
        text: Color(0xFFC3B6F1),
        tint: Color(0xFF3C325B),
      ),
    },
  );

  @override
  MoonColors copyWith() => this; // tokens are fixed; themes switch whole sets

  @override
  MoonColors lerp(covariant MoonColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return MoonColors(
      bg: l(bg, other.bg),
      raised: l(raised, other.raised),
      sand: l(sand, other.sand),
      line: l(line, other.line),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      inverseBg: l(inverseBg, other.inverseBg),
      inverseText: l(inverseText, other.inverseText),
      shopBlockBg: l(shopBlockBg, other.shopBlockBg),
      shopBlockText: l(shopBlockText, other.shopBlockText),
      shopBlockSub: l(shopBlockSub, other.shopBlockSub),
      ochre: l(ochre, other.ochre),
      onOchre: l(onOchre, other.onOchre),
      checkboxBorder: l(checkboxBorder, other.checkboxBorder),
      chevron: l(chevron, other.chevron),
      removeIcon: l(removeIcon, other.removeIcon),
      welcomeBg: l(welcomeBg, other.welcomeBg),
      welcomeText: l(welcomeText, other.welcomeText),
      welcomeBody: l(welcomeBody, other.welcomeBody),
      destructive: l(destructive, other.destructive),
      onDestructive: l(onDestructive, other.onDestructive),
      scrim: l(scrim, other.scrim),
      phases: {
        for (final p in Phase.values)
          p: PhasePalette.lerp(phase(p), other.phase(p), t),
      },
    );
  }
}
