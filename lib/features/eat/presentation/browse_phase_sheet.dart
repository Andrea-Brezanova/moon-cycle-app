import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/domain/browse_scope.dart';
import '../../../core/domain/phase.dart';
import '../../content/application/content_providers.dart';
import '../../cycle/application/cycle_providers.dart';
import '../../cycle/application/viewing_phase.dart';
import '../../foods/application/browse_scope.dart';
import '../../recipes/application/recipes_scope.dart';

/// "Browse by phase": your phase, the other phases, and every phase at once.
/// Choosing applies to Foods and Recipes together.
Future<void> showBrowsePhaseSheet(BuildContext context) =>
    showMoonSheet<void>(context, builder: (_) => const _BrowsePhaseSheet());

class _BrowsePhaseSheet extends ConsumerWidget {
  const _BrowsePhaseSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final catalogue = ref.watch(catalogueProvider);
    final actual = ref.watch(actualPhaseProvider);
    final viewing = ref.watch(viewingPhaseProvider);
    final day = ref.watch(cycleStateProvider).value?.cycleDay;
    final all =
        ref.watch(foodsScopeProvider) == BrowseScope.all &&
        ref.watch(recipesScopeProvider) == BrowseScope.all;

    void pick(Phase? phase) {
      if (phase != null) ref.read(viewingPhaseProvider.notifier).choose(phase);
      final scope = phase == null ? BrowseScope.all : BrowseScope.phase;
      ref.read(foodsScopeProvider.notifier).set(scope);
      ref.read(recipesScopeProvider.notifier).set(scope);
      Navigator.of(context, rootNavigator: true).pop();
    }

    Widget row({
      required String title,
      String? subtitle,
      required bool selected,
      required VoidCallback onTap,
      Color? dot,
      MoonIconName? icon,
      bool highlight = false,
    }) => Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: subtitle == null ? title : '$title. $subtitle',
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: highlight ? c.phase(actual).tint : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (dot != null)
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              )
            else if (icon != null)
              MoonIcon(icon, size: 18, color: c.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: dmSans(
                      15,
                      weight: FontWeight.w600,
                      height: 1.25,
                      color: c.text,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: dmSans(12.5, height: 1.3, color: c.textMuted),
                    ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? c.text : null,
                border: selected ? null : Border.all(color: c.line),
              ),
              child: selected
                  ? MoonIcon(
                      MoonIconName.check,
                      size: 14,
                      color: c.bg,
                      strokeWidth: 2.4,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Browse by phase',
              style: fraunces(24, height: 1.1, color: c.text),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'YOUR PHASE',
            style: MoonType.overline.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: 8),
          row(
            title: catalogue.phase(actual).name,
            subtitle: day == null
                ? 'Right for you now'
                : 'Day $day · right for you now',
            selected: !all && viewing == actual,
            dot: c.phase(actual).accent,
            highlight: true,
            onTap: () => pick(actual),
          ),
          const SizedBox(height: 14),
          Text(
            'OTHER PHASES',
            style: MoonType.overline.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: 8),
          for (final p in Phase.values)
            if (p != actual)
              row(
                title: catalogue.phase(p).name,
                selected: !all && viewing == p,
                dot: c.phase(p).accent,
                onTap: () => pick(p),
              ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 1,
            color: c.line,
          ),
          row(
            title: 'All phases',
            subtitle: 'Every food and recipe',
            selected: all,
            icon: MoonIconName.foods,
            onTap: () => pick(null),
          ),
        ],
      ),
    );
  }
}
