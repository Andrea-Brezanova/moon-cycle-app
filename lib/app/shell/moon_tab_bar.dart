import 'package:flutter/material.dart';

import '../../core/design/moon_theme.dart';
import '../../core/design/tokens/moon_layout.dart';
import '../../core/design/tokens/moon_typography.dart';
import '../../core/design/widgets/moon_icon.dart';
import '../../core/design/widgets/pressable.dart';
import '../router/routes.dart';

/// The Editorial tab bar (spec §6): solid `raised`, a hairline on top, five
/// equal tabs, each a 23 pt icon over an 11 pt label, with a 5 pt ochre dot
/// under the active tab.
///
/// 88 pt tall including the home-indicator area. If the system's bottom inset
/// is larger than the iPhone home indicator (34 pt), the bar grows by the
/// difference so nothing sits under the system bar.
class MoonTabBar extends StatelessWidget {
  const MoonTabBar({super.key, required this.current, required this.onSelect});

  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  static const double homeIndicator = 34;

  /// The bar's height for a given bottom inset.
  static double heightFor(double bottomInset) =>
      MoonSize.tabBar +
      (bottomInset > homeIndicator ? bottomInset - homeIndicator : 0);

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final inset = MediaQuery.paddingOf(context).bottom;
    return Container(
      height: heightFor(inset),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      decoration: BoxDecoration(
        color: c.raised,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final tab in AppTab.values)
              Expanded(
                child: _TabItem(
                  key: ValueKey('tab-${tab.name}'),
                  tab: tab,
                  active: tab == current,
                  onTap: () => onSelect(tab),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    super.key,
    required this.tab,
    required this.active,
    required this.onTap,
  });

  final AppTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final color = active ? c.text : c.textMuted;
    return Pressable(
      onTap: onTap,
      selected: active,
      semanticLabel: tab.label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MoonIcon(
            tab.icon,
            size: MoonSize.tabIcon,
            color: color,
            strokeWidth: active ? 1.9 : 1.6,
          ),
          const SizedBox(height: 5),
          Text(
            tab.label,
            maxLines: 1,
            textScaler: TextScaler.noScaling,
            style: MoonType.tab.copyWith(
              color: color,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            key: active ? const ValueKey('tab-active-dot') : null,
            width: MoonSize.activeDot,
            height: MoonSize.activeDot,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? c.ochre : null,
            ),
          ),
        ],
      ),
    );
  }
}
