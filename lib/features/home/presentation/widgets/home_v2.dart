import 'package:flutter/material.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/botanical_sprig.dart';
import '../../../../core/design/widgets/editorial_text.dart';
import '../../../../core/design/widgets/moon_icon.dart';
import '../../../../core/design/widgets/pressable.dart';
import '../../../../core/design/widgets/text_link.dart';
import '../../../../core/domain/phase.dart';
import '../../../content/domain/food.dart';
import 'plant_photos.dart';

/// A small overline above a Home section.
class HomeOverline extends StatelessWidget {
  const HomeOverline(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Semantics(header: true, child: Overline(text));
}

/// Today's focus: a soft rounded card with the phase's headline, a short
/// description, a link to the phase page and a botanical sprig in the corner.
/// The copy comes from the phase content, not from this widget.
class TodaysFocusCard extends StatelessWidget {
  const TodaysFocusCard({
    super.key,
    required this.phase,
    required this.headline,
    required this.body,
    required this.onMore,
  });

  final Phase phase;
  final String headline;
  final String body;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark ? c.raised : c.phase(phase).tint.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(26),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Decorative; never overlaps the text (it sits in the padded corner).
          Positioned(
            right: 8,
            bottom: 6,
            child: ExcludeSemantics(
              child: SizedBox(
                width: 64,
                height: 116,
                child: CustomPaint(
                  painter: SprigPainter(
                    leaf: c.phase(phase).accent.withValues(alpha: 0.55),
                    stem: c.phase(phase).accent.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            // Extra right padding keeps the text clear of the sprig.
            padding: const EdgeInsets.fromLTRB(20, 20, 66, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: EditorialHeading(
                    italicLastWord(headline),
                    style: fraunces(26, height: 1.12),
                  ),
                ),
                const SizedBox(height: 10),
                Text(body, style: dmSans(14, height: 1.5, color: c.text)),
                const SizedBox(height: 14),
                TextLink(
                  'Learn more about your phase\u00A0→',
                  onTap: onMore,
                  size: 13,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small hand-drawn style sprig: a curved stem with paired leaves.
/// One of the three optional daily suggestions: a photo, a label, a title, a
/// line and a round chevron. Suggestions only: nothing to complete or score.
class DailyCard extends StatelessWidget {
  const DailyCard({
    super.key,
    required this.label,
    required this.title,
    required this.body,
    required this.accent,
    required this.accentFill,
    required this.image,
    required this.onTap,
    required this.semanticLabel,
  });

  final String label;
  final String title;
  final String body;

  /// The label colour and the chevron button's glyph.
  final Color accent;

  /// The chevron button's fill.
  final Color accentFill;
  final Widget image;
  final VoidCallback onTap;
  final String semanticLabel;

  static const double _imageSize = 92;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: Container(
        constraints: const BoxConstraints(minHeight: _imageSize),
        decoration: BoxDecoration(
          color: c.raised,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
                child: SizedBox(width: _imageSize, child: image),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: dmSans(
                          10.5,
                          weight: FontWeight.w700,
                          height: 1.2,
                          tracking: 0.14,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: fraunces(19, height: 1.15, color: c.text),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: dmSans(12, height: 1.38, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Center(
                  child: ExcludeSemantics(
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accentFill,
                        shape: BoxShape.circle,
                      ),
                      child: MoonIcon(
                        MoonIconName.chev,
                        size: 15,
                        strokeWidth: 2.2,
                        color: c.text,
                      ),
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

/// The photo for the EAT card: a curated plant photo (the day's first plant
/// that has one) cropped to the tile, else a tinted tile with the food's emoji.
Widget plantImage(Food? food, Color tone, String emoji) {
  final photo = food == null ? null : plantPhotos[food.id];
  if (photo == null) {
    return ColoredBox(
      color: tone,
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 38))),
    );
  }
  return Image.asset(
    photo.asset,
    fit: BoxFit.cover,
    alignment: photo.alignment,
    excludeFromSemantics: true,
  );
}

/// A clearly temporary tile for a card with no photograph yet (MOVE, RELAX):
/// a soft tint, an icon and the word "photo" so it can't be mistaken for final
/// art. Replace with the approved photograph when it is supplied.
class PlaceholderImage extends StatelessWidget {
  const PlaceholderImage({super.key, required this.tone, required this.icon});

  final Color tone;
  final MoonIconName icon;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return ColoredBox(
      color: tone,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MoonIcon(icon, size: 30, color: c.textMuted),
          const SizedBox(height: 6),
          Text(
            'photo to come',
            style: dmSans(10, weight: FontWeight.w600, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

/// "Start your daily check-in", "1 entry today", "8 entries today".
String diaryEntriesToday(int count) => switch (count) {
  0 => 'Start your daily check-in',
  1 => '1 entry today',
  _ => '$count entries today',
};

/// "Your list is empty", "1 item to buy", "8 items to buy".
String shoppingToBuy(int count) => switch (count) {
  0 => 'Your list is empty',
  1 => '1 item to buy',
  _ => '$count items to buy',
};

/// A quiet Quick access card: a softly tinted background, a large line icon, the
/// feature's name, one live line and a small chevron. The whole card is the tap
/// target.
class QuickAccessCard extends StatelessWidget {
  const QuickAccessCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.onTap,
  });

  /// A decorative icon, drawn about 30 pt.
  final Widget icon;
  final String title;
  final String subtitle;

  /// The card's background.
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Pressable(
      onTap: onTap,
      semanticLabel: '$title. $subtitle',
      child: Container(
        constraints: const BoxConstraints(minHeight: 132),
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 16),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: c.raised,
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: icon),
                  ),
                ),
                const Spacer(),
                MoonIcon(
                  MoonIconName.chev,
                  size: 16,
                  color: c.textMuted,
                  strokeWidth: 2,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(title, style: fraunces(20, height: 1.15, color: c.text)),
            const SizedBox(height: 3),
            Text(subtitle, style: dmSans(13, height: 1.35, color: c.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// A calendar with four small dots, one for each thing a day can hold in My
/// Diary: meals, symptoms, activities and notes. Drawn with the same stroke as
/// the line icons.
class DiaryCheckInIcon extends StatelessWidget {
  const DiaryCheckInIcon({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _CheckInPainter(
          line: c.phase(Phase.luteal).text,
          dots: [
            c.phase(Phase.follicular).accent, // meals
            c.phase(Phase.luteal).accent, // symptoms
            c.phase(Phase.ovulatory).accent, // activities
            c.phase(Phase.menstrual).accent, // notes
          ],
        ),
      ),
    );
  }
}

class _CheckInPainter extends CustomPainter {
  _CheckInPainter({required this.line, required this.dots});

  final Color line;
  final List<Color> dots;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 24; // the 24-unit grid the line icons use
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7 * u
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = line;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(3.5 * u, 5 * u, 17 * u, 15.5 * u),
          Radius.circular(3 * u),
        ),
        stroke,
      )
      ..drawLine(Offset(3.5 * u, 10 * u), Offset(20.5 * u, 10 * u), stroke)
      ..drawLine(Offset(8 * u, 3 * u), Offset(8 * u, 6.5 * u), stroke)
      ..drawLine(Offset(16 * u, 3 * u), Offset(16 * u, 6.5 * u), stroke);
    const spots = [
      Offset(8.5, 13.6),
      Offset(15.5, 13.6),
      Offset(8.5, 17.2),
      Offset(15.5, 17.2),
    ];
    for (final (i, p) in spots.indexed) {
      canvas.drawCircle(
        Offset(p.dx * u, p.dy * u),
        1.45 * u,
        Paint()..color = dots[i],
      );
    }
  }

  @override
  bool shouldRepaint(_CheckInPainter old) =>
      old.line != line || old.dots != dots;
}
