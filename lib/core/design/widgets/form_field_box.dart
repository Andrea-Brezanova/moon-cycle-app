import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../moon_theme.dart';
import '../tokens/moon_typography.dart';

/// A text input in a raised, hairline-outlined box (a pill on one line, a
/// rounded box on several). The box is the field: no Material underline.
class FormFieldBox extends StatelessWidget {
  const FormFieldBox({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.keyboardType,
    this.formatters,
    this.minLines = 1,
    this.suffix,
    this.capitalization = TextCapitalization.sentences,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final int minLines;
  final String? suffix;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final multi = minLines > 1;
    // The text field fills the whole box (its padding is the field's own), so
    // the tap target is the box.
    return Container(
      decoration: BoxDecoration(
        color: c.raised,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(multi ? 22 : 28),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        textCapitalization: capitalization,
        minLines: minLines,
        maxLines: multi ? null : 1,
        style: dmSans(16, height: 1.5, color: c.text),
        cursorColor: c.ochre,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: dmSans(16, height: 1.5, color: c.textMuted),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          suffixText: suffix,
          suffixStyle: dmSans(15, height: 1.5, color: c.textMuted),
        ),
      ),
    );
  }
}
