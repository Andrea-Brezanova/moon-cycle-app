import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_chip.dart';
import '../../preferences/application/preference_providers.dart';
import '../../preferences/data/preferences_repository.dart';
import '../../preferences/domain/diet.dart';
import 'widgets/settings_widgets.dart';

/// Settings › Food Preferences (`27-settings-food-preferences`): the diet
/// pills (saved on tap) and what each choice leaves out.
class FoodPreferencesSettingsPage extends ConsumerWidget {
  const FoodPreferencesSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final diet = ref.watch(dietProvider).value;
    final repository = ref.read(preferencesRepositoryProvider);

    return SettingsSubScaffold(
      backLabel: 'My App',
      title: 'Food Preferences',
      gap: 26,
      children: [
        const SettingsHelper(
          'We’ll leave out foods and recipes that don’t fit how you eat.',
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Overline('How you eat'),
            const SizedBox(height: 12),
            Wrap(
              spacing: MoonSpace.chipGap,
              runSpacing: MoonSpace.chipGap,
              children: [
                for (final d in Diet.values)
                  MoonChip(
                    d.label,
                    height: MoonSize.dietPill,
                    state: d == diet
                        ? MoonChipState.selected
                        : MoonChipState.normal,
                    onTap: () => repository.saveDiet(d),
                  ),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.line)),
          ),
          child: Column(
            children: [
              for (final d in Diet.values)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: c.line)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.label,
                        style: dmSans(
                          15,
                          weight: FontWeight.w600,
                          height: 1.3,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          d.summary,
                          textAlign: TextAlign.right,
                          style: dmSans(14, height: 1.4, color: c.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
