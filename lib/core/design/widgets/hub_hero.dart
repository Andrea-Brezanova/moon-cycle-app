import 'package:flutter/material.dart';

import '../moon_theme.dart';
import '../tokens/moon_typography.dart';
import 'editorial_text.dart';

/// A hub's opening card: a photograph and, joined beneath it, a heading and a
/// line. The same on Eat, Move and Relax (image width, 1.86 aspect, 24 pt
/// radius, spacing). [asset] is decorative.
class HubHero extends StatelessWidget {
  const HubHero({
    super.key,
    required this.asset,
    required this.heading,
    required this.body,
  });

  final String asset;

  /// The last word is set in italics.
  final String heading;
  final String body;

  static const aspectRatio = 1.86;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Container(
      decoration: BoxDecoration(
        color: c.raised,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Decorative: the heading below says what the page is.
          ExcludeSemantics(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EditorialHeading(
                  italicLastWord(heading),
                  style: fraunces(28, height: 1.15, color: c.text),
                ),
                const SizedBox(height: 8),
                Text(body, style: dmSans(15, height: 1.5, color: c.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
