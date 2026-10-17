import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../preferences/application/preference_providers.dart';
import '../../preferences/domain/appearance.dart';
import 'widgets/settings_widgets.dart';

/// Settings › Appearance: System (the default), Light or Dark. The choice is
/// applied at once and saved on the phone. The selected row carries a check
/// mark as well as a bolder label, and is announced as selected.
class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final selected = ref.watch(appearanceProvider);
    final controller = ref.read(appearanceProvider.notifier);

    return SettingsSubScaffold(
      title: 'Appearance',
      children: [
        Semantics(
          container: true,
          label: 'Appearance',
          child: MoonListGroup(
            children: [
              for (final mode in AppearanceMode.values)
                Pressable(
                  onTap: () => controller.set(mode),
                  selected: mode == selected,
                  semanticLabel: '${mode.label}, ${mode.summary}',
                  child: ExcludeSemantics(
                    child: MoonListRow(
                      label: mode.label,
                      subtitle: mode.summary,
                      showChevron: false,
                      trailing: SizedBox(
                        width: 22,
                        child: mode == selected
                            ? MoonIcon(
                                MoonIconName.check,
                                size: 22,
                                color: c.text,
                                strokeWidth: 2.4,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Text(
          'System follows your phone’s light or dark setting, including when '
          'it changes.',
          style: dmSans(14, height: 1.4, color: c.textMuted),
        ),
      ],
    );
  }
}
