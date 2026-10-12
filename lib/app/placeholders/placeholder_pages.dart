import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/moon_theme.dart';
import '../../core/design/tokens/moon_layout.dart';
import '../../core/design/tokens/moon_typography.dart';
import '../../core/design/widgets/moon_list.dart';
import '../../core/design/widgets/text_link.dart';
import '../config/app_config.dart';
import '../router/routes.dart';
import '../shell/tab_scroll.dart';

// Temporary pages for Milestone 4: they prove the navigation and are built
// only from approved Editorial components. Each one is replaced by its real
// screen in a later milestone (noted on the page) and then deleted.

const _milestone = {
  AppTab.home: 8,
  AppTab.foods: 10,
  AppTab.recipes: 11,
  AppTab.shop: 12,
  AppTab.settings: 13,
};

/// A tab's first screen.
class PlaceholderTabPage extends ConsumerWidget {
  const PlaceholderTabPage({super.key, required this.tab});

  final AppTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    return SafeArea(
      bottom: false,
      child: ListView(
        controller: ref.watch(tabScrollProvider).of(tab),
        padding: const EdgeInsets.fromLTRB(
          MoonSpace.gutter,
          10,
          MoonSpace.gutter,
          MoonSpace.sectionGap,
        ),
        children: [
          Semantics(
            header: true,
            child: Text(tab.label, style: MoonType.h1.copyWith(color: c.text)),
          ),
          const SizedBox(height: 12),
          Text(
            'Placeholder. The real screen arrives in Milestone '
            '${_milestone[tab]}.',
            style: MoonType.body.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: 24),
          ..._content(context, ref),
          // Room to scroll, so "tap the active tab to scroll to the top"
          // can be tried and tested.
          const SizedBox(height: 1600),
          Text(
            'End of ${tab.label}',
            style: MoonType.small.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }

  List<Widget> _content(BuildContext context, WidgetRef ref) => switch (tab) {
    AppTab.settings => [
      Text(
        'Flavour: ${ref.watch(appConfigProvider).flavor.name}',
        style: MoonType.body.copyWith(color: context.moon.textMuted),
      ),
      if (kDebugMode) ...[
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: TextLink(
            'Component gallery',
            onTap: () => context.push(Routes.debugGallery),
          ),
        ),
      ],
      const SizedBox(height: 16),
      MoonListGroup(
        children: [
          for (final page in SettingsPage.values)
            MoonListRow(
              label: page.title,
              onTap: () => context.push(Routes.settings(page)),
            ),
        ],
      ),
    ],
    _ => const [],
  };
}

/// A screen pushed inside a tab (recipe detail, Settings sub-pages).
class PlaceholderSubPage extends StatelessWidget {
  const PlaceholderSubPage({
    super.key,
    required this.title,
    required this.backLabel,
    required this.milestone,
  });

  final String title;
  final String backLabel;
  final int milestone;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          children: [
            SubScreenHeader(
              backLabel: backLabel,
              onBack: () => context.pop(),
              title: title,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MoonSpace.gutter,
                16,
                MoonSpace.gutter,
                0,
              ),
              child: Text(
                'Placeholder page. The real page arrives in Milestone '
                '$milestone.',
                style: MoonType.body.copyWith(color: c.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
