import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/hero_tokens.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/domain/phase.dart';
import '../../../core/time/today.dart';
import '../../content/application/content_providers.dart';
import '../../cycle/application/cycle_providers.dart';
import 'diary_format.dart';

/// The phase's soft background (cards and rows), or the plum surface in dark.
Color diarySurfaceFor(BuildContext context, Phase phase) =>
    Theme.of(context).brightness == Brightness.dark
    ? HeroTokens.darkSolid
    : HeroTokens.lightWash[phase]!;

/// The phase on [date] and its day of the cycle, "Follicular · day 7".
class PhaseDayLabel {
  const PhaseDayLabel(this.phase, this.text);
  final Phase phase;
  final String text;
}

final phaseDayLabelProvider = Provider.autoDispose
    .family<PhaseDayLabel?, LocalDate>((ref, date) {
      final s = ref.watch(cycleStateProvider).value;
      if (s == null) return null;
      final today = ref.watch(todayProvider);
      final p = phaseOn(s, date, today);
      final name = ref.watch(catalogueProvider).phase(p.phase).name;
      return PhaseDayLabel(p.phase, '$name · day ${p.day}');
    });

/// "‹  Today · Saturday 4 October  ›" with the phase and day under it.
class DiaryDateBar extends ConsumerWidget {
  const DiaryDateBar({
    super.key,
    required this.date,
    required this.onPrevious,
    required this.onNext,
  });

  final LocalDate date;
  final VoidCallback onPrevious;

  /// Null on today (no future days).
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final today = ref.watch(todayProvider);
    final label = ref.watch(phaseDayLabelProvider(date));
    final narrow = MediaQuery.sizeOf(context).width < 375;
    final text = barDate(date, today, short: narrow);
    final next = onNext != null && date.isBefore(today) ? onNext : null;

    Widget arrow(MoonIconName icon, String semantic, VoidCallback? tap) =>
        Pressable(
          onTap: tap,
          semanticLabel: semantic,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tap == null ? null : c.bg,
              shape: BoxShape.circle,
            ),
            child: MoonIcon(
              icon,
              size: 18,
              strokeWidth: 2,
              color: tap == null ? c.removeIcon : c.text,
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: c.raised,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          arrow(MoonIconName.back, 'Previous day', onPrevious),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: dmSans(
                      16,
                      weight: FontWeight.w600,
                      height: 1.25,
                      color: c.text,
                    ),
                  ),
                  if (label != null) ...[
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: c.phase(label.phase).accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            label.text,
                            style: dmSans(
                              12.5,
                              weight: FontWeight.w500,
                              height: 1.2,
                              color: c.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          arrow(MoonIconName.chev, 'Next day', next),
        ],
      ),
    );
  }
}

/// A form's top row: "Cancel", a centred title, and a balancing space.
class DiaryFormHeader extends StatelessWidget {
  const DiaryFormHeader({
    super.key,
    required this.title,
    required this.onCancel,
  });

  final String title;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final cancel = Pressable(
      onTap: onCancel,
      semanticLabel: 'Cancel',
      child: Container(
        constraints: const BoxConstraints(minWidth: 72, minHeight: 44),
        alignment: Alignment.centerLeft,
        child: Text(
          'Cancel',
          style: dmSans(15, weight: FontWeight.w500, color: c.textMuted),
        ),
      ),
    );
    final heading = Semantics(
      header: true,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: dmSans(17, weight: FontWeight.w600, height: 1.2, color: c.text),
      ),
    );
    // At large text sizes Cancel and the title no longer fit side by side:
    // Cancel sits above and the title gets the full width.
    if (MediaQuery.textScalerOf(context).scale(15) > 20) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: Alignment.centerLeft, child: cancel),
          Padding(padding: const EdgeInsets.only(bottom: 4), child: heading),
        ],
      );
    }
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          cancel,
          Expanded(child: heading),
          const SizedBox(width: 72),
        ],
      ),
    );
  }
}

/// A form section: overline, optional hint on the right, then the content.
class DiarySection extends StatelessWidget {
  const DiarySection({
    super.key,
    required this.title,
    this.hint,
    required this.child,
  });

  final String title;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Semantics(header: true, child: Overline(title))),
            if (hint != null)
              Text(
                hint!,
                style: dmSans(
                  12.5,
                  weight: FontWeight.w500,
                  color: c.removeIcon,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// Equal-width single choice (Energy, Sleep, strength). Tapping the chosen
/// option again clears it.
class DiaryChoiceRow<T> extends StatelessWidget {
  const DiaryChoiceRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.semanticLabel,
  });

  final List<(T, String)> options;
  final T? selected;
  final ValueChanged<T?> onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Semantics(
      container: true,
      label: semanticLabel,
      // IntrinsicHeight + stretch: when one label wraps (large text, narrow
      // phone) every option grows to the same height.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, (value, label)) in options.indexed) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Pressable(
                  onTap: () => onChanged(value == selected ? null : value),
                  selected: value == selected,
                  semanticLabel: label,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 6,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value == selected ? c.inverseBg : c.raised,
                      border: value == selected
                          ? null
                          : Border.all(color: c.line),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    // A word never breaks mid-way: a label that doesn't fit its
                    // column shrinks a little instead (large text, narrow phone).
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: dmSans(
                          13,
                          weight: value == selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          height: 1.15,
                          color: value == selected ? c.inverseText : c.text,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The fixed bottom bar of a form: a hairline and the gold button.
class DiarySaveBar extends StatelessWidget {
  const DiarySaveBar({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        MediaQuery.paddingOf(context).bottom > 0 ? 24 : 14,
      ),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: MoonButton(label, onPressed: onPressed),
    );
  }
}

/// A multi-line optional note field (surface fill, line border, radius 18).
class DiaryNoteField extends StatelessWidget {
  const DiaryNoteField({
    super.key,
    required this.controller,
    required this.hint,
    required this.semanticLabel,
  });

  final TextEditingController controller;
  final String hint;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Semantics(
      textField: true,
      label: semanticLabel,
      child: Container(
        decoration: BoxDecoration(
          color: c.raised,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(18),
        ),
        child: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          style: dmSans(15, height: 1.45, color: c.text),
          cursorColor: c.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: dmSans(15, height: 1.45, color: c.removeIcon),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }
}
