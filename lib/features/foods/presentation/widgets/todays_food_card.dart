import 'package:flutter/material.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_colors.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/editorial_text.dart';
import '../../../../core/design/widgets/pressable.dart';
import '../../../../core/design/widgets/text_link.dart';
import '../../../content/domain/food.dart';
import '../food_emoji.dart';

/// The six playful headlines. `*…*` is set in italic. One is chosen from the
/// date and food, so it stays the same all day.
const todaysFoodHeadlines = [
  'Fancy some *{food}* today?',
  'How about *{food}* today?',
  'Today’s pick: *{food}*!',
  'Wanna try *{food}* today?',
  '*{Food}* is on the menu today!',
  'Feel like *{food}* today?',
];

/// [template] filled in for [food] ("Fancy some *broccoli* today?").
String todaysFoodHeadline(String template, String food) {
  final lower = food.toLowerCase();
  final capital = food.isEmpty
      ? food
      : '${food[0].toUpperCase()}${food.substring(1)}';
  return template.replaceAll('{food}', lower).replaceAll('{Food}', capital);
}

/// "Today's food" on Foods: label, headline, one factual line (the food's
/// existing reason for the phase) and a link to its page.
class TodaysFoodCard extends StatelessWidget {
  const TodaysFoodCard({
    super.key,
    required this.food,
    required this.headline,
    required this.intro,
    required this.palette,
    required this.onOpen,
  });

  final Food food;
  final String headline;
  final String? intro;
  final PhasePalette palette;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Pressable(
      onTap: onOpen,
      semanticLabel:
          'Today’s food: ${food.displayName}. See ${food.displayName}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        decoration: BoxDecoration(
          color: palette.tint,
          borderRadius: BorderRadius.circular(24),
        ),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    foodEmoji(food),
                    style: const TextStyle(fontSize: 26, height: 1),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: Overline('Today’s food')),
                ],
              ),
              const SizedBox(height: 12),
              EditorialHeading(headline, style: fraunces(28, height: 1.12)),
              if (intro != null) ...[
                const SizedBox(height: 10),
                Text(
                  intro!,
                  style: dmSans(15, height: 1.45, color: c.textMuted),
                ),
              ],
              const SizedBox(height: 14),
              TextLink(
                'See ${food.displayName.toLowerCase()} →',
                onTap: onOpen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
