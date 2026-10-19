import 'package:flutter/material.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_icon.dart';

/// A tab that exists in the navigation but isn't built yet (Move, Relax).
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title, required this.icon});

  final String title;
  final MoonIconName icon;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MoonSpace.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Semantics(
                header: true,
                child: Text(title, style: MoonType.h1.copyWith(color: c.text)),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: box.maxHeight),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: c.sand,
                                shape: BoxShape.circle,
                              ),
                              child: MoonIcon(icon, size: 28, color: c.text),
                            ),
                            const SizedBox(height: 20),
                            const Overline('Coming soon'),
                            const SizedBox(height: 10),
                            Text(
                              '$title is on its way.',
                              textAlign: TextAlign.center,
                              style: fraunces(26, height: 1.15, color: c.text),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'We’re building it with care. Nothing to do here yet.',
                              textAlign: TextAlign.center,
                              style: dmSans(
                                15,
                                height: 1.5,
                                color: c.textMuted,
                              ),
                            ),
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
      ),
    );
  }
}
