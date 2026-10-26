import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/hub_item.dart';

/// The bundled, editor-approved Move and Relax content. The file ships with
/// no approved items until a reviewer adds them (assets/content/README.md).
final hubItemsProvider = FutureProvider<List<HubItem>>((ref) async {
  final source = await rootBundle.loadString('assets/content/hub_content.json');
  return parseHubItems(source);
});

/// The approved items of one kind.
final hubItemsOfKindProvider = Provider.family<List<HubItem>, HubKind>((
  ref,
  kind,
) {
  final all = ref.watch(hubItemsProvider).value ?? const <HubItem>[];
  return [
    for (final i in all)
      if (i.kind == kind) i,
  ];
});

final hubItemProvider = Provider.family<HubItem?, String>((ref, id) {
  for (final i in ref.watch(hubItemsProvider).value ?? const <HubItem>[]) {
    if (i.id == id) return i;
  }
  return null;
});
