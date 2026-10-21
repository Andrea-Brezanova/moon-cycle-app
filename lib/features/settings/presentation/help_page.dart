import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/config/app_links.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/pressable.dart';
import 'widgets/settings_widgets.dart';

/// The Help questions. Only the first answer is drawn; the spec says every
/// answer needs content review before release (spec §11.5).
// TODO(open-question): review all answers; write "irregular cycle".
const helpQuestions = [
  (
    'How is my phase worked out?',
    'From the start of your last period and your usual cycle and period '
        'length. Ovulation is estimated 14 days before your next period, so '
        'phase dates are estimates, not measurements.',
  ),
  ('What if my cycle is irregular?', '[Answer needs content review]'),
  (
    'Is Moon Cycle a contraceptive or fertility tool?',
    // The wording of the note in My Cycle.
    'No. Phases are estimates based on your dates. Moon Cycle isn’t a '
        'contraceptive or a fertility tool.',
  ),
  (
    'Where is my data stored?',
    // The wording of the note in Privacy & Data.
    'Your data lives on this phone. Cycle dates, food preferences and your '
        'shopping list are stored only here, encrypted. Nothing is sent to a '
        'server.',
  ),
  (
    'Why can’t I see some foods?',
    'We leave out foods and recipes that don’t fit how you eat, and hide '
        'those that contain the allergies and foods you avoid. You can change '
        'both in Settings.',
  ),
];

/// Settings › Help (`32-settings-help`): questions that open in place,
/// "Contact support" and the disclaimer.
class HelpPage extends ConsumerStatefulWidget {
  const HelpPage({super.key});

  @override
  ConsumerState<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends ConsumerState<HelpPage> {
  // The first question is open, as drawn.
  final _open = <int>{0};

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final email = ref.watch(appLinksProvider).supportEmail;

    return SettingsSubScaffold(
      title: 'Help',
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Overline('Questions'),
            const SizedBox(height: 6),
            for (final (i, (question, answer)) in helpQuestions.indexed)
              Container(
                decoration: BoxDecoration(
                  border: i == 0
                      ? null
                      : Border(top: BorderSide(color: c.line)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Pressable(
                      onTap: () => setState(
                        () =>
                            _open.contains(i) ? _open.remove(i) : _open.add(i),
                      ),
                      expanded: _open.contains(i),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 60),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                question,
                                style: dmSans(
                                  17,
                                  weight: FontWeight.w500,
                                  height: 1.3,
                                  color: c.text,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            AnimatedRotation(
                              turns: _open.contains(i) ? 0.5 : 0,
                              duration: const Duration(milliseconds: 150),
                              child: MoonIcon(
                                MoonIconName.down,
                                size: 18,
                                color: c.removeIcon,
                                strokeWidth: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_open.contains(i))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          answer,
                          style: dmSans(15, height: 1.55, color: c.textMuted),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
        MoonButton(
          'Contact support',
          variant: MoonButtonVariant.secondary,
          // TODO(open-question): the support address. Disabled until set.
          onPressed: email == null
              ? null
              : () => launchUrl(
                  Uri(
                    scheme: 'mailto',
                    path: email,
                    query: 'subject=Moon%20Cycle%20support',
                  ),
                ),
        ),
        const SettingsFootnote(
          'Moon Cycle offers general food guidance, not medical advice. Talk '
          'to a doctor about symptoms or changes in your cycle.',
        ),
      ],
    );
  }
}
