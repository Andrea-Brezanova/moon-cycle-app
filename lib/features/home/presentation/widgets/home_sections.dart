import 'package:flutter/material.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_colors.dart';
import '../../../../core/design/tokens/moon_layout.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/editorial_text.dart';
import '../../../../core/design/widgets/moon_button.dart';
import '../../../../core/design/widgets/moon_icon.dart';
import '../../../../core/design/widgets/pressable.dart';
import '../../../../core/design/widgets/text_link.dart';
import '../../../../core/domain/phase.dart';
import '../../../cycle/domain/phase_guidance.dart';

/// "Your focus": three short, phase-specific points and a way to read more.
class FocusSection extends StatelessWidget {
  const FocusSection({super.key, required this.phase, required this.onMore});

  final Phase phase;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final accent = c.phase(phase).accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(child: Overline('Your focus')),
            TextLink('Learn more →', onTap: onMore, size: 14),
          ],
        ),
        const SizedBox(height: 10),
        for (final point in phaseFocusCompact(phase))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        point.title,
                        style: dmSans(
                          17,
                          weight: FontWeight.w600,
                          height: 1.35,
                          color: c.text,
                        ),
                      ),
                      Text(
                        point.line,
                        style: dmSans(15, height: 1.4, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One of the six cards in "Your choices".
///
/// [locked] cards show a Premium lock and look quieter; [onTap] null (an
/// unlocked feature with nothing to open yet) shows the card but doesn't act.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.palette,
    required this.onTap,
    this.locked = false,
    this.comingSoon = false,
  });

  final MoonIconName icon;
  final String title;
  final String subtitle;
  final PhasePalette palette;
  final VoidCallback? onTap;
  final bool locked;

  /// Not available yet for anyone: quieter, no lock, nothing to tap.
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final quiet = locked || comingSoon;
    // Light: the phase's tint. Dark: the app's plum surface, as designed.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = quiet ? c.textMuted : c.text;
    return Pressable(
      onTap: comingSoon ? null : onTap,
      semanticLabel: comingSoon
          ? '$title, coming soon'
          : locked
          ? '$title, Premium, locked. $subtitle'
          : '$title. $subtitle',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 150),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          decoration: BoxDecoration(
            color: quiet ? null : (dark ? c.raised : palette.tint),
            // Same 1 pt edge either way, so the titles line up across a row.
            border: Border.all(
              color: locked ? c.line : const Color(0x00000000),
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: quiet ? null : (dark ? c.bg : c.raised),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: MoonIcon(
                      icon,
                      size: 18,
                      color: fg,
                      strokeWidth: 1.8,
                    ),
                  ),
                  const Spacer(),
                  if (locked)
                    MoonIcon(
                      MoonIconName.lock,
                      size: 14,
                      color: c.textMuted,
                      strokeWidth: 1.8,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: fraunces(
                  19,
                  weight: FontWeight.w500,
                  height: 1.15,
                  color: fg,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: dmSans(13, height: 1.3, color: c.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Your choices": a two-column grid of cards of equal height.
class HomeChoices extends StatelessWidget {
  const HomeChoices({super.key, required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Overline('Your choices'),
      const SizedBox(height: 12),
      for (var i = 0; i < cards.length; i += 2) ...[
        if (i > 0) const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards[i]),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < cards.length ? cards[i + 1] : const SizedBox(),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

/// "Has your period started?" (`21-home-period-late`), from 3 days late.
class LatePeriodCard extends StatelessWidget {
  const LatePeriodCard({super.key, required this.onLog});

  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(MoonRadius.lateCard),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Overline('Your period'),
          const SizedBox(height: 10),
          EditorialHeading(
            'Has your period *started?*',
            style: fraunces(26, height: 1.12),
          ),
          const SizedBox(height: 10),
          Text(
            'Log it and your cycle restarts at day 1. Until then, we’ll keep '
            'you in your luteal phase.',
            style: dmSans(15, height: 1.5, color: c.textMuted),
          ),
          const SizedBox(height: 16),
          MoonButton('Log my period', onPressed: onLog, expand: false),
        ],
      ),
    );
  }
}
