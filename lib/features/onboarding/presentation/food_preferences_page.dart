import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_chip.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../../core/domain/phase.dart';
import '../../content/application/content_providers.dart';
import '../../preferences/domain/diet.dart';
import '../../preferences/presentation/avoid_food_sheet.dart';
import '../application/onboarding_controller.dart';
import 'widgets/onboarding_step.dart';

/// Onboarding step 4 (`04-onboarding-food-preferences`). Continue and "Skip
/// for now" both save everything and open the reveal.
class FoodPreferencesPage extends ConsumerStatefulWidget {
  const FoodPreferencesPage({super.key});

  @override
  ConsumerState<FoodPreferencesPage> createState() =>
      _FoodPreferencesPageState();
}

class _FoodPreferencesPageState extends ConsumerState<FoodPreferencesPage> {
  bool _saving = false;

  Future<void> _finish({required bool skip}) async {
    if (_saving) return;
    setState(() => _saving = true);
    final controller = ref.read(onboardingControllerProvider.notifier);
    if (skip) controller.clearPreferences();
    try {
      await controller.save();
      if (mounted) context.go(Routes.onboardingYourPhase);
    } on Exception {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t save. Please try again.')),
      );
    }
  }

  Future<void> _addAnother() async {
    final choice = await showAvoidFoodSheet(
      context,
      catalogue: ref.read(catalogueProvider),
    );
    final controller = ref.read(onboardingControllerProvider.notifier);
    switch (choice) {
      case AvoidCatalogueFood(:final food):
        if (!ref.read(onboardingControllerProvider).foodIds.contains(food.id)) {
          controller.toggleFood(food.id);
        }
      case AvoidTypedFood(:final label):
        controller.addCustom(label);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final answers = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final catalogue = ref.watch(catalogueProvider);
    final chosen = c.phase(Phase.menstrual);

    return OnboardingStep(
      step: 3,
      overline: 'Your table',
      question: 'Anything you’d rather *not eat?*',
      helper: 'We’ll leave these out of your foods and recipes.',
      content: [
        _Section(
          title: 'How you eat',
          chips: [
            for (final diet in Diet.values)
              MoonChip(
                diet.label,
                height: MoonSize.dietPill,
                state: answers.diet == diet
                    ? MoonChipState.selected
                    : MoonChipState.normal,
                onTap: () => controller.setDiet(diet),
              ),
          ],
        ),
        _Section(
          title: 'Allergies & foods to avoid',
          chips: [
            for (final allergen in catalogue.allergens)
              MoonChip(
                allergen.label,
                palette: chosen,
                state: answers.allergenIds.contains(allergen.id)
                    ? MoonChipState.onList
                    : MoonChipState.normal,
                onTap: () => controller.toggleAllergen(allergen.id),
              ),
            for (final id in answers.foodIds)
              MoonChip(
                catalogue.food(id)!.displayName,
                palette: chosen,
                state: MoonChipState.onList,
                onTap: () => controller.toggleFood(id),
              ),
            for (final label in answers.customAvoidances)
              MoonChip(
                label,
                palette: chosen,
                state: MoonChipState.onList,
                onTap: () => controller.removeCustom(label),
              ),
            MoonOutlineChip('Add another', onTap: _addAnother),
          ],
        ),
      ],
      actions: [
        MoonButton(
          'Continue',
          variant: MoonButtonVariant.secondary,
          onPressed: _saving ? null : () => _finish(skip: false),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextLink.onboarding(
            'Skip for now',
            onTap: () => _finish(skip: true),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.chips});

  final String title;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Overline(title),
      const SizedBox(height: 12),
      Wrap(
        spacing: MoonSpace.chipGap,
        runSpacing: MoonSpace.chipGap,
        children: chips,
      ),
    ],
  );
}
