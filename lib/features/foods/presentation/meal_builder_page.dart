import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/centered_header.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../content/domain/text_match.dart';
import '../../cycle/application/viewing_phase.dart' show actualPhaseProvider;
import '../../entitlements/application/entitlement_providers.dart';
import '../../entitlements/domain/entitlements.dart';
import '../application/food_providers.dart';
import '../application/meal_selection.dart';
import 'widgets/food_chip.dart';

/// Build a meal: choose one or more foods you feel like cooking with, from any
/// category, and find recipes that use them. Each section (proteins, bases,
/// plants) is optional guidance, not a requirement.
///
/// A section first shows only the foods of the user's **current** phase;
/// "Show all foods" adds the rest below, in their own group. Any food can be
/// chosen whichever phase it is from, up to [MealBuilderConfig.maxIngredients].
/// Free for everyone. If its tier is ever raised, a user without it sees why and is pointed to the
/// existing Subscription page.
///
/// [foodId] starts the meal with that food (from its page).
class MealBuilderPage extends ConsumerStatefulWidget {
  const MealBuilderPage({super.key, this.foodId});

  final String? foodId;

  @override
  ConsumerState<MealBuilderPage> createState() => _MealBuilderPageState();
}

class _MealBuilderPageState extends ConsumerState<MealBuilderPage> {
  final _search = TextEditingController();
  String _query = '';
  final _expanded = <MealSlot>{};

  @override
  void initState() {
    super.initState();
    final id = widget.foodId;
    if (id != null) {
      // After the first frame: providers can't change while building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final food = ref.read(catalogueProvider).food(id);
        if (mounted && food != null) {
          ref.read(mealSelectionProvider.notifier).seed(food);
        }
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _search.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final allowed = ref.watch(featureGateProvider).canUse(Feature.buildMeal);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 42 + 76),
          children: [
            // Back goes to whichever screen opened this one (a food's page, or
            // Eat); with nothing to go back to, to Eat.
            CenteredHeader(
              title: 'Meal builder',
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(AppTab.eat.path),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MoonSpace.gutter,
                12,
                MoonSpace.gutter,
                0,
              ),
              child: allowed ? _builder(context) : _locked(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locked(BuildContext context) {
    final c = context.moon;
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
        const SizedBox(height: 10),
        Text(
          'Build a Meal is part of Moon Cycle Premium.',
          style: MoonType.body.copyWith(color: c.text),
        ),
        const SizedBox(height: 18),
        MoonButton(
          'See Premium',
          expand: false,
          onPressed: () =>
              context.go(Routes.settings(SettingsPage.subscription)),
        ),
      ],
    );
  }

  Widget _builder(BuildContext context) {
    final c = context.moon;
    final phase = ref.watch(actualPhaseProvider);
    final selection = ref.watch(mealSelectionProvider);
    final catalogue = ref.watch(catalogueProvider);
    final featuredIds = catalogue.phase(phase).foodIds.toSet();
    final palette = c.phase(phase);
    final q = normaliseName(_query);
    final controller = ref.read(mealSelectionProvider.notifier);
    final chosen = [for (final id in selection.ids) ?catalogue.food(id)];

    Widget chip(Food f) => FoodChip(
      food: f,
      palette: palette,
      featured: featuredIds.contains(f.id),
      selected: selection.contains(f.id),
      semanticLabelOverride: [
        f.displayName,
        if (featuredIds.contains(f.id)) 'featured in your ${phase.name} phase',
        if (selection.contains(f.id)) 'chosen',
      ].join(', '),
      // At the limit, foods not yet chosen are dimmed and cannot be added.
      onTap: !selection.contains(f.id) && selection.isFull
          ? null
          : () => controller.toggle(f),
    );

    Widget chips(List<Food> foods) => Wrap(
      spacing: MoonSpace.chipGap,
      runSpacing: MoonSpace.chipGap,
      children: [for (final f in foods) chip(f)],
    );

    Widget section({
      required MealSlot slot,
      required String title,
      required String hint,
    }) {
      final options = ref.watch(mealOptionsProvider(slot));
      final searching = q.isNotEmpty;
      final expanded = _expanded.contains(slot);
      bool matches(Food f) =>
          normaliseName(f.name).contains(q) ||
          f.synonyms.any((s) => normaliseName(s).contains(q));

      // What is listed: current-phase foods; or, searching, every eligible
      // food that matches (current phase first); or, expanded, the phase
      // foods and then the others as their own group.
      final primary = searching
          ? [
              for (final f in options.phaseFoods)
                if (matches(f)) f,
            ]
          : options.phaseFoods;
      final others = searching
          ? [
              for (final f in options.otherFoods)
                if (matches(f)) f,
            ]
          : expanded
          ? options.otherFoods
          : const <Food>[];
      final listed = {
        for (final f in [...primary, ...others]) f.id,
      };
      // Chosen foods the list is not showing stay visible and removable.
      final hidden = [
        for (final f in chosen)
          if (mealSlotFor(f) == slot && !listed.contains(f.id)) f,
      ];

      return Container(
        key: ValueKey('section-${slot.name}'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: dmSans(
                  16,
                  weight: FontWeight.w600,
                  height: 1.3,
                  color: c.text,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(hint, style: dmSans(14, height: 1.45, color: c.textMuted)),
            const SizedBox(height: 12),
            if (hidden.isNotEmpty) ...[
              chips(hidden),
              const SizedBox(height: MoonSpace.chipGap),
            ],
            if (primary.isEmpty && others.isEmpty)
              Text(
                searching
                    ? 'No matches here.'
                    : options.all.isEmpty
                    ? 'Nothing fits your food preferences.'
                    : 'No ${title.toLowerCase()} are featured in your '
                          '${phase.name} phase. Show all foods to see more.',
                style: dmSans(14, height: 1.4, color: c.textMuted),
              )
            else ...[
              if (primary.isNotEmpty) chips(primary),
              if (others.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  searching ? 'Other phases' : 'From other phases',
                  key: ValueKey('other-phases-${slot.name}'),
                  style: dmSans(
                    13,
                    weight: FontWeight.w600,
                    height: 1.3,
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                chips(others),
              ],
            ],
            if (!searching && options.otherFoods.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextLink(
                  expanded ? 'Show fewer foods' : 'Show all foods',
                  size: 14,
                  onTap: () => setState(
                    () =>
                        expanded ? _expanded.remove(slot) : _expanded.add(slot),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Build a meal',
            style: fraunces(26, height: 1.12, color: c.text),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose one or more foods you feel like eating. We’ll find recipes '
          'that bring your ingredients together.',
          style: MoonType.body.copyWith(color: c.text),
        ),
        const SizedBox(height: 16),
        MoonTextField(
          hint: 'Search foods',
          leadingIcon: MoonIconName.search,
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
          trailing: _query.isEmpty
              ? null
              : Pressable(
                  onTap: _clearSearch,
                  semanticLabel: 'Clear search',
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: MoonIcon(
                      MoonIconName.close,
                      size: 16,
                      color: c.textMuted,
                      strokeWidth: 2,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: palette.tint,
                shape: BoxShape.circle,
                border: Border.all(color: palette.accent),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tinted: featured in your ${phase.name} phase. Any food works '
                'in any phase.',
                style: dmSans(13, height: 1.4, color: c.textMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        section(
          slot: MealSlot.protein,
          title: 'Proteins',
          hint:
              'Meat, eggs, tofu, beans and lentils, seafood, dairy, nuts and '
              'seeds. Optional.',
        ),
        section(
          slot: MealSlot.base,
          title: 'Bases',
          hint: 'Whole grains, potatoes, bread or other starches. Optional.',
        ),
        section(
          slot: MealSlot.plant,
          title: 'Plants',
          hint: 'Vegetables and fruit. Optional.',
        ),
        _Summary(
          chosen: chosen,
          onCreate: selection.canCreate
              ? () => context.push(Routes.mealResults(selection.ids))
              : null,
          onClear: selection.isEmpty ? null : controller.clear,
        ),
      ],
    );
  }
}

/// "Your meal": what is chosen so far, and the button that finds recipes. One
/// food is enough; nothing else is required.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.chosen,
    required this.onCreate,
    required this.onClear,
  });

  final List<Food> chosen;
  final VoidCallback? onCreate;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final full = chosen.length >= MealBuilderConfig.maxIngredients;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 18),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Overline('Your meal'),
          const SizedBox(height: 8),
          Text(
            chosen.isEmpty
                ? 'Nothing chosen yet.'
                : chosen.map((f) => f.displayName).join(' · '),
            style: MoonType.body.copyWith(color: c.text),
          ),
          const SizedBox(height: 4),
          Text(
            full
                ? 'That’s the most foods one search can use '
                      '(${MealBuilderConfig.maxIngredients}). Remove one to '
                      'add another.'
                : chosen.isEmpty
                ? 'Choose at least one food.'
                : '${chosen.length} of ${MealBuilderConfig.maxIngredients} foods',
            key: const ValueKey('meal-count'),
            style: dmSans(14, height: 1.4, color: c.textMuted),
          ),
          const SizedBox(height: 16),
          MoonButton(
            'Create my meal',
            variant: onCreate == null
                ? MoonButtonVariant.ghost
                : MoonButtonVariant.primary,
            onPressed: onCreate,
          ),
          if (onClear != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextLink('Clear my choices', size: 14, onTap: onClear),
            ),
          ],
        ],
      ),
    );
  }
}
