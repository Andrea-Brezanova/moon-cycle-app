import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_colors.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/brand.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/recipe_photo.dart';
import '../../../core/domain/phase.dart';

/// Onboarding step 1 (`01-onboarding-welcome`): organic shapes on plum, the
/// phase ring, and the welcome copy. "I already have an account" is hidden
/// in v1 (spec §12).
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final size = MediaQuery.sizeOf(context);
    // The design is 844 pt tall; on shorter phones the ring moves up so it
    // doesn't run into the copy.
    final ringTop = 150.0 * math.min(1.0, size.height / 844);
    final bottom = math.max(
      44.0,
      MediaQuery.viewPaddingOf(context).bottom + 10,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: moonStatusBar(Brightness.dark),
      child: Scaffold(
        backgroundColor: c.welcomeBg,
        body: Stack(
          children: [
            ..._shapes(c),
            Positioned(
              left: 0,
              right: 0,
              top: ringTop,
              child: const Center(
                child: PhaseRingMark(size: 150, onPlum: true),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(28, 0, 28, bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      label: 'Moon Cycle',
                      excludeSemantics: true,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Wordmark(xHeight: 15, color: c.welcomeText),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Semantics(
                      header: true,
                      child: EditorialHeading(
                        'Eat in rhythm\nwith your *cycle.*',
                        style: MoonType.h1Welcome,
                        color: c.welcomeText,
                        italicColor: c.ochre,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Foods, recipes and a shopping list that follow your '
                      'four phases, so you always know what to eat right now.',
                      style: dmSans(17, height: 1.5, color: c.welcomeBody),
                    ),
                    const SizedBox(height: 28),
                    MoonButton(
                      'Get started',
                      trailingIcon: MoonIconName.arrow,
                      onPressed: () =>
                          context.push(Routes.onboardingLastPeriod),
                    ),
                    // v1 hides "I already have an account" (spec §12); its
                    // space stays so the approved layout doesn't shift.
                    const SizedBox(height: 14 + 15),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Positions and sizes from the canvas (`EdOnboard1`).
  static List<Widget> _shapes(MoonColors c) => [
    Positioned(
      left: -90,
      top: -70,
      child: OrganicShape(
        variant: 0,
        color: c.phase(Phase.menstrual).accent,
        width: 300,
        height: 280,
        opacity: 0.9,
      ),
    ),
    Positioned(
      right: -130,
      top: 300,
      child: OrganicShape(
        variant: 1,
        color: c.phase(Phase.follicular).accent,
        width: 260,
        height: 260,
        opacity: 0.85,
      ),
    ),
    Positioned(
      left: -56,
      top: 236,
      child: OrganicShape(
        variant: 2,
        color: c.phase(Phase.luteal).accent,
        width: 130,
        height: 120,
        opacity: 0.85,
      ),
    ),
    Positioned(
      right: 30,
      top: 40,
      child: OrganicShape(variant: 2, color: c.ochre, width: 70, height: 64),
    ),
  ];
}
