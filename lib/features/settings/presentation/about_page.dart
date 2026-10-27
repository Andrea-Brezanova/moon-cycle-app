import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/build_info.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import 'widgets/settings_widgets.dart';

/// Me › My App › About: exactly which build is installed.
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final info = ref.watch(buildInfoProvider);
    Widget row(String label, String value, {Key? key, bool first = false}) =>
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: first ? null : Border(top: BorderSide(color: c.line)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: dmSans(15, height: 1.3, color: c.textMuted)),
              const SizedBox(width: 16),
              Expanded(
                child: SelectableText(
                  value,
                  key: key,
                  textAlign: TextAlign.end,
                  style: dmSans(
                    15,
                    weight: FontWeight.w600,
                    height: 1.3,
                    color: c.text,
                  ),
                ),
              ),
            ],
          ),
        );
    return SettingsSubScaffold(
      title: 'About',
      children: [
        Column(
          children: [
            row(
              'Version',
              info.versionLine,
              key: const ValueKey('about-version'),
              first: true,
            ),
            row('Commit', info.commit, key: const ValueKey('about-commit')),
            row('Built', info.builtLine, key: const ValueKey('about-built')),
            row(
              'Flavor',
              info.flavorLabel,
              key: const ValueKey('about-flavor'),
            ),
          ],
        ),
        Text(
          'These come from the source this app was built from. “unknown” means '
          'it was built without them; “-dirty” means the source had changes '
          'that were not committed.',
          style: dmSans(13, height: 1.45, color: c.textMuted),
        ),
      ],
    );
  }
}
