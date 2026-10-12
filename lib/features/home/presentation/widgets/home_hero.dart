import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/hero_tokens.dart';
import '../../../../core/design/tokens/moon_layout.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/brand.dart';
import '../../../../core/design/widgets/hero_backdrop.dart';
import '../../../../core/design/widgets/moon_icon.dart';
import '../../../../core/design/widgets/moon_orbit.dart';
import '../../../../core/design/widgets/pressable.dart';
import '../../../../core/domain/phase.dart';
import '../../../../core/format/dates.dart';
import '../../../../core/time/today.dart';
import '../../../content/application/content_providers.dart';
import '../../../cycle/domain/cycle_state.dart';
import '../../../cycle/presentation/cycle_orbit.dart';
import '../../application/home_providers.dart';

/// Home's full-bleed hero (spec §7.2): the wordmark and date, the moon in its
/// orbit, and today's phase. Dragging around the orbit previews another day;
/// the background and everything below the hero stay on today.
class HomeHero extends ConsumerWidget {
  const HomeHero({super.key, required this.state});

  final CycleState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final previewDay = ref.watch(homePreviewProvider);
    final shownPhase = previewDay == null
        ? state.phase
        : state.ranges.forDay(previewDay).phase;
    final content = ref.watch(catalogueProvider).phase(shownPhase);
    final today = ref.watch(todayProvider);
    final (Color text, Color summary, Color muted) = dark
        ? (HeroTokens.darkText, HeroTokens.darkSub, HeroTokens.darkMuted)
        : (HeroTokens.lightText, HeroTokens.lightText, HeroTokens.lightMuted);
    final width = MediaQuery.sizeOf(context).width;
    final moon = math.min(300.0, width - 90);

    return HeroBackdrop(
      phase: state.phase,
      dark: dark,
      pageColor: c.bg,
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.viewPaddingOf(context).top + 4,
          bottom: 56,
        ),
        child: Column(
          children: [
            Container(
              // The wordmark's line box on the canvas (Gwendolyn 34.8 pt).
              height: 34.8,
              padding: const EdgeInsets.symmetric(horizontal: MoonSpace.gutter),
              child: Row(
                children: [
                  Semantics(
                    label: 'Moon Cycle',
                    header: true,
                    excludeSemantics: true,
                    child: Wordmark(xHeight: 12, color: text),
                  ),
                  const Spacer(),
                  Text(
                    DateText.short(today),
                    style: dmSans(
                      13,
                      weight: FontWeight.w500,
                      height: 1,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _DraggableMoon(state: state, size: moon, dark: dark),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MoonSpace.gutter),
              child: Column(
                children: [
                  Text(
                    content.season,
                    textAlign: TextAlign.center,
                    style: MoonType.season.copyWith(
                      color: c.phase(shownPhase).text,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Semantics(
                    header: true,
                    child: Text(
                      content.name,
                      textAlign: TextAlign.center,
                      style: MoonType.phaseName.copyWith(color: text),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 290),
                    child: Text(
                      content.summary,
                      textAlign: TextAlign.center,
                      style: dmSans(17, height: 1.5, color: summary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    previewDay == null
                        ? homeHeroMeta(state)
                        : homePreviewMeta(state, previewDay),
                    textAlign: TextAlign.center,
                    style: dmSans(
                      13,
                      weight: FontWeight.w500,
                      height: 1.5,
                      color: muted,
                    ),
                  ),
                  if (previewDay != null) ...[
                    const SizedBox(height: 14),
                    _BackToToday(day: state.cycleDay),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraggableMoon extends ConsumerWidget {
  const _DraggableMoon({
    required this.state,
    required this.size,
    required this.dark,
  });

  final CycleState state;
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewDay = ref.watch(homePreviewProvider);
    final preview = ref.read(homePreviewProvider.notifier);
    final length = state.cycleLength;
    final shownDay = previewDay ?? state.orbitDay;

    void dragTo(Offset local) {
      final day = OrbitMath.dayAt(
        local * (OrbitGeometry.viewBox / size),
        length,
      );
      if (day != shownDay) {
        HapticFeedback.selectionClick();
        preview.preview(day);
      }
    }

    return Semantics(
      container: true,
      label: orbitSemanticLabel(state),
      value: previewDay == null ? 'Day $shownDay' : 'Previewing day $shownDay',
      increasedValue: shownDay < length
          ? 'Previewing day ${shownDay + 1}'
          : null,
      decreasedValue: shownDay > 1 ? 'Previewing day ${shownDay - 1}' : null,
      hint: 'Swipe up or down to preview other days',
      onIncrease: shownDay < length
          ? () => preview.preview(shownDay + 1)
          : null,
      onDecrease: shownDay > 1 ? () => preview.preview(shownDay - 1) : null,
      child: RawGestureDetector(
        gestures: {
          _OrbitDrag: GestureRecognizerFactoryWithHandlers<_OrbitDrag>(
            () => _OrbitDrag(
              // The ring's band in the 300-unit design space.
              onRing: (local) {
                final d =
                    (local * (OrbitGeometry.viewBox / size) -
                            const Offset(
                              OrbitGeometry.centre,
                              OrbitGeometry.centre,
                            ))
                        .distance;
                return d > OrbitGeometry.radius - 32 &&
                    d < OrbitGeometry.radius + 32;
              },
            ),
            (r) => r
              ..onStart = ((d) => dragTo(d.localPosition))
              ..onUpdate = ((d) => dragTo(d.localPosition)),
          ),
        },
        child: ExcludeSemantics(
          child: MoonOrbit(
            size: size,
            dark: dark,
            haloColor: dark
                ? HeroTokens.darkSolid
                : HeroTokens.lightWash[state.phase]!,
            spec: orbitSpecFor(state, previewDay: previewDay),
          ),
        ),
      ),
    );
  }
}

/// A drag that starts on the orbit ring is the preview gesture straight
/// away, so it isn't taken by the page's scrolling; a drag anywhere else
/// (the moon's centre) still scrolls the page.
class _OrbitDrag extends PanGestureRecognizer {
  _OrbitDrag({required this.onRing});

  final bool Function(Offset local) onRing;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    if (onRing(event.localPosition)) resolve(GestureDisposition.accepted);
  }
}

class _BackToToday extends ConsumerWidget {
  const _BackToToday({required this.day});

  final int day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    return Pressable(
      onTap: ref.read(homePreviewProvider.notifier).backToToday,
      semanticLabel: 'Back to today, day $day',
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.fromLTRB(14, 10, 18, 10),
        decoration: ShapeDecoration(
          color: c.sand,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MoonIcon(
              MoonIconName.back,
              size: 16,
              color: c.text,
              strokeWidth: 2,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Back to today · Day $day',
                style: dmSans(
                  14,
                  weight: FontWeight.w600,
                  height: 1,
                  color: c.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Day 2 of 6 in phase · Day 7 of 28 in cycle" over "Ovulatory in 5 days"
/// ("Period in 8 days" in luteal); when late, "Period 4 days late · Day 32 in
/// cycle".
String homeHeroMeta(CycleState s) {
  if (s.isLate) {
    return 'Period ${DateText.days(s.daysLate)} late · Day ${s.cycleDay} in '
        'cycle';
  }
  final next = s.phase == Phase.luteal
      ? 'Period in ${DateText.days(s.daysToNextPhase)}'
      : '${phaseName(s.nextPhase)} in ${DateText.days(s.daysToNextPhase)}';
  return 'Day ${s.phaseDay} of ${s.phaseLength} in phase · Day ${s.cycleDay} '
      'of ${s.cycleLength} in cycle\n$next';
}

/// "Previewing day 14 · in 7 days" (or "· 4 days ago").
String homePreviewMeta(CycleState s, int day) {
  final offset = day - s.cycleDay;
  final when = offset >= 0
      ? 'in ${DateText.days(offset)}'
      : '${DateText.days(-offset)} ago';
  return 'Previewing day $day · $when';
}
