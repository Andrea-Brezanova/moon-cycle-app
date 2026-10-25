import 'package:flutter/material.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/editorial_text.dart';
import '../../domain/food_profile.dart';

/// The five standard sections of a food's profile, in the Food Detail page's
/// own style (small overlines over body text): what it offers, key nutrients,
/// a practical serving, how to eat it, and cycle relevance. Percentages are a
/// serving's share of the daily reference for the nutrient, not a portion
/// advice.
class FoodProfileSections extends StatelessWidget {
  const FoodProfileSections({super.key, required this.profile});

  final FoodProfile profile;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    Widget block(String label, Widget body) => Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Overline(label), const SizedBox(height: 6), body],
      ),
    );
    Widget text(String t) =>
        Text(t, style: MoonType.body.copyWith(color: c.text));

    // "18% of daily reference", or one share per age group.
    String reference(ProfileNutrient n) => n.references.length == 1
        ? '${n.references.single.percent}% of daily reference'
        : '${n.references.map((r) => '${r.percent}% (${r.group})').join(' · ')} '
              'of daily reference';

    return Column(
      key: const ValueKey('food-profile'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        block('What this food offers', text(profile.whatItOffers)),
        block(
          'Key nutrients',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Per serving: ${profile.practicalServing} · '
                '${profile.energyKcal} kcal',
                style: dmSans(13, height: 1.4, color: c.textMuted),
              ),
              const SizedBox(height: 8),
              for (final (i, n) in profile.nutrients.indexed) ...[
                if (i > 0) Divider(height: 1, color: c.line),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          n.name,
                          style: dmSans(15, height: 1.3, color: c.text),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_fmt(n.amount)} ${n.unit}',
                              textAlign: TextAlign.end,
                              style: dmSans(
                                15,
                                weight: FontWeight.w600,
                                height: 1.3,
                                color: c.text,
                              ),
                            ),
                            if (n.references.isNotEmpty)
                              Text(
                                reference(n),
                                textAlign: TextAlign.end,
                                style: dmSans(
                                  12,
                                  height: 1.3,
                                  color: c.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                'Percentages compare one serving with the daily reference for '
                'the nutrient, for adult women. They are not a recommended '
                'portion of this food.',
                style: dmSans(12.5, height: 1.4, color: c.textMuted),
              ),
            ],
          ),
        ),
        block('A practical serving', text(profile.practicalServing)),
        block('How to eat it', text(profile.howToEatIt)),
        block('Cycle relevance', text(profile.cycleRelevance)),
        const SizedBox(height: 14),
        Text(
          profile.reviewLabel,
          key: const ValueKey('food-profile-review'),
          style: dmSans(12.5, height: 1.4, color: c.textMuted),
        ),
      ],
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();
}
