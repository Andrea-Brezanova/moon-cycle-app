import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/phase_selector.dart';
import '../../../core/design/widgets/text_link.dart';
import '../application/cycle_providers.dart';
import '../application/viewing_phase.dart';

/// The top of Foods, Recipes and Shop (spec §7.3–7.5): the H1, the shared
/// phase selector, and a line saying which phase is shown: "Your current
/// phase · day 7", or "Browsing luteal · Back to follicular".
class PhaseHeader extends ConsumerWidget {
  const PhaseHeader({
    super.key,
    required this.title,
    this.showPhaseLine = true,
    this.gap = 18,
  });

  final String title;

  /// Foods and Shop show it; Recipes doesn't (spec §7.4).
  final bool showPhaseLine;

  /// 18 on Foods and Shop, 16 on Recipes.
  final double gap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final viewing = ref.watch(viewingPhaseProvider);
    final actual = ref.watch(actualPhaseProvider);
    final day = ref.watch(cycleStateProvider).value?.cycleDay;
    final controller = ref.read(viewingPhaseProvider.notifier);
    final style = dmSans(
      13,
      weight: FontWeight.w500,
      height: 1,
      color: c.textMuted,
    );
    final dot = Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: c.phase(viewing).accent,
        shape: BoxShape.circle,
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        MoonSpace.gutter,
        MediaQuery.viewPaddingOf(context).top + 10,
        MoonSpace.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: MoonType.h1.copyWith(color: c.text)),
          ),
          SizedBox(height: gap),
          PhaseSelector(selected: viewing, onChanged: controller.choose),
          if (!showPhaseLine)
            const SizedBox.shrink()
          else if (viewing == actual) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                dot,
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    day == null
                        ? 'Your current phase'
                        : 'Your current phase · day $day',
                    style: style,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                dot,
                Text('Browsing ${viewing.name} ·', style: style),
                TextLink(
                  'Back to ${actual.name}',
                  onTap: controller.showActual,
                  size: 13,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
