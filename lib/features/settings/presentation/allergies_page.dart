import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_chip.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/domain/phase.dart';
import '../../content/application/content_providers.dart';
import '../../preferences/application/preference_providers.dart';
import '../../preferences/data/preferences_repository.dart';
import '../../preferences/domain/food_avoidance.dart';
import '../../preferences/presentation/avoid_food_sheet.dart';
import 'widgets/settings_widgets.dart';

/// Settings › Allergies & foods to avoid (`28-settings-allergies`). Changes
/// are saved as they're made.
class AllergiesPage extends ConsumerWidget {
  const AllergiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final catalogue = ref.watch(catalogueProvider);
    final avoidances = ref.watch(avoidancesProvider).value ?? const [];
    final repository = ref.read(preferencesRepositoryProvider);
    final chosen = c.phase(Phase.menstrual);

    final allergens = {
      for (final a in avoidances.whereType<AllergenAvoidance>())
        a.allergenId: a.id,
    };
    final specific = [
      for (final a in avoidances)
        if (switch (a) {
              FoodItemAvoidance(:final foodId) =>
                catalogue.food(foodId)?.displayName,
              CustomAvoidance(:final label) => label,
              AllergenAvoidance() => null,
            }
            case final name?)
          (a.id, name),
    ];

    Future<void> search() async {
      final choice = await showAvoidFoodSheet(context, catalogue: catalogue);
      switch (choice) {
        case AvoidCatalogueFood(:final food):
          await repository.avoidFood(food.id);
        case AvoidTypedFood(:final label):
          await repository.avoidCustom(label);
        case null:
          break;
      }
    }

    return SettingsSubScaffold(
      title: 'Allergies & foods to *avoid*',
      titleSize: 36,
      children: [
        const SettingsHelper('We hide foods and recipes that contain these.'),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Overline('Common allergens'),
            const SizedBox(height: 12),
            Wrap(
              spacing: MoonSpace.chipGap,
              runSpacing: MoonSpace.chipGap,
              children: [
                for (final allergen in catalogue.allergens)
                  MoonChip(
                    allergen.label,
                    palette: chosen,
                    state: allergens.containsKey(allergen.id)
                        ? MoonChipState.onList
                        : MoonChipState.normal,
                    onTap: () => allergens.containsKey(allergen.id)
                        ? repository.removeAvoidance(allergens[allergen.id]!)
                        : repository.avoidAllergen(allergen.id),
                  ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Overline('Specific foods'),
            const SizedBox(height: 12),
            _SearchField(onTap: search),
            if (specific.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: MoonSpace.chipGap,
                runSpacing: MoonSpace.chipGap,
                children: [
                  for (final (id, name) in specific)
                    MoonRemovableChip(
                      label: name,
                      tint: chosen.tint,
                      removeLabel: 'Remove ${name.toLowerCase()}',
                      onRemove: () => repository.removeAvoidance(id),
                    ),
                ],
              ),
            ],
          ],
        ),
        const InfoNote(
          icon: MoonIconName.avoid,
          text: TextSpan(
            text:
                'Always check labels. We filter with our ingredient data, but '
                'we can’t guarantee a food or recipe is free from an allergen.',
          ),
        ),
      ],
    );
  }
}

/// Looks like the search field; opens the food search sheet (the same one
/// as onboarding's "Add another").
class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Search foods to avoid',
      child: Container(
        height: MoonSize.input,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: ShapeDecoration(
          color: c.raised,
          shape: StadiumBorder(side: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            MoonIcon(
              MoonIconName.search,
              size: 18,
              color: c.textMuted,
              strokeWidth: 2,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search foods to avoid',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: dmSans(16, height: 1, color: c.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
