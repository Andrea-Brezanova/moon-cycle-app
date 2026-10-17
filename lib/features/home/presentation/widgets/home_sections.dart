import 'package:flutter/material.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_layout.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/editorial_text.dart';
import '../../../../core/design/widgets/moon_button.dart';
import '../../../../core/design/widgets/moon_chip.dart';
import '../../../../core/design/widgets/text_link.dart';
import '../../../../core/domain/phase.dart';
import '../../../content/domain/food.dart';
import '../../../cycle/domain/phase_guidance.dart';
import '../food_emoji.dart';

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

/// "Today's food": one food from the phase, with its emoji, and two actions.
/// No photo and no paragraph: the name carries the meaning, the emoji only
/// decorates it.
class TodaysFoodSection extends StatelessWidget {
  const TodaysFoodSection({
    super.key,
    required this.food,
    required this.phase,
    required this.onWhy,
    required this.onRecipes,
  });

  final Food food;
  final Phase phase;
  final VoidCallback onWhy;
  final VoidCallback onRecipes;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final palette = c.phase(phase);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Overline('Today’s food'),
        const SizedBox(height: 12),
        Semantics(
          container: true,
          label: 'Today’s food: ${food.displayName}',
          child: ExcludeSemantics(
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: palette.tint,
                    shape: const CircleBorder(),
                  ),
                  child: Text(
                    foodEmoji(food),
                    style: const TextStyle(fontSize: 30, height: 1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    food.displayName,
                    style: fraunces(30, height: 1.1, color: c.text),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: MoonSpace.chipGap,
          runSpacing: 0,
          children: [
            MoonChip('Why this food?', onTap: onWhy),
            MoonChip('Recipes', onTap: onRecipes),
          ],
        ),
      ],
    );
  }
}

/// The two free actions: the meal builder and food discovery, stacked so
/// each label has the full width.
class HomeActions extends StatelessWidget {
  const HomeActions({
    super.key,
    required this.onBuildMeal,
    required this.onTryNew,
  });

  final VoidCallback onBuildMeal;
  final VoidCallback onTryNew;

  @override
  Widget build(BuildContext context) {
    final build = MoonButton(
      'Build a meal',
      onPressed: onBuildMeal,
      variant: MoonButtonVariant.ghost,
    );
    final tryNew = MoonButton(
      'Try something new',
      onPressed: onTryNew,
      variant: MoonButtonVariant.ghost,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [build, const SizedBox(height: 12), tryNew],
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
