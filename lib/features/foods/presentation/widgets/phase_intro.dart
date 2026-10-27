import 'package:flutter/material.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_colors.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/editorial_text.dart';
import '../../../../core/domain/phase.dart';
import '../../../content/domain/phase_content.dart';
import '../../../cycle/domain/phase_guidance.dart';

/// The phase explanation (Learn more): season and tagline, the longer approved
/// description, then what your
/// body may need and how to eat this phase, and the suggestions-not-rules note.
class PhaseIntro extends StatelessWidget {
  const PhaseIntro({
    super.key,
    required this.phase,
    required this.content,
    required this.palette,
  });

  final Phase phase;
  final PhaseContent content;
  final PhasePalette palette;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final copy = foodsIntroCopy(phase);
    Widget block(String label, String text) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Overline(label),
        const SizedBox(height: 6),
        Text(text, style: MoonType.body.copyWith(color: c.text)),
        const SizedBox(height: 18),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content.season,
          style: MoonType.season.copyWith(color: palette.text, height: 1.08),
        ),
        const SizedBox(height: 10),
        EditorialHeading(
          italicLastWord(content.tagline),
          style: fraunces(32, height: 1.1),
        ),
        const SizedBox(height: 20),
        if (content.learnMore.isNotEmpty) ...[
          const Overline('About this phase'),
          const SizedBox(height: 6),
          for (final paragraph in content.learnMore.split('\n\n'))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                paragraph,
                style: MoonType.body.copyWith(color: c.text),
              ),
            ),
          const SizedBox(height: 8),
        ],
        block('What your body may need', copy.need),
        block('How to eat this phase', copy.how),
        Text(
          foodsUniversalNote,
          style: dmSans(14, height: 1.4, color: c.textMuted),
        ),
      ],
    );
  }
}
