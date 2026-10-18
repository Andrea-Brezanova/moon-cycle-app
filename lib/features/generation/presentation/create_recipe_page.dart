import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../discovery/domain/recipe_matcher.dart';
import '../../foods/application/meal_selection.dart';
import '../application/generation_providers.dart';
import '../application/recipe_creator.dart';
import '../domain/generation_failure.dart';

/// The fallback: makes a new recipe for the chosen foods, with progress, a
/// retry that cannot create a second recipe, and a way back. A finished recipe
/// opens in the normal recipe page; it is already saved to the user's private
/// recipes.
class CreateRecipePage extends ConsumerStatefulWidget {
  const CreateRecipePage({super.key, required this.choice});

  final MealChoice choice;

  @override
  ConsumerState<CreateRecipePage> createState() => _CreateRecipePageState();
}

class _CreateRecipePageState extends ConsumerState<CreateRecipePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = ref.read(recipeCreationProvider.notifier);
      controller.reset();
      controller.start(
        MealSelection(
          proteinId: widget.choice.proteinId,
          baseId: widget.choice.baseId,
          plantIds: widget.choice.plantIds,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final state = ref.watch(recipeCreationProvider);
    final controller = ref.read(recipeCreationProvider.notifier);

    ref.listen(recipeCreationProvider, (_, next) {
      if (next is CreationDone && !next.existing) {
        // Straight to the recipe, in the Recipes tab; back returns to the list.
        context.go(Routes.recipe(next.recipe.id));
      }
    });

    final body = switch (state) {
      CreationIdle() || CreationRunning() => _Progress(
        step: state is CreationRunning ? state.step : CreationStep.checking,
      ),
      CreationError(:final failure) => _Failure(
        failure: failure,
        onRetry: controller.retry,
        onBack: () => context.pop(),
      ),
      CreationDone(:final recipe) => _AlreadySaved(
        title: recipe.recipe.title,
        onOpen: () => context.go(Routes.recipe(recipe.id)),
        onAnother: controller.makeAnother,
      ),
    };

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 42 + 76),
          children: [
            SubScreenHeader(
              backLabel: 'Your meal',
              onBack: () => context.pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MoonSpace.gutter,
                12,
                MoonSpace.gutter,
                0,
              ),
              child: body,
            ),
          ],
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.step});

  final CreationStep step;

  static const _labels = {
    CreationStep.checking: 'Checking your choices',
    CreationStep.writing: 'Writing your recipe',
    CreationStep.validating: 'Checking the recipe',
    CreationStep.repairing: 'Improving the recipe',
    CreationStep.saving: 'Saving it to your recipes',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Creating your recipe',
            style: fraunces(30, height: 1.12, color: c.text),
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          liveRegion: true,
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  _labels[step]!,
                  key: const ValueKey('creation-step'),
                  style: MoonType.body.copyWith(color: c.text),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'You can leave this screen: the recipe is saved to My recipes when '
          'it is ready.',
          style: dmSans(13, height: 1.4, color: c.textMuted),
        ),
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({
    required this.failure,
    required this.onRetry,
    required this.onBack,
  });

  final GenerationFailure failure;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  static String message(GenerationFailureKind kind) => switch (kind) {
    GenerationFailureKind.unavailable =>
      'Creating recipes isn’t available yet.',
    GenerationFailureKind.notSignedIn =>
      'Creating a recipe needs an account. Browsing never does.',
    GenerationFailureKind.notEntitled =>
      'Creating recipes is part of Moon Cycle Premium.',
    GenerationFailureKind.quotaExceeded =>
      'You’ve used this month’s recipes. They renew next month.',
    GenerationFailureKind.rateLimited =>
      'That was a lot at once. Please try again in a minute.',
    GenerationFailureKind.timeout =>
      'That took too long. Nothing was used. Please try again.',
    GenerationFailureKind.network =>
      'We couldn’t reach the service. Check your connection and try again.',
    GenerationFailureKind.invalidResult =>
      'We couldn’t make a recipe we’re happy with for these foods. Nothing '
          'was used. You can try again or change a food.',
    GenerationFailureKind.invalidSelection =>
      'These choices can’t make a recipe. Please change them.',
    GenerationFailureKind.unknown =>
      'Something went wrong. Nothing was used. Please try again.',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'We couldn’t create it',
            style: fraunces(30, height: 1.12, color: c.text),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message(failure.kind),
          key: const ValueKey('creation-failure'),
          style: MoonType.body.copyWith(color: c.text),
        ),
        const SizedBox(height: 20),
        if (failure.retryable)
          MoonButton('Try again', onPressed: onRetry)
        else
          MoonButton('Back', onPressed: onBack),
        if (failure.retryable) ...[
          const SizedBox(height: 12),
          Center(child: TextLink('Change my foods', onTap: onBack)),
        ],
      ],
    );
  }
}

/// The same foods already have a saved recipe: open it, or make another.
class _AlreadySaved extends StatelessWidget {
  const _AlreadySaved({
    required this.title,
    required this.onOpen,
    required this.onAnother,
  });

  final String title;
  final VoidCallback onOpen;
  final VoidCallback onAnother;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'You already have this',
            style: fraunces(30, height: 1.12, color: c.text),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'You made “$title” from these foods.',
          key: const ValueKey('already-saved'),
          style: MoonType.body.copyWith(color: c.text),
        ),
        const SizedBox(height: 20),
        MoonButton('Open it', onPressed: onOpen),
        const SizedBox(height: 12),
        MoonButton(
          'Make another version',
          variant: MoonButtonVariant.ghost,
          onPressed: onAnother,
        ),
      ],
    );
  }
}
