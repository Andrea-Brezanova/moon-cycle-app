import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_colors.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/centered_header.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/form_field_box.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_segmented.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pill_choice.dart';
import '../../../core/domain/phase.dart';
import '../../collections/data/collection_link_repository.dart';
import '../../collections/domain/collection_link.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/recipe.dart';
import '../../diary/presentation/diary_confirm_sheet.dart';
import '../../diary/presentation/diary_toast.dart';
import '../application/generation_providers.dart';
import '../application/manual_recipe_service.dart';
import '../data/personal_recipe_repository.dart';
import '../domain/manual_recipe.dart';
import '../domain/personal_recipe.dart';
import '../domain/recipe_text_parser.dart';

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
  final _paste = TextEditingController();
  final _linkAddress = TextEditingController();
  final _linkTitle = TextEditingController();
  final _linkCreator = TextEditingController();
  final _linkNote = TextEditingController();
  bool _linkTried = false;
  RecipeCategory _category = RecipeCategory.lunch;

  /// New recipes can be written, or filled in from pasted text.
  _Mode _mode = _Mode.write;

  /// What the last paste found, shown above the form until the user saves.
  PastedRecipe? _imported;

  // The ingredient lines that can't be matched to a Moon Cycle food, worked
  // out only when the ingredient text changes.
  String _checkedText = '\u0000';
  List<String> _unchecked = const [];
  int _lineCount = 0;

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
    _paste.text,
    _linkAddress.text,
    _linkTitle.text,
    _linkCreator.text,
    _linkNote.text,
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
    for (final c in [
      _title,
      _minutes,
      _serves,
      _notes,
      _ingredients,
      _steps,
      _paste,
      _linkAddress,
      _linkTitle,
      _linkCreator,
      _linkNote,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Fills the form from the pasted text. Nothing is saved: the user reviews
  /// and saves.
  Future<void> _review() async {
    final parsed = parsePastedRecipe(_paste.text);
    if (parsed.isEmpty) return;
    final hasWriting = [
      _title,
      _notes,
      _ingredients,
      _steps,
    ].any((c) => c.text.trim().isNotEmpty);
    if (hasWriting) {
      final replace =
          await showMoonSheet<bool>(
            context,
            builder: (_) => const DiaryConfirmSheet(
              title: 'Replace what you’ve written?',
              body: 'The form will be filled in from the pasted text.',
              yes: 'Replace',
              no: 'Keep mine',
            ),
          ) ??
          false;
      if (!replace || !mounted) return;
    }
    setState(() {
      _title.text = parsed.title;
      _minutes.text = parsed.minutes?.toString() ?? '';
      _serves.text = parsed.serves?.toString() ?? '';
      _notes.text = parsed.notes;
      _ingredients.text = parsed.ingredients.join('\n');
      _steps.text = parsed.steps.join('\n');
      _imported = parsed;
      _mode = _Mode.write;
    });
  }

  void _checkIngredients() {
    final text = _ingredients.text;
    if (text == _checkedText) return;
    _checkedText = text;
    final foods = ref.read(catalogueProvider).foods;
    final lines = splitLines(text);
    _lineCount = lines.length;
    _unchecked = [
      for (final l in lines)
        if (matchFood(l, foods) == null) l,
    ];
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

  /// Saves the link tab: a link to a recipe found elsewhere. It is only a
  /// link (no ingredients), kept in My recipes under Links.
  Future<void> _saveLink() async {
    if (_saving) return;
    setState(() => _linkTried = true);
    if (parseLinkAddress(_linkAddress.text) == null ||
        _linkTitle.text.trim().isEmpty) {
      return;
    }
    setState(() => _saving = true);
    final saved = await ref
        .read(collectionLinkRepositoryProvider)
        .add(
          category: LinkCategory.recipes,
          address: _linkAddress.text,
          title: _linkTitle.text,
          creator: _linkCreator.text,
          note: _linkNote.text,
        );
    if (!mounted) return;
    if (saved == null) {
      setState(() => _saving = false);
      showDiaryToast(context, 'We couldn’t save that link. Please try again.');
      return;
    }
    showDiaryToast(context, 'Link added to My recipes');
    _start = _signature();
    _leave(true);
  }

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

  /// The "Add a link" tab.
  List<Widget> _linkForm(MoonColors c) {
    final addressBad =
        _linkTried && parseLinkAddress(_linkAddress.text) == null;
    final titleBad = _linkTried && _linkTitle.text.trim().isEmpty;
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: Overline(text),
    );
    Widget problem(String text) => Padding(
      padding: const EdgeInsets.only(top: 6, left: 6),
      child: Text(text, style: dmSans(13, height: 1.35, color: c.destructive)),
    );
    return [
      label('Link'),
      FormFieldBox(
        key: const ValueKey('link-address'),
        controller: _linkAddress,
        hint: 'youtube.com/watch?v=…',
        keyboardType: TextInputType.url,
        capitalization: TextCapitalization.none,
        onChanged: (_) => setState(() {}),
      ),
      if (addressBad)
        problem(
          'Enter a web address that starts with http or https, like '
          'youtube.com/watch?v=…',
        ),
      label('Name'),
      FormFieldBox(
        key: const ValueKey('link-title'),
        controller: _linkTitle,
        hint: 'What is it called?',
        onChanged: (_) => setState(() {}),
      ),
      if (titleBad) problem('Give it a name.'),
      label('Creator (optional)'),
      FormFieldBox(
        key: const ValueKey('link-creator'),
        controller: _linkCreator,
        hint: 'Who made it?',
      ),
      label('Your note (optional)'),
      FormFieldBox(
        key: const ValueKey('link-note'),
        controller: _linkNote,
        hint: 'Why you saved it',
        minLines: 3,
        keyboardType: TextInputType.multiline,
      ),
      const SizedBox(height: 26),
      MoonButton(
        'Save link',
        key: const ValueKey('save-recipe-link'),
        onPressed: _saving ? null : _saveLink,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final editing = widget.recipeId != null;
    final problem = _showProblem ? _input.problem : null;
    _checkIngredients();
    final pasting = _mode == _Mode.paste && !editing;
    final linking = _mode == _Mode.link && !editing;
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
                          if (!editing) ...[
                            MoonSegmented<_Mode>(
                              semanticLabel: 'How to add the recipe',
                              options: const [
                                (_Mode.write, 'Write my own'),
                                (_Mode.paste, 'Paste text'),
                                (_Mode.link, 'Add a link'),
                              ],
                              selected: _mode,
                              onChanged: (m) => setState(() => _mode = m),
                            ),
                            const SizedBox(height: 14),
                          ],
                          Text(
                            linking
                                ? 'Save a link to a recipe you found elsewhere. '
                                      'It opens at its source; nothing is '
                                      'downloaded or copied, and it isn’t used '
                                      'to search by ingredient.'
                                : pasting
                                ? 'Paste a recipe you already have. It’s read '
                                      'here on your phone, never sent '
                                      'anywhere, and nothing is saved until '
                                      'you check it and save.'
                                : 'Write your own. It’s saved privately on '
                                      'this phone.',
                            textAlign: TextAlign.center,
                            style: dmSans(14, height: 1.5, color: c.textMuted),
                          ),
                          if (linking) ...[
                            ..._linkForm(c),
                          ] else if (pasting) ...[
                            const SizedBox(height: 18),
                            FormFieldBox(
                              controller: _paste,
                              hint: 'Paste your recipe here',
                              minLines: 12,
                              onChanged: (_) => setState(() {}),
                              keyboardType: TextInputType.multiline,
                              capitalization: TextCapitalization.none,
                            ),
                            const SizedBox(height: 20),
                            MoonButton(
                              'Review recipe',
                              onPressed: _paste.text.trim().isEmpty
                                  ? null
                                  : _review,
                            ),
                          ] else ...[
                            if (_imported != null) ...[
                              const SizedBox(height: 16),
                              _ImportNote(found: _imported!),
                            ],
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
                                    onTap: () =>
                                        setState(() => _category = cat),
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
                            _UncheckedNote(
                              total: _lineCount,
                              unchecked: _unchecked,
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

enum _Mode { write, paste, link }

/// After a paste: what was found, and a reminder that it is a draft.
class _ImportNote extends StatelessWidget {
  const _ImportNote({required this.found});

  final PastedRecipe found;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final got = [
      if (found.title.isNotEmpty) 'a name',
      if (found.ingredients.isNotEmpty)
        '${found.ingredients.length} '
            '${found.ingredients.length == 1 ? 'ingredient' : 'ingredients'}',
      if (found.steps.isNotEmpty)
        '${found.steps.length} ${found.steps.length == 1 ? 'step' : 'steps'}',
      if (found.serves != null) 'servings',
      if (found.minutes != null) 'a time',
    ];
    final missed = [
      if (found.title.isEmpty) 'a name',
      if (found.ingredients.isEmpty) 'ingredients',
      if (found.steps.isEmpty) 'steps',
    ];
    return Container(
      key: const ValueKey('import-note'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.phase(Phase.follicular).tint.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'From your pasted text',
            style: fraunces(19, height: 1.2, color: c.text),
          ),
          const SizedBox(height: 6),
          Text(
            'Check everything and fix anything we got wrong. Nothing is saved '
            'until you tap Save.',
            style: dmSans(14, height: 1.45, color: c.text),
          ),
          if (got.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Found: ${got.join(', ')}.',
              style: dmSans(13, height: 1.45, color: c.textMuted),
            ),
          ],
          if (missed.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Not found, so left empty: ${missed.join(', ')}.',
              style: dmSans(13, height: 1.45, color: c.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Under the ingredients: which lines can't be checked against food
/// preferences or allergens (we don't recognise them as a Moon Cycle food).
class _UncheckedNote extends StatelessWidget {
  const _UncheckedNote({required this.total, required this.unchecked});

  final int total;
  final List<String> unchecked;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    if (total == 0 || unchecked.isEmpty) {
      return Text(
        total == 0
            ? 'We match names to Moon Cycle foods where we can. Anything else '
                  'is kept as you wrote it, and can’t be checked against your '
                  'food preferences.'
            : 'Every ingredient was matched to a Moon Cycle food.',
        key: const ValueKey('unchecked-none'),
        style: dmSans(13, height: 1.45, color: c.textMuted),
      );
    }
    final shown = unchecked.take(6).toList();
    return Container(
      key: const ValueKey('unchecked-note'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${unchecked.length} of $total '
            '${total == 1 ? 'ingredient' : 'ingredients'} can’t be checked '
            'against your food preferences or allergens:',
            style: dmSans(
              13,
              weight: FontWeight.w600,
              height: 1.45,
              color: c.text,
            ),
          ),
          const SizedBox(height: 4),
          for (final l in shown)
            Text('• $l', style: dmSans(13, height: 1.45, color: c.textMuted)),
          if (unchecked.length > shown.length)
            Text(
              '…and ${unchecked.length - shown.length} more',
              style: dmSans(13, height: 1.45, color: c.textMuted),
            ),
          const SizedBox(height: 4),
          Text(
            'Check these yourself before you cook.',
            style: dmSans(13, height: 1.45, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
