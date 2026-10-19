import 'package:flutter/material.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/hero_tokens.dart';
import '../../../../core/design/tokens/moon_colors.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/editorial_text.dart';
import '../../../../core/design/widgets/moon_icon.dart';
import '../../../../core/design/widgets/pressable.dart';
import '../../../../core/design/widgets/text_link.dart';
import '../../../../core/domain/phase.dart';
import '../../../content/domain/food.dart';
import '../../../foods/presentation/food_emoji.dart';
import 'plant_photos.dart';

/// "Today's inspiration": three plants of the day as photo tiles, a way to find
/// recipes with them, and a one-line caption.
class PlantsSection extends StatelessWidget {
  const PlantsSection({
    super.key,
    required this.plants,
    required this.phaseName,
    required this.onFood,
    required this.onFindRecipes,
  });

  final List<Food> plants;

  /// The phase's name as shown in the sentence ("follicular").
  final String phaseName;
  final void Function(Food food) onFood;
  final VoidCallback onFindRecipes;

  static const _tileGap = 10.0;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    const light = MoonColors.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Overline('Today’s inspiration'),
                  const SizedBox(height: 8),
                  Semantics(
                    header: true,
                    child: EditorialHeading(
                      '3 plants *a day*',
                      style: fraunces(30, height: 1.1, tracking: -0.02),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Pressable(
              onTap: onFindRecipes,
              semanticLabel: 'Find recipes with today’s plants',
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.line),
                ),
                child: MoonIcon(
                  MoonIconName.arrowUpRight,
                  size: 19,
                  strokeWidth: 1.9,
                  color: c.text,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (plants.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: _tileGap),
                Expanded(
                  child: i < plants.length
                      ? _PlantTile(
                          food: plants[i],
                          // Light-palette tones in both modes.
                          tone: switch (i) {
                            0 => light.sand,
                            1 => light.phase(Phase.follicular).tint,
                            _ => Color.alphaBlend(
                              light.ochre.withValues(alpha: 0.22),
                              light.bg,
                            ),
                          },
                          onTap: () => onFood(plants[i]),
                        )
                      : const SizedBox(),
                ),
              ],
            ],
          ),
        if (plants.isNotEmpty) const SizedBox(height: 16),
        Text(
          plants.isEmpty
              ? 'No plants fit your food preferences in this phase.'
              : 'Three plants for your $phaseName phase, new every day.',
          style: dmSans(14, height: 1.45, color: c.textMuted),
        ),
      ],
    );
  }
}

class _PlantTile extends StatelessWidget {
  const _PlantTile({
    required this.food,
    required this.tone,
    required this.onTap,
  });

  final Food food;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final photo = plantPhotos[food.id];
    return Pressable(
      onTap: onTap,
      semanticLabel: food.displayName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 1,
              child: photo == null
                  // No photo yet: the tone with the food's emoji.
                  ? ColoredBox(
                      color: tone,
                      child: Center(
                        child: ExcludeSemantics(
                          child: Text(
                            foodEmoji(food),
                            style: const TextStyle(fontSize: 44),
                          ),
                        ),
                      ),
                    )
                  : ColoredBox(
                      color: tone,
                      // Multiply: the photo's white studio background takes the
                      // tone's colour. In dark mode the photo is dimmed a touch.
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(tone, BlendMode.multiply),
                        child: ColorFiltered(
                          colorFilter: dark
                              ? const ColorFilter.matrix(<double>[
                                  0.94, 0, 0, 0, 0, //
                                  0, 0.94, 0, 0, 0, //
                                  0, 0, 0.94, 0, 0, //
                                  0, 0, 0, 1, 0,
                                ])
                              : const ColorFilter.mode(
                                  Color(0x00000000),
                                  BlendMode.dst,
                                ),
                          child: Image.asset(
                            photo.asset,
                            fit: BoxFit.cover,
                            alignment: photo.alignment,
                            width: double.infinity,
                            height: double.infinity,
                            excludeFromSemantics: true,
                            errorBuilder: (_, _, _) => const SizedBox(),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          ExcludeSemantics(
            child: Text(
              food.displayName,
              textAlign: TextAlign.center,
              style: dmSans(
                15,
                weight: FontWeight.w600,
                height: 1.3,
                color: c.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Make something good": the Build a meal card.
class BuildMealCard extends StatelessWidget {
  const BuildMealCard({
    super.key,
    required this.phase,
    required this.onCreate,
    required this.onExploreFoods,
    required this.onExploreRecipes,
  });

  final Phase phase;
  final VoidCallback onCreate;
  final VoidCallback onExploreFoods;
  final VoidCallback onExploreRecipes;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 10),
      decoration: BoxDecoration(
        color: dark ? HeroTokens.darkSolid : HeroTokens.lightWash[phase],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Overline('Make something good'),
                    const SizedBox(height: 8),
                    Semantics(
                      header: true,
                      child: Text(
                        'Build a meal',
                        style: fraunces(32, height: 1.05, color: c.text),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.raised,
                  shape: BoxShape.circle,
                ),
                child: ExcludeSemantics(
                  child: MoonIcon(
                    MoonIconName.recipes,
                    size: 23,
                    color: c.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Choose ingredients you love and discover recipes featuring them.',
            style: dmSans(16, height: 1.5, color: c.text),
          ),
          const SizedBox(height: 14 + 8),
          Pressable(
            onTap: onCreate,
            semanticLabel: 'Create my meal',
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                color: c.ochre,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Create my meal',
                      style: dmSans(
                        16,
                        weight: FontWeight.w600,
                        height: 1.2,
                        color: c.onOchre,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  MoonIcon(
                    MoonIconName.arrow,
                    size: 19,
                    strokeWidth: 1.9,
                    color: c.onOchre,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14 + 4),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _CardLink(
                    icon: MoonIconName.foods,
                    label: 'Explore foods',
                    onTap: onExploreFoods,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CardLink(
                    icon: MoonIconName.recipes,
                    label: 'Explore recipes',
                    onTap: onExploreRecipes,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardLink extends StatelessWidget {
  const _CardLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final MoonIconName icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        // Wraps under the icon rather than overflowing at large text sizes.
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            MoonIcon(icon, size: 19, color: c.textMuted),
            TextLink(label, onTap: null, size: 15),
          ],
        ),
      ),
    );
  }
}

/// "Go to": the shopping list and the diary.
class GoToSection extends StatelessWidget {
  const GoToSection({
    super.key,
    required this.onShopping,
    required this.onDiary,
  });

  final VoidCallback onShopping;
  final VoidCallback onDiary;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Indented to line up with the overline inside the card above.
      Padding(
        padding: const EdgeInsets.only(left: 22),
        child: Semantics(header: true, child: const Overline('Go to')),
      ),
      const SizedBox(height: 14),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _GoToCard(
                icon: MoonIconName.basket,
                title: 'Shopping list',
                subtitle: 'Plan what you need',
                onTap: onShopping,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GoToCard(
                icon: MoonIconName.document,
                title: 'Log diary',
                subtitle: 'Remember what you ate',
                onTap: onDiary,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _GoToCard extends StatelessWidget {
  const _GoToCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final MoonIconName icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Pressable(
      onTap: onTap,
      semanticLabel: '$title, $subtitle',
      child: Container(
        constraints: const BoxConstraints(minHeight: 140),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: MoonIcon(icon, size: 22, color: c.text),
            ),
            const SizedBox(height: 30),
            Text(
              title,
              style: fraunces(
                20,
                weight: FontWeight.w500,
                height: 1.1,
                color: c.text,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: dmSans(
                13,
                weight: FontWeight.w500,
                height: 1.3,
                color: c.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
