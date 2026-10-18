import 'package:flutter/material.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_layout.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/editorial_text.dart';
import '../../../../core/design/widgets/moon_button.dart';
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
