import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/app_version.dart';
import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/brand.dart';

/// The MoonCycle mark, wordmark and "Version 1.0 · dev" line, shown once, at
/// the bottom of Me › My App. The full build details (commit, build date) are
/// on the About screen.
class AppFooter extends ConsumerWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final version = ref.watch(appVersionProvider);
    final flavor = ref.watch(appConfigProvider).flavor;
    return Semantics(
      label:
          'MoonCycle, version $version'
          '${flavor == Flavor.prod ? '' : ', ${flavor.name}'}',
      child: ExcludeSemantics(
        child: Opacity(
          opacity: 0.9,
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PhaseRingMark(size: 16),
                  const SizedBox(width: 4),
                  Wordmark(xHeight: 9, color: c.text),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                [
                  'Version $version',
                  if (flavor != Flavor.prod) flavor.name,
                ].join(' · '),
                style: dmSans(12, height: 1, color: c.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
