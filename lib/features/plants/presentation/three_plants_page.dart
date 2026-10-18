import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_colors.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../cycle/application/viewing_phase.dart' show actualPhaseProvider;
import '../../foods/presentation/food_emoji.dart';
import '../application/plant_providers.dart';

/// 3 Plants a Day: three plants from the user's real phase to discover today,
/// the same all day. Pick one, two or all three, and "Create my meal" finds real
/// recipes with the same search as Build a meal. Free; never generates anything.
class ThreePlantsPage extends ConsumerWidget {
  const ThreePlantsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final phase = ref.watch(actualPhaseProvider);
    final palette = c.phase(phase);
    final catalogue = ref.watch(catalogueProvider);
    final content = catalogue.phase(phase);
    final plants = ref.watch(threePlantsProvider);
    final picks = ref.watch(plantPicksProvider);
    final chosen = [
      for (final f in plants)
        if (picks.contains(f.id)) f.id,
    ];

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 42 + 76),
          children: [
            SubScreenHeader(
              backLabel: 'Home',
              title: '3 Plants a Day',
              titleSize: 36,
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(Routes.home),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MoonSpace.gutter,
                8,
                MoonSpace.gutter,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'A little more variety, every day.',
                    style: MoonType.body.copyWith(color: c.textMuted),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    key: const ValueKey('phase-info'),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: palette.tint,
                      borderRadius: BorderRadius.circular(MoonRadius.gridCard),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Overline('Your ${content.name} phase'),
                        const SizedBox(height: 6),
                        Text(
                          content.season,
                          style: fraunces(
                            20,
                            height: 1.2,
                            color: palette.text,
                          ).copyWith(fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          content.tagline,
                          style: dmSans(14, height: 1.4, color: c.text),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Overline('Today’s three plants'),
                  const SizedBox(height: 4),
                  if (plants.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'No plants fit your food preferences in this phase.',
                        key: const ValueKey('no-plants'),
                        style: MoonType.body.copyWith(color: c.textMuted),
                      ),
                    ),
                  for (final f in plants)
                    _PlantCard(
                      food: f,
                      phaseName: content.name,
                      why: f.why[phase]?.short,
                      category: catalogue.categoryFor(f).name,
                      selected: picks.contains(f.id),
                      palette: palette,
                      onTap: () =>
                          ref.read(plantPicksProvider.notifier).toggle(f.id),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    'Choose one, two, or all three plants. We’ll find recipes '
                    'featuring your picks.',
                    style: dmSans(14, height: 1.45, color: c.textMuted),
                  ),
                  const SizedBox(height: 16),
                  MoonButton(
                    'Create my meal',
                    onPressed: chosen.isEmpty
                        ? null
                        : () => context.push(
                            Routes.mealResults(chosen, fromPlants: true),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlantCard extends StatelessWidget {
  const _PlantCard({
    required this.food,
    required this.phaseName,
    required this.why,
    required this.category,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final Food food;
  final String phaseName;
  final String? why;
  final String category;
  final bool selected;
  final PhasePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Pressable(
        onTap: onTap,
        selected: selected,
        semanticLabel:
            '${food.displayName}, ${category.toLowerCase()}, featured in your '
            '$phaseName phase. ${selected ? 'Chosen' : 'Not chosen'}',
        child: Container(
          key: ValueKey('plant-${food.id}'),
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? palette.tint : c.bg,
            borderRadius: BorderRadius.circular(MoonRadius.gridCard),
            border: Border.all(
              color: selected ? c.text : c.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: ExcludeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  foodEmoji(food),
                  style: const TextStyle(fontSize: 34, height: 1.1),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.displayName,
                        style: fraunces(22, height: 1.15, color: c.text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category,
                        style: dmSans(
                          12,
                          weight: FontWeight.w600,
                          height: 1.3,
                          color: c.textMuted,
                        ),
                      ),
                      if (why != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          why!,
                          style: dmSans(14, height: 1.4, color: c.text),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? c.text : null,
                    border: Border.all(
                      color: selected ? c.text : c.textMuted,
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? MoonIcon(
                          MoonIconName.check,
                          size: 15,
                          color: c.bg,
                          strokeWidth: 2.4,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
