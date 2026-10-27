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
import '../../routines/data/routine_repository.dart';
import '../../routines/domain/routine.dart';
import '../data/collection_link_repository.dart';
import '../domain/collection_link.dart';
import 'my_routines_page.dart';

/// One routine: its name, its ordered steps (your own words or saved links),
/// and what you can do with them: add, reorder, remove, rename or delete the
/// routine.
class RoutinePage extends ConsumerStatefulWidget {
  const RoutinePage({super.key, required this.routineId});

  final String routineId;

  @override
  ConsumerState<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends ConsumerState<RoutinePage> {
  final _step = TextEditingController();

  @override
  void dispose() {
    _step.dispose();
    super.dispose();
  }

  RoutineRepository get _repo => ref.read(routineRepositoryProvider);

  void _addText() {
    final text = _step.text;
    _step.clear();
    _repo.addTextStep(widget.routineId, text);
  }

  Future<void> _rename(Routine r) async {
    final title = await askForText(
      context,
      title: 'Rename ${r.kind.name}',
      hint: 'Name your ${r.kind.name}',
      action: 'Save',
      initial: r.title,
    );
    if (title != null) await _repo.rename(r.id, title);
  }

  Future<void> _pickLink(List<CollectionLink> links) async {
    final picked = await showMoonSheet<CollectionLink>(
      context,
      fromTop: 120,
      builder: (_) => _LinkPicker(links: links),
    );
    if (picked != null) await _repo.addLinkStep(widget.routineId, picked.id);
  }

  Future<void> _delete(Routine r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete this ${r.kind.name}?'),
        content: Text(
          '“${r.title}” and its steps will be removed. Saved links stay in '
          'My Collections.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            key: const ValueKey('routine-confirm-delete'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _repo.delete(r.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final routines = ref.watch(routinesProvider).value;
    final links = ref.watch(collectionLinksProvider).value ?? const [];
    Routine? routine;
    for (final r in routines ?? const <Routine>[]) {
      if (r.id == widget.routineId) routine = r;
    }
    final workout = routine?.kind == RoutineKind.workout;
    final noun = workout ? 'workout' : 'routine';
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CenteredHeader(
              title: '',
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(
                      workout
                          ? Routes.collectionWorkouts
                          : Routes.collectionRoutines,
                    ),
              trailingIcon: routine == null ? null : MoonIconName.pencil,
              trailingLabel: 'Rename $noun',
              trailingKey: const ValueKey('routine-rename'),
              onTrailing: routine == null ? null : () => _rename(routine!),
            ),
            Expanded(
              child: routines == null
                  ? const SizedBox.shrink()
                  : routine == null
                  ? Padding(
                      padding: const EdgeInsets.all(MoonSpace.gutter),
                      child: Text(
                        'This is no longer available.',
                        style: MoonType.body.copyWith(color: c.text),
                      ),
                    )
                  : _body(context, routine, links, noun),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    Routine routine,
    List<CollectionLink> links,
    String noun,
  ) {
    final c = context.moon;
    final byId = {for (final l in links) l.id: l};
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        MoonSpace.gutter,
        4,
        MoonSpace.gutter,
        40,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(
            routine.title,
            key: const ValueKey('routine-title'),
            style: fraunces(32, height: 1.12, color: c.text),
          ),
        ),
        const SizedBox(height: 20),
        const Overline('Steps'),
        const SizedBox(height: 8),
        if (routine.steps.isEmpty)
          Text(
            'No steps yet. Add a line of your own or a saved link.',
            key: const ValueKey('routine-no-steps'),
            style: dmSans(14, height: 1.45, color: c.textMuted),
          )
        else
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (oldIndex, newIndex) => _repo.moveStep(
              routine.id,
              routine.steps[oldIndex].id,
              newIndex,
            ),
            children: [
              for (final (i, s) in routine.steps.indexed)
                _StepRow(
                  key: ValueKey('step-${s.id}'),
                  index: i,
                  step: s,
                  link: s.linkId == null ? null : byId[s.linkId],
                  onRemove: () => _repo.removeStep(routine.id, s.id),
                ),
            ],
          ),
        const SizedBox(height: 18),
        MoonTextField(
          key: const ValueKey('routine-step-field'),
          hint: 'Add a step in your own words',
          controller: _step,
          onSubmitted: (_) => _addText(),
          keepFocusOnSubmit: true,
          trailing: Pressable(
            key: const ValueKey('routine-add-step'),
            onTap: _addText,
            semanticLabel: 'Add step',
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
        const SizedBox(height: 12),
        MoonButton(
          'Add a saved link',
          key: const ValueKey('routine-add-link'),
          variant: MoonButtonVariant.ghost,
          onPressed: links.isEmpty ? null : () => _pickLink(links),
        ),
        if (links.isEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Save a workout, spa or recipe link in My Collections first, then '
            'add it here.',
            style: dmSans(13, height: 1.45, color: c.textMuted),
          ),
        ],
        const SizedBox(height: 32),
        Pressable(
          key: const ValueKey('routine-delete'),
          onTap: () => _delete(routine),
          semanticLabel: 'Delete $noun',
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.centerLeft,
            child: Text(
              'Delete $noun',
              style: dmSans(
                15,
                weight: FontWeight.w600,
                height: 1.2,
                color: c.destructive,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    super.key,
    required this.index,
    required this.step,
    required this.link,
    required this.onRemove,
  });

  final int index;
  final RoutineStep step;
  final CollectionLink? link;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final isLink = step.linkId != null;
    final label = isLink ? (link?.title ?? 'Removed link') : (step.text ?? '');
    final detail = isLink && link != null ? link!.platform.label : null;
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
              label: 'Reorder step ${index + 1}',
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
            child: Pressable(
              onTap: isLink && link != null
                  ? () => context.push(Routes.collectionLink(link!.id))
                  : null,
              semanticLabel: '${index + 1}. $label',
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. $label',
                      style: dmSans(
                        16,
                        weight: FontWeight.w500,
                        color: link == null && isLink ? c.textMuted : c.text,
                      ),
                    ),
                    if (detail != null)
                      Text(
                        detail,
                        style: dmSans(12.5, height: 1.3, color: c.textMuted),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Pressable(
            key: ValueKey('step-remove-${step.id}'),
            onTap: onRemove,
            semanticLabel: 'Remove step ${index + 1}',
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

class _LinkPicker extends StatelessWidget {
  const _LinkPicker({required this.links});

  final List<CollectionLink> links;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('Add a saved link', style: fraunces(26, color: c.text)),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              for (final l in links)
                Pressable(
                  key: ValueKey('pick-${l.id}'),
                  onTap: () => Navigator.pop(context, l),
                  semanticLabel: '${l.title}, ${l.platform.label}',
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 56),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: c.line)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l.title,
                                style: dmSans(
                                  16,
                                  weight: FontWeight.w500,
                                  color: c.text,
                                ),
                              ),
                              Text(
                                '${l.category.label} · ${l.platform.label}',
                                style: dmSans(
                                  12.5,
                                  height: 1.3,
                                  color: c.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        MoonIcon(MoonIconName.plus, size: 18, color: c.text),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
