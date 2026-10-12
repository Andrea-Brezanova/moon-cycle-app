import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/number_stepper.dart';
import '../../cycle/domain/cycle_rules.dart';
import '../application/onboarding_controller.dart';
import 'widgets/onboarding_step.dart';

/// Onboarding step 3 (`03-onboarding-cycle-length`).
class CycleLengthPage extends ConsumerWidget {
  const CycleLengthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final answers = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    return OnboardingStep(
      step: 2,
      gap: 22,
      overline: 'Your rhythm',
      question: 'How long is your cycle, *usually?*',
      content: [
        Column(
          children: [
            NumberStepper(
              label: 'Cycle length',
              value: answers.cycleLength,
              min: CycleRules.minCycleLength,
              max: CycleRules.maxCycleLength,
              hint: 'From the first day of one period to the next.',
              onChanged: controller.setCycleLength,
            ),
            NumberStepper(
              label: 'Period length',
              value: answers.periodLength,
              min: CycleRules.minPeriodLength,
              max: CycleRules.maxPeriodLength,
              hint: 'How many days you usually bleed.',
              onChanged: controller.setPeriodLength,
            ),
          ],
        ),
        const InfoNote.plain(
          text: TextSpan(
            text:
                'Not sure? 28 and 5 are good starting points. We’ll adjust as '
                'you log your periods.',
          ),
        ),
      ],
      actions: [
        MoonButton(
          'Continue',
          variant: MoonButtonVariant.secondary,
          onPressed: () => context.push(Routes.onboardingFoodPreferences),
        ),
      ],
    );
  }
}
