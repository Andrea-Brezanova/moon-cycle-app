import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../privacy/application/data_export_service.dart';

/// "Export my data" (Privacy & Data, Delete my data): opens the share sheet
/// with the export, anchored to the tapped control on iPad.
Future<void> exportMyData(BuildContext context, WidgetRef ref) async {
  final box = context.findRenderObject() as RenderBox?;
  final origin = box == null || !box.hasSize
      ? null
      : box.localToGlobal(Offset.zero) & box.size;
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
