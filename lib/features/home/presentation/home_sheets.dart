import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/design/widgets/recipe_photo.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../cycle/application/viewing_phase.dart';
import '../../foods/presentation/food_emoji.dart';
import '../../recipes/presentation/widgets/recipe_image.dart';
import '../application/try_something_new.dart';

/// "Try something new": Today's food and two more foods from the real phase,
/// each with a recipe that uses it. "Show me more" moves to the next page.
Future<void> showTryNewSheet(BuildContext context) =>
    showMoonSheet<void>(context, builder: (_) => const _TryNew());

class _TryNew extends ConsumerStatefulWidget {
  const _TryNew();

  @override
  ConsumerState<_TryNew> createState() => _TryNewState();
}

class _TryNewState extends ConsumerState<_TryNew> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final pages = ref.watch(tryNewPagesProvider);
    final phase = ref.watch(actualPhaseProvider);
    final suggestions = suggestionPage(pages, _page);

    void open(String route) {
      final router = GoRouter.of(context);
      Navigator.pop(context);
      router.push(route);
    }

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
            'Three foods from your ${phase.name} phase, each with a recipe '
            'to try.',
            style: dmSans(15, height: 1.4, color: c.textMuted),
          ),
          const SizedBox(height: 14),
          if (suggestions.isEmpty)
            Text(
              'No suggestions fit your food preferences right now.',
              style: dmSans(15, height: 1.4, color: c.textMuted),
            ),
          for (final (i, s) in suggestions.indexed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: i > 0 ? Border(top: BorderSide(color: c.line)) : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 84,
                    child: Pressable(
                      onTap: () => open(Routes.recipe(s.recipe.id)),
                      semanticLabel: s.recipe.title,
                      child: RecipePhoto(
                        height: 84,
                        radius: 16,
                        palette: c.phase(s.recipe.phase),
                        image: recipeImage(s.recipe),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.isTodaysFood
                              ? 'TODAY’S FOOD · ${s.food.displayName}'
                              : s.food.displayName,
                          style: dmSans(
                            12,
                            weight: FontWeight.w600,
                            height: 1.3,
                            color: c.textMuted,
                          ),
                        ),
                        Pressable(
                          onTap: () => open(Routes.recipe(s.recipe.id)),
                          semanticLabel:
                              '${s.recipe.title}, ${s.recipe.minutes} minutes',
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 44),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                s.recipe.title,
                                style: fraunces(
                                  18,
                                  weight: FontWeight.w500,
                                  height: 1.2,
                                  color: c.text,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            ExcludeSemantics(
                              child: Text(
                                foodEmoji(s.food),
                                style: const TextStyle(fontSize: 16, height: 1),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: TextLink(
                                'About ${s.food.displayName.toLowerCase()}',
                                size: 14,
                                onTap: () =>
                                    open(Routes.food(s.food.id, phase: phase)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (pages.length > 1) ...[
            const SizedBox(height: 10),
            MoonButton(
              'Show me more',
              variant: MoonButtonVariant.ghost,
              onPressed: () => setState(() => _page++),
            ),
          ],
        ],
      ),
    );
  }
}
