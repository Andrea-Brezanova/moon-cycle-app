import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/centered_header.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/domain/phase.dart';
import '../../routines/data/routine_repository.dart';
import '../../routines/domain/routine.dart';

/// My Collections › My Routines: the reusable sequences you made, each a
/// title and an ordered list of steps (saved links or your own words). No
/// schedule, reminders or suggestions.
class MyRoutinesPage extends ConsumerWidget {
  const MyRoutinesPage({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final title = await askForText(
      context,
      title: 'New routine',
      hint: 'Name your routine',
      action: 'Create',
    );
    if (title == null) return;
    final id = await ref.read(routineRepositoryProvider).create(title);
    if (id != null && context.mounted) {
      await context.push(Routes.routine(id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final routines = ref.watch(routinesProvider).value ?? const <Routine>[];
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CenteredHeader(
              title: 'My Routines',
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(Routes.collections),
              trailingIcon: MoonIconName.plus,
              trailingLabel: 'New routine',
              trailingKey: const ValueKey('routine-new'),
              onTrailing: () => _create(context, ref),
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
                  if (routines.isEmpty)
                    EmptyState(
                      icon: MoonIconName.clock,
                      title: 'No routines yet',
                      body:
                          'A routine is a sequence you can come back to, like '
                          'a morning stretch or an evening wind-down. Add '
                          'your own steps or saved links.',
                      palette: c.phase(Phase.luteal),
                      actions: [
                        MoonButton(
                          'Create a routine',
                          key: const ValueKey('routine-create-empty'),
                          expand: false,
                          onPressed: () => _create(context, ref),
                        ),
                      ],
                    )
                  else
                    for (final r in routines) ...[
                      _RoutineCard(routine: r),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.routine});

  final Routine routine;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final n = routine.steps.length;
    final line = n == 0 ? 'No steps yet' : '$n ${n == 1 ? 'step' : 'steps'}';
    return Pressable(
      key: ValueKey('routine-${routine.id}'),
      onTap: () => context.push(Routes.routine(routine.id)),
      semanticLabel: '${routine.title}. $line',
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
        decoration: BoxDecoration(
          color: c.raised,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(22),
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.title,
                      style: fraunces(19, height: 1.2, color: c.text),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      line,
                      style: dmSans(13, height: 1.3, color: c.textMuted),
                    ),
                  ],
                ),
              ),
              MoonIcon(MoonIconName.chev, size: 16, color: c.chevron),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small sheet with one text field. Returns the trimmed text, or null if
/// cancelled or left empty.
Future<String?> askForText(
  BuildContext context, {
  required String title,
  required String hint,
  required String action,
  String initial = '',
}) => showMoonSheet<String>(
  context,
  builder: (_) =>
      _AskSheet(title: title, hint: hint, action: action, initial: initial),
);

class _AskSheet extends StatefulWidget {
  const _AskSheet({
    required this.title,
    required this.hint,
    required this.action,
    required this.initial,
  });

  final String title;
  final String hint;
  final String action;
  final String initial;

  @override
  State<_AskSheet> createState() => _AskSheetState();
}

class _AskSheetState extends State<_AskSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    Navigator.pop(context, text.isEmpty ? null : text);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(widget.title, style: fraunces(26, color: c.text)),
        ),
        const SizedBox(height: 14),
        MoonTextField(
          key: const ValueKey('ask-field'),
          hint: widget.hint,
          controller: _controller,
          autofocus: true,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        MoonButton(
          widget.action,
          key: const ValueKey('ask-submit'),
          onPressed: _submit,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
