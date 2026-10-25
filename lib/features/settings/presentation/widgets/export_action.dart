import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/moon_surfaces.dart';
import '../../../../core/design/widgets/pressable.dart';
import '../../../privacy/application/data_export_service.dart';

/// "Export my data" (Privacy & Data, Delete my data): first says what the file
/// contains and that it isn't protected once it leaves the app, then opens the
/// share sheet with the export, anchored to the tapped control on iPad.
Future<void> exportMyData(BuildContext context, WidgetRef ref) async {
  final box = context.findRenderObject() as RenderBox?;
  final origin = box == null || !box.hasSize
      ? null
      : box.localToGlobal(Offset.zero) & box.size;
  final go = await showMoonSheet<bool>(
    context,
    builder: (_) => const _ExportWarning(),
  );
  if (go != true || !context.mounted) return;
  try {
    await ref.read(dataExportServiceProvider).share(origin: origin);
  } on Exception {
    if (!context.mounted) return;
    // Not drawn: the same message style as other save failures.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Couldn’t export. Please try again.')),
    );
  }
}

/// The notice before an export. The file is plain text: Moon Cycle's
/// encryption covers the data on the phone, not a copy that is shared.
class _ExportWarning extends StatelessWidget {
  const _ExportWarning();

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
          child: Text(
            'Before you export',
            style: fraunces(24, height: 1.15, color: c.text),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your export may contain sensitive writing: your cycle history, '
          'diary entries, activities, the personal Notes you wrote and the '
          'links you saved.',
          style: dmSans(15, height: 1.5, color: c.text),
        ),
        const SizedBox(height: 10),
        Text(
          'The file is not encrypted once it leaves the app. Anyone who can '
          'open it can read it. Share it only with people or places you '
          'trust, and delete your copies when you no longer need them.',
          style: dmSans(15, height: 1.5, color: c.textMuted),
        ),
        const SizedBox(height: 22),
        Pressable(
          onTap: () => close(true),
          semanticLabel: 'Continue to export',
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: c.inverseBg,
              shape: const StadiumBorder(),
            ),
            child: Text(
              'Continue to export',
              style: dmSans(
                16,
                weight: FontWeight.w600,
                height: 1.2,
                color: c.inverseText,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Pressable(
          onTap: () => close(false),
          semanticLabel: 'Cancel',
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            child: Text(
              'Cancel',
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
