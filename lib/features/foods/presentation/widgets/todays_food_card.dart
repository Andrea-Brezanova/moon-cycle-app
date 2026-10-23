import 'package:flutter/material.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_colors.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/editorial_text.dart';
import '../../../../core/design/widgets/moon_icon.dart';
import '../../../../core/design/widgets/pressable.dart';
import '../../../content/domain/food.dart';
import '../../../home/presentation/widgets/plant_photos.dart';
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
/// existing reason for the phase) and a link to its page. A food with a
/// curated photo is drawn over the photo; any other on a tinted card.
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
    final photo = plantPhotos[food.id];
    // Over a photo the text is ivory on a plum fade; otherwise the usual ink.
    final fg = photo != null ? const Color(0xFFFFFDF8) : c.text;
    final muted = photo != null ? const Color(0xE6FFFDF8) : c.textMuted;
    return Pressable(
      onTap: onOpen,
      semanticLabel:
          'Today’s food: ${food.displayName}. See ${food.displayName}',
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 168),
        decoration: BoxDecoration(
          color: palette.tint,
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExcludeSemantics(
          child: Stack(
            children: [
              if (photo != null) ...[
                Positioned.fill(
                  child: Image.asset(
                    photo.asset,
                    fit: BoxFit.cover,
                    alignment: photo.alignment,
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x1A1B152E), Color(0xCC1B152E)],
                      ),
                    ),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 64, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (photo == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          foodEmoji(food),
                          style: const TextStyle(fontSize: 26, height: 1),
                        ),
                      ),
                    Overline('Today’s food', color: muted),
                    SizedBox(height: photo != null ? 44 : 10),
                    EditorialHeading(
                      headline,
                      style: fraunces(26, height: 1.12),
                      color: fg,
                    ),
                    if (intro != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        intro!,
                        style: dmSans(14, height: 1.4, color: muted),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: photo != null
                        ? const Color(0xFFFFFDF8)
                        : c.inverseBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: MoonIcon(
                      MoonIconName.chev,
                      size: 16,
                      color: photo != null
                          ? const Color(0xFF37255C)
                          : c.inverseText,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
