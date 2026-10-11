import 'package:flutter/widgets.dart';

/// A tap target with the Editorial pressed feedback: the design has no ink
/// ripples, so the content dims briefly while pressed.
///
/// [onTap] null means disabled (no feedback, announced as disabled).
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.isButton = true,
    this.selected,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Announce as a button to screen readers.
  final bool isButton;

  /// For toggle-like controls (phase selector, chips): the selected state.
  final bool? selected;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: widget.isButton,
      enabled: enabled,
      selected: widget.selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.7 : 1,
          duration: const Duration(milliseconds: 90),
          child: widget.child,
        ),
      ),
    );
  }
}
