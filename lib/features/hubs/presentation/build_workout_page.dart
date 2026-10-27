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
import '../application/hub_providers.dart';
import '../application/workout_draft.dart';
import '../domain/hub_item.dart';

/// Move › Build Your Workout: put a workout together from individual
/// exercises. Choose from the Exercises library (reviewed items only) or type
/// your own, reorder with the handles, remove with the minus. Saving the
/// finished workout to My Workouts needs a storage addition that is awaiting
/// approval, so the button says so instead of pretending to save.
class BuildWorkoutPage extends ConsumerStatefulWidget {
  const BuildWorkoutPage({super.key});

  @override
  ConsumerState<BuildWorkoutPage> createState() => _BuildWorkoutPageState();
}

class _BuildWorkoutPageState extends ConsumerState<BuildWorkoutPage> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _addTyped() {
    ref.read(workoutDraftProvider.notifier).addCustom(_name.text);
    _name.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final draft = ref.watch(workoutDraftProvider);
    final library = ref.watch(hubItemsOfKindProvider(HubKind.exercise));
    final notifier = ref.read(workoutDraftProvider.notifier);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CenteredHeader(
              title: 'Build Your Workout',
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(AppTab.move.path),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  MoonSpace.gutter,
                  14,
                  MoonSpace.gutter,
                  40,
                ),
                children: [
                  Text(
                    'Choose exercises and put them in the order you like.',
                    style: dmSans(15, height: 1.5, color: c.textMuted),
                  ),
                  const SizedBox(height: 18),
                  const Overline('Exercises'),
                  const SizedBox(height: 8),
                  if (library.isEmpty)
                    Text(
                      'Moon Cycle’s exercises are being written and reviewed. '
                      'Until then, add your own below.',
                      key: const ValueKey('workout-library-empty'),
                      style: dmSans(14, height: 1.45, color: c.textMuted),
                    )
                  else
                    for (final e in library)
                      _LibraryRow(
                        item: e,
                        onAdd: () => notifier.addLibrary(e.id, e.title),
                      ),
                  const SizedBox(height: 14),
                  MoonTextField(
                    key: const ValueKey('workout-add-field'),
                    hint: 'Add your own exercise',
                    controller: _name,
                    onSubmitted: (_) => _addTyped(),
                    trailing: Pressable(
                      key: const ValueKey('workout-add'),
                      onTap: _addTyped,
                      semanticLabel: 'Add exercise',
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: MoonIcon(
                          MoonIconName.plus,
                          size: 20,
                          color: c.text,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Overline('Your workout'),
                  const SizedBox(height: 8),
                  if (draft.isEmpty)
                    Text(
                      'Nothing added yet.',
                      key: const ValueKey('workout-empty'),
                      style: dmSans(14, height: 1.45, color: c.textMuted),
                    )
                  else
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      onReorderItem: notifier.move,
                      children: [
                        for (final (i, e) in draft.indexed)
                          _DraftRow(
                            key: ValueKey('workout-row-${e.key}'),
                            index: i,
                            exercise: e,
                            onRemove: () => notifier.remove(e.key),
                          ),
                      ],
                    ),
                  const SizedBox(height: 22),
                  const MoonButton(
                    'Save to My Workouts',
                    key: ValueKey('workout-save'),
                    variant: MoonButtonVariant.ghost,
                    onPressed: null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saving a built workout is not available yet: it needs a '
                    'small storage addition that is waiting for approval. '
                    'Your list is kept only while you are on this page.',
                    key: const ValueKey('workout-save-note'),
                    style: dmSans(13, height: 1.45, color: c.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryRow extends StatelessWidget {
  const _LibraryRow({required this.item, required this.onAdd});

  final HubItem item;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Pressable(
      key: ValueKey('workout-lib-${item.id}'),
      onTap: onAdd,
      semanticLabel: 'Add ${item.title}',
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: dmSans(16, weight: FontWeight.w500, color: c.text),
              ),
            ),
            if (item.durationMinutes != null)
              Text(
                '${item.durationMinutes} min',
                style: dmSans(13, color: c.textMuted),
              ),
            const SizedBox(width: 10),
            MoonIcon(MoonIconName.plus, size: 18, color: c.text),
          ],
        ),
      ),
    );
  }
}

class _DraftRow extends StatelessWidget {
  const _DraftRow({
    super.key,
    required this.index,
    required this.exercise,
    required this.onRemove,
  });

  final int index;
  final DraftExercise exercise;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Semantics(
              label: 'Reorder ${exercise.name}',
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: MoonIcon(MoonIconName.more, size: 20, color: c.text),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${index + 1}. ${exercise.name}',
              style: dmSans(16, weight: FontWeight.w500, color: c.text),
            ),
          ),
          Pressable(
            key: ValueKey('workout-remove-${exercise.key}'),
            onTap: onRemove,
            semanticLabel: 'Remove ${exercise.name}',
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: MoonIcon(MoonIconName.minus, size: 20, color: c.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
