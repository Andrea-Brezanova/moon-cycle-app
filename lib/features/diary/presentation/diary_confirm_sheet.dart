import 'package:flutter/material.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/pressable.dart';

/// A two-choice confirmation in a sheet: the first choice is the one that
/// loses something.
class DiaryConfirmSheet extends StatelessWidget {
  const DiaryConfirmSheet({
    super.key,
    required this.title,
    required this.body,
    required this.yes,
    required this.no,
  });

  final String title;
  final String body;
  final String yes;
  final String no;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    void close(bool value) =>
        Navigator.of(context, rootNavigator: true).pop(value);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: fraunces(24, height: 1.15, color: c.text)),
        ),
        const SizedBox(height: 8),
        Text(body, style: dmSans(15, height: 1.5, color: c.textMuted)),
        const SizedBox(height: 22),
        Pressable(
          onTap: () => close(true),
          semanticLabel: yes,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: c.destructive,
              shape: const StadiumBorder(),
            ),
            child: Text(
              yes,
              style: dmSans(
                16,
                weight: FontWeight.w600,
                height: 1.2,
                color: c.onDestructive,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Pressable(
          onTap: () => close(false),
          semanticLabel: no,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            child: Text(
              no,
              style: dmSans(
                16,
                weight: FontWeight.w600,
                height: 1.2,
                color: c.text,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
