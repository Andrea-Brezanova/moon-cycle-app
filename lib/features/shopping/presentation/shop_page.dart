import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/shell/tab_scroll.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../content/application/content_providers.dart';
import '../../cycle/application/viewing_phase.dart';
import '../../cycle/presentation/phase_header.dart';
import '../../generation/application/generation_providers.dart';
import '../application/shopping_controller.dart';
import '../application/shopping_summary.dart';
import '../domain/shopping_item.dart';
import '../domain/shopping_list.dart';
import 'widgets/shop_row.dart';

/// The Shop tab (`09-shop`, `35-shop-empty`, `36-shop-undo`): one list for
/// the user, To buy grouped by aisle and a collapsed Done. The phase selector
/// only sets the shared context; it never filters the list (PRD §4).
class ShopPage extends ConsumerStatefulWidget {
  const ShopPage({super.key});

  @override
  ConsumerState<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<ShopPage> {
  final _add = TextEditingController();
  final _addFocus = FocusNode();
  bool _doneOpen = false;

  @override
  void dispose() {
    _add.dispose();
    _addFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _add.text;
    if (text.trim().isEmpty) return;
    _add.clear();
    await ref.read(shoppingControllerProvider.notifier).addTyped(text);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final items = ref.watch(shoppingItemsProvider).value ?? const [];
    final summary = ref.watch(shoppingSummaryProvider);
    final catalogue = ref.watch(catalogueProvider);
    final viewing = ref.watch(viewingPhaseProvider);
    final controller = ref.read(shoppingControllerProvider.notifier);
    final undo = ref.watch(shoppingControllerProvider);
    final groups = toBuyByAisle(items, [
      for (final a in catalogue.aisles) a.id,
    ]);
    final done = doneItems(items);
    final total = summary.toBuy + summary.done;

    Widget row(ShoppingItem item, {required bool divider}) => ShopRow(
      item: item,
      divider: divider,
      fallbackPhase: viewing,
      recipeTitle: (id) =>
          catalogue.recipe(id)?.title ??
          ref.watch(personalRecipeTitlesProvider)[id],
      onToggle: () => controller.toggle(item),
      onRemove: () => controller.remove(item),
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ListView(
              controller: ref.watch(tabScrollProvider).of(AppTab.shop),
              padding: const EdgeInsets.only(bottom: 42 + 76),
              children: [
                const PhaseHeader(title: 'Shopping list', showPhaseLine: false),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    MoonSpace.gutter,
                    26,
                    MoonSpace.gutter,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Summary(
                        toBuy: summary.toBuy,
                        done: summary.done,
                        showDone: total > 0,
                      ),
                      const SizedBox(height: 14),
                      _Progress(
                        fraction: total == 0 ? 0 : summary.done / total,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: MoonTextField(
                              hint: 'Add an item',
                              controller: _add,
                              focusNode: _addFocus,
                              keepFocusOnSubmit: true,
                              onSubmitted: (_) => _submit(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          RoundIconButton.add(onPressed: _submit),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (items.isEmpty)
                        EmptyState(
                          icon: MoonIconName.shop,
                          title: 'Your list is *empty*',
                          body:
                              'Add foods from Foods or a recipe’s ingredients, or '
                              'type an item above.',
                          palette: c.phase(viewing),
                          actions: [
                            TextLink(
                              'Browse foods',
                              onTap: () => context.go(AppTab.foods.path),
                            ),
                          ],
                        ),
                      for (final (aisle, inAisle) in groups) ...[
                        const SizedBox(height: 22),
                        Overline(catalogue.aisle(aisle).name),
                        const SizedBox(height: 4),
                        for (final (i, item) in inAisle.indexed)
                          row(item, divider: i > 0),
                      ],
                      if (done.isNotEmpty) ...[
                        const SizedBox(height: 26),
                        Container(
                          padding: const EdgeInsets.only(top: 16),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: c.line)),
                          ),
                          child: Row(
                            children: [
                              Pressable(
                                onTap: () =>
                                    setState(() => _doneOpen = !_doneOpen),
                                semanticLabel:
                                    'Done, ${done.length} '
                                    '${done.length == 1 ? 'item' : 'items'}, '
                                    '${_doneOpen ? 'expanded' : 'collapsed'}',
                                child: SizedBox(
                                  height: 44,
                                  child: Row(
                                    children: [
                                      Text(
                                        'Done',
                                        style: fraunces(24, color: c.text),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: ShapeDecoration(
                                          color: c.sand,
                                          shape: const StadiumBorder(),
                                        ),
                                        child: Text(
                                          '${done.length}',
                                          style: dmSans(
                                            13,
                                            weight: FontWeight.w600,
                                            height: 1,
                                            color: c.text,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      AnimatedRotation(
                                        turns: _doneOpen ? 0.5 : 0,
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        child: MoonIcon(
                                          MoonIconName.down,
                                          size: 18,
                                          color: c.text,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              TextLink(
                                'Clear all',
                                size: 14,
                                onTap: controller.clearDone,
                              ),
                            ],
                          ),
                        ),
                        if (_doneOpen)
                          for (final (i, item) in done.indexed)
                            row(item, divider: i > 0),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (undo != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: UndoToast(
                message: undo.message,
                onUndo: controller.undoClear,
              ),
            ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.toBuy,
    required this.done,
    required this.showDone,
  });

  final int toBuy;
  final int done;

  /// "0 done" shows once there's a list; an empty list shows only "0 to buy".
  final bool showDone;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Semantics(
      label: '$toBuy to buy${showDone ? ', $done done' : ''}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            // Unchanged at 390 pt; shrinks on narrow phones at large text.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.bottomLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$toBuy',
                    style: MoonType.shopCount.copyWith(color: c.text),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'to buy',
                    style: fraunces(20, italic: true, color: c.text),
                  ),
                ],
              ),
            ),
          ),
          if (showDone)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '$done done',
                style: dmSans(
                  14,
                  weight: FontWeight.w500,
                  height: 1,
                  color: c.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return ExcludeSemantics(
      child: Container(
        height: 4,
        decoration: ShapeDecoration(
          color: c.line,
          shape: const StadiumBorder(),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fraction,
          child: Container(
            decoration: ShapeDecoration(
              color: c.text,
              shape: const StadiumBorder(),
            ),
          ),
        ),
      ),
    );
  }
}
