import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/moon_theme.dart';
import '../router/routes.dart';
import 'moon_tab_bar.dart';
import 'tab_scroll.dart';

/// The five-tab shell (PRD §3, "Tab mechanics").
///
/// - Each tab keeps its own stack (the router's indexed stack).
/// - Switching tabs is instant, with no animation.
/// - Tapping the active tab returns it to its first screen; if it is already
///   there, the screen scrolls to the top.
/// - Android back: inside a tab, one screen back (handled by the tab's own
///   navigator); on the first screen of Foods, Recipes, Shop or Settings, to
///   Home; on Home's first screen, the app may close.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  AppTab get _current => AppTab.values[shell.currentIndex];

  /// True when the active tab shows its first screen.
  bool _atTabRoot(BuildContext context) =>
      GoRouter.of(context).state.uri.path == _current.path;

  void _select(BuildContext context, WidgetRef ref, AppTab tab) {
    if (tab != _current) {
      shell.goBranch(tab.index);
    } else if (!_atTabRoot(context)) {
      shell.goBranch(tab.index, initialLocation: true);
    } else {
      ref.read(tabScrollProvider).scrollToTop(tab);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final atHome = _current == AppTab.home;
    return PopScope(
      // Only reached when the active tab is on its first screen: pushed
      // screens inside a tab are popped by that tab's navigator first.
      canPop: atHome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) shell.goBranch(AppTab.home.index);
      },
      child: Scaffold(
        backgroundColor: context.moon.bg,
        body: shell,
        bottomNavigationBar: MoonTabBar(
          current: _current,
          onSelect: (tab) => _select(context, ref, tab),
        ),
      ),
    );
  }
}
