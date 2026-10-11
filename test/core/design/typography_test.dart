import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/design/tokens/moon_typography.dart';

void main() {
  test('Fraunces uses the 72pt cut from 40 pt and the 24pt cut below', () {
    expect(fraunces(40).fontFamily, MoonFonts.fraunces72);
    expect(
      fraunces(100, weight: FontWeight.w300).fontFamily,
      MoonFonts.fraunces72,
    );
    expect(fraunces(39).fontFamily, MoonFonts.fraunces24);
    expect(fraunces(18, italic: true).fontFamily, MoonFonts.fraunces24);
  });

  test('weights that the static cuts do not have are caught', () {
    expect(() => fraunces(44, weight: FontWeight.w500), throwsAssertionError);
    expect(() => fraunces(26, weight: FontWeight.w300), throwsAssertionError);
    expect(
      () => fraunces(48, weight: FontWeight.w300, italic: true),
      throwsAssertionError,
    );
    expect(
      () => fraunces(22, weight: FontWeight.w500, italic: true),
      returnsNormally,
    );
  });

  test('tracking is in em, line height is CSS-style', () {
    final s = fraunces(44, height: 1);
    expect(s.letterSpacing, closeTo(-0.88, 1e-9)); // −0.02em × 44
    expect(s.height, 1);
    expect(s.leadingDistribution, TextLeadingDistribution.even);
    expect(MoonType.overline.letterSpacing, closeTo(12 * 0.14, 1e-9));
    expect(MoonType.dayNumber.letterSpacing, closeTo(-3.5, 1e-9));
    expect(dmSans(16).fontFamily, MoonFonts.dmSans);
  });

  test('the scale matches theme.ts', () {
    expect(
      [
        MoonType.dayNumber.fontSize,
        MoonType.shopCount.fontSize,
        MoonType.h1Reveal.fontSize,
        MoonType.h1.fontSize,
        MoonType.h2.fontSize,
        MoonType.h3.fontSize,
        MoonType.categoryHead.fontSize,
        MoonType.cardTitle.fontSize,
        MoonType.season.fontSize,
        MoonType.bodyL.fontSize,
        MoonType.body.fontSize,
        MoonType.rowLabel.fontSize,
        MoonType.button.fontSize,
        MoonType.ui.fontSize,
        MoonType.small.fontSize,
        MoonType.micro.fontSize,
        MoonType.tab.fontSize,
        MoonType.overline.fontSize,
      ],
      [100, 72, 54, 44, 36, 26, 22, 21, 18, 17, 16, 17, 16, 15, 13, 12, 11, 12],
    );
    expect(MoonType.h3.fontWeight, FontWeight.w500);
    expect(MoonType.season.fontStyle, FontStyle.italic);
    expect(MoonType.body.height, 1.55);
  });
}
