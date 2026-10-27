import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/hero_tokens.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/dimmed_photo.dart';
import '../../../../core/design/widgets/editorial_text.dart';
import '../../../../core/design/widgets/moon_icon.dart';
import '../../../../core/design/widgets/pressable.dart';
import '../../../../core/design/widgets/text_link.dart';
import '../../../../core/domain/phase.dart';

/// A Home section header: DM Sans 13 bold, 0.22em tracking, uppercase, in the
/// text colour, 2 pt in from the left. 12 pt separates it from its content.
class HomeOverline extends StatelessWidget {
  const HomeOverline(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(
          text.toUpperCase(),
          style: dmSans(
            13,
            weight: FontWeight.w700,
            height: 1.2,
            tracking: 0.22,
            color: c.text,
          ),
        ),
      ),
    );
  }
}

/// Today's focus: the phase's own soft background, a Fraunces headline with
/// its last word in italic, its paragraphs (the card grows to fit them), a link to the phase page and a leaf
/// sprig in the corner. The copy comes from the phase content.
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
    final palette = c.phase(phase);
    return Container(
      decoration: BoxDecoration(
        color: dark ? HeroTokens.darkSolid : HeroTokens.lightWash[phase],
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Decorative, in the bottom-right corner; the text column is
          // narrow enough to clear it.
          Positioned(
            right: -14,
            bottom: -22,
            child: ExcludeSemantics(
              child: Transform.scale(
                scale: 0.9,
                alignment: Alignment.bottomRight,
                child: SizedBox(
                  width: 118,
                  height: 190,
                  child: CustomPaint(
                    painter: FocusSprigPainter(color: palette.accent),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 232),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: EditorialHeading(
                      italicLastWord(headline),
                      style: fraunces(28, height: 1.12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final (i, paragraph) in body.split('\n\n').indexed) ...[
                    if (i > 0) const SizedBox(height: 10),
                    Text(
                      paragraph,
                      style: dmSans(15, height: 1.5, color: c.text),
                    ),
                  ],
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextLink(
                        'Learn more about your phase\u00A0→',
                        onTap: onMore,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The leaf sprig on Today's focus (drawn from the Home board): a curved stem
/// with eight leaves, in line art with a light fill, in the phase colour.
class FocusSprigPainter extends CustomPainter {
  FocusSprigPainter({required this.color});

  final Color color;

  /// Where each leaf is attached on the 118 × 190 board: x, y, rotation in
  /// degrees, scale.
  static const _leaves = [
    (66.0, 160.0, -150.0, 1.05),
    (68.0, 140.0, -30.0, 0.95),
    (61.0, 116.0, -160.0, 1.0),
    (63.0, 96.0, -40.0, 0.9),
    (63.0, 74.0, -150.0, 0.85),
    (70.0, 52.0, -50.0, 0.8),
    (78.0, 34.0, -140.0, 0.7),
    (88.0, 16.0, -60.0, 0.6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 118, size.height / 190);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    final stem = Path()
      ..moveTo(70, 190)
      ..cubicTo(66, 150, 58, 110, 64, 70)
      ..cubicTo(68, 44, 78, 24, 92, 8);
    canvas.drawPath(stem, line..strokeWidth = 1.6);
    final leaf = Path()
      ..moveTo(0, 0)
      ..cubicTo(9, -10, 27, -10, 38, 0)
      ..cubicTo(27, 10, 9, 10, 0, 0)
      ..close();
    for (final (x, y, deg, scale) in _leaves) {
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(deg * math.pi / 180)
        ..scale(scale);
      canvas
        ..drawPath(leaf, Paint()..color = color.withValues(alpha: 0.14))
        ..drawPath(leaf, line..strokeWidth = 1.3)
        ..drawLine(
          const Offset(3, 0),
          const Offset(33, 0),
          line..strokeWidth = 1,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(FocusSprigPainter old) => old.color != color;
}

/// One of the three daily picks: a photo and a text column, side by side (the
/// photo on the left or the right), the whole block tappable. Suggestions
/// only: nothing to complete or score.
class PickBlock extends StatelessWidget {
  const PickBlock({
    super.key,
    required this.photoOnLeft,
    required this.asset,
    required this.focus,
    required this.label,
    required this.labelColor,
    required this.title,
    required this.body,
    required this.link,
    required this.onTap,
    this.divider = false,
  });

  final bool photoOnLeft;
  final String asset;

  /// Where the subject is (0 to 1 from the top left), so the crop keeps it.
  final Offset focus;
  final String label;
  final Color labelColor;
  final String title;
  final String body;
  final String link;
  final VoidCallback onTap;

  /// A hairline above the block (blocks 2 and 3).
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final photo = ExcludeSemantics(
      child: SizedBox(
        height: 176,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: DimmedPhoto(
            dim: dark,
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              alignment: Alignment(focus.dx * 2 - 1, focus.dy * 2 - 1),
            ),
          ),
        ),
      ),
    );
    final text = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: dmSans(
              11,
              weight: FontWeight.w700,
              height: 1.2,
              tracking: 0.18,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(title, style: fraunces(24, height: 1.08, color: c.text)),
          const SizedBox(height: 6),
          Text(body, style: dmSans(13.5, height: 1.4, color: c.textMuted)),
          const SizedBox(height: 10),
          _UnderlinedLink(link),
        ],
      ),
    );
    return Pressable(
      onTap: onTap,
      semanticLabel: '$label, $title. $body $link',
      child: Container(
        padding: EdgeInsets.only(top: divider ? 18 : 0),
        decoration: BoxDecoration(
          border: divider ? Border(top: BorderSide(color: c.line)) : null,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: photoOnLeft ? photo : text),
              const SizedBox(width: 16),
              Expanded(child: photoOnLeft ? text : photo),
            ],
          ),
        ),
      ),
    );
  }
}

/// "See the plants →": DM Sans 14 semibold with a 2 pt accent underline.
class _UnderlinedLink extends StatelessWidget {
  const _UnderlinedLink(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.ochre, width: 2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: dmSans(
                14,
                weight: FontWeight.w600,
                height: 1.2,
                color: c.text,
              ),
            ),
          ),
          const SizedBox(width: 6),
          MoonIcon(MoonIconName.arrow, size: 14, color: c.text, strokeWidth: 2),
        ],
      ),
    );
  }
}

/// Home's bottom section, "Your space": one softly tinted card holding the
/// My Collections row (a bookmark, a live count, a chevron) and, below a
/// hairline, two photo shortcuts: My Diary and Shopping List. Everything shown
/// is read live from the app's own data.
class YourSpaceCard extends StatelessWidget {
  const YourSpaceCard({
    super.key,
    required this.phase,
    required this.collectionsCount,
    required this.onCollections,
    required this.onDiary,
    required this.onShopping,
  });

  final Phase phase;

  /// The number of saved items; the badge is hidden at 0.
  final int collectionsCount;
  final VoidCallback onCollections;
  final VoidCallback onDiary;
  final VoidCallback onShopping;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final big =
        MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(14) > 14 * 1.3;
    final shortcuts = [
      _Shortcut(
        key: const ValueKey('your-space-diary'),
        asset: 'assets/images/home/quick_my_diary.jpg',
        focus: const Alignment(0, -0.2),
        title: 'My Diary',
        wrap: big,
        onTap: onDiary,
      ),
      _Shortcut(
        key: const ValueKey('your-space-shopping'),
        asset: 'assets/images/home/quick_shopping_list.jpg',
        focus: const Alignment(-0.1, -0.2),
        title: 'Shopping List',
        wrap: big,
        onTap: onShopping,
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? HeroTokens.darkSolid : HeroTokens.lightWash[phase],
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Pressable(
            key: const ValueKey('your-space-collections'),
            onTap: onCollections,
            semanticLabel: collectionsCount == 0
                ? 'My Collections'
                : 'My Collections, $collectionsCount saved',
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.all(2),
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.raised,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: MoonIcon(
                          MoonIconName.bookmark,
                          size: 20,
                          color: c.text,
                          strokeWidth: 1.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              Text(
                                'My Collections',
                                style: fraunces(18, height: 1.1, color: c.text),
                              ),
                              if (collectionsCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.raised,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '$collectionsCount',
                                    key: const ValueKey('collections-badge'),
                                    style: dmSans(
                                      11.5,
                                      weight: FontWeight.w700,
                                      height: 1.3,
                                      color: c.text,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Recipes, workouts, sounds',
                            style: dmSans(
                              12.5,
                              height: 1.3,
                              color: c.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: c.raised,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: MoonIcon(
                          MoonIconName.chev,
                          size: 14,
                          color: c.text,
                          strokeWidth: 2.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            color: c.line,
          ),
          const SizedBox(height: 12),
          if (big)
            Column(
              children: [shortcuts[0], const SizedBox(height: 8), shortcuts[1]],
            )
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: shortcuts[0]),
                  const SizedBox(width: 8),
                  Expanded(child: shortcuts[1]),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    super.key,
    required this.asset,
    required this.focus,
    required this.title,
    required this.wrap,
    required this.onTap,
  });

  final String asset;
  final Alignment focus;
  final String title;

  /// Large text or a narrow screen: titles may take two lines.
  final bool wrap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Pressable(
      onTap: onTap,
      semanticLabel: title,
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: c.raised,
          borderRadius: BorderRadius.circular(18),
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: DimmedPhoto(
                    dim: dark,
                    child: Image.asset(
                      asset,
                      fit: BoxFit.cover,
                      alignment: focus,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: wrap ? 2 : 1,
                      overflow: wrap ? null : TextOverflow.clip,
                      style: fraunces(15, height: 1.1, color: c.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
