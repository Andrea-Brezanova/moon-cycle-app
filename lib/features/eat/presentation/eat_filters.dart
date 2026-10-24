import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/domain/phase.dart';
import '../../content/application/content_providers.dart';
import '../../cycle/application/viewing_phase.dart';
import 'browse_phase_sheet.dart';

/// The one filter system on Foods and Recipes: two equal controls side by side,
/// the phase (left, tinted, opens "Browse by phase") and the type (right,
/// outlined, opens a sheet of the foods' categories or the meal types).
class EatFilterBar extends ConsumerWidget {
  const EatFilterBar({
    super.key,
    required this.all,
    required this.typeLabel,
    required this.typeSemantic,
    required this.onType,
  });

  /// Every phase at once ("All phases").
  final bool all;

  /// What the type control shows: "All foods", "Grains", "All meals"...
  final String typeLabel;

  /// "Showing all foods. Change food type".
  final String typeSemantic;
  final VoidCallback onType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final viewing = ref.watch(viewingPhaseProvider);
    final phaseName = ref.watch(catalogueProvider).phase(viewing).name;
    final label = all ? 'All phases' : phaseName;
    final palette = c.phase(viewing);

    Widget control({
      Key? key,
      required String text,
      required String semantic,
      required VoidCallback onTap,
      required Color fill,
      Color? border,
      Color? dot,
    }) => Pressable(
      key: key,
      onTap: onTap,
      semanticLabel: semantic,
      child: Container(
        height: 44,
        padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
        decoration: ShapeDecoration(
          color: fill,
          shape: StadiumBorder(
            side: border == null ? BorderSide.none : BorderSide(color: border),
          ),
        ),
        child: Row(
          children: [
            if (dot != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: dmSans(
                  14.5,
                  weight: FontWeight.w600,
                  height: 1,
                  color: c.text,
                ),
              ),
            ),
            const SizedBox(width: 8),
            MoonIcon(
              MoonIconName.down,
              size: 17,
              color: c.text,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );

    return Row(
      children: [
        Expanded(
          child: control(
            key: const ValueKey('phase-pill'),
            text: label,
            semantic: all
                ? 'Showing all phases. Change phase'
                : 'Showing ${phaseName.toLowerCase()}. Change phase',
            onTap: () => showBrowsePhaseSheet(context),
            fill: all ? c.sand : palette.tint,
            dot: all ? null : palette.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: control(
            key: const ValueKey('type-filter'),
            text: typeLabel,
            semantic: typeSemantic,
            onTap: onType,
            fill: c.raised,
            border: c.line,
          ),
        ),
      ],
    );
  }
}

/// One choice in the type sheet.
final class TypeOption<T> {
  const TypeOption(this.value, this.label, this.count);

  final T value;
  final String label;
  final int count;
}

/// The type sheet ("Food type" / "Meal type"): radio rows with live counts.
/// Choosing a row applies it and closes the sheet; the chosen value (which may
/// be null for "All") is returned.
Future<void> showTypeSheet<T>(
  BuildContext context, {
  required String title,
  required List<TypeOption<T?>> options,
  required T? selected,
  required Phase phase,
  required ValueChanged<T?> onChosen,
}) => showMoonSheet<void>(
  context,
  builder: (ctx) => _TypeSheet<T>(
    title: title,
    options: options,
    selected: selected,
    phase: phase,
    onChosen: (v) {
      onChosen(v);
      Navigator.of(ctx, rootNavigator: true).pop();
    },
  ),
);

class _TypeSheet<T> extends StatelessWidget {
  const _TypeSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.phase,
    required this.onChosen,
  });

  final String title;
  final List<TypeOption<T?>> options;
  final T? selected;
  final Phase phase;
  final ValueChanged<T?> onChosen;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final palette = c.phase(phase);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: fraunces(28, height: 1.1, color: c.text)),
        ),
        const SizedBox(height: 14),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final o in options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Pressable(
                    onTap: () => onChosen(o.value),
                    selected: o.value == selected,
                    semanticLabel: '${o.label}, ${o.count}',
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 46),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: o.value == selected ? palette.tint : null,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              o.label,
                              style: dmSans(
                                15.5,
                                weight: o.value == selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                height: 1.25,
                                color: c.text,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${o.count}',
                            style: dmSans(13, height: 1, color: c.textMuted),
                          ),
                          const SizedBox(width: 12),
                          _Radio(selected: o.value == selected),
                        ],
                      ),
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

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? c.text : null,
        border: Border.all(color: selected ? c.text : c.textMuted, width: 1.5),
      ),
      child: selected
          ? MoonIcon(
              MoonIconName.check,
              size: 14,
              color: c.bg,
              strokeWidth: 2.6,
            )
          : null,
    );
  }
}
