import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/centered_header.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_icon.dart';

/// A diary feature that isn't built yet (Log activities, Notes): an honest,
/// quiet page. It has no form and saves nothing.
class DiaryComingSoonPage extends StatelessWidget {
  const DiaryComingSoonPage({
    super.key,
    required this.title,
    required this.icon,
    required this.headline,
    required this.body,
  });

  final String title;
  final MoonIconName icon;
  final String headline;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CenteredHeader(
              title: title,
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(Routes.diary),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MoonSpace.gutter,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ExcludeSemantics(
                            child: Container(
                              width: 72,
                              height: 72,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: c.sand,
                                shape: BoxShape.circle,
                              ),
                              child: MoonIcon(icon, size: 30, color: c.text),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Overline('Coming soon'),
                          const SizedBox(height: 10),
                          Text(
                            headline,
                            textAlign: TextAlign.center,
                            style: fraunces(26, height: 1.15, color: c.text),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            body,
                            textAlign: TextAlign.center,
                            style: dmSans(15, height: 1.5, color: c.textMuted),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
