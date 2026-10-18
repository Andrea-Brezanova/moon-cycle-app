import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../cycle/application/viewing_phase.dart';
import '../../entitlements/application/entitlement_providers.dart';
import '../../entitlements/domain/entitlements.dart';
import 'food_detail_page.dart';
import 'widgets/meal_builder_section.dart';

/// Build a Balanced Meal: its own destination, reached from Home and from a
/// food's page. Premium only: a free user who reaches it (a link, a restored
/// route) sees why and is pointed to the existing Subscription page.
class MealBuilderPage extends ConsumerWidget {
  const MealBuilderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final allowed = ref.watch(featureGateProvider).canUse(Feature.buildMeal);
    final phase = ref.watch(viewingPhaseProvider);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 42 + 76),
          children: [
            SubScreenHeader(
              backLabel: 'Foods',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(Routes.home),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MoonSpace.gutter,
                12,
                MoonSpace.gutter,
                0,
              ),
              child: allowed
                  ? MealBuilderSection(
                      phase: phase,
                      onFood: (food) => openFoodDetail(
                        context,
                        ref,
                        food: food,
                        phase: phase,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'Build a balanced meal',
                            style: fraunces(26, height: 1.12, color: c.text),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Build a Meal is part of Moon Cycle Premium.',
                          style: MoonType.body.copyWith(color: c.text),
                        ),
                        const SizedBox(height: 18),
                        MoonButton(
                          'See Premium',
                          expand: false,
                          onPressed: () => context.go(
                            Routes.settings(SettingsPage.subscription),
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
