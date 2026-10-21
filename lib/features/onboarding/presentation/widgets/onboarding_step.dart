import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_layout.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/editorial_text.dart';
import '../../../../core/design/widgets/moon_icon.dart';
import '../../../../core/design/widgets/pinned_actions_scroll.dart';
import '../../../../core/design/widgets/pressable.dart';

/// The layout of onboarding steps 2–4 (spec §7.1): the progress header, the
/// question, the step's content, and its actions pinned to the bottom. The
/// page scrolls when it doesn't fit (small phones, large text).
class OnboardingStep extends StatelessWidget {
  const OnboardingStep({
    super.key,
    required this.step,
    required this.overline,
    required this.question,
    this.helper,
    required this.content,
    required this.actions,
    this.gap = 26,
  });

  /// 1, 2 or 3 (of 3).
  final int step;
  final String overline;

  /// The H2 with its last words in `*italic*`.
  final String question;
  final String? helper;

  /// The step's blocks between the question and the actions.
  final List<Widget> content;
  final List<Widget> actions;

  /// Space between the blocks (26; 22 on the cycle-length step).
  final double gap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final bottom = math.max(40.0, MediaQuery.viewPaddingOf(context).bottom + 6);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: PinnedActionsScroll(
          padding: EdgeInsets.fromLTRB(
            MoonSpace.gutterOnboarding,
            8,
            MoonSpace.gutterOnboarding,
            bottom,
          ),
          minGap: gap,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OnboardingProgress(step: step),
              SizedBox(height: gap),
              Semantics(
                header: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Overline(overline),
                    const SizedBox(height: 12),
                    EditorialHeading(question, style: MoonType.h2),
                    if (helper != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        helper!,
                        style: dmSans(16, height: 1.5, color: c.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              for (final child in content) ...[SizedBox(height: gap), child],
            ],
          ),
          actions: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: actions,
          ),
        ),
      ),
    );
  }
}

/// Back button, three progress bars and "n of 3".
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Row(
      children: [
        Transform.translate(
          offset: const Offset(-10, 0),
          child: Pressable(
            onTap: () => context.pop(),
            semanticLabel: 'Back',
            child: SizedBox.square(
              dimension: 44,
              child: Center(
                child: MoonIcon(
                  MoonIconName.back,
                  size: 22,
                  color: c.text,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6), // 16 minus the back button's -10 offset
        Expanded(
          child: Semantics(
            label: 'Step $step of 3',
            excludeSemantics: true,
            child: Row(
              children: [
                for (var i = 1; i <= 3; i++) ...[
                  if (i > 1) const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: ShapeDecoration(
                        color: i <= step ? c.ochre : c.line,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        ExcludeSemantics(
          child: Text(
            '$step of 3',
            style: dmSans(
              13,
              weight: FontWeight.w500,
              height: 1,
              color: c.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
