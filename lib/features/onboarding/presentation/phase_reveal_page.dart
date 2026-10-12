import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/hero_tokens.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_orbit.dart';
import '../../../core/design/widgets/pinned_actions_scroll.dart';
import '../../../core/domain/phase.dart';
import '../../../core/format/dates.dart';
import '../../content/application/content_providers.dart';
import '../../cycle/application/cycle_providers.dart';
import '../../cycle/domain/cycle_state.dart';
import '../../cycle/presentation/cycle_orbit.dart';
import '../application/onboarding_status.dart';

/// Onboarding step 5 (`05-onboarding-your-phase`, `37-…-all-phases`): the
/// phase the user is in, on the Home hero's background with the same moon.
///
/// Everything is saved by now, so there's no way back to the questions.
class PhaseRevealPage extends ConsumerWidget {
  const PhaseRevealPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cycleStateProvider).value;
    return PopScope(
      canPop: false,
      child: state == null
          ? Scaffold(backgroundColor: context.moon.bg)
          : _Reveal(state: state),
    );
  }
}

class _Reveal extends ConsumerWidget {
  const _Reveal({required this.state});

  final CycleState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final phase = state.phase;
    final palette = c.phase(phase);
    final content = ref.watch(catalogueProvider).phase(phase);
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.viewPaddingOf(context);
    final top = math.max(64.0, padding.top + 17);
    final bottom = math.max(44.0, padding.bottom + 10);
    final moon = math.min(300.0, size.width - 90);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: moonStatusBar(Theme.of(context).brightness),
      child: Scaffold(
        backgroundColor: c.bg,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: _background(
              phase: phase,
              dark: dark,
              page: c.bg,
              height: size.height,
            ),
          ),
          child: PinnedActionsScroll(
            padding: EdgeInsets.fromLTRB(28, top, 28, bottom),
            minGap: 18,
            crossAxisAlignment: CrossAxisAlignment.center,
            content: Column(
              children: [
                Overline('You’re in your', color: palette.text),
                const SizedBox(height: 18),
                Semantics(
                  header: true,
                  child: Text(
                    content.name,
                    textAlign: TextAlign.center,
                    style: MoonType.h1Reveal.copyWith(color: c.text),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  content.season,
                  textAlign: TextAlign.center,
                  style: fraunces(
                    20,
                    italic: true,
                    height: 1.08,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 18),
                MoonOrbit(
                  size: moon,
                  dark: dark,
                  haloColor: dark
                      ? HeroTokens.darkSolid
                      : HeroTokens.lightWash[phase]!,
                  spec: orbitSpecFor(state),
                  semanticLabel: orbitSemanticLabel(state),
                ),
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    '${content.summary} Your foods and recipes now follow '
                    'this phase.',
                    textAlign: TextAlign.center,
                    style: dmSans(17, height: 1.5, color: c.text),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  revealNextLine(state),
                  textAlign: TextAlign.center,
                  style: dmSans(
                    14,
                    weight: FontWeight.w500,
                    height: 1,
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
            actions: MoonButton(
              'See my foods',
              trailingIcon: MoonIconName.arrow,
              onPressed: () async {
                await ref.read(onboardingCompletedProvider.notifier).complete();
                if (context.mounted) context.go(AppTab.foods.path);
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Solid to 520 pt, then fading into the page by 660 pt (canvas).
  static LinearGradient _background({
    required Phase phase,
    required bool dark,
    required Color page,
    required double height,
  }) {
    final solidEnd = (520 / height).clamp(0.0, 1.0);
    final fadeEnd = (660 / height).clamp(0.0, 1.0);
    final (Color top, Color solid) = dark
        ? (HeroTokens.darkTop, HeroTokens.darkSolid)
        : (HeroTokens.lightWash[phase]!, HeroTokens.lightWash[phase]!);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [top, solid, page, page],
      stops: [0, solidEnd, fadeEnd, 1],
    );
  }
}

/// "Ovulatory in 5 days · Next period 26 October"; in luteal "Next period in
/// 8 days · 12 October" (canvas `EdRevealPhases`).
String revealNextLine(CycleState s) {
  if (s.isLate) return 'Period ${DateText.days(s.daysLate)} late';
  final next = DateText.dayMonth(s.estimatedNextPeriodDate);
  if (s.phase == Phase.luteal) {
    return 'Next period in ${DateText.days(s.daysUntilNextPeriod)} · $next';
  }
  return '${phaseName(s.nextPhase)} in ${DateText.days(s.daysToNextPhase)} '
      '· Next period $next';
}
