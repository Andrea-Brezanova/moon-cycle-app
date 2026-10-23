import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../cycle/application/viewing_phase.dart';
import 'browse_phase_sheet.dart';

/// The phase on show; opens "Browse by phase".
class PhasePill extends ConsumerWidget {
  const PhasePill({super.key, required this.label, required this.all});

  final String label;
  final bool all;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final viewing = ref.watch(viewingPhaseProvider);
    return Pressable(
      key: const ValueKey('phase-pill'),
      onTap: () => showBrowsePhaseSheet(context),
      semanticLabel: 'Browse by phase. Showing $label',
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: ShapeDecoration(
          color: all ? c.sand : c.phase(viewing).tint,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!all) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: c.phase(viewing).accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
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
            MoonIcon(MoonIconName.down, size: 14, color: c.text),
          ],
        ),
      ),
    );
  }
}
