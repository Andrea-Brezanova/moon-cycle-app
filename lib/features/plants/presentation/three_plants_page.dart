import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_colors.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/dimmed_photo.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../cycle/application/viewing_phase.dart' show actualPhaseProvider;
import '../../home/presentation/widgets/home_v2.dart' show HomeOverline;
import '../../home/presentation/widgets/plant_photos.dart';
import '../application/plant_providers.dart';

/// 3 Plants a Day: three plants from the user's real phase to discover today,
/// the same all day. Tap the ones you'd like to cook with (none, one, two or
/// all three), then "Find a meal" runs the same real-recipe search as Build a
/// meal. Free; never generates anything.
class ThreePlantsPage extends ConsumerWidget {
  const ThreePlantsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final dark = Theme.of(context).brightness == Brightness.dark;
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
    // Nothing chosen means all three.
    final searchIds = chosen.isEmpty ? [for (final f in plants) f.id] : chosen;
    final buttonLabel = switch (chosen.length) {
      1 => 'Find a meal with 1 plant',
      2 => 'Find a meal with 2 plants',
      _ => 'Find a meal with all ${plants.isEmpty ? 3 : plants.length}',
    };

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  SubScreenHeader(
                    backLabel: 'Home',
                    title: '3 Plants a Day',
                    titleSize: 44,
                    onBack: () => context.canPop()
                        ? context.pop()
                        : context.go(Routes.home),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Text(
                      'A little more variety, every day.',
                      style: dmSans(16, height: 1.45, color: c.textMuted),
                    ),
                  ),
                  Container(
                    key: const ValueKey('phase-info'),
                    margin: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(
                        alpha: dark ? 0.20 : 0.14,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR ${content.name.toUpperCase()} PHASE',
                          style: dmSans(
                            12,
                            weight: FontWeight.w600,
                            height: 1.2,
                            tracking: 0.2,
                            color: c.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          content.season,
                          style: fraunces(
                            26,
                            height: 1.15,
                            italic: true,
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          content.tagline,
                          style: dmSans(15, height: 1.4, color: c.text),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: HomeOverline('Today’s three plants'),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(26, 12, 24, 0),
                    child: Text(
                      'Tap the plants you’d like to cook with.',
                      style: dmSans(14, height: 1.4, color: c.textMuted),
                    ),
                  ),
                  if (plants.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                      child: Text(
                        'No plants fit your food preferences in this phase.',
                        key: const ValueKey('no-plants'),
                        style: MoonType.body.copyWith(color: c.textMuted),
                      ),
                    ),
                  for (final f in plants)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                      child: _PlantCard(
                        food: f,
                        phaseName: content.name,
                        why: f.why[phase]?.short,
                        category: catalogue.categoryFor(f).name,
                        selected: picks.contains(f.id),
                        palette: palette,
                        onTap: () =>
                            ref.read(plantPicksProvider.notifier).toggle(f.id),
                      ),
                    ),
                ],
              ),
            ),
            _FindMealBar(
              label: buttonLabel,
              onTap: searchIds.isEmpty
                  ? null
                  : () => context.push(
                      Routes.mealResults(searchIds, fromPlants: true),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The main action, pinned above the tab bar: never disabled while there are
/// plants (nothing chosen searches for all three).
class _FindMealBar extends StatelessWidget {
  const _FindMealBar({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pressable(
            key: const ValueKey('find-meal'),
            onTap: onTap,
            semanticLabel: label,
            child: Container(
              constraints: const BoxConstraints(minHeight: 54),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: ShapeDecoration(
                color: c.text,
                shape: const StadiumBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: dmSans(
                        15.5,
                        weight: FontWeight.w600,
                        height: 1.2,
                        color: c.bg,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  MoonIcon(
                    MoonIconName.arrow,
                    size: 17,
                    color: c.bg,
                    strokeWidth: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Recipes featuring your picks.',
            textAlign: TextAlign.center,
            style: dmSans(12.5, height: 1.3, color: c.textMuted),
          ),
        ],
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
    final photo = plantPhotos[food.id];
    return Pressable(
      onTap: onTap,
      checked: selected,
      semanticLabel:
          '${food.displayName}, ${category.toLowerCase()}, '
          '${selected ? 'selected' : 'not selected'}',
      child: Container(
        key: ValueKey('plant-${food.id}'),
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? palette.tint : c.raised,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? palette.accent.withValues(alpha: 0.6) : c.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: photo != null
                      ? DimmedPhoto(
                          dim: Theme.of(context).brightness == Brightness.dark,
                          child: Image.asset(
                            photo.asset,
                            fit: BoxFit.cover,
                            alignment: photo.alignment,
                          ),
                        )
                      : ColoredBox(
                          color: palette.tint,
                          child: Center(
                            child: MoonIcon(
                              MoonIconName.foods,
                              size: 28,
                              color: palette.text,
                            ),
                          ),
                        ),
                ),
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
                        13,
                        weight: FontWeight.w500,
                        height: 1.3,
                        color: c.textMuted,
                      ),
                    ),
                    if (why != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        why!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: dmSans(14, height: 1.4, color: c.text),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? c.text : null,
                  border: selected
                      ? null
                      : Border.all(color: c.chevron, width: 1.5),
                ),
                child: selected
                    ? Center(
                        child: MoonIcon(
                          MoonIconName.check,
                          size: 16,
                          color: c.bg,
                          strokeWidth: 2.4,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
