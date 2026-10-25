import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_layout.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/moon_list.dart';

/// A Settings sub-screen: "‹ Settings", the title, then [children] spaced
/// by [gap] (`26`–`32` in the designs).
class SettingsSubScaffold extends StatelessWidget {
  const SettingsSubScaffold({
    super.key,
    required this.title,
    this.titleSize = 40,
    this.top = 18,
    this.gap = 28,
    this.backLabel = 'Settings',
    required this.children,
  });

  /// Words in `*asterisks*` are italic.
  final String title;
  final double titleSize;

  /// Space between the title and the first child.
  final double top;
  final double gap;

  /// The page the back button returns to: 'Settings' for the pages under
  /// Settings, 'Account & Plus' for the subscription and privacy pages, 'Me'
  /// for the hubs themselves.
  final String backLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 42),
          children: [
            SubScreenHeader(
              backLabel: backLabel,
              onBack: () => context.pop(),
              title: title,
              titleSize: titleSize,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                MoonSpace.gutter,
                top,
                MoonSpace.gutter,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, child) in children.indexed) ...[
                    if (i > 0) SizedBox(height: gap),
                    child,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The lead paragraph under a sub-screen title (16, muted).
class SettingsHelper extends StatelessWidget {
  const SettingsHelper(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: dmSans(16, height: 1.5, color: context.moon.textMuted));
}

/// The small note at the end of a sub-screen (13, muted).
class SettingsFootnote extends StatelessWidget {
  const SettingsFootnote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: dmSans(13, height: 1.45, color: context.moon.textMuted),
  );
}
