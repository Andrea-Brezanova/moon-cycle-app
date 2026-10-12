import 'package:flutter/material.dart';

import '../moon_theme.dart';
import '../tokens/moon_colors.dart';
import '../tokens/moon_layout.dart';
import '../tokens/moon_typography.dart';
import 'editorial_text.dart';
import 'moon_icon.dart';
import 'pressable.dart';

/// The bottom-sheet frame (spec §6): page colour, top radius 32, a 40 × 5
/// handle. Use with [showMoonSheet].
class MoonSheet extends StatelessWidget {
  const MoonSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(MoonRadius.sheet),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        MoonSpace.gutter,
        12,
        MoonSpace.gutter,
        40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: ShapeDecoration(
                color: c.line,
                shape: const StadiumBorder(),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Flexible(child: child),
        ],
      ),
    );
  }
}

/// Shows [builder]'s content in a [MoonSheet] over the theme's scrim.
///
/// Sheets cover the tab bar (spec §6), so they open on the root navigator,
/// and they rise above the keyboard.
Future<T?> showMoonSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  useRootNavigator: true,
  backgroundColor: const Color(0x00000000),
  barrierColor: context.moon.scrim,
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: MoonSheet(child: builder(context)),
  ),
);

/// The Undo toast after "Clear all" (spec §7.5). Placement (16 from the sides,
/// 104 from the bottom) and the 8-second timer belong to the screen.
class UndoToast extends StatelessWidget {
  const UndoToast({super.key, required this.message, required this.onUndo});

  final String message;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Semantics(
      liveRegion: true,
      child: Container(
        height: 60,
        padding: const EdgeInsets.only(left: 20, right: 10),
        decoration: BoxDecoration(
          color: c.inverseBg,
          borderRadius: BorderRadius.circular(MoonRadius.toast),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3D1B152E),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: dmSans(
                  15,
                  weight: FontWeight.w500,
                  height: 1,
                  color: c.inverseText,
                ),
              ),
            ),
            Pressable(
              onTap: onUndo,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: c.ochre,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Undo',
                  style: dmSans(
                    15,
                    weight: FontWeight.w600,
                    height: 1,
                    color: c.onOchre,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An empty state (spec §6): a tinted circle with a line icon, a Fraunces 26
/// title (words in `*asterisks*` italic), a muted body and the way out.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.palette,
    this.actions = const [],
  });

  final MoonIconName icon;
  final String title;
  final String body;
  final PhasePalette palette;

  /// Usually one or two `TextLink`s.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 28, 12, 0),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: palette.tint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: MoonIcon(
              icon,
              size: 32,
              color: palette.text,
              strokeWidth: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          EditorialHeading(
            title,
            style: fraunces(26, height: 1.15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: dmSans(15, color: c.textMuted),
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(spacing: 22, runSpacing: 12, children: actions),
          ],
        ],
      ),
    );
  }
}

/// An info note (spec §6): raised, hairline outline, radius 20, a muted icon
/// and muted text. Used for privacy and allergy notes.
///
/// [InfoNote.plain] is the onboarding variant: raised, no outline, no icon
/// ("Not sure? 28 and 5 are good starting points.").
class InfoNote extends StatelessWidget {
  const InfoNote({
    super.key,
    required MoonIconName this.icon,
    required this.text,
  }) : outlined = true;

  const InfoNote.plain({super.key, required this.text})
    : icon = null,
      outlined = false;

  final MoonIconName? icon;
  final bool outlined;

  /// Plain text, or rich text with an emphasised lead-in.
  final InlineSpan text;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final body = Text.rich(
      text,
      style: dmSans(14, height: outlined ? 1.45 : 1.5, color: c.textMuted),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(MoonRadius.infoNote),
        border: outlined ? Border.all(color: c.line) : null,
      ),
      child: icon == null
          ? body
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: MoonIcon(
                    icon!,
                    size: 18,
                    color: c.textMuted,
                    strokeWidth: 1.8,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: body),
              ],
            ),
    );
  }
}

/// The "on your list" mark: a tinted circle with a check (spec §6).
class OnListMark extends StatelessWidget {
  const OnListMark({super.key, required this.palette, this.size = 22});

  final PhasePalette palette;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'on your list',
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: palette.tint, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: MoonIcon(
        MoonIconName.check,
        size: (size * 0.55).roundToDouble(),
        color: palette.text,
        strokeWidth: 2.6,
      ),
    ),
  );
}

/// A recipe count: bowl icon and number, muted (food rows, Cook with…).
class RecipeCountBadge extends StatelessWidget {
  const RecipeCountBadge(this.count, {super.key, this.size = 12});

  final int count;

  /// Text size; the icon is 2 pt larger.
  final double size;

  @override
  Widget build(BuildContext context) {
    final muted = context.moon.textMuted;
    return Semantics(
      label: '$count recipe${count == 1 ? '' : 's'}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MoonIcon(
            MoonIconName.recipes,
            size: size + 2,
            color: muted,
            strokeWidth: 1.8,
          ),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: dmSans(
              size,
              weight: FontWeight.w600,
              height: 1,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// The pill text field (spec §6): 52 high, raised, hairline outline; an
/// ochre 2 pt outline while focused.
class MoonTextField extends StatefulWidget {
  const MoonTextField({
    super.key,
    required this.hint,
    this.controller,
    this.leadingIcon,
    this.onSubmitted,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.trailing,
  });

  final String hint;
  final TextEditingController? controller;
  final MoonIconName? leadingIcon;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool autofocus;

  /// E.g. a clear button at the end of a search field.
  final Widget? trailing;

  @override
  State<MoonTextField> createState() => _MoonTextFieldState();
}

class _MoonTextFieldState extends State<MoonTextField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_changed);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final focused = _focus.hasFocus;
    return Container(
      height: MoonSize.input,
      padding: EdgeInsets.only(
        left: widget.leadingIcon == null ? 20 : 18,
        right: 18,
      ),
      decoration: ShapeDecoration(
        color: c.raised,
        shape: StadiumBorder(
          side: BorderSide(
            color: focused ? c.ochre : c.line,
            width: focused ? 2 : 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (widget.leadingIcon != null) ...[
            MoonIcon(
              widget.leadingIcon!,
              size: 18,
              color: c.textMuted,
              strokeWidth: 2,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              onSubmitted: widget.onSubmitted,
              onChanged: widget.onChanged,
              autofocus: widget.autofocus,
              cursorColor: c.text,
              style: dmSans(16, height: 1.2, color: c.text),
              decoration: InputDecoration.collapsed(
                hintText: widget.hint,
                hintStyle: dmSans(16, height: 1.2, color: c.textMuted),
              ),
            ),
          ),
          ?widget.trailing,
        ],
      ),
    );
  }
}
