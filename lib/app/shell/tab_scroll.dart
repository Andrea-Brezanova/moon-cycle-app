import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/routes.dart';

/// One scroll controller per tab's first screen, so tapping the active tab
/// again can scroll that screen back to the top.
class TabScrollControllers {
  final Map<AppTab, ScrollController> _controllers = {
    for (final tab in AppTab.values) tab: ScrollController(),
  };

  ScrollController of(AppTab tab) => _controllers[tab]!;

  /// Scrolls [tab]'s first screen to the top, if it is showing.
  void scrollToTop(AppTab tab) {
    final c = _controllers[tab]!;
    if (c.hasClients && c.offset > 0) {
      c.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
  }
}

final tabScrollProvider = Provider<TabScrollControllers>((ref) {
  final controllers = TabScrollControllers();
  ref.onDispose(controllers.dispose);
  return controllers;
});
