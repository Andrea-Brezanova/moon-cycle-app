import 'package:flutter/widgets.dart';

import '../moon_theme.dart';
import '../tokens/moon_typography.dart';
import 'pressable.dart';

/// A text link. Flutter's built-in underline can't be offset or thickened, so
/// the underline is painted here, 4 pt below the baseline.
///
/// - [TextLink]: the Editorial link, SemiBold with a 2 pt ochre underline
///   (spec §6), e.g. "All foods", "Clear all".
/// - [TextLink.onboarding]: the quieter link on the onboarding screens,
///   Medium with a thin underline in the text colour, e.g. "I’m not sure".
///   An intentional exception to the spec rule, matching the approved
///   onboarding screens (docs/design-deviations.md).
class TextLink extends StatelessWidget {
  const TextLink(
    this.label, {
    super.key,
    required this.onTap,
    this.size = 15,
    this.weight = FontWeight.w600,
    this.color,
  }) : _onboarding = false;

  const TextLink.onboarding(
    this.label, {
    super.key,
    required this.onTap,
    this.color,
  }) : size = 15,
       weight = FontWeight.w500,
       _onboarding = true;

  final String label;
  final VoidCallback? onTap;
  final double size;
  final FontWeight weight;

  /// Text colour; defaults to the theme's text colour. The onboarding
  /// underline follows it (cream on the welcome screen).
  final Color? color;

  final bool _onboarding;

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? context.moon.text;
    final style = dmSans(size, weight: weight, height: 1, color: textColor);
    final scaler = MediaQuery.textScalerOf(context);
    return Pressable(
      onTap: onTap,
      isButton: false,
      child: Semantics(
        link: true,
        child: CustomPaint(
          foregroundPainter: UnderlinePainter(
            text: label,
            style: style,
            scaler: scaler,
            color: _onboarding ? textColor : context.moon.ochre,
            thickness: _onboarding ? 1 : 2,
          ),
          child: Text(label, style: style, textScaler: scaler),
        ),
      ),
    );
  }
}

/// Paints a [thickness] underline in [color], [offset] below the baseline.
class UnderlinePainter extends CustomPainter {
  UnderlinePainter({
    required this.text,
    required this.style,
    required this.scaler,
    required this.color,
    required this.thickness,
  });

  final String text;
  final TextStyle style;
  final TextScaler scaler;
  final Color color;
  final double thickness;

  static const double offset = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout(maxWidth: size.width);
    final baseline = tp.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, baseline + offset, tp.width, thickness),
      Paint()..color = color,
    );
    tp.dispose();
  }

  @override
  bool shouldRepaint(UnderlinePainter old) =>
      old.text != text ||
      old.style != style ||
      old.scaler != scaler ||
      old.color != color ||
      old.thickness != thickness;
}
