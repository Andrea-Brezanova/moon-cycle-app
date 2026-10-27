import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../content/application/content_providers.dart';
import '../application/cycle_providers.dart';

/// A phase dot and "FOLLICULAR · DAY 7" (the real phase and cycle day), 8 pt
/// above the title.
class PhaseOverline extends ConsumerWidget {
  const PhaseOverline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final state = ref.watch(cycleStateProvider).value;
    if (state == null) return const SizedBox.shrink();
    final name = ref.watch(catalogueProvider).phase(state.phase).name;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: c.phase(state.phase).accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              '${name.toUpperCase()} · DAY ${state.cycleDay}',
              style: dmSans(
                12,
                weight: FontWeight.w700,
                height: 1.2,
                tracking: 0.18,
                color: c.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
