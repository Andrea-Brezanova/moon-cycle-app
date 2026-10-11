import 'package:flutter/widgets.dart';

import '../../domain/phase.dart';
import '../tokens/hero_tokens.dart';

/// The Home hero / onboarding reveal background (spec §3.3).
///
/// - Light: the phase wash, solid until [HeroTokens.fadeHeight] above the
///   bottom, then fading into the page colour.
/// - Dark: the same night plum for every phase (#37255C → #2E2150), fading
///   into the dark page.
///
/// Full-bleed, no rounded corners. Painted, so it fits any content height.
class HeroBackdrop extends StatelessWidget {
  const HeroBackdrop({
    super.key,
    required this.phase,
    required this.dark,
    required this.pageColor,
    required this.child,
  });

  final Phase phase;
  final bool dark;

  /// The page colour the hero fades into (`context.moon.bg`).
  final Color pageColor;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _HeroPainter(
      top: dark ? HeroTokens.darkTop : HeroTokens.lightWash[phase]!,
      solid: dark ? HeroTokens.darkSolid : HeroTokens.lightWash[phase]!,
      end: pageColor,
    ),
    child: child,
  );
}

class _HeroPainter extends CustomPainter {
  _HeroPainter({required this.top, required this.solid, required this.end});

  final Color top;
  final Color solid;
  final Color end;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 0) return;
    final fadeStart = ((size.height - HeroTokens.fadeHeight) / size.height)
        .clamp(0.0, 1.0);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, solid, end],
          stops: [0, fadeStart, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_HeroPainter old) =>
      old.top != top || old.solid != solid || old.end != end;
}
