import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/collections_providers.dart';

/// Opens [url] in the browser or the source's own app. Only `http` and `https`
/// addresses are ever saved; if nothing can open it, say so.
Future<void> openLink(BuildContext context, WidgetRef ref, Uri url) async {
  var opened = false;
  try {
    opened = await ref.read(linkLauncherProvider)(url);
  } on Object {
    opened = false;
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('We couldn’t open that link.')),
    );
  }
}
