import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_layout.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/moon_chip.dart';
import '../../../../core/design/widgets/moon_icon.dart';
import '../../../../core/design/widgets/pressable.dart';
import '../../../../core/domain/phase.dart';
import '../../../content/domain/food.dart';
import '../../application/food_providers.dart';

/// "Build a balanced meal" (Foods › This phase): educational guidance, not a
/// meal planner. Protein, a satisfying base and 2–3 plants, with protein
/// sources named across categories and ideas that respect the user's diet.
/// Featured status is shown as emphasis only; every idea is fine to eat in
/// any phase.
class MealBuilderSection extends ConsumerStatefulWidget {
  const MealBuilderSection({
    super.key,
    required this.phase,
    this.onFood,
    this.initiallyExpanded = false,
  });

  final Phase phase;
  final ValueChanged<Food>? onFood;
  final bool initiallyExpanded;

  @override
  ConsumerState<MealBuilderSection> createState() => _MealBuilderSectionState();
}

class _MealBuilderSectionState extends ConsumerState<MealBuilderSection> {
  late bool _open = widget.initiallyExpanded;
  late bool _baseOpen = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final ideas = ref.watch(proteinIdeasProvider(widget.phase));
    final baseIdeas = ref.watch(baseIdeasProvider(widget.phase));
    final body = dmSans(15, height: 1.5, color: c.textMuted);
    final strong = dmSans(
      16,
      weight: FontWeight.w600,
      height: 1.3,
      color: c.text,
    );

    Widget step(String number, String title, String text, {Widget? extra}) =>
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 16, bottom: 16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.line)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  number,
                  style: fraunces(20, height: 1.1, color: c.textMuted),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: strong),
                    const SizedBox(height: 4),
                    Text(text, style: body),
                    if (extra != null) ...[const SizedBox(height: 12), extra],
                  ],
                ),
              ),
            ],
          ),
        );

    Widget ideaChips(FoodIdeas ideas) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ideas.featured.isNotEmpty) ...[
          Text(
            'Featured this phase',
            style: dmSans(
              13,
              weight: FontWeight.w600,
              height: 1,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: MoonSpace.chipGap,
            runSpacing: MoonSpace.chipGap,
            children: [
              for (final f in ideas.featured)
                MoonChip(
                  f.displayName,
                  onTap: widget.onFood == null ? null : () => widget.onFood!(f),
                ),
            ],
          ),
        ],
        if (ideas.general.isNotEmpty) ...[
          if (ideas.featured.isNotEmpty) const SizedBox(height: 14),
          Text(
            'Also good',
            style: dmSans(
              13,
              weight: FontWeight.w600,
              height: 1,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: MoonSpace.chipGap,
            runSpacing: MoonSpace.chipGap,
            children: [
              for (final f in ideas.general)
                MoonOutlineChip(
                  f.displayName,
                  icon: null,
                  onTap: widget.onFood == null ? null : () => widget.onFood!(f),
                ),
            ],
          ),
        ],
      ],
    );

    Widget toggle(String label, bool open, VoidCallback onTap) => Pressable(
      onTap: onTap,
      expanded: open,
      semanticLabel: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: dmSans(
                  15,
                  weight: FontWeight.w600,
                  height: 1.2,
                  color: c.text,
                ),
              ),
            ),
            const SizedBox(width: 6),
            RotatedBox(
              quarterTurns: open ? 3 : 1,
              child: MoonIcon(
                MoonIconName.chev,
                size: 14,
                color: c.chevron,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Build a balanced meal',
            style: fraunces(26, height: 1.12, color: c.text),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'For a simple meal, start with a protein, add a satisfying base, '
          'then add 2–3 plants you enjoy.',
          style: MoonType.body.copyWith(color: c.text),
        ),
        const SizedBox(height: 16),
        step(
          '1',
          'Choose a protein',
          'Protein comes from meat, eggs, tofu, beans and lentils, seafood, '
              'dairy, nuts and seeds. Amounts vary between foods.',
          extra: ideas.isEmpty
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    toggle(
                      'Protein ideas',
                      _open,
                      () => setState(() => _open = !_open),
                    ),
                    if (_open) ideaChips(ideas),
                  ],
                ),
        ),
        step(
          '2',
          'Choose a base',
          'Something satisfying: whole grains, potatoes or sweet potatoes, '
              'bread, legumes or other substantial starches.',
          extra: baseIdeas.isEmpty
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    toggle(
                      'Base ideas',
                      _baseOpen,
                      () => setState(() => _baseOpen = !_baseOpen),
                    ),
                    if (_baseOpen) ideaChips(baseIdeas),
                  ],
                ),
        ),
        step(
          '3',
          'Add 2–3 plants',
          'Vegetables and fruit you enjoy, for colour and variety.',
        ),
        const SizedBox(height: 4),
        Text(
          'Featured foods are what Moon Cycle emphasizes in this phase for '
          'nutrition fit, meal style and variety. You can enjoy any food at '
          'any time.',
          style: dmSans(13, height: 1.4, color: c.textMuted),
        ),
      ],
    );
  }
}
