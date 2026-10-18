import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../content/domain/text_match.dart';
import '../../cycle/application/viewing_phase.dart';
import '../../entitlements/application/entitlement_providers.dart';
import '../../entitlements/domain/entitlements.dart';
import '../application/food_providers.dart';
import '../application/meal_selection.dart';
import 'widgets/meal_option_chip.dart';

/// Build a Balanced Meal: choose one protein, one base and two or three
/// plants from the whole food library. Foods featured in the viewed phase come
/// first and wear the phase tint; nothing is hidden or disabled because of the
/// phase. Premium only: a free user who reaches it sees why and is pointed to
/// the existing Subscription page.
///
/// [foodId] starts the meal with that food (from its page), in its slot.
/// Creating the meal comes with recipe generation in a later stage.
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
    final phase = ref.watch(viewingPhaseProvider);
    final selection = ref.watch(mealSelectionProvider);
    final catalogue = ref.watch(catalogueProvider);
    final featuredIds = catalogue.phase(phase).foodIds.toSet();
    final palette = c.phase(phase);
    final q = normaliseName(_query);

    Food? food(String? id) => id == null ? null : catalogue.food(id);

    Widget step({
      required int number,
      required String title,
      required String hint,
      required MealSlot slot,
      required List<Food> chosen,
      String? counter,
    }) {
      final options = ref.watch(mealOptionsProvider(slot));
      final searching = q.isNotEmpty;
      final expanded = _expanded.contains(slot);
      final shown = searching
          ? [
              for (final f in options.all)
                if (normaliseName(f.name).contains(q) ||
                    f.synonyms.any((s) => normaliseName(s).contains(q)))
                  f,
            ]
          : expanded
          ? options.all
          : options.suggested;
      final controller = ref.read(mealSelectionProvider.notifier);
      final plantsFull =
          slot == MealSlot.plant &&
          selection.plantIds.length >= MealSelection.maxPlants;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '$number',
                style: fraunces(20, height: 1.1, color: c.textMuted),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      counter == null ? title : '$title · $counter',
                      style: dmSans(
                        16,
                        weight: FontWeight.w600,
                        height: 1.3,
                        color: c.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hint,
                    style: dmSans(14, height: 1.45, color: c.textMuted),
                  ),
                  const SizedBox(height: 12),
                  // Chosen foods that the current list isn't showing.
                  if (chosen.any((f) => !shown.contains(f))) ...[
                    Wrap(
                      spacing: MoonSpace.chipGap,
                      children: [
                        for (final f in chosen.where((f) => !shown.contains(f)))
                          MealOptionChip(
                            food: f,
                            featured: featuredIds.contains(f.id),
                            selected: true,
                            palette: palette,
                            phaseName: phase.name,
                            onTap: () => controller.remove(f.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (shown.isEmpty)
                    Text(
                      searching
                          ? 'No matches here.'
                          : 'Nothing fits your food preferences.',
                      style: dmSans(14, height: 1.4, color: c.textMuted),
                    )
                  else
                    Wrap(
                      spacing: MoonSpace.chipGap,
                      runSpacing: 0,
                      children: [
                        for (final f in shown)
                          MealOptionChip(
                            food: f,
                            featured: featuredIds.contains(f.id),
                            selected: selection.contains(f.id),
                            palette: palette,
                            phaseName: phase.name,
                            onTap: !selection.contains(f.id) && plantsFull
                                ? null
                                : () => controller.toggle(slot, f),
                          ),
                      ],
                    ),
                  if (!searching &&
                      options.all.length > options.suggested.length)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: TextLink(
                        expanded
                            ? 'Show fewer'
                            : 'Show all ${options.all.length}',
                        size: 14,
                        onTap: () => setState(
                          () => expanded
                              ? _expanded.remove(slot)
                              : _expanded.add(slot),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final protein = food(selection.proteinId);
    final base = food(selection.baseId);
    final plants = [for (final id in selection.plantIds) ?food(id)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
        step(
          number: 1,
          title: 'Choose a protein',
          hint:
              'Meat, eggs, tofu, beans and lentils, seafood, dairy, nuts and '
              'seeds. Amounts vary between foods.',
          slot: MealSlot.protein,
          chosen: [?protein],
        ),
        step(
          number: 2,
          title: 'Choose a base',
          hint:
              'Something satisfying: whole grains, potatoes or sweet potatoes, '
              'bread, legumes or other substantial starches.',
          slot: MealSlot.base,
          chosen: [?base],
        ),
        step(
          number: 3,
          title: 'Add 2–3 plants',
          hint: 'Vegetables and fruit you enjoy, for colour and variety.',
          slot: MealSlot.plant,
          chosen: plants,
          counter: '${plants.length} of ${MealSelection.maxPlants}',
        ),
        _Summary(
          protein: protein,
          base: base,
          plants: plants,
          complete: selection.isComplete,
          onClear: selection.isEmpty
              ? null
              : ref.read(mealSelectionProvider.notifier).clear,
        ),
      ],
    );
  }
}

/// "Your meal": what is chosen so far, and what is still missing. Creating the
/// meal arrives with recipe generation, so it is shown as coming soon.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.protein,
    required this.base,
    required this.plants,
    required this.complete,
    required this.onClear,
  });

  final Food? protein;
  final Food? base;
  final List<Food> plants;
  final bool complete;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final parts = [?protein, ?base, ...plants].map((f) => f.displayName);
    final missing = [
      if (protein == null) 'a protein',
      if (base == null) 'a base',
      if (plants.length < MealSelection.minPlants)
        plants.isEmpty
            ? '2–3 plants'
            : 'at least ${MealSelection.minPlants} plants',
    ];
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
            parts.isEmpty ? 'Nothing chosen yet.' : parts.join(' · '),
            style: MoonType.body.copyWith(color: c.text),
          ),
          if (!complete) ...[
            const SizedBox(height: 4),
            Text(
              'Still to choose: ${missing.join(', ')}.',
              style: dmSans(14, height: 1.4, color: c.textMuted),
            ),
          ],
          const SizedBox(height: 16),
          const MoonButton(
            'Create my meal · Coming soon',
            variant: MoonButtonVariant.ghost,
            onPressed: null,
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
