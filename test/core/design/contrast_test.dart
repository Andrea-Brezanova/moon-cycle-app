import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/design/tokens/hero_tokens.dart';
import 'package:moon_cycle/core/design/tokens/moon_colors.dart';
import 'package:moon_cycle/core/domain/phase.dart';

/// WCAG 2.x contrast ratio.
double contrast(Color a, Color b) {
  double lum(Color c) {
    double ch(double v) =>
        v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) as double;
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  final (x, y) = (lum(a), lum(b));
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

void expectContrast(Color fg, Color bg, double min, String what) => expect(
  contrast(fg, bg),
  greaterThanOrEqualTo(min),
  reason: '$what: ${contrast(fg, bg).toStringAsFixed(2)}:1, needs $min:1',
);

const text = 4.5; // WCAG AA for body text
const graphic = 3.0; // WCAG AA for icons and UI graphics

void main() {
  for (final (name, c) in [
    ('light', MoonColors.light),
    ('dark', MoonColors.dark),
  ]) {
    group('$name theme', () {
      test('text on surfaces', () {
        for (final (surface, bg) in [
          ('bg', c.bg),
          ('raised', c.raised),
          ('sand', c.sand),
        ]) {
          expectContrast(c.text, bg, text, 'text on $surface');
          expectContrast(c.textMuted, bg, text, 'textMuted on $surface');
        }
      });

      test('filled controls', () {
        expectContrast(c.inverseText, c.inverseBg, text, 'inverse');
        expectContrast(c.onOchre, c.ochre, text, 'on ochre');
        expectContrast(c.onDestructive, c.destructive, text, 'destructive');
        expectContrast(c.destructive, c.bg, text, 'destructive text on bg');
        expectContrast(c.shopBlockText, c.shopBlockBg, text, 'shop block');
        expectContrast(c.shopBlockSub, c.shopBlockBg, text, 'shop block sub');
        expectContrast(c.welcomeText, c.welcomeBg, text, 'welcome');
      });

      test('phase colours', () {
        for (final p in Phase.values) {
          final pal = c.phase(p);
          expectContrast(pal.text, c.bg, text, '${p.name} text on page');
          expectContrast(c.text, pal.tint, text, 'text on ${p.name} tint');
          expectContrast(
            pal.text,
            pal.tint,
            graphic,
            '${p.name} check on tint',
          );
        }
      });

      test('the checkbox and toggle outlines are visible', () {
        expectContrast(c.checkboxBorder, c.bg, 1.8, 'checkbox outline');
      });
    });
  }

  group('hero', () {
    test('light washes: plum, muted and season text', () {
      for (final p in Phase.values) {
        final wash = HeroTokens.lightWash[p]!;
        expectContrast(HeroTokens.lightText, wash, text, '${p.name} title');
        expectContrast(HeroTokens.lightMuted, wash, text, '${p.name} muted');
        expectContrast(
          MoonColors.light.phase(p).text,
          wash,
          text,
          '${p.name} season',
        );
      }
    });

    test('dark night plum: text, summary, muted and season', () {
      for (final bg in [HeroTokens.darkTop, HeroTokens.darkSolid]) {
        expectContrast(HeroTokens.darkText, bg, text, 'dark title');
        expectContrast(HeroTokens.darkSub, bg, text, 'dark summary');
        expectContrast(HeroTokens.darkMuted, bg, text, 'dark muted');
        for (final p in Phase.values) {
          expectContrast(
            MoonColors.dark.phase(p).text,
            bg,
            text,
            '${p.name} dark season',
          );
        }
      }
    });

    test('day label and number on the moon, both themes', () {
      for (final moon in [
        HeroTokens.moonLightInner,
        HeroTokens.moonLightOuter,
        HeroTokens.moonDarkInner,
        HeroTokens.moonDarkOuter,
      ]) {
        expectContrast(HeroTokens.moonLabel, moon, text, 'DAY on moon');
        expectContrast(HeroTokens.moonNumber, moon, text, 'number on moon');
      }
    });
  });
}
