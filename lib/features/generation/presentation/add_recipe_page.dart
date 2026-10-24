import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/centered_header.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/form_field_box.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pill_choice.dart';
import '../../content/domain/recipe.dart';
import '../../diary/presentation/diary_confirm_sheet.dart';
import '../../diary/presentation/diary_toast.dart';
import '../application/generation_providers.dart';
import '../application/manual_recipe_service.dart';
import '../data/personal_recipe_repository.dart';
import '../domain/manual_recipe.dart';
import '../domain/personal_recipe.dart';

/// Add a recipe (or edit one): write your own. The recipe is saved privately
/// on this phone, listed under My recipes › Added by me, and can be logged in
/// the diary and put on the shopping list like any other.
class AddRecipePage extends ConsumerStatefulWidget {
  const AddRecipePage({super.key, this.recipeId});

  /// The recipe to edit; null starts a new one.
  final String? recipeId;

  @override
  ConsumerState<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends ConsumerState<AddRecipePage> {
  final _title = TextEditingController();
  final _minutes = TextEditingController();
  final _serves = TextEditingController();
  final _notes = TextEditingController();
  final _ingredients = TextEditingController();
  final _steps = TextEditingController();
  RecipeCategory _category = RecipeCategory.lunch;

  PersonalRecipe? _existing;
  bool _loading = false;
  bool _missing = false;
  bool _saving = false;
  bool _showProblem = false;

  late String _start = _signature();

  String _signature() => [
    _title.text,
    _category.name,
    _minutes.text,
    _serves.text,
    _notes.text,
    _ingredients.text,
    _steps.text,
  ].join('\u0000');

  bool get _dirty => _signature() != _start;

  ManualRecipeInput get _input => ManualRecipeInput(
    title: _title.text,
    category: _category,
    minutes: int.tryParse(_minutes.text.trim()),
    serves: int.tryParse(_serves.text.trim()),
    notes: _notes.text,
    ingredientsText: _ingredients.text,
    stepsText: _steps.text,
  );

  @override
  void initState() {
    super.initState();
    final id = widget.recipeId;
    if (id == null) return;
    _loading = true;
    ref
        .read(personalRecipeRepositoryProvider)
        .byIdFor(ref.read(personalRecipeOwnersProvider), id)
        .then((r) {
          if (!mounted) return;
          final found = r != null && r.isManual ? r : null;
          setState(() {
            _loading = false;
            if (found == null) {
              _missing = true;
              return;
            }
            _existing = found;
            final input = inputFromRecipe(found.recipe);
            _title.text = input.title;
            _category = input.category;
            _minutes.text = input.minutes?.toString() ?? '';
            _serves.text = input.serves?.toString() ?? '';
            _notes.text = input.notes;
            _ingredients.text = input.ingredientsText;
            _steps.text = input.stepsText;
            _start = _signature();
          });
        });
  }

  @override
  void dispose() {
    for (final c in [_title, _minutes, _serves, _notes, _ingredients, _steps]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _back() async {
    if (_dirty) {
      final discard =
          await showMoonSheet<bool>(
            context,
            builder: (_) => const DiaryConfirmSheet(
              title: 'Discard your changes?',
              body: 'This recipe hasn’t been saved yet.',
              yes: 'Discard',
              no: 'Keep editing',
            ),
          ) ??
          false;
      if (!discard || !mounted) return;
    }
    if (mounted) _leave();
  }

  void _leave([bool saved = false]) =>
      context.canPop() ? context.pop(saved) : context.go(Routes.myRecipes);

  Future<void> _save() async {
    if (_saving) return;
    if (_input.problem != null) {
      setState(() => _showProblem = true);
      return;
    }
    setState(() => _saving = true);
    final service = ref.read(manualRecipeServiceProvider);
    final existing = _existing;
    if (existing != null) {
      await service.update(existing, _input);
    } else {
      await service.create(_input);
    }
    if (!mounted) return;
    showDiaryToast(
      context,
      existing != null ? 'Recipe updated' : 'Added to My recipes',
    );
    _start = _signature();
    _leave(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final editing = widget.recipeId != null;
    final problem = _showProblem ? _input.problem : null;
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: Overline(text),
    );
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              CenteredHeader(
                title: editing ? 'Edit recipe' : 'Add a recipe',
                onBack: _back,
              ),
              Expanded(
                child: _loading
                    ? const SizedBox.shrink()
                    : _missing
                    ? Padding(
                        padding: const EdgeInsets.all(MoonSpace.gutter),
                        child: Text(
                          'We couldn’t find that recipe.',
                          style: MoonType.body.copyWith(color: c.text),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          MoonSpace.gutter,
                          8,
                          MoonSpace.gutter,
                          32,
                        ),
                        children: [
                          Text(
                            'Write your own. It’s saved privately on this '
                            'phone.',
                            textAlign: TextAlign.center,
                            style: dmSans(14, height: 1.5, color: c.textMuted),
                          ),
                          label('Name'),
                          FormFieldBox(
                            controller: _title,
                            hint: 'Recipe name',
                            onChanged: (_) => setState(() {}),
                          ),
                          label('Meal'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              for (final (cat, text) in const [
                                (RecipeCategory.breakfast, 'Breakfast'),
                                (RecipeCategory.lunch, 'Meals'),
                                (RecipeCategory.snack, 'Snacks'),
                              ])
                                PillChoice(
                                  label: text,
                                  selected: _category == cat,
                                  onTap: () => setState(() => _category = cat),
                                ),
                            ],
                          ),
                          label('Time and servings (optional)'),
                          Row(
                            children: [
                              Expanded(
                                child: FormFieldBox(
                                  controller: _minutes,
                                  hint: 'Time',
                                  suffix: 'min',
                                  onChanged: (_) => setState(() {}),
                                  keyboardType: TextInputType.number,
                                  formatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FormFieldBox(
                                  controller: _serves,
                                  hint: 'Serves',
                                  onChanged: (_) => setState(() {}),
                                  keyboardType: TextInputType.number,
                                  formatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(3),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          label('About it (optional)'),
                          FormFieldBox(
                            controller: _notes,
                            hint: 'A line about the recipe',
                            minLines: 2,
                            onChanged: (_) => setState(() {}),
                            keyboardType: TextInputType.multiline,
                          ),
                          label('Ingredients'),
                          FormFieldBox(
                            controller: _ingredients,
                            hint: 'One per line, e.g. 150 g green lentils',
                            minLines: 5,
                            onChanged: (_) => setState(() {}),
                            keyboardType: TextInputType.multiline,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We match names to Moon Cycle foods where we can. '
                            'Anything else is kept as you wrote it, and can’t '
                            'be checked against your food preferences.',
                            style: dmSans(13, height: 1.45, color: c.textMuted),
                          ),
                          label('Steps'),
                          FormFieldBox(
                            controller: _steps,
                            hint: 'One step per line',
                            minLines: 5,
                            onChanged: (_) => setState(() {}),
                            keyboardType: TextInputType.multiline,
                          ),
                          if (problem != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              problem,
                              key: const ValueKey('recipe-problem'),
                              style: dmSans(
                                14,
                                height: 1.4,
                                color: c.destructive,
                              ),
                            ),
                          ],
                          const SizedBox(height: 26),
                          MoonButton(
                            editing ? 'Save changes' : 'Save recipe',
                            onPressed: _saving ? null : _save,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
