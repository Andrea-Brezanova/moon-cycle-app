import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/domain/phase.dart';
import '../../content/application/content_providers.dart';
import '../../foods/presentation/ingredient_sheet.dart';
import '../../foods/presentation/widgets/meal_builder_section.dart';
import '../application/home_discovery.dart';
import 'food_emoji.dart';

/// "Build a meal": the same simple guidance as on Foods, in a sheet.
Future<void> showBuildMealSheet(BuildContext context, {required Phase phase}) =>
    showMoonSheet<void>(context, builder: (_) => _BuildMeal(phase: phase));

class _BuildMeal extends ConsumerWidget {
  const _BuildMeal({required this.phase});

  final Phase phase;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SingleChildScrollView(
    child: MealBuilderSection(
      phase: phase,
      onFood: (food) =>
          showFoodSuggestionSheet(context, ref, food: food, phase: phase),
    ),
  );
}

/// "Try something new": three foods from the phase, other than Today's food,
/// from different categories where possible. "Show me 3 more" moves on.
Future<void> showTryNewSheet(BuildContext context, {required Phase phase}) =>
    showMoonSheet<void>(context, builder: (_) => _TryNew(phase: phase));

class _TryNew extends ConsumerStatefulWidget {
  const _TryNew({required this.phase});

  final Phase phase;

  @override
  ConsumerState<_TryNew> createState() => _TryNewState();
}

class _TryNewState extends ConsumerState<_TryNew> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final pages = ref.watch(tryNewPagesProvider(widget.phase));
    final foods = pageOfThree(pages, _page);
    final catalogue = ref.watch(catalogueProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Try something new',
              style: fraunces(32, height: 1.1, color: c.text),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Three foods from this phase.',
            style: dmSans(15, height: 1.4, color: c.textMuted),
          ),
          const SizedBox(height: 14),
          for (final (i, food) in foods.indexed)
            Pressable(
              onTap: () => showFoodSuggestionSheet(
                context,
                ref,
                food: food,
                phase: widget.phase,
              ),
              semanticLabel:
                  '${food.displayName}, '
                  '${catalogue.categoryFor(food).name}',
              child: Container(
                constraints: const BoxConstraints(minHeight: 64),
                decoration: BoxDecoration(
                  border: i > 0 ? Border(top: BorderSide(color: c.line)) : null,
                ),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Text(
                        foodEmoji(food),
                        style: const TextStyle(fontSize: 26, height: 1),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            food.displayName,
                            style: dmSans(
                              17,
                              weight: FontWeight.w600,
                              height: 1.3,
                              color: c.text,
                            ),
                          ),
                          Text(
                            catalogue.categoryFor(food).name,
                            style: dmSans(13, height: 1.3, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                    MoonIcon(
                      MoonIconName.chev,
                      size: 14,
                      color: c.chevron,
                      strokeWidth: 2,
                    ),
                  ],
                ),
              ),
            ),
          if (pages.length > 1) ...[
            const SizedBox(height: 14),
            MoonButton(
              'Show me 3 more',
              variant: MoonButtonVariant.ghost,
              onPressed: () => setState(() => _page++),
            ),
          ],
        ],
      ),
    );
  }
}
