import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/botanical_sprig.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/domain/phase.dart';
import '../../../core/time/today.dart';
import '../../entitlements/application/entitlement_providers.dart';
import '../../entitlements/domain/entitlements.dart';

/// My Diary: the landing hub. A "Today" card and five ways in: symptoms, a
/// meal, activities (coming soon), notes (coming soon) and the entries. Each
/// opens a screen that already exists; the hub itself stores nothing.
class DiaryHubPage extends ConsumerWidget {
  const DiaryHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final today = ref.watch(todayProvider);
    final allowed = ref.watch(featureGateProvider).canUse(Feature.logDiary);

    // The diary pages apply their own rule; where the diary isn't available,
    // the way in goes to the Subscription page, like Log meal on a food page.
    void open(String location) => allowed
        ? context.push(location)
        : context.go(Routes.settings(SettingsPage.subscription));

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        // A handful of blocks, all built: no lazy list needed.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            MoonSpace.gutter,
            4,
            MoonSpace.gutter,
            42 + 76,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Transform.translate(
                  offset: const Offset(-10, 0),
                  child: Pressable(
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go(AppTab.more.path),
                    semanticLabel: 'Back',
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: MoonIcon(
                          MoonIconName.back,
                          size: 22,
                          color: c.text,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Semantics(
                header: true,
                child: Text(
                  'My Diary',
                  style: fraunces(
                    44,
                    weight: FontWeight.w400,
                    height: 1.05,
                    color: c.text,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'A gentle place to track your meals, symptoms and daily '
                'patterns.',
                style: dmSans(
                  17,
                  height: 1.45,
                  color: c.phase(Phase.luteal).text,
                ),
              ),
              const SizedBox(height: 22),
              _TodayCard(onTap: () => open(Routes.diaryOn(date: today))),
              const SizedBox(height: 16),
              _HubCard(
                icon: MoonIconName.heart,
                phase: Phase.luteal,
                title: 'Log symptoms',
                body: 'Track mood, energy, body and sleep.',
                locked: !allowed,
                onTap: () => open(Routes.logSymptoms()),
              ),
              const SizedBox(height: 10),
              _HubCard(
                icon: MoonIconName.utensils,
                phase: Phase.follicular,
                title: 'Log a meal',
                body: 'Remember what you ate today.',
                locked: !allowed,
                onTap: () => open(Routes.logMeal()),
              ),
              const SizedBox(height: 10),
              _HubCard(
                icon: MoonIconName.move,
                phase: Phase.ovulatory,
                title: 'Log activities',
                body: 'Capture movement, exercise or walks.',
                onTap: () => context.push(Routes.diaryActivities),
              ),
              const SizedBox(height: 10),
              _HubCard(
                icon: MoonIconName.pencil,
                phase: Phase.menstrual,
                title: 'Notes',
                body: 'Free writing space for thoughts, reflections or notes.',
                onTap: () => context.push(Routes.diaryNotes),
              ),
              const SizedBox(height: 10),
              _HubCard(
                icon: MoonIconName.book,
                phase: Phase.luteal,
                title: 'View my entries',
                body: 'See your recent check-ins and history.',
                locked: !allowed,
                onTap: () => open(Routes.diaryEntries),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Today": a soft lavender card with a botanical sprig and a round arrow.
/// Opens today's entries.
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final p = c.phase(Phase.luteal);
    final dark = Theme.of(context).brightness == Brightness.dark;
    // At large text sizes the picture is dropped, so the words keep the whole
    // card and stay whole.
    final large = MediaQuery.textScalerOf(context).scale(16) > 20;
    return Pressable(
      onTap: onTap,
      semanticLabel:
          'Today. Check in with how you feel and what you did today. '
          'Open today’s entries',
      child: Container(
        constraints: const BoxConstraints(minHeight: 150),
        decoration: BoxDecoration(
          color: dark ? c.raised : p.tint.withValues(alpha: 0.7),
          border: dark ? Border.all(color: c.line) : null,
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Decorative: a lavender moon, a sprig and a gold dot.
            if (!large)
              Positioned(
                right: 14,
                top: 14,
                bottom: 10,
                width: 120,
                child: ExcludeSemantics(
                  child: Stack(
                    children: [
                      Positioned(
                        left: 14,
                        top: 10,
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: p.accent.withValues(
                              alpha: dark ? 0.4 : 0.32,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        top: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: c.ochre,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: SprigPainter(
                            leaf: c.phase(Phase.follicular).accent,
                            stem: c.phase(Phase.follicular).text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                22,
                20,
                large ? 22 : 150,
                large ? 56 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today',
                    style: fraunces(30, height: 1.1, color: c.text),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check in with how you feel and what you did today.',
                    style: dmSans(15, height: 1.45, color: c.textMuted),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Positioned(
              right: 14,
              bottom: 14,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: dark ? p.accent : c.raised,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: MoonIcon(
                    MoonIconName.chev,
                    size: 16,
                    color: dark ? c.bg : c.text,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A way in: a pastel icon disc, a serif title, a line and a chevron.
class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.phase,
    required this.title,
    required this.body,
    required this.onTap,
    this.locked = false,
  });

  final MoonIconName icon;
  final Phase phase;
  final String title;
  final String body;
  final VoidCallback onTap;

  /// The diary isn't available on this plan; shows a lock.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final palette = c.phase(phase);
    return Pressable(
      onTap: onTap,
      semanticLabel: '$title. $body${locked ? ' Part of Premium.' : ''}',
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: c.raised,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: palette.tint,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: MoonIcon(icon, size: 24, color: palette.text),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: fraunces(20, height: 1.15, color: c.text)),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: dmSans(14, height: 1.35, color: c.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            MoonIcon(
              locked ? MoonIconName.lock : MoonIconName.chev,
              size: 18,
              color: c.chevron,
            ),
          ],
        ),
      ),
    );
  }
}
